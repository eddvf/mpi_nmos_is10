#!/usr/bin/env bash
set -euo pipefail

set -a; source .env; set +a
export DOLLAR='$'
mkdir -p nginx bind/config json_configs keycloak/import

envsubst '${REGISTRY_HOST} ${REGISTRY_IP} ${NODE_HOST} ${NODE_IP} ${KEYCLOAK_HOST} ${KEYCLOAK_IP} ${KEYCLOAK_REALM}' < templates/nginx.conf.tpl > nginx/nginx.conf
envsubst < templates/db.domain.tpl > "bind/config/db.${DOMAIN}"

rm -f keycloak/import/*.json
envsubst < templates/nmos-realm.json.tpl > "keycloak/import/${KEYCLOAK_REALM}-realm.json"

echo "; reverse placeholder" > bind/config/db.reverse
envsubst < templates/node.json.tpl > json_configs/node.json
envsubst < templates/registry.json.tpl > json_configs/registry.json

echo "[render] done."
