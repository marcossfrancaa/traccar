#!/bin/bash

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Função para exibir o cabeçalho
show_header() {
    clear
    echo -e "${BLUE}"
    echo "  _______  _______  _______  _______  _______  _______  _______ "
    echo " |       ||       ||       ||       ||       ||       ||       |"
    echo " |   _   ||   _   ||   _   ||   _   ||   _   ||   _   ||   _   |"
    echo " |  | |  ||  | |  ||  | |  ||  | |  ||  | |  ||  | |  ||  | |  |"
    echo " |  |_|  ||  |_|  ||  |_|  ||  |_|  ||  |_|  ||  |_|  ||  |_|  |"
    echo " |       ||       ||       ||       ||       ||       ||       |"
    echo " |_______||_______||_______||_______||_______||_______||_______|"
    echo -e "${NC}"
    echo "================================================================"
    echo " Instalação e Configuração Automática do Traccar"
    echo "================================================================"
    echo
}

# Função para verificar se um comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCESSO]${NC} $1"
    else
        echo -e "${RED}[ERRO]${NC} Falha ao executar: $1"
        exit 1
    fi
}

# Exibir cabeçalho
show_header

# Solicitar domínio ou IP
echo -e "${YELLOW}[ETAPA 1]${NC} Configuração do domínio ou IP"
read -p "Digite o domínio ou IP do servidor (ex: traccar.meudominio.com ou 192.168.1.100): " DOMAIN_OR_IP

# Atualizar o sistema
echo -e "${YELLOW}[ETAPA 2]${NC} Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y
check_success "Atualização do sistema"

# Instalar o Nginx
echo -e "${YELLOW}[ETAPA 3]${NC} Instalando o Nginx..."
sudo apt install nginx -y
check_success "Instalação do Nginx"

# Criar estrutura de diretórios para o Traccar
echo -e "${YELLOW}[ETAPA 4]${NC} Criando estrutura de diretórios..."
sudo mkdir -p /opt/traccar/{logs,config}
check_success "Criação de diretórios"

# Configurar o Nginx
echo -e "${YELLOW}[ETAPA 5]${NC} Configurando o Nginx..."
sudo tee /etc/nginx/sites-available/traccar.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_OR_IP;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    listen 80;
}
EOL
check_success "Configuração do Nginx"

# Habilitar o site no Nginx
echo -e "${YELLOW}[ETAPA 6]${NC} Habilitando o site no Nginx..."
sudo ln -s /etc/nginx/sites-available/traccar.conf /etc/nginx/sites-enabled/
check_success "Habilitação do site no Nginx"

# Testar configuração do Nginx
echo -e "${YELLOW}[ETAPA 7]${NC} Testando configuração do Nginx..."
sudo nginx -t
check_success "Teste de configuração do Nginx"

# Reiniciar o Nginx
echo -e "${YELLOW}[ETAPA 8]${NC} Reiniciando o Nginx..."
sudo systemctl restart nginx
check_success "Reinicialização do Nginx"

# Instalar o Docker
echo -e "${YELLOW}[ETAPA 9]${NC} Instalando o Docker..."
curl -fsSL https://get.docker.com | sh
check_success "Instalação do Docker"

# Verificar instalação do Docker
echo -e "${YELLOW}[ETAPA 10]${NC} Verificando instalação do Docker..."
docker --version
check_success "Verificação do Docker"

# Instalar o Docker Compose
echo -e "${YELLOW}[ETAPA 11]${NC} Instalando o Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
check_success "Instalação do Docker Compose"

# Verificar instalação do Docker Compose
echo -e "${YELLOW}[ETAPA 12]${NC} Verificando instalação do Docker Compose..."
docker-compose --version
check_success "Verificação do Docker Compose"

# Baixar configuração do Traccar
echo -e "${YELLOW}[ETAPA 13]${NC} Baixando configuração do Traccar..."
sudo docker run --rm --entrypoint cat traccar/traccar:latest /opt/traccar/conf/traccar.xml > /opt/traccar/config/traccar.xml
check_success "Download da configuração do Traccar"

# Criar arquivo docker-compose.yml
echo -e "${YELLOW}[ETAPA 14]${NC} Criando docker-compose.yml..."
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
EOL
check_success "Criação do docker-compose.yml"

# Iniciar o Traccar
echo -e "${YELLOW}[ETAPA 15]${NC} Iniciando o Traccar..."
cd /opt/traccar
sudo docker-compose up -d
check_success "Inicialização do Traccar"

# Verificar status do Traccar
echo -e "${YELLOW}[ETAPA 16]${NC} Verificando status do Traccar..."
sudo docker ps
check_success "Verificação do status do Traccar"

# Instalar o Certbot para SSL
echo -e "${YELLOW}[ETAPA 17]${NC} Instalando o Certbot..."
sudo apt install certbot python3-certbot-nginx -y
check_success "Instalação do Certbot"

# Obter certificado SSL (apenas se for um domínio válido)
if [[ $DOMAIN_OR_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}[ETAPA 18]${NC} IP detectado. SSL não será configurado automaticamente."
else
    echo -e "${YELLOW}[ETAPA 18]${NC} Obtendo certificado SSL para $DOMAIN_OR_IP..."
    sudo certbot --nginx -d $DOMAIN_OR_IP
    check_success "Obtenção do certificado SSL"

    # Testar renovação automática do SSL
    echo -e "${YELLOW}[ETAPA 19]${NC} Testando renovação automática do SSL..."
    sudo certbot renew --dry-run
    check_success "Teste de renovação automática do SSL"
fi

# Mensagem final
echo -e "${GREEN}"
echo "================================================================"
echo " Instalação e configuração do Traccar concluída!"
if [[ $DOMAIN_OR_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo " Acesse a interface web em: http://$DOMAIN_OR_IP"
else
    echo " Acesse a interface web em: https://$DOMAIN_OR_IP"
fi
echo "================================================================"
echo -e "${NC}"

# Cadastrar usuário, email e senha
echo -e "${YELLOW}[ETAPA 20]${NC} Cadastrando usuário administrador..."
read -p "Digite o nome de usuário: " USERNAME
read -p "Digite o email: " EMAIL
read -sp "Digite a senha: " PASSWORD
echo

# Criar usuário administrador via API do Traccar
echo -e "${YELLOW}[ETAPA 21]${NC} Criando usuário administrador..."
curl -X POST "http://localhost:8082/api/users" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "'"$USERNAME"'",
        "email": "'"$EMAIL"'",
        "password": "'"$PASSWORD"'",
        "admin": true
    }'
check_success "Cadastro do usuário administrador"

# Exibir informações do usuário
echo -e "${GREEN}"
echo "================================================================"
echo " Usuário administrador cadastrado com sucesso!"
echo " Nome de usuário: $USERNAME"
echo " Email: $EMAIL"
echo " Senha: $PASSWORD"
echo "================================================================"
echo -e "${NC}"