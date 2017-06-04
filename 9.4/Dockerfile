FROM goodrainapps/alpine:3.6
MAINTAINER zhouyq@goodrain.com

COPY builded /usr/local/pgsql

RUN mkdir /usr/local/pgsql/data && \
    chown postgres /usr/local/pgsql/data && \
    sed -ir 's#/var/lib/postgresql#/usr/local/pgsql/#' /etc/passwd

WORKDIR /usr/local/pgsql
VOLUME /usr/local/pgsql/data
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/docker-entrypoint.sh"]
