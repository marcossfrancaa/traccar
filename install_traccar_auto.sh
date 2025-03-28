#!/bin/bash

# =================================================================
# Script de Instalação e Configuração do Traccar
# Copyright © 2025 - Todos os direitos reservados
# Versão: 1.0
# =================================================================

# Detectar e corrigir o formato do arquivo
if [[ "$(uname)" == "Linux" ]]; then
    # Verificar se o arquivo contém caracteres CRLF (\r\n)
    if grep -q $'\r' "$0"; then
        echo -e "\e[38;5;220m[AVISO]\e[0m O script contém caracteres inválidos (CRLF). Convertendo para LF..."
        # Criar uma cópia temporária do script com o formato correto
        tr -d '\r' < "$0" > /tmp/install_traccar.sh
        chmod +x /tmp/install_traccar.sh
        echo -e "\e[38;5;154m[SUCESSO]\e[0m Formato corrigido. Executando o script novamente...\n"
        # Executar a versão corrigida e sair
        exec /tmp/install_traccar.sh "$@"
    fi
fi

# Cores para o terminal
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[38;5;220m'
GOLD='\e[38;5;178m'
LIGHTYELLOW='\e[38;5;222m'
BRIGHTYELLOW='\e[38;5;226m'
BLUE='\e[0;34m'
NC='\e[0m' # Sem cor

# Função para exibir o cabeçalho
show_header() {
    clear
    echo -e "${YELLOW}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo -e "║  ${BRIGHTYELLOW}████████╗██████╗  █████╗  ██████╗ ██████╗  █████╗ ██████╗ ${YELLOW} ║"
    echo -e "║  ${BRIGHTYELLOW}╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝ ██╔══██╗██╔══██╗${YELLOW} ║"
    echo -e "║  ${GOLD}   ██║   ██████╔╝███████║██║     ██║      ███████║██████╔╝${YELLOW} ║"
    echo -e "║  ${GOLD}   ██║   ██╔══██╗██╔══██║██║     ██║      ██╔══██║██╔══██╗${YELLOW} ║"
    echo -e "║  ${LIGHTYELLOW}   ██║   ██║  ██║██║  ██║╚██████╗╚██████╗ ██║  ██║██║  ██║${YELLOW} ║"
    echo -e "║  ${LIGHTYELLOW}   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝${YELLOW} ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BRIGHTYELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHTYELLOW}║${NC}       Instalação e Configuração Automática do Traccar       ${BRIGHTYELLOW}║${NC}"
    echo -e "${BRIGHTYELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${LIGHTYELLOW}Copyright © 2025 - Todos os direitos reservados${NC}"
    echo
}

# Função para verificar se um comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓ SUCESSO]${NC} $1"
    else
        echo -e "${RED}[✗ ERRO]${NC} Falha ao executar: $1"
        echo -e "${YELLOW}[!] Detalhes do erro:${NC}"
        echo -e "${RED}$2${NC}"
        exit 1
    fi
}

# Função para verificar dependências
check_dependencies() {
    echo -e "${YELLOW}[VERIFICAÇÃO]${NC} Verificando dependências necessárias..."
    
    DEPS=("curl" "wget" "apt")
    MISSING_DEPS=()
    
    for dep in "${DEPS[@]}"; do
        if ! command -v $dep &> /dev/null; then
            MISSING_DEPS+=($dep)
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        echo -e "${RED}[✗ ERRO]${NC} Dependências ausentes: ${MISSING_DEPS[@]}"
        echo -e "${YELLOW}[INFO]${NC} Tentando instalar as dependências necessárias..."
        
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y ${MISSING_DEPS[@]}
            if [ $? -ne 0 ]; then
                echo -e "${RED}[✗ ERRO]${NC} Não foi possível instalar as dependências. Abortando."
                exit 1
            fi
        else
            echo -e "${RED}[✗ ERRO]${NC} Não foi possível instalar automaticamente. Por favor, instale manualmente: ${MISSING_DEPS[@]}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}[✓ SUCESSO]${NC} Todas as dependências estão instaladas."
}

