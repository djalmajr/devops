version: '3.8'

services:
  minio:
    image: minio/minio:${minio_version}
    container_name: minio
    restart: unless-stopped
    ports:
      - "${minio_api_port}:9000"
      - "${minio_console_port}:9001"
    environment:
      MINIO_ROOT_USER: ${minio_root_user}
      MINIO_ROOT_PASSWORD: ${minio_root_password}
      MINIO_CONSOLE_ADDRESS: ":9001"
      MINIO_SERVER_URL: "http://${minio_hostname}:${minio_api_port}"
    volumes:
      - minio_data:/data
      - minio_config:/root/.minio
    command: server /data --console-address ":9001"
    networks:
      - minio_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Cliente MinIO para testes e configuração inicial
  minio-client:
    image: minio/mc:${minio_client_version}
    container_name: minio-client
    depends_on:
      minio:
        condition: service_healthy
    environment:
      MINIO_ROOT_USER: ${minio_root_user}
      MINIO_ROOT_PASSWORD: ${minio_root_password}
      MINIO_HOSTNAME: ${minio_hostname}
      MINIO_API_PORT: ${minio_api_port}
    networks:
      - minio_network
    entrypoint: >
      /bin/sh -c "
      echo 'Aguardando MinIO estar pronto...';
      sleep 10;
      mc alias set myminio http://minio:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD;
      echo 'Criando bucket padrão...';
      mc mb myminio/default --ignore-existing;
      mc policy set public myminio/default;
      echo 'MinIO configurado com sucesso!';
      echo 'Console Web: http://$$MINIO_HOSTNAME:${minio_console_port}';
      echo 'API: http://$$MINIO_HOSTNAME:${minio_api_port}';
      echo 'Usuário: '$$MINIO_ROOT_USER;
      echo 'Senha: '$$MINIO_ROOT_PASSWORD;
      exit 0;
      "

volumes:
  minio_data:
    driver: local
  minio_config:
    driver: local

networks:
  minio_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16