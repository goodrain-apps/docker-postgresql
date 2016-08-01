FROM ubuntu:14.04

RUN echo "Asia/Shanghai" > /etc/timezone;dpkg-reconfigure -f noninteractive tzdata
RUN groupadd -r -g 200 postgres && useradd -r -u 200 -g postgres postgres

RUN apt-get update && apt-get install -y locales wget && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


ENV PG_VERSION=9.3 \
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

EXPOSE 5432
VOLUME /var/lib/postgresql
CMD ["/sbin/entrypoint.sh"]
