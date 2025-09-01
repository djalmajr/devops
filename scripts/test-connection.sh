#!/bin/bash

# Script de teste de conectividade com a VM
# Configuração via variáveis de ambiente
# Suporte para chaves SSH e autenticação por senha

set -e

# Variáveis de ambiente (com valores padrão)
VM_HOST="${VM_HOST:-rancher.home}"
SSH_USER="${SSH_USER:-ubuntu}"
SSH_PASS="${SSH_PASS:-}"

# Verificar se sshpass está disponível para evitar múltiplas solicitações de senha
USE_SSHPASS=false
if command -v sshpass >/dev/null 2>&1 && [[ -n "$SSH_PASS" ]]; then
    USE_SSHPASS=true
    SSH_CMD="sshpass -p '$SSH_PASS' ssh"
else
    SSH_CMD="ssh"
fi

echo "🔍 Testando conectividade com a VM $VM_HOST"
echo "============================================"
echo "💡 Dica: Configure chaves SSH para evitar senhas repetidas"
echo ""

# Teste 1: Ping
echo "1. Testando ping..."
if ping -c 2 $VM_HOST > /dev/null 2>&1; then
    echo "   ✅ Ping OK"
else
    echo "   ❌ Ping falhou"
    echo "   💡 Verifique se a VM está ligada"
    exit 1
fi

# Teste 2: SSH básico
echo "2. Testando SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes $SSH_USER@$VM_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "   ✅ SSH OK (usando chave SSH)"
    SSH_METHOD="chave SSH"
    SSH_CMD="ssh -o ConnectTimeout=10 -o BatchMode=yes"
elif [[ "$USE_SSHPASS" == "true" ]] && eval "$SSH_CMD -o ConnectTimeout=10 -o BatchMode=no $SSH_USER@$VM_HOST 'echo SSH_OK'" > /dev/null 2>&1; then
    echo "   ✅ SSH OK (usando senha via sshpass)"
    SSH_METHOD="senha (sshpass)"
    SSH_CMD="$SSH_CMD -o ConnectTimeout=10 -o BatchMode=no"
elif ssh -o ConnectTimeout=10 -o BatchMode=no $SSH_USER@$VM_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "   ✅ SSH OK (usando senha interativa)"
    SSH_METHOD="senha interativa"
    SSH_CMD="ssh -o ConnectTimeout=10 -o BatchMode=no"
    echo "   💡 Para evitar múltiplas solicitações de senha:"
    echo "      - Configure chaves SSH: ./scripts/setup-ssh-keys.sh"
    echo "      - Ou defina SSH_PASS na variável de ambiente"
else
    echo "   ❌ SSH falhou"
    echo "   💡 Verifique:"
    echo "      - Se o SSH está habilitado na VM"
    echo "      - Se sua chave SSH está configurada"
    echo "      - Configure chaves SSH: ssh-copy-id $SSH_USER@$VM_HOST"
    echo "      - Teste manual: ssh $SSH_USER@$VM_HOST"
    exit 1
fi

# Teste 3: Verificar Docker
echo "3. Verificando Docker..."
if DOCKER_OUTPUT=$(eval "$SSH_CMD $SSH_USER@$VM_HOST 'docker --version'" 2>&1); then
    echo "   ✅ Docker: $DOCKER_OUTPUT"
else
    echo "   ⚠️  Docker não instalado ou não funcional"
fi

# Teste 4: Verificar Rancher
echo "4. Verificando Rancher..."
if eval "$SSH_CMD $SSH_USER@$VM_HOST 'docker ps | grep rancher'" > /dev/null 2>&1; then
    echo "   ✅ Container Rancher está rodando"
else
    echo "   ℹ️  Container Rancher não encontrado"
fi

# Teste 5: Verificar recursos
echo "5. Verificando recursos da VM..."
if RESOURCES=$(eval "$SSH_CMD $SSH_USER@$VM_HOST 'df -h / | tail -1 | awk \"{print \\\$3\\\"/\\\"\\\$2\\\" (\\\"\\\$5\\\")\\\"}\"; free -h | grep Mem | awk \"{print \\\$2\\\" total, \\\"\\\$3\\\" usado, \\\"\\\$7\\\" livre\\\"}\"; nproc'" 2>&1); then
    echo "$RESOURCES" | while IFS= read -r line; do
        case $line in
            */*) echo "   💾 Disco: $line" ;;
            *total*) echo "   🧠 Memória: $line" ;;
            [0-9]*) echo "   🔥 CPU: $line cores" ;;
        esac
    done
else
    echo "   ⚠️  Não foi possível obter informações de recursos"
fi

# Teste 6: Verificar se Rancher está acessível via HTTP
echo "6. Testando acesso HTTP ao Rancher..."
if curl -f -s --max-time 5 "http://$VM_HOST/ping" > /dev/null 2>&1; then
    echo "   ✅ Rancher está rodando e acessível!"
    echo "   🌐 Acesse: http://$VM_HOST"
elif curl -s --max-time 5 "http://$VM_HOST" > /dev/null 2>&1; then
    echo "   ⚠️  Serviço HTTP responde mas Rancher pode não estar pronto"
    echo "   💡 Aguarde alguns minutos ou verifique os logs"
else
    echo "   ℹ️  Rancher não está acessível via HTTP"
fi

echo ""
echo "📋 Resumo:"
echo "   VM IP: $VM_HOST"
echo "   SSH: $SSH_USER@$VM_HOST ($SSH_METHOD)"
echo "   Rancher URL: http://$VM_HOST"
echo ""
if [[ "$SSH_METHOD" == *"senha"* ]]; then
    echo "💡 Para evitar digitação de senhas:"
    echo "   ./scripts/setup-ssh-keys.sh  # Configuração automática"
    echo "   ssh-copy-id $SSH_USER@$VM_HOST  # Configuração manual"
    echo ""
fi
echo "🚀 Para instalar o Rancher, escolha uma opção:"
echo "   - Docker Compose: cd docker && ./install.sh"
echo "   - Terraform: cd terraform && ./install.sh"
