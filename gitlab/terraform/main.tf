# GitLab Terraform Configuration
# Instala e configura GitLab em uma VM remota via SSH

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
  description = "Hostname da VM onde o GitLab será instalado"
  type        = string
  default     = "gitlab.home"
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

variable "gitlab_version" {
  description = "Versão do GitLab"
  type        = string
  default     = "latest"
}

variable "gitlab_hostname" {
  description = "Hostname do GitLab"
  type        = string
  default     = "gitlab.home"
}

variable "gitlab_root_password" {
  description = "Senha root do GitLab"
  type        = string
  default     = "MySecP4ss!"
  sensitive   = true
}

variable "gitlab_http_port" {
  description = "Porta HTTP do GitLab"
  type        = string
  default     = "80"
}

variable "gitlab_https_port" {
  description = "Porta HTTPS do GitLab"
  type        = string
  default     = "443"
}

variable "gitlab_ssh_port" {
  description = "Porta SSH do GitLab"
  type        = string
  default     = "22"
}

variable "gitlab_timezone" {
  description = "Timezone do GitLab"
  type        = string
  default     = "America/Sao_Paulo"
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

# Verificar recursos do sistema
resource "null_resource" "check_system_resources" {
  depends_on = [null_resource.ssh_test]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Verificando recursos do sistema...'",
      "TOTAL_MEM=$(free -m | awk 'NR==2{printf \"%.0f\", $2}')",
      "TOTAL_DISK=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')",
      "echo 'Memória total: '$${TOTAL_MEM}MB",
      "echo 'Espaço em disco disponível: '$${TOTAL_DISK}GB",
      "if [ \"$$TOTAL_MEM\" -lt 4096 ]; then",
      "  echo 'AVISO: GitLab recomenda pelo menos 4GB de RAM. Atual: '$${TOTAL_MEM}MB",
      "fi",
      "if [ \"$$TOTAL_DISK\" -lt 10 ]; then",
      "  echo 'AVISO: GitLab recomenda pelo menos 10GB de espaço em disco. Atual: '$${TOTAL_DISK}GB",
      "fi"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Instalar Docker
resource "null_resource" "install_docker" {
  depends_on = [null_resource.check_system_resources]

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

# Configurar limites do sistema
resource "null_resource" "configure_system_limits" {
  depends_on = [null_resource.install_docker]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Configurando limites do sistema para GitLab...'",
      "sudo sysctl -w vm.max_map_count=262144",
      "echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf",
      "echo 'Limites do sistema configurados'"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Criar diretório e arquivos de configuração
resource "null_resource" "setup_gitlab" {
  depends_on = [null_resource.configure_system_limits]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/gitlab",
      "sudo chown ${var.ssh_user}:${var.ssh_user} /opt/gitlab",
      "cd /opt/gitlab",
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
  depends_on = [null_resource.setup_gitlab]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "file" {
    content = templatefile("${path.module}/docker-compose.yml.tpl", {
      gitlab_version       = var.gitlab_version
      gitlab_hostname      = var.gitlab_hostname
      gitlab_root_password = var.gitlab_root_password
      gitlab_http_port     = var.gitlab_http_port
      gitlab_https_port    = var.gitlab_https_port
      gitlab_ssh_port      = var.gitlab_ssh_port
      gitlab_timezone      = var.gitlab_timezone
    })
    destination = "/opt/gitlab/docker-compose.yml"
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
      "cd /opt/gitlab",
      "cat > .env << EOF",
      "GITLAB_VERSION=${var.gitlab_version}",
      "GITLAB_HOSTNAME=${var.gitlab_hostname}",
      "GITLAB_ROOT_PASSWORD=${var.gitlab_root_password}",
      "GITLAB_HTTP_PORT=${var.gitlab_http_port}",
      "GITLAB_HTTPS_PORT=${var.gitlab_https_port}",
      "GITLAB_SSH_PORT=${var.gitlab_ssh_port}",
      "GITLAB_TIMEZONE=${var.gitlab_timezone}",
      "EOF"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Iniciar GitLab
resource "null_resource" "start_gitlab" {
  depends_on = [null_resource.create_env_file]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/gitlab",
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
      "echo 'Iniciando GitLab...'",
      "# Verificar se usuário tem acesso ao Docker, senão usar sudo",
      "if docker ps >/dev/null 2>&1; then",
      "  $DOCKER_COMPOSE_CMD up -d",
      "else",
      "  echo 'Usando sudo para executar Docker...'",
      "  sudo $DOCKER_COMPOSE_CMD up -d",
      "fi",
      "echo 'Aguardando GitLab inicializar (pode levar 5-10 minutos)...'",
      "sleep 30",
      "echo 'Verificando status...'",
      "if docker ps >/dev/null 2>&1; then",
      "  $DOCKER_COMPOSE_CMD ps",
      "else",
      "  sudo $DOCKER_COMPOSE_CMD ps",
      "fi"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Verificar se GitLab está funcionando
resource "null_resource" "verify_gitlab" {
  depends_on = [null_resource.start_gitlab]

  connection {
    type        = local.ssh_connection.type
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    host        = local.ssh_connection.host
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/gitlab",
      "# Detectar qual comando docker-compose usar",
      "if [ -x /usr/local/bin/docker-compose ]; then",
      "  DOCKER_COMPOSE_CMD='/usr/local/bin/docker-compose'",
      "elif docker compose version >/dev/null 2>&1; then",
      "  DOCKER_COMPOSE_CMD='docker compose'",
      "else",
      "  echo 'Erro: Docker Compose não encontrado'",
      "  exit 1",
      "fi",
      "echo 'Verificando saúde do GitLab...'",
      "for i in {1..20}; do",
      "  if curl -f -s http://localhost:${var.gitlab_http_port}/users/sign_in >/dev/null 2>&1; then",
      "    echo 'GitLab está funcionando!'",
      "    break",
      "  else",
      "    echo 'Tentativa $i/20: GitLab ainda não está pronto...'",
      "    sleep 30",
      "  fi",
      "done",
      "echo 'Status final dos containers:'",
      "if docker ps >/dev/null 2>&1; then",
      "  $DOCKER_COMPOSE_CMD ps",
      "else",
      "  sudo $DOCKER_COMPOSE_CMD ps",
      "fi"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}

# Outputs
output "gitlab_url" {
  description = "URL do GitLab"
  value       = "http://${var.vm_host}:${var.gitlab_http_port}"
}

output "gitlab_https_url" {
  description = "URL HTTPS do GitLab"
  value       = "https://${var.vm_host}:${var.gitlab_https_port}"
}

output "gitlab_ssh_url" {
  description = "URL SSH do GitLab"
  value       = "ssh://git@${var.vm_host}:${var.gitlab_ssh_port}"
}

output "gitlab_credentials" {
  description = "Credenciais do GitLab"
  value = {
    username = "root"
    password = var.gitlab_root_password
  }
  sensitive = true
}

output "ssh_command" {
  description = "Comando SSH para conectar na VM"
  value       = "ssh ${var.ssh_user}@${var.vm_host}"
}

output "useful_commands" {
  description = "Comandos úteis para gerenciar o GitLab"
  value = {
    ssh_connect  = "ssh ${var.ssh_user}@${var.vm_host}"
    view_logs    = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/gitlab && (docker compose logs -f 2>/dev/null || /usr/local/bin/docker-compose logs -f)'"
    restart      = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/gitlab && (docker compose restart 2>/dev/null || /usr/local/bin/docker-compose restart)'"
    stop         = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/gitlab && (docker compose down 2>/dev/null || /usr/local/bin/docker-compose down)'"
    status       = "ssh ${var.ssh_user}@${var.vm_host} 'cd /opt/gitlab && (docker compose ps 2>/dev/null || /usr/local/bin/docker-compose ps)'"
    health_check = "ssh ${var.ssh_user}@${var.vm_host} 'docker exec gitlab gitlab-rake gitlab:check SANITIZE=true'"
  }
}