# Função para fazer backup das configurações existentes
backup_existing_config() {
    if [ -d "/opt/traccar" ]; then
        echo -e "${YELLOW}[BACKUP]${NC} Detectada instalação existente do Traccar. Fazendo backup..."
        BACKUP_DIR="/opt/traccar_backup_$(date +%Y%m%d_%H%M%S)"
        sudo cp -r /opt/traccar $BACKUP_DIR
        check_success "Backup da instalação anterior em $BACKUP_DIR" "Não foi possível fazer backup."
    fi
}

# Função para verificar espaço em disco
check_disk_space() {
    echo -e "${YELLOW}[VERIFICAÇÃO]${NC} Verificando espaço em disco..."
    
    FREE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
    if [ $FREE_SPACE -lt 1024 ]; then
        echo -e "${YELLOW}[AVISO]${NC} Espaço em disco baixo: ${FREE_SPACE}MB disponíveis. Recomendado pelo menos 1GB."
        read -p "Deseja continuar mesmo assim? (s/n): " CONTINUE
        if [[ ! $CONTINUE =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}[INFO]${NC} Instalação cancelada pelo usuário."
            exit 0
        fi
    else
        echo -e "${GREEN}[✓ SUCESSO]${NC} Espaço em disco suficiente: ${FREE_SPACE}MB disponíveis."
    fi
}

# Função para exibir progresso
show_progress() {
    local PROGRESS=$1
    local TOTAL=$2
    local PERCENTAGE=$((PROGRESS * 100 / TOTAL))
    local COMPLETED=$((PROGRESS * 50 / TOTAL))
    local REMAINING=$((50 - COMPLETED))
    
    echo -ne "${YELLOW}["
    for ((i=0; i<COMPLETED; i++)); do
        echo -ne "█"
    done
    for ((i=0; i<REMAINING; i++)); do
        echo -ne "░"
    done
    echo -ne "] ${PERCENTAGE}%${NC}\r"
}

# Exibir cabeçalho
show_header

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[AVISO]${NC} Este script precisa ser executado como root ou com sudo."
    read -p "Deseja continuar com sudo? (s/n): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}[INFO]${NC} Instalação cancelada pelo usuário."
        exit 0
    fi
    # Executar novamente com sudo
    exec sudo "$0" "$@"
fi

# Verificar dependências
check_dependencies

# Verificar espaço em disco
check_disk_space

# Backup de configurações existentes
backup_existing_config

# Solicitar domínio ou IP
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 1] Configuração do domínio ou IP                      ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
read -p "Digite o domínio ou IP do servidor (ex: traccar.meudominio.com ou 192.168.1.100): " DOMAIN_OR_IP

# Validar entrada do domínio ou IP
if [[ -z "$DOMAIN_OR_IP" ]]; then
    echo -e "${RED}[✗ ERRO]${NC} Domínio ou IP não pode estar vazio. Abortando."
    exit 1
fi

# Validar formato de IP
if [[ $DOMAIN_OR_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IFS='.' read -ra ADDR <<< "$DOMAIN_OR_IP"
    for i in "${ADDR[@]}"; do
        if [ $i -lt 0 ] || [ $i -gt 255 ]; then
            echo -e "${RED}[✗ ERRO]${NC} Endereço IP inválido. Abortando."
            exit 1
        fi
    done
fi

TOTAL_STEPS=21
CURRENT_STEP=1

# Atualizar o sistema
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 2] Atualizando o sistema                              ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo apt update && sudo apt upgrade -y
check_success "Atualização do sistema" "Erro durante a atualização do sistema. Verifique sua conexão de internet e permissões."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Instalar o Nginx
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 3] Instalando o Nginx                                 ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo apt install nginx -y
check_success "Instalação do Nginx" "Erro ao instalar o Nginx. Verifique sua conexão de internet e permissões."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Criar estrutura de diretórios para o Traccar
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 4] Criando estrutura de diretórios                    ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo mkdir -p /opt/traccar/{logs,config,data}
check_success "Criação de diretórios" "Erro ao criar diretórios. Verifique permissões."
sudo chmod -R 755 /opt/traccar
CURRENT_STEP=$((CURRENT_STEP + 1))

