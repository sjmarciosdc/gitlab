#!/bin/bash

# Função para exibir o menu de ajuda
mostrar_ajuda() {
    echo "Uso: ./control.sh [comando]"
    echo
    echo "Comandos disponíveis:"
    echo "  backup                   - Realiza o backup dos dados"
    echo "  clear                    - Limpa as pastas config, logs e data"
    echo "  down-docker              - Para os serviços Docker"
    echo "  generate-config          - Gera os arquivos de configuração a partir de templates"
    echo "  install-ngrok-service    - Instala o serviço Ngrok usando ngrok.yml"
    echo "  logs                     - Exibe os logs do Docker"
    echo "  mudar-senha              - Reseta a senha do GitLab"
    echo "  reinstall-ngrok-service  - Reinstala o serviço Ngrok"
    echo "  restart-ngrok-service    - Reinicia o serviço Ngrok"
    echo "  restaure                 - Restaura um backup (exemplo: ./control.sh restaure <arquivo.7z>)"
    echo "  start-ngrok-service      - Inicia o serviço Ngrok"
    echo "  stop-ngrok-service       - Para o serviço Ngrok"
    echo "  uninstall-ngrok-service  - Desinstala o serviço Ngrok"
    echo "  up-docker                - Inicia os serviços Docker"
    echo "  help                     - Mostra este menu de ajuda"
    echo
}

# Função para realizar o backup
backup() {
    PASTA_BACKUP="backups"
    DATA=$(date +"%Y%m%d%H%M")

    if [ ! -d "$PASTA_BACKUP" ]; then
        mkdir -p "$PASTA_BACKUP"
        echo "Pasta '$PASTA_BACKUP' criada."
    fi

    docker-compose down
    sudo 7z a "${PASTA_BACKUP}/backup_${DATA}.7z" config logs data
    echo "Backup criado em '${PASTA_BACKUP}/backup_${DATA}.7z'."
}

# Função para limpar pastas
clear() {
    rm -rf config
    rm -rf logs
    rm -rf data
    echo "Pastas 'config', 'logs' e 'data' foram removidas."
}

# Função para parar os serviços Docker
down_docker() {
    docker-compose down
    echo "Docker parado."
}

# Função para gerar arquivos de configuração
generate_config() {
    if [ -f ./env ]; then
        source ./env
        envsubst < docker-compose.yml.template > docker-compose.yml
        envsubst < ngrok.yml.template > ngrok.yml
        echo "Arquivos de configuração gerados."
    else
        echo "Arquivo 'env' não encontrado. Configure as variáveis de ambiente e tente novamente."
    fi
}

# Função para instalar o serviço Ngrok
install_ngrok_service() {
    sudo ngrok service install --config="./ngrok.yml"
    echo "Serviço Ngrok instalado."
}

# Função para exibir logs do Docker
logs() {
    docker-compose logs -f
}

# Função para mudar a senha do GitLab
mudar_senha() {
    docker-compose exec gitlab gitlab-rake "gitlab:password:reset"
    echo "Senha do GitLab resetada."
}

# Função para reinstalar o serviço Ngrok
reinstall_ngrok_service() {
    sudo ngrok service uninstall
    sudo ngrok service install --config="./ngrok.yml"
    sudo ngrok service restart
    echo "Serviço Ngrok reinstalado e reiniciado."
}

# Função para reiniciar o serviço Ngrok
restart_ngrok_service() {
    sudo ngrok service restart
    echo "Serviço Ngrok reiniciado."
}

# Função para restaurar um backup
restaure() {
    if [ -z "$1" ]; then
        echo "Erro: Informe o arquivo de backup a ser restaurado. Exemplo: ./control.sh restaure backup.7z"
    else
        7z x "$1"
        echo "Backup '$1' restaurado."
    fi
}

# Função para iniciar o serviço Ngrok
start_ngrok_service() {
    sudo ngrok service start
    echo "Serviço Ngrok iniciado."
}

# Função para parar o serviço Ngrok
stop_ngrok_service() {
    sudo ngrok service stop
    echo "Serviço Ngrok parado."
}

# Função para desinstalar o serviço Ngrok
uninstall_ngrok_service() {
    sudo ngrok service uninstall
    echo "Serviço Ngrok desinstalado."
}

# Função para iniciar os serviços Docker
up_docker() {
    mkdir -p config logs data
    docker-compose up -d
    echo "Docker iniciado."
}

# Verifica o comando passado
case $1 in
    backup)
        backup
        ;;
    clear)
        clear
        ;;
    down-docker)
        down_docker
        ;;
    generate-config)
        generate_config
        ;;
    install-ngrok-service)
        install_ngrok_service
        ;;
    logs)
        logs
        ;;
    mudar-senha)
        mudar_senha
        ;;
    reinstall-ngrok-service)
        reinstall_ngrok_service
        ;;
    restart-ngrok-service)
        restart_ngrok_service
        ;;
    restaure)
        shift
        restaure "$@"
        ;;
    start-ngrok-service)
        start_ngrok_service
        ;;
    stop-ngrok-service)
        stop_ngrok_service
        ;;
    uninstall-ngrok-service)
        uninstall_ngrok_service
        ;;
    up-docker)
        up_docker
        ;;
    help | *)
        mostrar_ajuda
        ;;
esac

