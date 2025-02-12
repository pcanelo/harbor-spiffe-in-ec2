# **01 Creación del Servidor SPIFFE en EC2**

### **Paso 1: Lanzar EC2 para SPIFFE**

```sh
aws ec2 run-instances --image-id ami-088b41ffb0933423f --instance-type t3.medium --subnet-id <SubnetId> --security-group-ids <SecurityGroupId> --key-name my-key --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SpireServer}]'  --user-data file://ssm-script.sh

```

### **Paso 2: Instalar SPIRE en EC2 (Amazon Linux 2023)**

```sh
sudo dnf update -y && sudo dnf upgrade -y
curl -o spire.tar.gz https://github.com/spiffe/spire/releases/download/v1.11.1/spire-1.11.1-linux-amd64-musl.tar.gz
mkdir -p /opt/spire && tar -xzf spire.tar.gz -C /opt/spire
```

Configurar `/opt/spire/conf/server.conf`:

```hcl
server {
    data_dir = "/opt/spire/data"
    bind_address = "0.0.0.0"
    bind_port = 8081
    log_level = "INFO"
    trust_domain = "acme.harbor"
}
```

Iniciar SPIRE:

```sh
/opt/spire/bin/spire-server run -config /opt/spire/conf/server.conf
```