# Configurar o Nginx
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 5] Configurando o Nginx                               ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo tee /etc/nginx/sites-available/traccar.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_OR_IP;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Configurações adicionais para WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Aumentar timeout para operações longas
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }

    # Configurações de segurança
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    
    client_max_body_size 10M;
    
    listen 80;
}
EOL
check_success "Configuração do Nginx" "Erro ao configurar o Nginx. Verifique permissões."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Habilitar o site no Nginx
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 6] Habilitando o site no Nginx                        ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo ln -sf /etc/nginx/sites-available/traccar.conf /etc/nginx/sites-enabled/
check_success "Habilitação do site no Nginx" "Erro ao habilitar o site no Nginx."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Testar configuração do Nginx
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 7] Testando configuração do Nginx                     ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo nginx -t
check_success "Teste de configuração do Nginx" "Erro na configuração do Nginx. Verifique a sintaxe."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Reiniciar o Nginx
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 8] Reiniciando o Nginx                                ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo systemctl restart nginx
check_success "Reinicialização do Nginx" "Erro ao reiniciar o Nginx."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Instalar o Docker
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 9] Instalando o Docker                                ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    check_success "Instalação do Docker" "Erro ao instalar o Docker."
else
    echo -e "${YELLOW}[INFO]${NC} Docker já está instalado. Pulando instalação."
fi
CURRENT_STEP=$((CURRENT_STEP + 1))

# Verificar instalação do Docker
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 10] Verificando instalação do Docker                  ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
docker --version
check_success "Verificação do Docker" "Docker não está instalado corretamente."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Instalar o Docker Compose
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 11] Instalando o Docker Compose                       ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    check_success "Instalação do Docker Compose" "Erro ao instalar o Docker Compose."
else
    echo -e "${YELLOW}[INFO]${NC} Docker Compose já está instalado. Pulando instalação."
fi
CURRENT_STEP=$((CURRENT_STEP + 1))

# Verificar instalação do Docker Compose
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 12] Verificando instalação do Docker Compose           ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
docker-compose --version
check_success "Verificação do Docker Compose" "Docker Compose não está instalado corretamente."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Baixar configuração do Traccar
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 13] Baixando configuração do Traccar                  ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo docker run --rm --entrypoint cat traccar/traccar:latest /opt/traccar/conf/traccar.xml > /opt/traccar/config/traccar.xml
check_success "Download da configuração do Traccar" "Erro ao baixar a configuração do Traccar."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Criar arquivo docker-compose.yml
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 14] Criando docker-compose.yml                        ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo tee /opt/traccar/docker-compose.yml > /dev/null <<EOL
version: '3.8'
services:
  traccar:
    image: traccar/traccar:latest
    container_name: traccar
    restart: unless-stopped
    ports:
      - "8082:8082"
      - "5000-5150:5000-5150"
      - "5000-5150:5000-5150/udp"
    volumes:
      - /opt/traccar/logs:/opt/traccar/logs:rw
      - /opt/traccar/config/traccar.xml:/opt/traccar/conf/traccar.xml:ro
      - /opt/traccar/data:/opt/traccar/data:rw
    environment:
      - TZ=America/Sao_Paulo
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOL
check_success "Criação do docker-compose.yml" "Erro ao criar o arquivo docker-compose.yml."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Iniciar o Traccar
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 15] Iniciando o Traccar                               ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
cd /opt/traccar
sudo docker-compose up -d
check_success "Inicialização do Traccar" "Erro ao iniciar o Traccar."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Criar script de inicialização automática
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 16] Configurando inicialização automática             ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo tee /etc/systemd/system/traccar.service > /dev/null <<EOL
[Unit]
Description=Traccar GPS Tracking Server
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/traccar
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable traccar.service
check_success "Configuração de inicialização automática" "Erro ao configurar inicialização automática."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Verificar status do Traccar
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 17] Verificando status do Traccar                     ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sleep 5 # Aguardar inicialização do container
sudo docker ps | grep traccar
check_success "Verificação do status do Traccar" "O container do Traccar não está em execução."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Instalar o Certbot para SSL
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 18] Instalando o Certbot                              ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
sudo apt install certbot python3-certbot-nginx -y
check_success "Instalação do Certbot" "Erro ao instalar o Certbot."
CURRENT_STEP=$((CURRENT_STEP + 1))

