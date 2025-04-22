# Estructura General del Script
1) Crear un bucket S3 en Outposts.

2) Crear una policy con permisos específicos para ese bucket.

3) Crear un IAM Role para EC2 con trust para ec2.amazonaws.com.

4) Asociar la policy al role.

5) Crear y asociar un Instance Profile.

6) Asociar el Instance Profile a tu instancia EC2.

### Explicación de cómo configurar harbor.yml.
En tu archivo harbor.yml, reemplaza o edita la sección storage_service:

~~~ yaml
 storage_service:
  s3:
    region: us-east-1
    bucket: harbor-storage-outpost
    regionendpoint: https://s3-outposts.us-east-1.amazonaws.com
    secure: true
    v4auth: true
    chunksize: 5242880
    rootdirectory: /registry
~~~
 