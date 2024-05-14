#!/bin/bash
set +e
cat > frontend.env <<EOF
CI_REGISTRY=${CI_REGISTRY}
CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE}
EOF
docker login ${CI_REGISTRY} -u ${DOCKER_USER} -p ${DOCKER_PASSWORD}
docker-compose --env-file frontend.env pull frontend
set -e
docker-compose up --force-recreate --remove-orphans -d frontend