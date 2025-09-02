# MinIO Terraform Configuration
# Instala e configura MinIO em uma VM remota via SSH

terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variáveis de entrada
variable "vm_host" {
  description = "Hostname da VM onde o MinIO será instalado"
  type        = string
  default     = "minio.home"
}

variable "ssh_user" {
  description = "Usuário SSH para conectar na VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Caminho para a chave SSH privada"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "minio_version" {
  description = "Versão do MinIO"
  type        = string
  default     = "latest"
}

variable "minio_hostname" {
  description = "Hostname do MinIO"
  type        = string
  default     = "minio.local"
}

variable "minio_root_user" {
  description = "Usuário root do MinIO"
  type        = string
  default     = "admin"
}

variable "minio_root_password" {
  description = "Senha root do MinIO"
  type        = string
  default     = "MySecP4ss!"
  sensitive   = true
}

variable "minio_api_port" {
  description = "Porta da API MinIO"
  type        = string
  default     = "9000"
}

variable "minio_console_port" {
  description = "Porta do console MinIO"
  type        = string
  default     = "9001"
}

variable "minio_client_version" {
  description = "Versão do cliente MinIO"
  type        = string
  default     = "latest"
}

# Conexão SSH
locals {
  ssh_connection = {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    host        = var.vm_host
  }
}

# Verificar conectividade SSH
resource "null_resource" "ssh_test" {
  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH connection successful'",
      "echo 'OS: '$(lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME)",
      "echo 'User: '$(whoami)",
      "echo 'Home: '$HOME"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Instalar Docker
resource "null_resource" "install_docker" {
  depends_on = [null_resource.ssh_test]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "# Verificar se Docker já está instalado",
      "if command -v docker >/dev/null 2>&1; then",
      "  echo 'Docker já está instalado'",
      "  docker --version",
      "else",
      "  echo 'Instalando Docker usando script oficial do Rancher...'",
      "  curl https://releases.rancher.com/install-docker/28.1.sh | sh",
      "  sudo usermod -aG docker ${var.ssh_user}",
      "  echo 'Docker instalado com sucesso'",
      "fi",
      "# Verificar se Docker Compose já está instalado",
      "if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then",
      "  echo 'Docker Compose já está instalado'",
      "  docker-compose --version 2>/dev/null || docker compose version",
      "else",
      "  echo 'Instalando Docker Compose...'",
      "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "  sudo chmod +x /usr/local/bin/docker-compose",
      "  echo 'Docker Compose instalado com sucesso'",
      "fi",
      "# Verificar se o docker-compose está acessível",
      "if [ -x /usr/local/bin/docker-compose ]; then",
      "  echo 'Docker Compose encontrado em /usr/local/bin/docker-compose'",
      "  /usr/local/bin/docker-compose --version",
      "elif docker compose version >/dev/null 2>&1; then",
      "  echo 'Docker Compose v2 encontrado como plugin do Docker'",
      "  docker compose version",
      "else",
      "  echo 'Erro: Docker Compose não foi instalado corretamente'",
      "  exit 1",
      "fi"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Criar diretório e arquivos de configuração
resource "null_resource" "setup_minio" {
  depends_on = [null_resource.install_docker]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/minio",
      "sudo chown ${var.ssh_user}:${var.ssh_user} /opt/minio",
      "cd /opt/minio",
      "if [ -f docker-compose.yml ]; then",
      "  # Detectar qual comando docker-compose usar",
      "  if [ -x /usr/local/bin/docker-compose ]; then",
      "    DOCKER_COMPOSE_CMD='/usr/local/bin/docker-compose'",
      "  elif docker compose version >/dev/null 2>&1; then",
      "    DOCKER_COMPOSE_CMD='docker compose'",
      "  else",
      "    echo 'Erro: Docker Compose não encontrado'",
      "    exit 1",
      "  fi",
      "  $DOCKER_COMPOSE_CMD down 2>/dev/null || true",
      "fi"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Copiar docker-compose.yml
resource "null_resource" "copy_docker_compose" {
  depends_on = [null_resource.setup_minio]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "file" {

    content = templatefile("${path.module}/docker-compose.yml.tpl", {
      minio_version        = var.minio_version
      minio_hostname       = var.minio_hostname
      minio_root_user      = var.minio_root_user
      minio_root_password  = var.minio_root_password
      minio_api_port       = var.minio_api_port
      minio_console_port   = var.minio_console_port
      minio_client_version = var.minio_client_version
    })
    destination = "/opt/minio/docker-compose.yml"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Criar arquivo .env
resource "null_resource" "create_env_file" {
  depends_on = [null_resource.copy_docker_compose]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/minio",
      "cat > .env << EOF",
      "MINIO_VERSION=${var.minio_version}",
      "MINIO_HOSTNAME=${var.minio_hostname}",
      "MINIO_ROOT_USER=${var.minio_root_user}",
      "MINIO_ROOT_PASSWORD=${var.minio_root_password}",
      "MINIO_API_PORT=${var.minio_api_port}",
      "MINIO_CONSOLE_PORT=${var.minio_console_port}",
      "MINIO_CLIENT_VERSION=${var.minio_client_version}",
      "EOF"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Iniciar MinIO
resource "null_resource" "start_minio" {
  depends_on = [null_resource.create_env_file]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/minio",
      "# Detectar qual comando docker-compose usar",
      "if [ -x /usr/local/bin/docker-compose ]; then",
      "  DOCKER_COMPOSE_CMD='/usr/local/bin/docker-compose'",
      "elif docker compose version >/dev/null 2>&1; then",
      "  DOCKER_COMPOSE_CMD='docker compose'",
      "else",
      "  echo 'Erro: Docker Compose não encontrado'",
      "  exit 1",
      "fi",
      "echo 'Usando comando: $DOCKER_COMPOSE_CMD'",
      "echo 'Iniciando MinIO...'",
      "$DOCKER_COMPOSE_CMD up -d",
      "echo 'Aguardando MinIO estar pronto...'",
      "sleep 30",
      "echo 'Verificando status...'",
      "$DOCKER_COMPOSE_CMD ps",
      "echo 'Logs da configuração inicial:'",
      "$DOCKER_COMPOSE_CMD logs minio-client || true"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Verificar se MinIO está funcionando
resource "null_resource" "verify_minio" {
  depends_on = [null_resource.start_minio]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/minio",
      "# Detectar qual comando docker-compose usar",
      "if [ -x /usr/local/bin/docker-compose ]; then",
      "  DOCKER_COMPOSE_CMD='/usr/local/bin/docker-compose'",
      "elif docker compose version >/dev/null 2>&1; then",
      "  DOCKER_COMPOSE_CMD='docker compose'",
      "else",
      "  echo 'Erro: Docker Compose não encontrado'",
      "  exit 1",
      "fi",
      "echo 'Verificando saúde do MinIO...'",
      "for i in {1..10}; do",
      "  if curl -f http://localhost:${var.minio_api_port}/minio/health/live >/dev/null 2>&1; then",
      "    echo 'MinIO está saudável!'",
      "    break",
      "  else",
      "    echo 'Tentativa $i/10: MinIO ainda não está pronto...'",
      "    sleep 10",
      "  fi",
      "done",
      "echo 'Status final dos containers:'",
      "$DOCKER_COMPOSE_CMD ps"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Outputs
output "minio_console_url" {
  description = "URL do console web do MinIO"
  value       = "http://${var.vm_host}:${var.minio_console_port}"
}

output "minio_api_url" {
  description = "URL da API do MinIO"
  value       = "http://${var.vm_host}:${var.minio_api_port}"
}

output "minio_credentials" {
  description = "Credenciais do MinIO"
  value = {
    username = var.minio_root_user
    password = var.minio_root_password
  }
  sensitive = true
}

output "useful_commands" {
  description = "Comandos úteis para gerenciar o MinIO"
  value = {
    ssh_connect = "ssh ${var.ssh_user}@${var.vm_host}"
    view_logs   = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/minio && (docker compose logs -f 2>/dev/null || /usr/local/bin/docker-compose logs -f)'"
    restart     = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/minio && (docker compose restart 2>/dev/null || /usr/local/bin/docker-compose restart)'"
    stop        = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/minio && (docker compose down 2>/dev/null || /usr/local/bin/docker-compose down)'"
    status      = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/minio && (docker compose ps 2>/dev/null || /usr/local/bin/docker-compose ps)'"
  }
}
