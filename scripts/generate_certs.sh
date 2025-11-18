#!/usr/bin/env bash
set -euo pipefail
set -a; source .env; set +a

CERT_DIR="nginx/certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "[certs] Cleaning old certs..."
rm -f *.key *.crt *.csr *.srl *.pem *.conf

echo "[certs] Creating CA..."
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -out ca.crt \
    -subj "/C=CH/ST=VD/L=Lausanne/O=NMOS Lab/CN=NMOS Lab CA"

cp ca.crt ca.pem

generate_cert() {
  local base=$1 ip=$2 cn=$3

  cat > "${base}.conf" <<EOF
[req]
default_bits = 2048
distinguished_name = dn
req_extensions = req_ext
prompt = no

[dn]
CN = ${cn}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${cn}
IP.1 = ${ip}
IP.2 = 127.0.0.1
EOF

  openssl genrsa -out ${base}.key 2048
  openssl req -new -key ${base}.key -out ${base}.csr -config ${base}.conf
  openssl x509 -req -in ${base}.csr \
      -CA ca.crt -CAkey ca.key -CAcreateserial \
      -out ${base}.crt -days 825 -sha256 \
      -extensions req_ext -extfile ${base}.conf

  cat ${base}.crt ca.crt > ${base}.fullchain.crt
  rm ${base}.csr ${base}.conf
  echo "[certs] Created certificate for ${cn}"
}

generate_cert registry "$REGISTRY_IP" "$REGISTRY_HOST"
generate_cert node "$NODE_IP" "$NODE_HOST"
generate_cert keycloak "$KEYCLOAK_IP" "$KEYCLOAK_HOST"

echo "[certs] ✅ Done"
