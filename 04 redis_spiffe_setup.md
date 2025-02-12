# **04 Instalación de Redis en EC2 con SPIFFE**

### **Paso 1: Lanzar EC2 para Redis**

```sh
aws ec2 run-instances --image-id ami-088b41ffb0933423f --instance-type t3.medium --subnet-id <SubnetId> --security-group-ids <SecurityGroupId> --key-name my-key --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=RedisServer}]' --user-data file://ssm-script.sh
```

### **Paso 2: Instalar y Configurar Redis (Amazon Linux 2023)**

Actualizar e instalar Redis:

```sh
sudo dnf update -y && sudo dnf upgrade -y
sudo dnf install -y redis
```

### **Paso 3: Configurar Redis para aceptar conexiones SPIFFE**

Editar `/etc/redis/redis.conf` para habilitar **TLS y autenticación SPIFFE**:

```conf
tls-port 6379
tls-cert-file /opt/spire/agent/data/svid.pem
tls-key-file /opt/spire/agent/data/svid-key.pem
tls-ca-cert-file /opt/spire/agent/data/root.pem
requirepass "strongpassword"
```

Reiniciar Redis para aplicar cambios:

```sh
sudo systemctl restart redis
```

### **Paso 4: Registrar Redis en SPIFFE**

Crear una identidad SPIFFE para Redis:

```sh
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://be.harbor/redis \
    -parentID spiffe://be.harbor/node \
    -selector unix:uid:1001
```
