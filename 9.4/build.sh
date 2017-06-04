#!/bin/bash
PG_VER=9.4.12
PG_URL=https://ftp.postgresql.org/pub/source/v${PG_VER}/postgresql-${PG_VER}.tar.bz2

set -xe; \
curl -sfSL ${PG_URL} | tar -xjC /tmp

cd /tmp/postgresql-* && \
    ./configure && \
    make && \
    make install  && \
    echo "PostgreSQL build completed!"
