Crear la Base de Datos PostgreSQL en RDS para Spire
crear la base con con el siguiente comando:

 ```sh
aws rds create-db-instance \
    --db-instance-identifier spire-db \
    --db-instance-class db.m5.large \
    --engine postgres \
    --allocated-storage 20 \
    --master-username spireadmin \
    --master-user-password mysecurepassword \
    --vpc-security-group-ids <SecurityGroupId> \
    --db-subnet-group-name <SubnetGroupId> \
    --engine-version 16.6
    --storage-encripted
```

Una vez creada, anota el endpoint de la base de datos, que será algo como:

 ```sh
spire-db.xxxxxxxx.us-east-1.rds.amazonaws.com
 ```

2 Configurar PostgreSQL en RDS para SPIRE
Conéctate a la base de datos y crea el usuario y la base de datos para SPIRE:

 ```sh
psql -h spire-db.xxxxxxxx.us-east-1.rds.amazonaws.com -U spireadmin
 ```

Ejecuta los siguientes comandos dentro de PostgreSQL:

```sh 
CREATE DATABASE spire;
CREATE USER spireuser WITH PASSWORD 'mysecurepassword';
GRANT ALL PRIVILEGES ON DATABASE spire TO spireuser;
 ```

3 Configurar server.conf en SPIRE para PostgreSQL
Edita el archivo de configuración de SPIRE /opt/spire/conf/server.conf y configúralo para usar PostgreSQL:

 ```sh
server {
    data_dir = "/opt/spire/data"
    bind_address = "0.0.0.0"
    bind_port = 8081
    log_level = "INFO"

    trust_domain = "be.harbor"

    database {
        plugin = "postgres"
        connection_string = "postgresql://spireuser:mysecurepassword@spire-db.xxxxxxxx.us-east-1.rds.amazonaws.com:5432/spire?sslmode=require"
    }
}
 ```

4 Iniciar SPIRE Server con PostgreSQL
Ejecuta SPIRE Server con la nueva configuración:

 ```sh
/opt/spire/bin/spire-server run -config /opt/spire/conf/server.conf
 ```

5 Verifica que SPIRE se está ejecutando correctamente con:

```sh
/opt/spire/bin/spire-server healthcheck
```

Verificar que SPIRE Está Usando PostgreSQL
Puedes verificar en la base de datos si se han creado las tablas de SPIRE:

 ```sh
psql -h spire-db.xxxxxxxx.us-east-1.rds.amazonaws.com -U spireuser -d spire -c "\dt"
 ```sh

Deberías ver una lista de tablas relacionadas con SPIRE.