# Obter certificado SSL (apenas se for um domínio válido)
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 19] Configurando SSL                                  ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
if [[ $DOMAIN_OR_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}[AVISO]${NC} IP detectado: $DOMAIN_OR_IP. SSL não será configurado automaticamente."
else
    echo -e "${YELLOW}[SSL]${NC} Obtendo certificado SSL para $DOMAIN_OR_IP..."
    
    # Verificar se o domínio é acessível
    if ping -c 1 $DOMAIN_OR_IP &> /dev/null || host $DOMAIN_OR_IP &> /dev/null; then
        sudo certbot --nginx -d $DOMAIN_OR_IP --non-interactive --agree-tos --email admin@$DOMAIN_OR_IP || {
            echo -e "${YELLOW}[AVISO]${NC} Falha na configuração automática do SSL. Tentando método interativo."
            sudo certbot --nginx -d $DOMAIN_OR_IP
        }
        check_success "Obtenção do certificado SSL" "Erro ao obter certificado SSL."
        
        # Testar renovação automática do SSL
        echo -e "${YELLOW}[SSL]${NC} Testando renovação automática do SSL..."
        sudo certbot renew --dry-run
        check_success "Teste de renovação automática do SSL" "Erro ao testar renovação do SSL."
        
        # Configurar cron para verificação diária de renovação
        echo -e "${YELLOW}[SSL]${NC} Configurando verificação diária de renovação do SSL..."
        echo "0 3 * * * root certbot renew --quiet" | sudo tee -a /etc/cron.d/certbot-renew > /dev/null
        check_success "Configuração de renovação automática" "Erro ao configurar renovação automática."
    else
        echo -e "${YELLOW}[AVISO]${NC} O domínio $DOMAIN_OR_IP não parece estar apontando para este servidor."
        echo -e "${YELLOW}[AVISO]${NC} Certifique-se de que o domínio está corretamente configurado no DNS."
        echo -e "${YELLOW}[AVISO]${NC} SSL não configurado. Você pode configurar manualmente mais tarde com:"
        echo -e "${LIGHTYELLOW}sudo certbot --nginx -d $DOMAIN_OR_IP${NC}"
    fi
fi
CURRENT_STEP=$((CURRENT_STEP + 1))

# Configurar firewall
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 20] Configurando firewall                             ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}[FIREWALL]${NC} Configurando regras de firewall..."
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8082/tcp
    sudo ufw allow 5000:5150/tcp
    sudo ufw allow 5000:5150/udp
    
    # Verificar se o firewall está ativo
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}[✓ SUCESSO]${NC} Regras de firewall configuradas."
    else
        echo -e "${YELLOW}[AVISO]${NC} Firewall não está ativo. Deseja ativá-lo? (s/n): "
        read -p "" ENABLE_FIREWALL
        if [[ $ENABLE_FIREWALL =~ ^[Ss]$ ]]; then
            sudo ufw --force enable
            check_success "Ativação do firewall" "Erro ao ativar o firewall."
        fi
    fi
else
    echo -e "${YELLOW}[AVISO]${NC} UFW não está instalado. Pulando configuração de firewall."
fi
CURRENT_STEP=$((CURRENT_STEP + 1))

# Cadastrar usuário, email e senha
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA 21] Cadastrando usuário administrador                 ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"
show_progress $CURRENT_STEP $TOTAL_STEPS
echo -e "${YELLOW}[USUÁRIO]${NC} Aguardando 10 segundos para garantir que o Traccar esteja pronto..."
sleep 10

read -read -p "Digite o nome de usuário: " USERNAME
read -p "Digite o email: " EMAIL
read -sp "Digite a senha: " PASSWORD
echo

