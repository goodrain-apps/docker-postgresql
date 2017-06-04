FROM goodrainapps/alpine:3.6
MAINTAINER zhouyq@goodrain.com

COPY builded /usr/local/pgsql

RUN mkdir /usr/local/pgsql/data && \
    chown postgres /usr/local/pgsql/data && \
    sed -ir 's#/var/lib/postgresql#/usr/local/pgsql/#' /etc/passwd

<<<<<<< HEAD

ENV PG_VERSION=9.4 \
    PG_USER=postgres \
    PG_HOME=/var/lib/postgresql \
    PG_RUNDIR=/run/postgresql \
    PG_LOGDIR=/var/log/postgresql

ENV PG_CONFDIR="/etc/postgresql/${PG_VERSION}/main" \
    PG_BINDIR="/usr/lib/postgresql/${PG_VERSION}/bin" \
    PG_DATADIR="${PG_HOME}/${PG_VERSION}/main"

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} \
 && rm -rf ${PG_HOME}/${PG_VERSION} \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
=======
WORKDIR /usr/local/pgsql
VOLUME /usr/local/pgsql/data
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
>>>>>>> 9.4

EXPOSE 5432

ENTRYPOINT ["/docker-entrypoint.sh"]
