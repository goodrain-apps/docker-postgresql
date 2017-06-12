FROM goodrainapps/alpine:3.6
MAINTAINER zhouyq@goodrain.com


ENV PACKAGE_DEPS \
		alpine-sdk \
		bison flex \
    coreutils \
		perl perl-utils\
		readline-dev \
		zlib-dev \
    dpkg-dev dpkg \
    openssl-dev \
    libc-dev \
    libedit-dev \
    libxml2-dev \
    libxslt-dev \
    util-linux-dev \
    zlib-dev

ENV PG_VERSION 9.5.7
ENV PG_SHA256 8b1e936f82109325decc0f5575e846b93fb4fd384e8c4bde83ff5e7f87fc6cad
ENV PG_URL=https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.bz2

RUN set -xe \
    && apk add --no-cache --virtual .build-deps $PACKAGE_DEPS \
    \
    && wget -O postgresql.tar.bz2 ${PG_URL} \
    && echo "$PG_SHA256 *postgresql.tar.bz2" | sha256sum -c - \
    && mkdir -p /usr/src/postgresql \
    && tar --strip-components 1 -xjf postgresql.tar.bz2 -C /usr/src/postgresql \
    && rm postgresql.tar.bz2 \

    && cd /usr/src/postgresql \
    # update "DEFAULT_PGSOCKET_DIR" to "/var/run/postgresql" (matching Debian)
    # see https://anonscm.debian.org/git/pkg-postgresql/postgresql.git/tree/debian/patches/51-default-sockets-in-var.patch?id=8b539fcb3e093a521c095e70bdfa76887217b89f
    && awk '$1 == "#define" && $2 == "DEFAULT_PGSOCKET_DIR" && $3 == "\"/tmp\"" { $3 = "\"/var/run/postgresql\""; print; next } { print }' src/include/pg_config_manual.h > src/include/pg_config_manual.h.new \
    && grep '/var/run/postgresql' src/include/pg_config_manual.h.new \
    && mv src/include/pg_config_manual.h.new src/include/pg_config_manual.h \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    # explicitly update autoconf config.guess and config.sub so they support more arches/libcs
    && wget -O config/config.guess "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" \
    && wget -O config/config.sub "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD" \
    \
    && ./configure \
      --build="$gnuArch" \
      --enable-integer-datetimes \
      --enable-thread-safety \
      --enable-tap-tests \
      --disable-rpath \
      --with-uuid=e2fs \
      --with-gnu-ld \
      --with-openssl \
      --with-libxml \
      --with-libxslt \
  	&& make -j "$(nproc)" world \
  	&& make install-world  \
  	&& make -C contrib install \
    \
    && runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	  )" \
    && apk add --no-cache --virtual .postgresql-rundeps $runDeps  \
    && cd / \
    && rm -rf /usr/src/postgresql \
    \
    && mkdir /usr/local/pgsql/data \
    && chown postgres /usr/local/pgsql/data \
    && sed -ir 's#/var/lib/postgresql#/usr/local/pgsql/#' /etc/passwd \
    \
    && apk del --no-cache .build-deps

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql
ENV PATH /usr/local/pgsql/bin:$PATH
ENV LANG en_US.utf8
WORKDIR /usr/local/pgsql
VOLUME /usr/local/pgsql/data
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["postgres"]
