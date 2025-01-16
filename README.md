
# Configuração, Execução e Gerenciamento do GitLab com Docker e Ngrok

Este repositório contém scripts e arquivos de configuração para executar uma instância do GitLab em contêiner Docker, além de gerenciar integrações com o Ngrok. Abaixo estão detalhados todos os passos e comandos para facilitar o uso e manutenção.

---

## 1. Visão Geral dos Arquivos Principais

- **`env.template`** e **`env`**  
  Arquivos de variáveis de ambiente. O arquivo `env.template` serve como modelo; você deve criar uma cópia chamada `env` e customizar as variáveis conforme suas necessidades (tokens do Ngrok, configurações de domínio, etc.).

- **`docker-compose.yml.template`**  
  Template do arquivo `docker-compose.yml`. Nele, algumas variáveis são referenciadas para que sejam substituídas pelos valores do arquivo `env`.

- **`docker-compose.yml`**  
  Gerado automaticamente a partir do template e das variáveis definidas em `env`. É o arquivo efetivamente utilizado pelo Docker-Compose para subir os serviços.

- **`ngrok.yml.template`**  
  Template do arquivo `ngrok.yml`. Também contém variáveis que serão substituídas pelos valores do arquivo `env`.

- **`ngrok.yml`**  
  Gerado automaticamente para configuração do Ngrok (autenticação, túneis, etc.).

