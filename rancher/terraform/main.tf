# Rancher Terraform Configuration
# Instala e configura Rancher em uma VM remota via SSH

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
  description = "Hostname da VM onde o Rancher será instalado"
  type        = string
  default     = "rancher.home"
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

variable "rancher_version" {
  description = "Versão do Rancher"
  type        = string
  default     = "latest"
}

variable "rancher_hostname" {
  description = "Hostname do Rancher"
  type        = string
  default     = "rancher.home"
}

variable "bootstrap_password" {
  description = "Senha inicial do Rancher"
  type        = string
  default     = "MySecP4ss!"
  sensitive   = true
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
resource "null_resource" "create_directories" {
  depends_on = [null_resource.install_docker]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/rancher/data",
      "sudo mkdir -p /opt/rancher/logs",
      "sudo mkdir -p /opt/backups/rancher",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /opt/rancher",
      "sudo chown -R ${var.ssh_user}:${var.ssh_user} /opt/backups"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Copiar docker-compose.yml
resource "null_resource" "copy_docker_compose" {
  depends_on = [null_resource.create_directories]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "file" {
    content = templatefile("${path.module}/docker-compose.yml.tpl", {
      rancher_version    = var.rancher_version
      rancher_hostname   = var.rancher_hostname
      bootstrap_password = var.bootstrap_password
    })
    destination = "/opt/rancher/docker-compose.yml"
  }

  triggers = {
    always_run = timestamp()
  }
}

# Iniciar Rancher
resource "null_resource" "install_rancher" {
  depends_on = [null_resource.copy_docker_compose]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/rancher",
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
      "$DOCKER_COMPOSE_CMD down || true",
      "$DOCKER_COMPOSE_CMD pull",
      "$DOCKER_COMPOSE_CMD up -d",
      "echo 'Aguardando Rancher inicializar...'",
      "sleep 60",
      "docker ps"
    ]
  }

  triggers = {
    docker_compose_content = filesha256("${path.module}/docker-compose.yml.tpl")
  }
}

# Verificar se Rancher está funcionando
resource "null_resource" "verify_rancher" {
  depends_on = [null_resource.install_rancher]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "timeout 300 bash -c 'until curl -f -s http://${var.vm_host}/ping; do echo \"Aguardando Rancher...\"; sleep 10; done'",
      "echo 'Rancher está funcionando!'"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Outputs
output "rancher_url" {
  description = "URL do Rancher"
  value       = "http://${var.vm_host}"
}

output "rancher_https_url" {
  description = "URL HTTPS do Rancher"
  value       = "https://${var.vm_host}"
}

output "initial_password" {
  description = "Senha inicial do Rancher"
  value       = var.bootstrap_password
  sensitive   = true
}

output "ssh_command" {
  description = "Comando SSH para conectar na VM"
  value       = "ssh ${var.ssh_user}@${var.vm_host}"
}

output "useful_commands" {
  description = "Comandos úteis para gerenciar o Rancher"
  value = {
    ssh_connect = "ssh ${var.ssh_user}@${var.vm_host}"
    view_logs   = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/rancher && (docker compose logs -f 2>/dev/null || /usr/local/bin/docker-compose logs -f)'"
    restart     = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/rancher && (docker compose restart 2>/dev/null || /usr/local/bin/docker-compose restart)'"
    stop        = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/rancher && (docker compose down 2>/dev/null || /usr/local/bin/docker-compose down)'"
    status      = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/rancher && (docker compose ps 2>/dev/null || /usr/local/bin/docker-compose ps)'"
  }
}
