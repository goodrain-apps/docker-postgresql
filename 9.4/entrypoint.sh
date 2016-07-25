#!/bin/bash

[ $DEBUG ] && set -x

set -e

# set this env variable to true to enable a line in the
# pg_hba.conf file to trust samenet.  this can be used to connect
# from other containers on the same host without authentication
PSQL_TRUST_LOCALNET=${PSQL_TRUST_LOCALNET:-true}

DB_NAME=${DB_NAME:-${POSTGRESQL_USER:-admin}}
DB_USER=${DB_USER:-${POSTGRESQL_USER:-admin}}
DB_PASS=${DB_PASS:-${POSTGRESQL_PASS:-}}
DB_UNACCENT=${DB_UNACCENT:false}

# by default postgresql will start up as a standalone instance.
# set this environment variable to master, slave or snapshot to use replication features.
# "snapshot" will create a point in time backup of a master instance.
PSQL_MODE=${PSQL_MODE:-standalone}

REPLICATION_USER=${REPLICATION_USER:-}
REPLICATION_PASS=${REPLICATION_PASS:-}
REPLICATION_HOST=${REPLICATION_HOST:-}
REPLICATION_PORT=${REPLICATION_PORT:-5432}

# set this env variable to "require" to enable encryption and "verify-full" for verification.
PSQL_SSLMODE=${PSQL_SSLMODE:-disable}

create_data_dir() {
  mkdir -p ${PG_HOME}
  chmod -R 0700 ${PG_HOME}
  chown -R ${PG_USER}:${PG_USER} ${PG_HOME}
}

create_log_dir() {
  mkdir -p ${PG_LOGDIR}
  chmod -R 1775 ${PG_LOGDIR}
  chown -R root:${PG_USER} ${PG_LOGDIR}
}

create_run_dir() {
  mkdir -p ${PG_RUNDIR} ${PG_RUNDIR}/${PG_VERSION}-main.pg_stat_tmp
  chmod -R 0755 ${PG_RUNDIR}
  chmod g+s ${PG_RUNDIR}
  chown -R ${PG_USER}:${PG_USER} ${PG_RUNDIR}
}

create_log_dir
create_run_dir

# get the config file
if [ "$MEMORY_SIZE" == "" ];then
    echo "Must set MEMORY_SIZE environment variable! "
exit 1
else
  echo "memory type:$MEMORY_SIZE"
  wget -q http://config.goodrain.me/services/postgresql/9.4/${MEMORY_SIZE}.conf -O ${PG_CONFDIR}/postgresql.conf
  if [ $? -ne 0 ];then
    echo "get ${MEMORY_SIZE} config error!"
    exit 1
  fi
fi

# fix ownership of ${PG_CONFDIR} (may be necessary if USERMAP_* was set)
chown -R ${PG_USER}:${PG_USER} ${PG_CONFDIR}

if [[ ${PSQL_SSLMODE} == disable ]]; then
  sed 's/ssl = true/#ssl = true/' -i ${PG_CONFDIR}/postgresql.conf
fi

# Change DSM from `posix' to `sysv' if we are inside an lx-brand container
if [[ $(uname -v) == "BrandZ virtual linux" ]]; then
  sed 's/\(dynamic_shared_memory_type = \)posix/\1sysv/' \
    -i ${PG_CONFDIR}/postgresql.conf
fi

if [[ ${PSQL_TRUST_LOCALNET} == true ]]; then
  echo "Enabling trust samenet in pg_hba.conf..."
  cat >> ${PG_CONFDIR}/pg_hba.conf <<EOF
host    all             all             samenet                 trust
EOF
fi

# allow remote connections to postgresql database
cat >> ${PG_CONFDIR}/pg_hba.conf <<EOF
host    all             all             0.0.0.0/0               md5
EOF

# allow replication connections to the database
if [[ -n ${REPLICATION_USER} ]]; then
  if [[ ${PSQL_SSLMODE} == disable ]]; then
    cat >> ${PG_CONFDIR}/pg_hba.conf <<EOF
host    replication     $REPLICATION_USER       0.0.0.0/0               md5
EOF
  else
    cat >> ${PG_CONFDIR}/pg_hba.conf <<EOF
hostssl replication     $REPLICATION_USER       0.0.0.0/0               md5
EOF
  fi
fi

if [[ ${PSQL_MODE} == master ]]; then
  if [[ -n ${REPLICATION_USER} ]]; then
    echo "Supporting hot standby..."
    cat >> ${PG_CONFDIR}/postgresql.conf <<EOF
wal_level = hot_standby
max_wal_senders = 3
checkpoint_segments = 8
wal_keep_segments = 8
EOF
  fi
fi

cd ${PG_HOME}

# initialize PostgreSQL data directory
if [[ ! -d ${PG_DATADIR} ]]; then

  create_data_dir

  if [[ ${PSQL_MODE} == slave || ${PSQL_MODE} == snapshot ]]; then
    echo "Replicating database..."
    if [[ ${PSQL_MODE} == snapshot ]]; then
      sudo -Hu ${PG_USER} \
        PGPASSWORD=$REPLICATION_PASS ${PG_BINDIR}/pg_basebackup -D ${PG_DATADIR} \
        -h ${REPLICATION_HOST} -p ${REPLICATION_PORT} -U ${REPLICATION_USER} -w -x -v -P
    elif [[ ${PSQL_MODE} == slave ]]; then
      # Setup streaming replication.
      sudo -Hu ${PG_USER} \
        PGPASSWORD=$REPLICATION_PASS ${PG_BINDIR}/pg_basebackup -D ${PG_DATADIR} \
        -h ${REPLICATION_HOST} -p ${REPLICATION_PORT} -U ${REPLICATION_USER} -w -v -P
      echo "Setting up hot standby configuration..."
      cat >> ${PG_CONFDIR}/postgresql.conf <<EOF