- **`control.sh`**  
  Script principal que gerencia as seguintes operações:
  - Criação, listagem e restauração de backups do GitLab.
  - Copiar backups entre o host e o contêiner GitLab.
  - Subir/derrubar os contêineres Docker.
  - Instalar, desinstalar e gerenciar o serviço Ngrok.
  - Gerar arquivos de configuração a partir de templates.
  - Resetar senha do GitLab, reconfigurar e exibir logs.
  
  O `control.sh` aceita parâmetros que correspondem aos comandos descritos na seção [4. Comandos disponíveis no `control.sh`](#4-comandos-dispon%C3%ADveis-no-controlsh).

- **Scripts auxiliares** (opcional, caso existam no seu projeto):
  - **`generate.sh`**: Pode chamar internamente o comando `./control.sh generate-config`.
  - **`up_docker.sh`**: Pode chamar internamente o comando `./control.sh up-docker`.
  - **`down_docker.sh`**: Pode chamar internamente o comando `./control.sh down-docker`.
  - E assim por diante, se você quiser scripts externos para simplificar o uso.

---

## 2. Passos Iniciais de Configuração

1. **Copiar o arquivo de variáveis de ambiente**  
   Crie um arquivo `env` a partir do template:
   ```bash
   cp env.template env
   ```
   Em seguida, edite o arquivo `env` para incluir suas configurações (por exemplo, token do Ngrok, portas, nome de domínio etc.).

2. **Gerar arquivos de configuração**  
   Gere os arquivos de configuração necessários (`docker-compose.yml` e `ngrok.yml`) com base nos templates e nas variáveis definidas no seu `env`.  
   Você pode fazer isso de duas formas:
   - **Chamando diretamente o `control.sh`:**
     ```bash
     ./control.sh generate-config
     ```
   - **Usando um script auxiliar (caso exista `generate.sh`):**
     ```bash
     ./generate.sh
     ```

3. **Subir os contêineres Docker**  
   Após a geração dos arquivos de configuração, você pode iniciar os serviços Docker (incluindo o GitLab).  
   - **Chamando diretamente o `control.sh`:**
     ```bash
     ./control.sh up-docker
     ```
   - **Usando um script auxiliar (caso exista `up_docker.sh`):**
     ```bash
     ./up_docker.sh
     ```

4. **Configurar Ngrok (opcional)**  
   - Se desejar instalar o Ngrok como serviço, para rodar em background:
     ```bash
     ./control.sh install-ngrok-service
     ```
   - Caso queira usar o Ngrok pontualmente, basta rodar o binário (ou o serviço). Lembre-se de que o arquivo `ngrok.yml` (gerado no passo anterior) contém suas configurações.

---

## 3. Problemas com a Cota do Ngrok

Se o seu token do Ngrok exceder o limite de cota, você pode:
1. Obter um novo token (em outra conta ou plano).
2. Substituir o token antigo no arquivo `env` pela nova chave.
3. Regenerar os arquivos de configuração:
   ```bash
   ./control.sh generate-config
   ```
4. Reiniciar ou reinstalar o serviço do Ngrok, se necessário:
   ```bash
   ./control.sh restart-ngrok-service
   ```
   ou
   ```bash
   ./control.sh reinstall-ngrok-service
   ```

---

## 4. Comandos disponíveis no `control.sh`

Execute:
```bash
./control.sh help
```
Para ver o menu de ajuda. Abaixo uma breve descrição de cada comando:

1. **`list-backups`**  
   - Lista os backups dentro do contêiner GitLab, no diretório `/var/opt/gitlab/backups`.
   ```bash
   ./control.sh list-backups
   ```

2. **`copy-backup [ARQUIVO]`**  
   - Copia um arquivo de backup específico **do contêiner GitLab** para a **máquina host** (diretório atual).
   ```bash
   ./control.sh copy-backup 123456789_YYYY_MM_DD_gitlab_backup.tar
   ```

3. **`push-backup [ARQUIVO]`**  
   - Envia (do **host** para o **contêiner**) um arquivo de backup localizado na pasta atual para `/var/opt/gitlab/backups` dentro do contêiner GitLab.
   ```bash
   ./control.sh push-backup 123456789_YYYY_MM_DD_gitlab_backup.tar
   ```

4. **`backup-gitlab`**  
   - Executa o comando nativo `gitlab-backup create` dentro do contêiner, gerando um arquivo de backup.
   ```bash
   ./control.sh backup-gitlab
   ```

5. **`restaure [ARQUIVO]`**  
   - Restaura um backup específico no GitLab. Copia o arquivo do host para o contêiner, para serviços do GitLab, e executa `gitlab-backup restore`.
   ```bash
   ./control.sh restaure 123456789_YYYY_MM_DD_gitlab_backup.tar
   ```

6. **`down-docker`**  
   - Para (derruba) todos os serviços Docker definidos em `docker-compose.yml`.
   ```bash
   ./control.sh down-docker
   ```

7. **`generate-config`**  
   - Gera os arquivos de configuração (`docker-compose.yml` e `ngrok.yml`) a partir dos templates (`docker-compose.yml.template` e `ngrok.yml.template`) usando as variáveis do arquivo `env`.
   ```bash
   ./control.sh generate-config
   ```

8. **`install-ngrok-service`**  
   - Instala o serviço Ngrok usando o arquivo `ngrok.yml`. Exige o binário Ngrok instalado localmente e privilégios de administrador.
   ```bash
   ./control.sh install-ngrok-service
   ```

9. **`logs`**  
   - Exibe em tempo real os logs do Docker Compose (`docker-compose logs -f`).
   ```bash
   ./control.sh logs
   ```

10. **`mudar-senha`**  
    - Reseta a senha do usuário root do GitLab (ou do usuário administrador).
    ```bash
    ./control.sh mudar-senha
    ```

11. **`reconfigurar-gitlab`**  
    - Executa `gitlab-ctl reconfigure` dentro do contêiner, aplicando possíveis alterações de configuração.
    ```bash
    ./control.sh reconfigurar-gitlab
    ```

12. **`reinstall-ngrok-service`**  
    - Desinstala e reinstala o serviço Ngrok, em seguida reinicia o serviço.
    ```bash
    ./control.sh reinstall-ngrok-service
    ```

13. **`restart-ngrok-service`**  
    - Reinicia o serviço Ngrok (caso instalado como serviço do sistema).
    ```bash
    ./control.sh restart-ngrok-service
    ```

14. **`start-ngrok-service`**  
    - Inicia o serviço Ngrok.
    ```bash
    ./control.sh start-ngrok-service
    ```

15. **`stop-ngrok-service`**  
    - Para o serviço Ngrok.
    ```bash
    ./control.sh stop-ngrok-service
    ```

16. **`uninstall-ngrok-service`**  
    - Desinstala o serviço Ngrok.
    ```bash
    ./control.sh uninstall-ngrok-service
    ```

17. **`up-docker`**  
    - Sobe (inicia) os serviços Docker definidos em `docker-compose.yml`.
    ```bash
    ./control.sh up-docker
    ```

18. **`help`**  
    - Mostra o menu de ajuda do script.
    ```bash
    ./control.sh help
    ```

---

## 5. Exemplos de Uso

### Criar e Listar Backups

```bash
# Cria um novo backup
./control.sh backup-gitlab

# Lista backups disponíveis no contêiner
./control.sh list-backups
```

### Restaurar Backup

```bash
# Supondo que você tenha o arquivo de backup no host
# 1. Copie o arquivo para o container e inicie o processo de restauração
./control.sh restaure 1737039975_2025_01_16_17.7.0_gitlab_backup.tar
```

### Parar e Subir Serviços Docker

```bash
# Parar serviços Docker
./control.sh down-docker

# Subir serviços Docker
./control.sh up-docker
```

### Gerenciar Ngrok

```bash
# Instalar o serviço Ngrok
./control.sh install-ngrok-service

# Reiniciar o serviço Ngrok
./control.sh restart-ngrok-service
```

---

## 6. Dicas e Observações

- Se estiver enfrentando problemas de permissão com Docker, verifique se seu usuário está no grupo `docker` ou use `sudo`.
- Sempre atualize o arquivo `env` e gere novamente os arquivos de configuração quando houver mudança de domínio, token do Ngrok ou outras variáveis importantes.
- Os scripts foram testados em ambientes Linux. Em outros sistemas operacionais, pode ser necessário adaptar comandos ou permissões.

---

## 7. Contribuições

Sinta-se à vontade para abrir *issues* ou enviar *merge requests* com correções ou novas funcionalidades. 

1. **Fork do repositório**  
2. **Crie uma nova branch** para suas alterações.  
3. **Commit e push** da sua branch.  
4. **Abra um pull request** para revisão.

---

## 8. Licença

Este projeto pode ser distribuído livremente. Adicione aqui a licença de sua preferência (MIT, GPL, etc.), se necessário.

---

**Esperamos que este guia tenha lhe ajudado a entender e gerenciar melhor a sua instância do GitLab e o serviço de tunelamento Ngrok!**