# Validar entradas
if [[ -z "$USERNAME" || -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo -e "${YELLOW}[AVISO]${NC} Todos os campos são obrigatórios."
    echo -e "${YELLOW}[AVISO]${NC} Você precisará criar o usuário manualmente através da interface web."
else
    # Verificar se o servidor está respondendo
    echo -e "${YELLOW}[VERIFICAÇÃO]${NC} Verificando se o servidor Traccar está respondendo..."
    MAX_RETRIES=5
    RETRY_COUNT=0
    SERVER_UP=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s http://localhost:8082 > /dev/null; then
            SERVER_UP=true
            break
        fi
        echo -e "${YELLOW}[AGUARDE]${NC} Servidor ainda não está pronto. Tentativa ${RETRY_COUNT}/${MAX_RETRIES}..."
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 5
    done
    
    if [ "$SERVER_UP" = true ]; then
        # Criar usuário administrador via API do Traccar
        echo -e "${YELLOW}[USUÁRIO]${NC} Criando usuário administrador..."
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8082/api/users" \
            -H "Content-Type: application/json" \
            -d '{
                "name": "'"$USERNAME"'",
                "email": "'"$EMAIL"'",
                "password": "'"$PASSWORD"'",
                "admin": true
            }')
        
        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
        
        if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
            echo -e "${GREEN}[✓ SUCESSO]${NC} Usuário administrador cadastrado com sucesso!"
        else
            echo -e "${YELLOW}[AVISO]${NC} Não foi possível criar o usuário automaticamente (Código HTTP: $HTTP_CODE)."
            echo -e "${YELLOW}[AVISO]${NC} Resposta do servidor: $RESPONSE_BODY"
            echo -e "${YELLOW}[AVISO]${NC} Você precisará criar o usuário manualmente através da interface web."
        fi
    else
        echo -e "${YELLOW}[AVISO]${NC} O servidor Traccar não está respondendo após várias tentativas."
        echo -e "${YELLOW}[AVISO]${NC} Você precisará criar o usuário manualmente através da interface web."
    fi
fi

# Criar script de manutenção
echo -e "${GOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC} [ETAPA EXTRA] Criando script de manutenção                   ${GOLD}║${NC}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════╝${NC}"

sudo tee /opt/traccar/traccar-maintenance.sh > /dev/null <<'EOL'
#!/bin/bash

# Cores para o terminal
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[38;5;220m'
NC='\e[0m' # Sem cor

echo -e "${YELLOW}==== Script de Manutenção do Traccar ====${NC}"
echo 

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Este script precisa ser executado como root ou com sudo.${NC}"
    exit 1
fi

show_menu() {
    echo -e "${YELLOW}Selecione uma opção:${NC}"
    echo "1) Reiniciar serviços"
    echo "2) Atualizar Traccar"
    echo "3) Fazer backup"
    echo "4) Restaurar backup"
    echo "5) Ver logs"
    echo "6) Status dos serviços"
    echo "7) Limpar logs antigos"
    echo "0) Sair"
    echo
    read -p "Opção: " OPTION
    
    case $OPTION in
        1) restart_services ;;
        2) update_traccar ;;
        3) backup_traccar ;;
        4) restore_backup ;;
        5) view_logs ;;
        6) check_status ;;
        7) clean_logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opção inválida${NC}" && show_menu ;;
    esac
}

restart_services() {
    echo -e "${YELLOW}Reiniciando serviços...${NC}"
    cd /opt/traccar
    docker-compose down
    docker-compose up -d
    systemctl restart nginx
    echo -e "${GREEN}Serviços reiniciados com sucesso!${NC}"
    read -p "Pressione Enter para continuar..."
    show_menu
}

update_traccar() {
    echo -e "${YELLOW}Atualizando Traccar...${NC}"
    cd /opt/traccar
    docker-compose pull
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}Traccar atualizado com sucesso!${NC}"
    read -p "Pressione Enter para continuar..."
    show_menu
}

backup_traccar() {
    BACKUP_DIR="/opt/traccar_backups"
    BACKUP_FILE="${BACKUP_DIR}/traccar_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p $BACKUP_DIR
    
    echo -e "${YELLOW}Criando backup...${NC}"
    cd /opt
    tar -czf $BACKUP_FILE traccar
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup criado com sucesso: ${BACKUP_FILE}${NC}"
    else
        echo -e "${RED}Erro ao criar backup${NC}"
    fi
    
    # Listar backups existentes
    echo -e "${YELLOW}Backups disponíveis:${NC}"
    ls -lh $BACKUP_DIR
    
    read -p "Pressione Enter para continuar..."
    show_menu
}

