# Databases

In this HashiQube DevOps lab you will get hands on experience with HashiCorp Vault and how it can provision credentials for you in your databases.

This section will help us integration 2 popular databases with HashiCorp Vault, namely Oracle MySQL and Microsoft MSSQL.

Let's start with Oracle's MySQL

## Oracle MySQL

![MySQL Logo](images/mysql-logo.png?raw=true "MySQL Logo")

## Provision

<!-- tabs:start -->
#### **Github Codespaces**

```
bash hashiqube/basetools.sh
bash docker/docker.sh
bash vault/vault.sh
bash database/mysql.sh
```

#### **Vagrant**

```
vagrant up --provision-with basetools,docker,docsify,vault,mysql
```

#### **Docker Compose**

```
docker compose exec hashiqube /bin/bash
bash hashiqube/basetools.sh
bash docker/docker.sh
bash docsify/docsify.sh
bash vault/vault.sh
bash database/mysql.sh
```
<!-- tabs:end -->

Let's verify that our mysql container is up and accepting connections

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"show databases;\""`
```log
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| db                 |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

Now let's bring up Vault, lets make sure it's running, by doing:

`vagrant up --provision-with basetools,docker,docsify,vault`
```log
Bringing machine 'user.local.dev' up with 'virtualbox' provider...
==> user.local.dev: Checking if box 'ubuntu/xenial64' version '20190918.0.0' is up to date...
==> user.local.dev: [vagrant-hostsupdater] Checking for host entries
==> user.local.dev: [vagrant-hostsupdater]   found entry for: 10.9.99.10 user.local.dev
==> user.local.dev: [vagrant-hostsupdater]   found entry for: 10.9.99.10 user.local.dev
==> user.local.dev: [vagrant-hostsupdater]   found entry for: 10.9.99.10 consul-user.local.dev
==> user.local.dev: [vagrant-hostsupdater]   found entry for: 10.9.99.10 vault-user.local.dev
==> user.local.dev: [vagrant-hostsupdater]   found entry for: 10.9.99.10 nomad-user.local.dev
==> user.local.dev: Running provisioner: vault (shell)...
   user.local.dev: Running: /var/folders/7j/gsrjvmds05n53ddg28krf4_80001p9/T/vagrant-shell20191024-26402-1ms4n4s.sh
   user.local.dev: Vault already installed and running
   user.local.dev: Vault http://localhost:8200/ui and enter the following codes displayed below
   user.local.dev: Unseal Key 1: aRBITqqWe57Tl38J9avHZVoow2oC6C2qjEgWFqQAV4Z1
   user.local.dev: Unseal Key 2: +Z0RHNn1lBkKas5WIiuXYha5LTA/7i+ncLBdJafBpNs8
   user.local.dev: Unseal Key 3: 0Wg9qT6rNeB1fm5CDUdEuM8nWtI6Jt5PTAT6z0HkZRBY
   user.local.dev: Unseal Key 4: ysw0/LJPGy4jfhoPG6Lvm+ARBzkT8Q70cXgvPRZRd5Pi
   user.local.dev: Unseal Key 5: g6el6P2RAtwymn8tHE38ltdyiOeEf1Wfn8+8kShxIdZP
   user.local.dev:
   user.local.dev: Initial Root Token: s.XmyUDCIJkHMA4QgeDO6oykz6
   user.local.dev:
   user.local.dev: Vault initialized with 5 key shares and a key threshold of 3. Please securely
   user.local.dev: distribute the key shares printed above. When the Vault is re-sealed,
   user.local.dev: restarted, or stopped, you must supply at least 3 of these keys to unseal it
   user.local.dev: before it can start servicing requests.
   user.local.dev:
   user.local.dev: Vault does not store the generated master key. Without at least 3 key to
   user.local.dev: reconstruct the master key, Vault will remain permanently sealed!
   user.local.dev:
   user.local.dev: It is possible to generate new unseal keys, provided you have a quorum of
   user.local.dev: existing unseal keys shares. See "vault operator rekey" for more information.
```

Unseal the Vault and login with the root token.
![Vault](images/vault_logged_in.png?raw=true "Vault")

Now let's enable the `database` secrets engine. Top right please click on `Enable new Engine` and select Database and click `Next`
![Vault](images/vault_enable_new_secret_engine_database.png?raw=true "Vault")
![Vault](images/vault_enable_new_secret_engine_database_enable.png?raw=true "Vault")

