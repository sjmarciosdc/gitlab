#!/bin/bash

# Função para exibir o menu de ajuda
mostrar_ajuda() {
    echo "Uso: ./control.sh [comando]"
    echo
    echo "Comandos disponíveis:"
    echo "  list-backups             - Lista os backups dentro do container GitLab"
    echo "  copy-backup [ARQUIVO]    - Copia um backup específico do container GitLab para a pasta atual (host)"
    echo "  push-backup [ARQUIVO]    - Envia um backup da pasta atual (host) para o container GitLab"
    echo "  backup-gitlab            - Realiza o backup do GitLab (gitlab-backup create)"
    echo "  restaure [ARQUIVO]       - Restaura um backup do GitLab (ex.: ./control.sh restaure 1737039975_2025_01_16_17.7.0_gitlab_backup.tar)"
    echo "  down-docker              - Para os serviços Docker"
    echo "  generate-config          - Gera os arquivos de configuração a partir de templates"
    echo "  install-ngrok-service    - Instala o serviço Ngrok usando ngrok.yml"
    echo "  logs                     - Exibe os logs do Docker"
    echo "  mudar-senha              - Reseta a senha do GitLab"
    echo "  reconfigurar-gitlab      - Executa o reconfigure do GitLab"
    echo "  reinstall-ngrok-service  - Reinstala o serviço Ngrok"
    echo "  restart-ngrok-service    - Reinicia o serviço Ngrok"
    echo "  start-ngrok-service      - Inicia o serviço Ngrok"
    echo "  stop-ngrok-service       - Para o serviço Ngrok"
    echo "  uninstall-ngrok-service  - Desinstala o serviço Ngrok"
    echo "  up-docker                - Inicia os serviços Docker"
    echo "  help                     - Mostra este menu de ajuda"
    echo
}

# Função para listar os arquivos de backup dentro do container GitLab
list_backups() {
    echo "Listando arquivos de backup em /var/opt/gitlab/backups do container 'gitlab':"
    docker-compose exec gitlab ls -lh /var/opt/gitlab/backups
}

# Função para copiar um backup específico do container para a pasta atual
copy_backup() {
    local BACKUP_FILE="$1"
    if [ -z "$BACKUP_FILE" ]; then
        echo "Erro: informe o nome do arquivo de backup."
        echo "Exemplo: ./control.sh copy-backup 1737039975_2025_01_16_17.7.0_gitlab_backup.tar"
        exit 1
    fi

    echo "Copiando '$BACKUP_FILE' do container GitLab para a pasta atual (host)..."
    docker cp "gitlab:/var/opt/gitlab/backups/$BACKUP_FILE" .
    echo "Cópia concluída: $BACKUP_FILE"
}

# Função para enviar (push) um backup do diretório atual para o container
push_backup() {
    local BACKUP_FILE="$1"
    if [ -z "$BACKUP_FILE" ]; then
        echo "Erro: informe o nome do arquivo de backup a enviar."
        echo "Exemplo: ./control.sh push-backup 1737039975_2025_01_16_17.7.0_gitlab_backup.tar"
        exit 1
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Erro: o arquivo '$BACKUP_FILE' não existe no diretório atual."
        exit 1
    fi

    echo "Enviando '$BACKUP_FILE' do diretório atual para /var/opt/gitlab/backups no container GitLab..."
    docker cp "$BACKUP_FILE" "gitlab:/var/opt/gitlab/backups/"
    echo "Arquivo '$BACKUP_FILE' copiado com sucesso para dentro do container."
}

# Função para realizar o backup nativo do GitLab
backup_gitlab() {
    docker-compose exec gitlab gitlab-backup create
    echo "Backup do GitLab criado com sucesso."
}

# Função para restaurar um backup do GitLab
restaure() {
    if [ -z "$1" ]; then
        echo "Erro: informe o nome do arquivo de backup completo."
        echo "Exemplo: ./control.sh restaure 1737039975_2025_01_16_17.7.0_gitlab_backup.tar"
        exit 1
    fi

    local BACKUP_FILE="$1"

    # Verifica se o arquivo existe no diretório atual
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Erro: o arquivo '$BACKUP_FILE' não existe no diretório atual."
        exit 1
    fi

    echo "Copiando '$BACKUP_FILE' para dentro do container GitLab..."
    docker cp "$BACKUP_FILE" gitlab:/var/opt/gitlab/backups/

    # Extrai o timestamp (tudo antes do primeiro underscore)
    local TIMESTAMP
    TIMESTAMP=$(echo "$BACKUP_FILE" | cut -d_ -f1)

    echo "Parando serviços Puma e Sidekiq no GitLab..."
    docker-compose exec gitlab gitlab-ctl stop puma
    docker-compose exec gitlab gitlab-ctl stop sidekiq

    echo "Ajustando permissões do arquivo de backup dentro do container..."
    docker-compose exec gitlab chown git:git "/var/opt/gitlab/backups/$BACKUP_FILE"

    echo "Iniciando restauração do backup: $BACKUP_FILE"
    # '-T' evita problemas de alocação de pseudoTTY, permitindo interação de confirmação
    docker-compose exec -T gitlab bash -c "gitlab-backup restore BACKUP=$TIMESTAMP"

    echo "Reconfigurando e reiniciando serviços do GitLab..."
    docker-compose exec gitlab gitlab-ctl reconfigure
    docker-compose exec gitlab gitlab-ctl start

    echo "Backup '$BACKUP_FILE' restaurado com sucesso!"
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

# Função para reconfigurar o GitLab
reconfigurar_gitlab() {
    docker-compose exec gitlab gitlab-ctl reconfigure
    echo "GitLab reconfigurado."
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
    # Removida a criação automática das pastas config, logs e data
    docker-compose up -d
    echo "Docker iniciado."
}

# Verifica o comando passado
case $1 in
    list-backups)
        list_backups
        ;;
    copy-backup)
        shift
        copy_backup "$@"
        ;;
    push-backup)
        shift
        push_backup "$@"
        ;;
    backup-gitlab)
        backup_gitlab
        ;;
    restaure)
        shift
        restaure "$@"
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
    reconfigurar-gitlab)
        reconfigurar_gitlab
        ;;
    reinstall-ngrok-service)
        reinstall_ngrok_service
        ;;
    restart-ngrok-service)
        restart_ngrok_service
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

