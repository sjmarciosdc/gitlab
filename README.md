# Configuração e Execução da Aplicação

## Passos para Configuração

1. **Copiar o arquivo de variáveis de ambiente**
   - Faça uma cópia do arquivo `env.template` e renomeie-o para `env`:
     ```bash
     cp env.template env
     ```
   - Edite o arquivo `env` e adicione suas variáveis personalizadas.

2. **Gerar arquivos de configuração**
   - Execute o script `generate.sh` para criar os arquivos de configuração necessários:
     ```bash
     ./generate.sh
     ```

3. **Subir a aplicação**
   - Execute o script `up_docker.sh` para iniciar a aplicação:
     ```bash
     ./up_docker.sh
     ```

## Problemas com o Ngrok

Se sua cota de uso no Ngrok acabar, siga os passos abaixo para continuar usando o serviço:
1. Substitua o token atual no arquivo `env` por um token válido que não tenha atingido o limite de cota.
2. Repita o processo de configuração e execução descrito acima:
   - Gere os arquivos novamente com `generate.sh`.
   - Suba a aplicação com `up_docker.sh`.

---

## Exemplos de Comandos

### Copiar o arquivo de variáveis
```bash
cp env.template env

