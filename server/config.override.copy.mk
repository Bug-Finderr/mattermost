# Custom configuration for M1 Mac
ENABLED_DOCKER_SERVICES = postgres inbucket minio elasticsearch
# Disable MySQL for M1 compatibility
# Use the M1-compatible Docker compose configuration

# Server settings for M1 Mac
MM_SERVICESETTINGS_SITEURL=http://localhost:8065
MM_SERVICESETTINGS_ALLOWCORSFROM=*
MM_SERVICESETTINGS_ALLOWCORSFROMBROWSEREXPOSEDAPIS=true
MM_LOGSETTINGS_CONSOLELEVEL=DEBUG
