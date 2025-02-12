# **05 Instalación de Harbor en EC2 con SPIFFE**

### **Paso 1: Lanzar EC2 para Harbor**

```sh
aws ec2 run-instances --image-id ami-088b41ffb0933423f --instance-type m5.xlarge --subnet-id <SubnetId> --security-group-ids <SecurityGroupId> --key-name my-key --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=HarborServer}]'
```

### **Paso 2: Instalar Docker y Configurar Harbor (Amazon Linux 2023)**

```sh
sudo dnf update -y && sudo dnf upgrade -y
sudo dnf install -y docker
sudo systemctl enable --now docker
```

### **Paso 3: Descargar e Instalar Harbor**

```sh
curl -O https://github.com/goharbor/harbor/releases/latest/download/harbor-online-installer.tgz
tar -xvzf harbor-online-installer.tgz
cd harbor
```

### **Paso 4: Configurar Harbor para Usar PostgreSQL, Redis y S3 con SPIFFE**

Editar `harbor.yml`:

```yaml
database:
  type: postgresql
  host: my-rds-instance.xxxxxxx.us-east-1.rds.amazonaws.com
  port: 5432
  username: harbor
  sslmode: verify-full
  sslcert: /opt/spire/agent/data/svid.pem
  sslkey: /opt/spire/agent/data/svid-key.pem
  sslrootcert: /opt/spire/agent/data/root.pem

external_redis:
  host: my-redis-instance.xxx.compute.amazonaws.com
  port: 6379
  tls: enabled
  cert: /opt/spire/agent/data/svid.pem
  key: /opt/spire/agent/data/svid-key.pem
  cacert: /opt/spire/agent/data/root.pem

storage_service:
  s3:
    accesskey: <AWS_ACCESS_KEY>
    secretkey: <AWS_SECRET_KEY>
    region: us-east-1
    bucket: harbor-storage-bucket
```

### **Paso 5: Registrar Harbor en SPIFFE**

```sh
/opt/spire/bin/spire-server entry create     -spiffeID spiffe://acme.harbor/harbor     -parentID spiffe://acme.harbor/node     -selector unix:uid:1000
```

### **Paso 6: Instalar y Ejecutar Harbor**

```sh
./install.sh
```

Harbor ahora está configurado para usar PostgreSQL en RDS, Redis en EC2 y S3 como backend de almacenamiento, con autenticación segura a través de SPIFFE.
