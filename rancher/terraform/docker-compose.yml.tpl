version: '3.8'

services:
  rancher:
    image: rancher/rancher:${rancher_version}
    container_name: rancher
    hostname: ${rancher_hostname}
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/rancher/data:/var/lib/rancher
      - /opt/rancher/logs:/var/log/auditlog
    environment:
      - CATTLE_SYSTEM_DEFAULT_REGISTRY=
      - CATTLE_BOOTSTRAP_PASSWORD=${bootstrap_password}
      - CATTLE_PASSWORD_MIN_LENGTH=8
    restart: unless-stopped
    privileged: true
    networks:
      - rancher-network

networks:
  rancher-network:
    driver: bridge