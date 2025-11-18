events { worker_connections 1024; }

http {
  # --- NMOS Registry ---
  server {
    listen 443 ssl;
    http2 on;
    server_name ${REGISTRY_HOST};

    ssl_certificate     /etc/nginx/certs/registry.fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/registry.key;

    location / {
      proxy_pass         http://${REGISTRY_IP};
      proxy_http_version 1.1;
      proxy_set_header   Host               $host;
      proxy_set_header   X-Real-IP          $remote_addr;
      proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto  $scheme;
    }
  }

  # --- NMOS Node ---
  server {
    listen 443 ssl;
    http2 on;
    server_name ${NODE_HOST};

    ssl_certificate     /etc/nginx/certs/node.fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/node.key;

    location / {
      proxy_pass         http://${NODE_IP};
      proxy_http_version 1.1;
      proxy_set_header   Host               $host;
      proxy_set_header   X-Real-IP          $remote_addr;
      proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto  $scheme;
    }
  }

  # --- Keycloak ---
  server {
    listen 443 ssl;
    http2 on;
    server_name ${KEYCLOAK_HOST};

    ssl_certificate     /etc/nginx/certs/keycloak.fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/keycloak.key;

    location / {
      proxy_pass         http://${KEYCLOAK_IP}:8080;
      proxy_http_version 1.1;
      proxy_set_header   Host               $host;
      proxy_set_header   X-Real-IP          $remote_addr;
      proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto  $scheme;
    }

    # IS-10 well-known mapping
    location = /.well-known/oauth-authorization-server/x-nmos/auth/v1.0 {
      proxy_pass http://${KEYCLOAK_IP}:8080/realms/${KEYCLOAK_REALM}/.well-known/openid-configuration;
    }
  }

  # --- HTTP -> HTTPS redirect ---
  server {
    listen 80;
    server_name ${REGISTRY_HOST} ${NODE_HOST} ${KEYCLOAK_HOST};
    return 301 https://$host$request_uri;
  }
}
