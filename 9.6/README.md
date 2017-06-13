# PostgreSQL  for [ACP](https://www.goodrain.com/ACP.html)



> PostgreSQL is a powerful, open source object-relational database system. It has more than 15 years of active development and a proven architecture that has earned it a strong reputation for reliability, data integrity, and correctness. It runs on all major operating systems, including Linux, UNIX (AIX, BSD, HP-UX, SGI IRIX, macOS, Solaris, Tru64), and Windows. It is fully ACID compliant, has full support for foreign keys, joins, views, triggers, and stored procedures (in multiple languages).

![postgresql](http://oe5ahutux.bkt.clouddn.com/postgresql-logo.png)



# Supported tags and Dockerfile links

`9.6` , `9.6.3` ,  `latest` [Dockerfile](https://github.com/goodrain-apps/docker-postgresql/blob/9.6/9.6/Dockerfile)

`9.5` , `9.5.7` [Dockerfile](https://github.com/goodrain-apps/docker-postgresql/blob/9.5/9.5/Dockerfile)

`9.4` , `9.4.12` [Dockerfile](https://github.com/goodrain-apps/docker-postgresql/blob/9.4/9.4/Dockerfile)

`9.3` , `9.3.17`  [Dockerfile](https://github.com/goodrain-apps/docker-postgresql/blob/9.3/9.3/Dockerfile)

# About this image

This images base alpine system ,can be installed in Goodrain [ACM](http://app.goodrain.com/group/detail/11/). Fully compatible with the Goodrain [ACP](https://www.goodrain.com/ACP.html) platform.

# How to use this image

## Via ACM install

[![deploy to ACP](http://ojfzu47n9.bkt.clouddn.com/20170603149649013919973.png)](http://app.goodrain.com/group/detail/11/)



## Via docker

### Installation

Automated builds of the image are available on [hub.docker.com](https://quay.io/repository/sameersbn/postgresql) and is the recommended method of installation.

```bash
docker pull goodrainapps/postgresql:9.4.12
```

Alternately you can build the image yourself.

```bash
https://github.com/goodrain-apps/docker-postgresql.git
cd docker-postgresql
git branch 9.4
make base
make build
make release
```

### Quick Start

Run the postgresql image

```bash
docker run -d --name posgresql goodrainapps/postgresql:9.4.12
```

The simplest way to login to the postgresql container as the administrative `postgres` user is to use the `docker exec` command to attach a new process to the running container and connect to the postgresql server over the unix socket,postgres user **default password** is `pass4you`

```bash
docker exec -it postgresql sudo -u postgres psql
```

### Persistence

For data persistence a volume should be mounted at `/usr/local/pgsql/data`.

The updated run command looks like this.

```bash
docker run -d --name posgresql
-v ${PWD}/data:/usr/local/pgsql/data
goodrainapps/postgresql:9.4.12
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

### Creating User and Database at Launch

The image allows you to create a user and database at **first** launch time.

To create a new user you should specify the `DB_USER` and `DB_PASS` variables. The following command will create a new user *dbuser* with the password *dbpass*.

```bash
docker run --name postgresql -d \
  -e 'DB_USER=dbuser' \
  -e 'DB_PASS=dbpass' \
  goodrainapps/postgresql:9.4.12
```

**NOTE**
- If the password is not specified the user will use default password `pass4you` 
- If the user user already exists no changes will be made

Similarly, you can also create a new database by specifying the database name in the `DB_NAME` variable.

```bash
docker run --name postgresql -d \
  -e 'DB_NAME=dbname' goodrainapps/postgresql:9.4.12
```

You may also specify a comma separated list of database names in the `DB_NAME` variable. The following command creates two new databases named *dbname1* and *dbname2* (p.s. this feature is only available in releases greater than 9.1-1).

```bash
docker run --name postgresql -d \
  -e 'DB_NAME=dbname1,dbname2' \
  goodrainapps/postgresql:9.4.12
```

If the `DB_USER` and `DB_PASS` variables are also specified while creating the database, then the user is granted access to the database(s).

For example,

```bash
docker run --name postgresql -d \
  -e 'DB_USER=dbuser' \
  -e 'DB_PASS=dbpass' \
  -e 'DB_NAME=dbname' \
  goodrainapps/postgresql:9.4.12
```

will create a user *dbuser* with the password *dbpass*. It will also create a database named *dbname* and the *dbuser* user will have full access to the *dbname* database.

The `PSQL_TRUST_LOCALNET` environment variable can be used to configure postgres to trust connections on the same network.  This is handy for other containers to connect without authentication. To enable this behavior, set `PSQL_TRUST_LOCALNET` to `true`.

For example,

```bash
docker run --name postgresql -d \
  -e 'PSQL_TRUST_LOCALNET=true' \
  goodrainapps/postgresql:9.4.12
```

This has the effect of adding the following to the `pg_hba.conf` file:

```
host    all             all             samenet                 trust
```



### Enable Unaccent (Search plain text with accent)

Unaccent is a text search dictionary that removes accents (diacritic signs) from lexemes. It's a filtering dictionary, which means its output is always passed to the next dictionary (if any), unlike the normal behavior of dictionaries. This allows accent-insensitive processing for full text search.

By default unaccent is configure to `false`

```bash
docker run --name postgresql -d \
  -e 'DB_UNACCENT=true' \
  goodrainapps/postgresql:9.4.12
```



# Environment variables 

| Name                      | Default    | Comments                                 |
| ------------------------- | ---------- | ---------------------------------------- |
| DB_NAME                   | admin      | The DB_NAME was created the first time it was started |
| DB_USER / POSTGRESQL_USER | admin      | DB_USER created at the first start       |
| DB_PASS / POSTGRESQL_PASS | pass4you   | The DB_PASS created at the first start   |
| PSQL_MODE                 | standalone | postgresql run mode                      |
| DB_UNACCENT               | false      | Enable Unaccent                          |
| PSQL_SSLMODE              | disable    | ssl connect                              |
| DEBUG                     | null       | docker-entrypoint.sh debug switch        |
| PAUSE                     | null       | docker-entrypoint.sh pause for debug     |



# Custom postgresql.conf

This image supports modifying the postgresql.conf configuration item when the container is started.

The following settings are set up by default:

```bash
CFG_SSl=${CFG_SSl:-off}
CFG_TIMEZONE=${CFG_TIMEZONE:-Asia/Shanghai}
CFG_LOG_TIMEZONE=${CFG_LOG_TIMEZONE:-Asia/Shanghai}
```

You can specify the configuration when starting the container, such as setting the `max_connections`,environment variable name must begin with `CFG_`

```bash
docker run -d \
-e DB_PASS=abc123 \
-e DB_USER=goodrain \
-e DB_NAME=grtest \
-e DEBUG=1 \
-e CFG_MAX_CONNECTIONS=200  \
goodrainapps/postgresql:9.4.12
```

