source ./env
envsubst < docker-compose.yml.template > docker-compose.yml
envsubst < ngrok.yml.template > ngrok.yml
