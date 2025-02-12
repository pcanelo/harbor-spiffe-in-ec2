# **02 Configuración de Almacenamiento S3 para Harbor con SPIFFE**

### **Paso 1: Crear un Bucket en S3**

```sh
aws s3api create-bucket --bucket harbor-storage-bucket --region us-east-1
```

### **Paso 2: Configurar Harbor para usar S3 como backend de almacenamiento**

Editar `harbor.yml`:

```yaml
storage_service:
  s3:
    accesskey: <AWS_ACCESS_KEY>
    secretkey: <AWS_SECRET_KEY>
    region: us-east-1
    bucket: harbor-storage-bucket
```

### **Paso 3: Configurar IAM Policies para Conexiones SPIFFE**

Para permitir que SPIFFE maneje las credenciales de acceso a S3, se debe configurar una política IAM restrictiva:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<AWS_ACCOUNT_ID>:role/spiffe-harbor-role"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::harbor-storage-bucket",
                "arn:aws:s3:::harbor-storage-bucket/*"
            ]
        }
    ]
}
```

Esta política asegura que solo identidades autenticadas por SPIFFE puedan acceder al bucket de S3.

### **Paso 4: Crear una Identidad SPIFFE para S3**

Registrar el bucket como un recurso SPIFFE autorizado:

```sh
/opt/spire/bin/spire-server entry create     -spiffeID spiffe://acme.harbor/s3     -parentID spiffe://acme.harbor/node     -selector aws:iam_role:spiffe-harbor-role
```
