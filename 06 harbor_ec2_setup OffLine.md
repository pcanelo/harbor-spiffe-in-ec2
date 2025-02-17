# **05 Instalación de Harbor en EC2 con SPIFFE**

### **Paso 1: Lanzar EC2 para Harbor**

```sh
aws ec2 run-instances --image-id ami-088b41ffb0933423f --instance-type m5.xlarge --subnet-id <SubnetId> --security-group-ids <SecurityGroupId> --key-name my-key --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=HarborServer}]' --user-data file://ssm-script.sh
```

### **Paso 2: Instalar Docker y Configurar Harbor (Amazon Linux 2023)**

```sh
sudo dnf update -y && sudo dnf upgrade -y
sudo dnf install -y docker
sudo systemctl enable --now docker
```

### **Paso 3: Descargar e Instalar Harbor Offline**

```sh
curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep browser_download_url | cut -d '"' -f 4 | grep '\.tgz$' | wget -i -
tar zxvf harbor-offline-installer-v*.tgz
cd harbor
```

### **Paso 4: Configurar Harbor para Usar PostgreSQL, Redis y S3 con SPIFFE**
### Ojo si hay rol IAM asociado a la EC2 para accesar los s3, no se necesita ACCESSKEY ni SECRETSKEY

Editar `harbor.yml`:

```yaml
external_database:
  type: postgresql
  host: my-rds-instance.xxxxxxx.us-east-1.rds.amazonaws.com
  port: 5432
  username: harbor


external_redis:
  host: my-redis-instance.xxx.compute.amazonaws.com
  port: 6379
  tls: enabled

storage_service:
  s3:
    accesskey: <AWS_ACCESS_KEY>
    secretkey: <AWS_SECRET_KEY>
    region: us-east-2
    bucket: harbor-storage-bucket
```

### **Paso 5: Registrar Harbor en SPIFFE**

```sh
/opt/spire/bin/spire-server entry create     -spiffeID spiffe://be.harbor/harbor     -parentID spiffe://be.harbor/node     -selector unix:uid:1000
```

### **Paso 6: Instalar y Ejecutar Harbor**

```sh
./install.sh
```

Harbor ahora está configurado para usar PostgreSQL en RDS, Redis en EC2 y S3 como backend de almacenamiento, con autenticación segura a través de SPIFFE.
