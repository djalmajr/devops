# 🌐 DNS Server Local - BIND9

> **Consulte o [README principal](../README.md) para pré-requisitos e configuração geral**

Servidor DNS local para resolução de domínios personalizados (ex: `gitlab.home`, `rancher.home`) com encaminhamento para DNS públicos.

## 📁 Estrutura

```
dns-server/
├── config/              # Configurações BIND9
│   ├── db.home         # Zona direta (nomes -> IPs)
│   ├── db.192.168.0    # Zona reversa (IPs -> nomes)
│   └── named.conf      # Configuração principal
└── docker-compose.yml   # Orquestração Docker
```

## ⚙️ Instalação

```bash
# Iniciar servidor DNS
docker-compose up -d

# Verificar status
docker-compose logs bind9
```

## 🔧 Configuração do Sistema

### macOS

1. **Ajustes do Sistema > Rede**
2. Selecione sua conexão > **Detalhes**
3. Aba **DNS** > Adicionar `192.168.0.24`
4. Mover para o **primeiro** da lista

### Teste

```bash
# Testar resolução
dig @192.168.0.24 gitlab.home
ping gitlab.home

# Limpar cache DNS (macOS)
sudo dscacheutil -flushcache
```

## 💡 Domínios Configurados

- `ns.home` → `192.168.0.24` (servidor DNS)
- `gitlab.home` → `192.168.0.102`
- `rancher.home` → `ns.home` (CNAME)

### Por que `.home` e não `.local`?

O domínio `.local` é reservado para mDNS e pode causar conflitos. O `.home` é seguro para uso privado.

## 🚀 Uso Rápido

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose down

# Ver logs
docker-compose logs -f bind9
```

## 🔍 Troubleshooting

### DNS não resolve

```bash
# Verificar se servidor está rodando
docker ps | grep bind9

# Testar diretamente o servidor
dig @192.168.0.24 gitlab.home

# Limpar cache DNS (macOS)
sudo dscacheutil -flushcache
```

### Configuração persistente macOS

```bash
# Se a configuração de rede não funcionar
sudo mkdir -p /etc/resolver
echo "nameserver 192.168.0.24" | sudo tee /etc/resolver/home
```
