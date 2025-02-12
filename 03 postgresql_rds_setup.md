# **03 Creación de la Base de Datos PostgreSQL en RDS**

### **Paso 1: Crear una instancia RDS PostgreSQL**

```sh
aws rds create-db-instance \
    --db-instance-identifier harbor-db \
    --db-instance-class db.m5.large \
    --engine postgres \
    --allocated-storage 20 \
    --master-username harbor \
    --master-user-password mysecurepassword \
    --vpc-security-group-ids <SecurityGroupId> \
    --db-subnet-group-name <SubnetGroupId>
```

### **Paso 2: Configurar PostgreSQL para aceptar conexiones SPIFFE**

Editar `pg_hba.conf`:

```conf
hostssl all harbor spiffe://acme.harbor/harbor cert
```
