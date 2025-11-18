{
  "logging_level": -40,
  "client_secure": true,
  "server_secure": false,
  "host_name": "${REGISTRY_HOST}",
  "domain": "${DOMAIN}",
  "pri": 99,
  "label": "easy-nmos-registry",
  "http_port": 80,
  "registration_expiry_interval": 12,
  "is04_versions": ["v1.3"],
  "is10_versions": ["v1.0"],
  "ca_certificate_file": "/home/certs/ca.pem",
  "authorization_endpoint": "https://${KEYCLOAK_HOST}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/auth",
  "token_endpoint": "https://${KEYCLOAK_HOST}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token",
  "jwks_uri": "https://${KEYCLOAK_HOST}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs",
  "server_authorization": true,
  "client_authorization": false
}
