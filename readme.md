## Dockerized PostgreSQL

## 概述
PostgreSQL是自由的对象-关系型数据库服务器（数据库管理系统），在灵活的BSD-风格许可证下发行。它在其他开放源代码数据库系统（比如MySQL和Firebird），和专有系统比如Oracle、Sybase、IBM的DB2和Microsoft SQL Server之外，为用户又提供了一种选择。

PostgreSQL不寻常的名字导致一些读者停下来尝试拼读它，特别是那些把SQL拼读为"sequel"的人。PostgreSQL开发者把它拼读为"post-gress-Q-L"。（[Audio sample](http://www.postgresql.org/files/postgresql.mp3)，5.6k MP3）。它也经常被简略念为"postgres"。

## 9.3-tsearchextras
> 这个版本是真对zulip单独配置的PostgreSQL

## 使用

### 命令行启动

```bash
docker run -it \
-e MEMORY_SIZE=small \
-e DB_NAME=zulip \
-e DB_USER=zulip \
-e DB_PASS=zulip \
-v /data:/var/lib/postgresql \
goodrain.me/postgresql-tsearchextras:9.3_122401
```

### 变量

| 变量名        | 默认值 | 可选值|
|---------------|---------|-------|
|`MEMORY_SIZE`    |micro    |micro,small,medium,large,2xlarge~64xlarge|
|`DB_NAME`或`POSTGRESQL_NAME`        | test    |用户自定义|
|`DB_USER`或`POSTGRESQL_USER`|admin|用户自定义|
|`DB_PASS`| |用户自定义|
|`DB_ROOT_PASS`|同DB_PASS| 用户自定义|

### 数据持久化
需要挂载镜像中的`/var/lib/postgresql` 目录

## 9.4
> 这个版本是基于 [sameersbn](https://github.com/sameersbn/docker-postgresql) 版本修改而来