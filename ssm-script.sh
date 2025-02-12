#!/bin/bash
# Actualizar paquetes
yum update -y

# Instalar el SSM Agent
yum install -y amazon-ssm-agent

# Habilitar y arrancar el servicio
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent