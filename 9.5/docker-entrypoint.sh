#!/bin/bash

[ $DEBUG ] && set -x

PG_DATA="/usr/local/pgsql/data"
PG_BINDIR="/usr/local/pgsql/bin"
PG_CONFIG="${PG_DATA}/postgresql.conf"

DB_NAME=${DB_NAME:-${POSTGRESQL_USER:-admin}}
DB_USER=${DB_USER:-${POSTGRESQL_USER:-admin}}
DB_PASS=${DB_PASS:-${POSTGRESQL_PASS:-pass4you}}
DB_UNACCENT=${DB_UNACCENT:false}
POSTGRES_INITDB_ARGS=${POSTGRES_INITDB_ARGS:---data-checksums}

export CFG_SSl=${CFG_SSl:-off}
export CFG_TIMEZONE=${CFG_TIMEZONE:-Asia/Shanghai}
export CFG_LOG_TIMEZONE=${CFG_LOG_TIMEZONE:-Asia/Shanghai}
DELIMITER="="


function set_config() {
    CONFIG_FILE=$1
    CFG=($( env | sed -nr "s/CFG_([0-9A-Z_a-z-]*)/\1/p"|tr A-Z a-z))

    for CFG_KEY in "${CFG[@]}"; do
        KEY=`echo $CFG_KEY | cut -d = -f 1`
        VAR=`echo $CFG_KEY | cut -d = -f 2`
        if [ "$VAR" == "" ]; then
            echo "Empty volue for option \"$KEY\"."
            continue
        fi
        grep -q "$KEY" $CONFIG_FILE
        if (($? > 0)); then
            echo "${KEY}${DELIMITER}${VAR}" >> $CONFIG_FILE
            echo "Config add option for \"$KEY\"."
        else
            sed -i -r "s~#?($KEY)[ ]*${DELIMITER}.*~\1 ${DELIMITER} $VAR~g" $CONFIG_FILE  >/dev/null 2>&1
            echo "Option found for \"$KEY\"."
        fi
    done
}


sleep ${PAUSE:-0}

# init db
if [ ! -s ${PG_DATA}/PG_VERSION ];then
  chown postgres ${PG_DATA}
  su-exec postgres ${PG_BINDIR}/initdb -D ${PG_DATA} ${POSTGRES_INITDB_ARGS}

  # get CFG_* environment variable modify or add to config file
  set_config $PG_CONFIG

  # allow remote connections to postgresql database
  echo "host    all             all             0.0.0.0/0               md5" >> ${PG_DATA}/pg_hba.conf


  # create db user
  if [[ -n ${DB_USER} ]]; then
    echo "Create DB User \"${DB_USER}\"..."
    echo "CREATE ROLE ${DB_USER} WITH SUPERUSER LOGIN PASSWORD '${DB_PASS}';" |
      su-exec postgres ${PG_BINDIR}/postgres --single \
        -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null
  fi

  # create database and Authorization user
  if [[ -n ${DB_NAME} ]]; then
    for db in $(awk -F',' '{for (i = 1 ; i <= NF ; i++) print $i}' <<< "${DB_NAME}"); do
      echo "Create DB \"${db}\"..."
      echo "CREATE DATABASE ${db};" | \
        su-exec postgres ${PG_BINDIR}/postgres --single \
          -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null

      if [[ ${DB_UNACCENT} == true ]]; then
        echo "Installing unaccent extension..."
        echo "CREATE EXTENSION IF NOT EXISTS unaccent;" | \
          su-exec postgres ${PG_BINDIR}/postgres --single ${db} \
            -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null
      fi

      if [[ -n ${DB_USER} ]]; then
        echo "GRANT DB User \"${DB_USER}\" to DB \"${db}\" access..."
        echo "GRANT ALL PRIVILEGES ON DATABASE ${db} to ${DB_USER};" |
          su-exec postgres ${PG_BINDIR}/postgres --single \
            -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null

        echo "GRANT ALL PRIVILEGES ON DATABASE ${db} to ${DB_USER};" |
          su-exec postgres ${PG_BINDIR}/postgres --single \
            -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null

      fi

      if [[ -n ${DB_PASS} ]]; then
        echo "Change postgres password..."
        echo "alter user postgres with password '$DB_PASS';" |
          su-exec postgres ${PG_BINDIR}/postgres --single \
            -D ${PG_DATA} -c config_file=${PG_CONFIG} >/dev/null
      else
        echo "The POSTGRESQL_PASS ENV was not found,postgres user password could not be modified"
      fi
    done
  fi
fi

# exec postgresql
echo "Start PostgreSQL service ..."
su-exec postgres ${PG_BINDIR}/postgres -D ${PG_DATA} -c config_file=${PG_CONFIG}