hot_standby = on
EOF
      sudo -Hu ${PG_USER} touch ${PG_DATADIR}/recovery.conf
      cat >> ${PG_DATADIR}/recovery.conf <<EOF
standby_mode = 'on'
primary_conninfo = 'host=${REPLICATION_HOST} port=${REPLICATION_PORT} user=${REPLICATION_USER} password=${REPLICATION_PASS} sslmode=${PSQL_SSLMODE}'
trigger_file = '/tmp/postgresql.trigger'
EOF
    fi

  else
    # check if we need to perform data migration
    PG_OLD_VERSION=$(find ${PG_HOME}/[0-9].[0-9]/main -maxdepth 1 -name PG_VERSION 2>/dev/null | sort -r | head -n1 | cut -d'/' -f5)

    echo "正在初始化数据库..."
    sudo -Hu ${PG_USER} ${PG_BINDIR}/initdb --pgdata=${PG_DATADIR} \
      --username=${PG_USER} --encoding=unicode --auth=trust >/dev/null
  fi
fi

if [[ -n ${PG_OLD_VERSION} ]]; then
  echo "Migrating postgresql ${PG_OLD_VERSION} data..."
  PG_OLD_CONFDIR="/etc/postgresql/${PG_OLD_VERSION}/main"
  PG_OLD_BINDIR="/usr/lib/postgresql/${PG_OLD_VERSION}/bin"
  PG_OLD_DATADIR="${PG_HOME}/${PG_OLD_VERSION}/main"

  # backup ${PG_OLD_DATADIR} to avoid data loss
  PG_BKP_SUFFIX=$(date +%Y%m%d%H%M%S)
  echo "Backing up ${PG_OLD_DATADIR} to ${PG_OLD_DATADIR}.${PG_BKP_SUFFIX}..."
  cp -a ${PG_OLD_DATADIR} ${PG_OLD_DATADIR}.${PG_BKP_SUFFIX}

  echo "Installing postgresql-${PG_OLD_VERSION}..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install postgresql-${PG_OLD_VERSION} postgresql-client-${PG_OLD_VERSION}
  rm -rf /var/lib/apt/lists/*

  # migrate ${PG_OLD_VERSION} data
  echo "Migration in progress. This could take a while, please be patient..."
  sudo -Hu ${PG_USER} ${PG_BINDIR}/pg_upgrade \
    -b ${PG_OLD_BINDIR} -B ${PG_BINDIR} \
    -d ${PG_OLD_DATADIR} -D ${PG_DATADIR} \
    -o "-c config_file=${PG_OLD_CONFDIR}/postgresql.conf" \
    -O "-c config_file=${PG_CONFDIR}/postgresql.conf" >/dev/null
fi

# Hot standby (slave and snapshot) servers can ignore the following code.
if [[ ! -f ${PG_HOME}/.init.ed ]]; then
  if [[ ${PSQL_MODE} == standalone || ${PSQL_MODE} == master ]]; then
    if [[ -n ${REPLICATION_USER} ]]; then
      if [[ -z ${REPLICATION_PASS} ]]; then
        echo ""
        echo "WARNING: "
        echo "  Please specify a password for replication user \"${REPLICATION_USER}\". Skipping user creation..."
        echo ""
        DB_USER=
      else
        echo "Creating user \"${REPLICATION_USER}\"..."
        echo "CREATE ROLE ${REPLICATION_USER} WITH REPLICATION LOGIN ENCRYPTED PASSWORD '${REPLICATION_PASS}';" |
          sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single \
            -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null
      fi
    fi

    if [[ -n ${DB_USER} ]]; then
      if [[ -z ${DB_PASS} ]]; then
        echo ""
        echo "WARNING: "
        echo "  Please specify a password for \"${DB_USER}\". Skipping user creation..."
        echo ""
        DB_USER=
      else
        echo "创建用户 \"${DB_USER}\"..."
        echo "CREATE ROLE ${DB_USER} with SUPERUSER LOGIN PASSWORD '${DB_PASS}';" |
          sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single \
            -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null
      fi
    fi

    if [[ -n ${DB_NAME} ]]; then
      for db in $(awk -F',' '{for (i = 1 ; i <= NF ; i++) print $i}' <<< "${DB_NAME}"); do
        echo "创建数据库 \"${db}\"..."
        echo "CREATE DATABASE ${db};" | \
          sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single \
            -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null

        if [[ ${DB_UNACCENT} == true ]]; then
          echo "Installing unaccent extension..."
          echo "CREATE EXTENSION IF NOT EXISTS unaccent;" | \
            sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single ${db} \
              -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null
        fi

        if [[ -n ${DB_USER} ]]; then
          echo "授予用户 \"${DB_USER}\" 对数据库 \"${db}\" 的使用权..."
          echo "GRANT ALL PRIVILEGES ON DATABASE ${db} to ${DB_USER};" |
            sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single \
              -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null
        fi

        if [[ -n ${DB_PASS} ]]; then
          echo "修改postgres用户密码"
          echo "alter user postgres with password '$DB_PASS';" |
            sudo -Hu ${PG_USER} ${PG_BINDIR}/postgres --single \
              -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf >/dev/null
        else
          echo "未传入POSTGRESQL_PASS系统变量，无法修改postgres用户密码"
        fi
      done
    fi
  fi
fi

echo "启动PostgreSQL服务..."
exec start-stop-daemon --start --chuid ${PG_USER}:${PG_USER} --exec ${PG_BINDIR}/postgres -- \
  -D ${PG_DATADIR} -c config_file=${PG_CONFDIR}/postgresql.conf
