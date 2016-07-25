FROM goodrain.me/ubuntu:122401
MAINTAINER zhouyq@goodrain.com

RUN echo "Asia/Shanghai" > /etc/timezone;dpkg-reconfigure -f noninteractive tzdata
RUN groupadd -r -g 200 rain && useradd -r -u 200 -g rain rain

ENV PG_VERSION=9.3 \
    PG_USER=postgres \
    PG_HOME=/var/lib/postgresql \
    PG_RUNDIR=/run/postgresql \
    PG_LOGDIR=/var/log/postgresql

ENV PG_CONFDIR="/etc/postgresql/${PG_VERSION}/main" \
    PG_BINDIR="/usr/lib/postgresql/${PG_VERSION}/bin" \
    PG_DATADIR="${PG_HOME}/${PG_VERSION}/main"

ADD entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh && \
    wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
    apt-get -q update && \
    wget -q https://dl.dropboxusercontent.com/u/283158365/zuliposs/postgresql-9.3-tsearch-extras_0.1.2_amd64.deb -P /tmp && \
    dpkg -i /tmp/postgresql-9.3-tsearch-extras_0.1.2_amd64.deb && \
    rm -f /tmp/postgresql-9.3-tsearch-extras_0.1.2_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} postgresql-9.3-tsearch-extras hunspell-en-us && \
    rm -rf ${PG_HOME} && \
    rm -rf /var/lib/apt/lists/*


ADD zulip_english.stop /usr/share/postgresql/9.3/tsearch_data/zulip_english.stop

EXPOSE 5432/tcp
VOLUME ["${PG_HOME}"]
CMD ["/sbin/entrypoint.sh"]
