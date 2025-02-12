# **Paso a paso: Implementación de Harbor con SPIFFE en AWS con Seguridad Aislada**

## **00 Creación de la VPC y Subnet Aislada**

### **Paso 1: Crear la VPC**

Ejecutar en AWS CLI o AWS Console:

```sh
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=HarborVPC}]'
```

Guardar el `VpcId` de la respuesta.

### **Paso 2: Crear la Subnet Aislada**

```sh
aws ec2 create-subnet --vpc-id <VpcId> --cidr-block 10.0.1.0/24 --availability-zone us-east-2a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=HarborSubnet}]'
```

### **Paso 3: Crear la Tabla de Rutas y Asociarla**

```sh
aws ec2 create-route-table --vpc-id <VpcId> --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=HarborRouteTable}]'
```
Luego 

```sh
aws ec2 associate-route-table --route-table-id <RouteTableId> --subnet-id <SubnetId>
```

### **Paso 4: Crear un Security Group para Harbor**

```sh
aws ec2 create-security-group --group-name HarborSG --description "Security Group for Harbor" --vpc-id <VpcId>
```

Agregar reglas para permitir solo tráfico necesario.

```sh
aws ec2 authorize-security-group-ingress --group-id <SecurityGroupId> --protocol tcp --port 443 --cidr 10.0.0.0/16
```