Now let's create credentials for Vault in mysql, vault will basically be the only static user in mysql and will only have create rights for Users.

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"CREATE USER 'vault'@'%' IDENTIFIED BY 'password';\""`

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"GRANT ALL PRIVILEGES ON *.* TO 'vault'@'%' WITH GRANT OPTION;\""`

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"GRANT CREATE USER ON *.* to 'vault'@'%';\""`

Now let's configure the vault user in Vaults database secrets engine to create users for our default database `db`

`vagrant ssh -c "vault write database/config/db plugin_name=mysql-database-plugin connection_url='{{username}}:{{password}}@tcp(localhost:3306)/' allowed_roles='mysql-role' username='vault' password='password'"`

You will see we used `allowed_roles='mysql-role'` that does not exist yet, let's create it now

`vagrant ssh -c "vault write database/roles/mysql-role db_name=db creation_statements=\"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT ALL PRIVILEGES ON db.* TO '{{name}}'@'%';\" default_ttl='1h' max_ttl='24h'"`
```log
Success! Data written to: database/roles/mysql-role
```

Let's quickly check the users before we ask Vault to give us credentials

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"SELECT User, Host from mysql.user;\""`
```log
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------------+-----------+
| User             | Host      |
+------------------+-----------+
| root             | %         |
| vault            | %         |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| root             | localhost |
+------------------+-----------+
```

Now let's ask Vault for credentials

`vagrant ssh -c "vault read database/creds/mysql-role"`
```log
Key                Value
---                -----
lease_id           database/creds/mysql-role/IhHPq0RcdmDdTIjsfLBePLcp
lease_duration     1h
lease_renewable    true
password           A1a-0bdhOg0OiZQV0TTP
username           v-root-mysqlrole-zV7t3V0bJFZZJTg
```

