#!/bin/bash

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Create certs directory if it doesn't exist
mkdir -p certs
cd certs

# Clean up old certificates
echo "Cleaning up old certificates..."
rm -f *.key *.crt *.csr *.srl *.pem *.conf

# Create a Certificate Authority
echo "Creating Certificate Authority..."
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
    -subj "/C=BE/ST=Brussels/L=Brussels/O=EBU/CN=EBU NMOS CA"

# Convert CA cert to PEM format (same content, just renamed for clarity)
cp ca.crt ca.pem

echo "CA certificate created."

# Function to create certificate with multiple SANs
# Usage: create_cert <base_name> <ip_address> <dns_name1> [dns_name2] [dns_name3] ...
create_cert() {
    local base_name=$1
    local ip=$2
    shift 2 # Remove base_name and ip from the list of arguments
    local dns_names=("$@") # The rest are DNS names

    echo "Creating certificate for ${dns_names[0]}..."

    # Create config file with SANs
    cat > ${base_name}.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = BE
ST = Brussels
L = Brussels
O = EBU
CN = ${dns_names[0]}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
IP.1 = ${ip}
IP.2 = 127.0.0.1
EOF

    # Add all DNS names to the config
    for i in "${!dns_names[@]}"; do
        echo "DNS.$((i+1)) = ${dns_names[$i]}" >> ${base_name}.conf
    done

    # Generate key
    openssl genrsa -out ${base_name}.key 2048

    # Generate CSR
    openssl req -new -key ${base_name}.key -out ${base_name}.csr -config ${base_name}.conf

    # Sign with CA
    openssl x509 -req -in ${base_name}.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -out ${base_name}.crt -days 365 \
        -extensions v3_req -extfile ${base_name}.conf

    # Create fullchain certificate
    cat ${base_name}.crt ca.crt > ${base_name}.fullchain.crt

    # Cleanup
    rm ${base_name}.csr ${base_name}.conf
}

# --- Create Certificates ---

# For NMOS Registry
create_cert "registry" "10.100.64.12" "nmos-registry.easyebu.com"

# For NMOS Node
create_cert "node" "10.100.64.13" "nmos-virtnode.easyebu.com"

# For Keycloak and Proxy (handles both hostnames)
create_cert "keycloak" "10.100.64.15" "keycloak.easyebu.com" "proxy.easyebu.com"


echo ""
echo "All certificates generated successfully!"
echo "CA certificate fingerprint:"
openssl x509 -in ca.pem -noout -fingerprint