restore_backup() {
    BACKUP_DIR="/opt/traccar_backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        echo -e "${RED}Nenhum backup encontrado em $BACKUP_DIR${NC}"
        read -p "Pressione Enter para continuar..."
        show_menu
        return
    fi
    
    echo -e "${YELLOW}Backups disponíveis:${NC}"
    
    # Listar backups e adicionar índices
    BACKUPS=($(ls -t $BACKUP_DIR/*.tar.gz 2>/dev/null))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum arquivo de backup encontrado${NC}"
        read -p "Pressione Enter para continuar..."
        show_menu
        return
    fi
    
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) $(basename ${BACKUPS[$i]}) ($(du -h ${BACKUPS[$i]} | cut -f1))"
    done
    
    echo "0) Cancelar"
    
    read -p "Selecione o backup a restaurar: " BACKUP_INDEX
    
    if [ "$BACKUP_INDEX" -eq 0 ]; then
        show_menu
        return
    fi
    
    if [ "$BACKUP_INDEX" -le ${#BACKUPS[@]} ]; then
        SELECTED_BACKUP=${BACKUPS[$((BACKUP_INDEX-1))]}
        
        echo -e "${YELLOW}Você selecionou: $(basename $SELECTED_BACKUP)${NC}"
        read -p "Tem certeza que deseja restaurar este backup? (s/n): " CONFIRM
        
        if [[ $CONFIRM =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Parando serviços...${NC}"
            cd /opt/traccar
            docker-compose down
            
            echo -e "${YELLOW}Restaurando backup...${NC}"
            cd /opt
            mv traccar traccar_old_$(date +%Y%m%d_%H%M%S)
            tar -xzf $SELECTED_BACKUP
            
            echo -e "${YELLOW}Iniciando serviços...${NC}"
            cd /opt/traccar
            docker-compose up -d
            
            echo -e "${GREEN}Backup restaurado com sucesso!${NC}"
        else
            echo -e "${YELLOW}Restauração cancelada${NC}"
        fi
    else
        echo -e "${RED}Índice inválido${NC}"
    fi
    
    read -p "Pressione Enter para continuar..."
    show_menu
}

view_logs() {
    echo -e "${YELLOW}Selecione o tipo de log:${NC}"
    echo "1) Docker logs (container Traccar)"
    echo "2) Nginx access log"
    echo "3) Nginx error log"
    echo "4) Traccar application logs"
    echo "0) Voltar"
    
    read -p "Opção: " LOG_OPTION
    
    case $LOG_OPTION in
        1)
            echo -e "${YELLOW}Docker logs:${NC}"
            docker logs --tail 100 traccar
            ;;
        2)
            echo -e "${YELLOW}Nginx access log:${NC}"
            tail -n 100 /var/log/nginx/access.log
            ;;
        3)
            echo -e "${YELLOW}Nginx error log:${NC}"
            tail -n 100 /var/log/nginx/error.log
            ;;
        4)
            if [ -d "/opt/traccar/logs" ]; then
                LOG_FILES=($(ls -t /opt/traccar/logs/*.log 2>/dev/null))
                if [ ${#LOG_FILES[@]} -eq 0 ]; then
                    echo -e "${RED}Nenhum arquivo de log encontrado${NC}"
                else
                    for i in "${!LOG_FILES[@]}"; do
                        echo "$((i+1))) $(basename ${LOG_FILES[$i]})"
                    done
                    
                    read -p "Selecione o arquivo de log: " LOG_INDEX
                    
                    if [ "$LOG_INDEX" -le ${#LOG_FILES[@]} ]; then
                        SELECTED_LOG=${LOG_FILES[$((LOG_INDEX-1))]}
                        echo -e "${YELLOW}$(basename $SELECTED_LOG):${NC}"
                        tail -n 100 $SELECTED_LOG
                    else
                        echo -e "${RED}Índice inválido${NC}"
                    fi
                fi
            else
                echo -e "${RED}Diretório de logs não encontrado${NC}"
            fi
            ;;
        0)
            show_menu
            return
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            ;;
    esac
    
    read -p "Pressione Enter para continuar..."
    view_logs
}

check_status() {
    echo -e "${YELLOW}Status do Docker:${NC}"
    docker ps -a | grep traccar
    
    echo -e "\n${YELLOW}Status do Nginx:${NC}"
    systemctl status nginx --no-pager | head -n 20
    
    echo -e "\n${YELLOW}Status do serviço Traccar:${NC}"
    systemctl status traccar --no-pager | head -n 20
    
    echo -e "\n${YELLOW}Uso de disco:${NC}"
    df -h /opt
    
    echo -e "\n${YELLOW}Uso de recursos do container:${NC}"
    docker stats traccar --no-stream
    
    read -p "Pressione Enter para continuar..."
    show_menu
}

clean_logs() {
    echo -e "${YELLOW}Limpando logs antigos...${NC}"
    
    # Limpar logs antigos do Traccar
    if [ -d "/opt/traccar/logs" ]; then
        echo "Logs do Traccar com mais de 30 dias:"
        find /opt/traccar/logs -name "*.log" -type f -mtime +30 -exec ls -lh {} \;
        
        read -p "Remover estes logs? (s/n): " CONFIRM
        if [[ $CONFIRM =~ ^[Ss]$ ]]; then
            find /opt/traccar/logs -name "*.log" -type f -mtime +30 -delete
            echo -e "${GREEN}Logs antigos removidos${NC}"
        fi
    fi
    
    # Rotacionar logs do Nginx
    echo -e "${YELLOW}Rotacionando logs do Nginx...${NC}"
    logrotate --force /etc/logrotate.d/nginx
    
    # Limpar containers antigos
    echo -e "${YELLOW}Removendo containers Docker não utilizados...${NC}"
    docker system prune -f
    
    echo -e "${GREEN}Limpeza concluída!${NC}"
    read -p "Pressione Enter para continuar..."
    show_menu
}

# Iniciar menu
show_menu
EOL

sudo chmod +x /opt/traccar/traccar-maintenance.sh
check_success "Criação do script de manutenção" "Erro ao criar script de manutenção."

# Mensagem final
echo -e "${BRIGHTYELLOW}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║            INSTALAÇÃO CONCLUÍDA COM SUCESSO!               ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GOLD}================================================================${NC}"
echo -e "${GOLD}               INFORMAÇÕES DE ACESSO                           ${NC}"
echo -e "${GOLD}================================================================${NC}"
if [[ $DOMAIN_OR_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${LIGHTYELLOW}Acesse a interface web em:${NC} http://$DOMAIN_OR_IP"
else
    echo -e "${LIGHTYELLOW}Acesse a interface web em:${NC} https://$DOMAIN_OR_IP"
fi

if [[ ! -z "$USERNAME" && ! -z "$EMAIL" && ! -z "$PASSWORD" ]]; then
    echo -e "${LIGHTYELLOW}Usuário:${NC} $USERNAME"
    echo -e "${LIGHTYELLOW}Email:${NC} $EMAIL"
    echo -e "${LIGHTYELLOW}Senha:${NC} $PASSWORD"
fi

echo
echo -e "${GOLD}================================================================${NC}"
echo -e "${GOLD}               COMANDOS ÚTEIS                                  ${NC}"
echo -e "${GOLD}================================================================${NC}"
echo -e "${LIGHTYELLOW}Para verificar status:${NC} docker ps | grep traccar"
echo -e "${LIGHTYELLOW}Para reiniciar:${NC} cd /opt/traccar && docker-compose restart"
echo -e "${LIGHTYELLOW}Para atualizar:${NC} cd /opt/traccar && docker-compose pull && docker-compose down && docker-compose up -d"
echo -e "${LIGHTYELLOW}Para manutenção:${NC} sudo /opt/traccar/traccar-maintenance.sh"
echo
echo -e "${GREEN}Suporte: suporte@traccar.meudominio.com${NC}"
echo
echo -e "${YELLOW}Copyright © 2025 - Todos os direitos reservados${NC}"
echo -e "${YELLOW}Este script foi criado para facilitar a instalação e configuração do Traccar.${NC}"
echo -e "${YELLOW}Contribua com o projeto: https://github.com/traccar/traccar${NC}"