Ok now let's check the user table again for the new users existence based on the role `mysql-role`

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"SELECT User, Host from mysql.user;\""`
```log
mysql: [Warning] Using a password on the command line interface can be insecure.
+-----------------------------------+-----------+
| User                              | Host      |
+-----------------------------------+-----------+
| root                              | %         |
| v-root-mysql-role-zV7t3V0bJFZZJTg | %         |
| vault                             | %         |
| mysql.infoschema                  | localhost |
| mysql.session                     | localhost |
| mysql.sys                         | localhost |
| root                              | localhost |
+-----------------------------------+-----------+
```

Let's ask Vault for the connection details to mysql

`vagrant ssh -c "curl --header 'X-Vault-Token:s.h7kojucmDDULDmxHAyr7jhrE' http://localhost:8200/v1/database/creds/mysql-role"`
```log
{
"request_id":"23116091-f72b-80f9-fb0e-6ce5418bae1d",
"lease_id":"database/creds/mysql-role/7wMxCUzNcEaOrvCspBhXnjTM",
"renewable":true,
"lease_duration":3600,
"data":{
  "password":"A1a-XhNU8s4P0Ph5Se9O",
  "username":"v-root-mysql-role-kmFADTyAAfv7LS0"
},
"wrap_info":null,
"warnings":null,
"auth":null
}
```

a simple way to use this is passing credentials to a docker container, like so:

```log
response=$(curl --header "X-Vault-Token:s.h7kojucmDDULDmxHAyr7jhrE" http://localhost:8200/v1/database/creds/mysql-role)
export DBPASSWORD=$(echo $response | jq -r .data.password)
export DBUSERNAME=$(echo $response | jq -r .data.username)

docker run --name webapp -d -p 8080:80 --rm -e DATABASE_URL=mysql+pymysql://DBUSERNAME:DBPASSWORD@mysql.consul/db webapp:latest
```

If we check the credentials after an hour, you will see that they have been removed by Vault

`vagrant ssh -c "mysql -h 127.0.0.1 -u root -ppassword -e \"SELECT User, Host from mysql.user;\""`

```log
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------------+-----------+
| User             | Host      |
+------------------+-----------+
| root             | %         |
| vault            | %         |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| root             | localhost |
+------------------+-----------+
```

[google ads](../googleads.html ':include :type=iframe width=100% height=300px')

## Oracle MySQL Provisioner

[filename](mysql.sh ':include :type=code')

## Microsoft SQL

![Microsoft SQL Logo](images/mssql-logo.png?raw=true "Microsoft SQL Logo")

## Provision

<!-- tabs:start -->
#### **Github Codespaces**

```
bash hashiqube/basetools.sh
bash docker/docker.sh
bash vault/vault.sh
bash database/mssql.sh
```

#### **Vagrant**

```
vagrant up --provision-with basetools,docker,docsify,vault,mssql
```

#### **Docker Compose**

```
docker compose exec hashiqube /bin/bash
bash hashiqube/basetools.sh
bash docker/docker.sh
bash docsify/docsify.sh
bash vault/vault.sh
bash database/mssql.sh
```
<!-- tabs:end -->

Now that MSSQL is launched let's get started.

We SSH into Vagrant `vagrant ssh`
Now let's create a database called `mssql`
`docker exec -it mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@ssw0rd -Q "CREATE DATABASE mssql"`

Now let's verify that the database was successfully created.
`docker exec -it mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@ssw0rd -Q "SELECT name, database_id, create_date FROM sys.databases"`
```log
name                                                                                                                             database_id create_date
-------------------------------------------------------------------------------------------------------------------------------- ----------- -----------------------
master                                                                                                                                     1 2003-04-08 09:13:36.390
tempdb                                                                                                                                     2 2019-11-20 03:23:54.157
model                                                                                                                                      3 2003-04-08 09:13:36.390
msdb                                                                                                                                       4 2018-06-13 18:27:29.220
mssql                                                                                                                                      5 2019-11-20 03:24:03.043

(5 rows affected)
```

Let's ensure the database engine in `vault secrets enable database`
```log
Success! Enabled the database secrets engine at: database/
```

Now let's enable the database in Vault.

`vault write database/config/mssql \
  plugin_name=mssql-database-plugin \
  connection_url='sqlserver://{{username}}:{{password}}@localhost:1433' \
  allowed_roles="mssql" \
  username="sa" \
  password="P@ssw0rd"`

And create a role that are allowed to fetch credentials from Vault.

`vault write database/roles/mssql \
  db_name=mssql \
  creation_statements="CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}'; \
  CREATE USER [{{name}}] FOR LOGIN [{{name}}]; \
  GRANT SELECT ON SCHEMA::dbo TO [{{name}}];" \
  default_ttl="1h" \
  max_ttl="24h"`

Now let's ask Vault to create some credentials for us

`vault read database/creds/mssql`

And let's see if the credentials were created
`docker exec -it mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U v-root-mssql-5nBk5IA9hydRgzOkgB8M-1574220338 -P A1a-dninssZ6v3mNBOfK -Q "SELECT * FROM sys.server_principals"`

```log
name                                                                                                                             principal_id sid                                                                                                                                                                          type type_desc                                                    is_disabled create_date             modify_date             default_database_name                                                                                                            default_language_name                                                                                                            credential_id owning_principal_id is_fixed_role
-------------------------------------------------------------------------------------------------------------------------------- ------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---- ------------------------------------------------------------ ----------- ----------------------- ----------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------- ------------------- -------------
sa                                                                                                                                          1 0x01                                                                                                                                                                         S    SQL_LOGIN                                                              0 2003-04-08 09:10:35.460 2019-11-20 03:23:54.283 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
public                                                                                                                                      2 0x02                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             0
sysadmin                                                                                                                                    3 0x03                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
securityadmin                                                                                                                               4 0x04                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
serveradmin                                                                                                                                 5 0x05                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
setupadmin                                                                                                                                  6 0x06                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
processadmin                                                                                                                                7 0x07                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
diskadmin                                                                                                                                   8 0x08                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
dbcreator                                                                                                                                   9 0x09                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
bulkadmin                                                                                                                                  10 0x0A                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
v-root-mssql-5nBk5IA9hydRgzOkgB8M-1574220338                                                                                              262 0x893ADA262238054280B2F0FE8F634F68                                                                                                                                           S    SQL_LOGIN                                                              0 2019-11-20 03:25:38.777 2019-11-20 03:25:38.790 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0

(11 rows affected)
```

Now let's wait an hour and check if Vault has removed the credential

`docker exec -it mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U v-root-mssql-5nBk5IA9hydRgzOkgB8M-1574220338 -P A1a-dninssZ6v3mNBOfK -Q "SELECT * FROM sys.server_principals"`
```log
Sqlcmd: Error: Microsoft ODBC Driver 17 for SQL Server : Login failed for user 'v-root-mssql-5nBk5IA9hydRgzOkgB8M-1574220338'..
```

*vagrant@riaannolan:~$* `docker exec -it mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@ssw0rd -Q "SELECT * FROM sys.server_principals"`
```log
name                                                                                                                             principal_id sid                                                                                                                                                                          type type_desc                                                    is_disabled create_date             modify_date             default_database_name                                                                                                            default_language_name                                                                                                            credential_id owning_principal_id is_fixed_role
-------------------------------------------------------------------------------------------------------------------------------- ------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---- ------------------------------------------------------------ ----------- ----------------------- ----------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------- ------------------- -------------
sa                                                                                                                                          1 0x01                                                                                                                                                                         S    SQL_LOGIN                                                              0 2003-04-08 09:10:35.460 2019-11-20 03:32:15.807 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
public                                                                                                                                      2 0x02                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             0
sysadmin                                                                                                                                    3 0x03                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
securityadmin                                                                                                                               4 0x04                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
serveradmin                                                                                                                                 5 0x05                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
setupadmin                                                                                                                                  6 0x06                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
processadmin                                                                                                                                7 0x07                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
diskadmin                                                                                                                                   8 0x08                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
dbcreator                                                                                                                                   9 0x09                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
bulkadmin                                                                                                                                  10 0x0A                                                                                                                                                                         R    SERVER_ROLE                                                            0 2009-04-13 12:59:06.030 2009-04-13 12:59:06.030 NULL                                                                                                                             NULL                                                                                                                                      NULL                   1             1
##MS_SQLResourceSigningCertificate##                                                                                                      101 0x0106000000000009010000005488E76D0CC357B76B75580222F2B12E78E2E0A2                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:10.900 2018-06-13 18:27:10.900 master                                                                                                                           NULL                                                                                                                                      NULL                NULL             0
##MS_SQLReplicationSigningCertificate##                                                                                                   102 0x010600000000000901000000797A1CDCF4B554BB72461A573EBF37DF38A8E95A                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:10.900 2018-06-13 18:27:10.900 master                                                                                                                           NULL                                                                                                                                      NULL                NULL             0
##MS_SQLAuthenticatorCertificate##                                                                                                        103 0x010600000000000901000000933CACCAA1A0D21D750FC6ECF27EC0B67452CBD6                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:10.903 2018-06-13 18:27:10.903 master                                                                                                                           NULL                                                                                                                                      NULL                NULL             0
##MS_PolicySigningCertificate##                                                                                                           105 0x0106000000000009010000002B99E5CBD00E8F5971F851F7E2C791D55223EE70                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:10.903 2018-06-13 18:27:10.903 master                                                                                                                           NULL                                                                                                                                      NULL                NULL             0
##MS_SmoExtendedSigningCertificate##                                                                                                      106 0x010600000000000901000000BD7C7E85333757CFDF554A95CC657D7FCDBD57B0                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:10.903 2018-06-13 18:27:10.903 master                                                                                                                           NULL                                                                                                                                      NULL                NULL             0
##MS_PolicyEventProcessingLogin##                                                                                                         256 0x444C3BC8EC6FCB43BF018A3118A7E2AE                                                                                                                                           S    SQL_LOGIN                                                              1 2018-06-13 18:27:36.807 2019-11-20 03:32:14.483 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
##MS_PolicyTsqlExecutionLogin##                                                                                                           257 0x64EDBF6D55705C48BAD91D921E8340BB                                                                                                                                           S    SQL_LOGIN                                                              1 2018-06-13 18:27:36.810 2019-11-20 03:32:14.483 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
##MS_AgentSigningCertificate##                                                                                                            258 0x0106000000000009010000005689043243A5B65B41804742FB020E1692F1FD59                                                                                                           C    CERTIFICATE_MAPPED_LOGIN                                               0 2018-06-13 18:27:41.753 2018-06-13 18:27:41.760 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
BUILTIN\Administrators                                                                                                                    259 0x01020000000000052000000020020000                                                                                                                                           G    WINDOWS_GROUP                                                          0 2018-06-13 18:29:22.210 2018-06-13 18:29:22.220 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
NT AUTHORITY\NETWORK SERVICE                                                                                                              260 0x010100000000000514000000                                                                                                                                                   U    WINDOWS_LOGIN                                                          0 2019-11-20 03:32:15.817 2019-11-20 03:32:18.840 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0
NT AUTHORITY\SYSTEM                                                                                                                       261 0x010100000000000512000000                                                                                                                                                   U    WINDOWS_LOGIN                                                          0 2019-11-20 03:32:15.823 2019-11-20 03:32:15.830 master                                                                                                                           us_english                                                                                                                                NULL                NULL             0

(21 rows affected)
```

[google ads](../googleads.html ':include :type=iframe width=100% height=300px')

## MSSQL Provisioner

[filename](mssql.sh ':include :type=code')

## PostgreSQL 

https://www.postgresql.org/

![PostgreSQL Logo](images/postgresql-logo.png?raw=true "PostgreSQL Logo")

## Provision

<!-- tabs:start -->
#### **Github Codespaces**

```
bash hashiqube/basetools.sh
bash docker/docker.sh
bash vault/vault.sh
bash database/postgresql.sh
```

#### **Vagrant**

```
vagrant up --provision-with basetools,docker,docsify,vault,postgresql
```

#### **Docker Compose**

```
docker compose exec hashiqube /bin/bash
bash hashiqube/basetools.sh
bash docker/docker.sh
bash docsify/docsify.sh
bash vault/vault.sh
bash database/postgresql.sh
```
<!-- tabs:end -->

## PostgreSQL Provisioner

[filename](postgresql.sh ':include :type=code')

[google ads](../googleads.html ':include :type=iframe width=100% height=300px')