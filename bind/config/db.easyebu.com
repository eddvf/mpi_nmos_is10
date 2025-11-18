$TTL 3600
@   IN  SOA dns1.easyebu.com. admin.easyebu.com. (
        2025010101 ; Serial
        3600       ; Refresh
        600        ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL
;
@       IN      NS      dns1.easyebu.com.
; Service discovery
_services._dns-sd._udp  IN PTR _nmos-system._tcp
_services._dns-sd._udp  IN PTR _nmos-query._tcp
_services._dns-sd._udp  IN PTR _nmos-registration._tcp
_services._dns-sd._udp  IN PTR _nmos-register._tcp
_services._dns-sd._udp  IN PTR _nmos-node._tcp
_services._dns-sd._udp  IN PTR _nmos-auth._tcp

; IS-04 System API via HTTPS (proxy)
_nmos-system._tcp              IN PTR  sys-api-1._nmos-system._tcp
sys-api-1._nmos-system._tcp    IN SRV  0 50 443 nmos-registry.easyebu.com.
sys-api-1._nmos-system._tcp    IN TXT  "api_ver=v1.3" "api_proto=https" "pri=10" "api_auth=true"

; IS-04 Registration API via HTTPS (proxy)
_nmos-registration._tcp        IN PTR  reg-api-1._nmos-registration._tcp
_nmos-register._tcp            IN PTR  reg-api-1._nmos-register._tcp

reg-api-1._nmos-registration._tcp IN SRV 0 50 443 nmos-registry.easyebu.com.
reg-api-1._nmos-registration._tcp IN TXT "api_ver=v1.3" "api_proto=https" "pri=10" "api_auth=true"

reg-api-1._nmos-register._tcp     IN SRV 0 50 443 nmos-registry.easyebu.com.
reg-api-1._nmos-register._tcp     IN TXT "api_ver=v1.3" "api_proto=https" "pri=10" "api_auth=true"

; IS-04 Query API via HTTPS (proxy)
_nmos-query._tcp               IN PTR  qry-api-1._nmos-query._tcp
qry-api-1._nmos-query._tcp     IN SRV  0 50 443 nmos-registry.easyebu.com.
qry-api-1._nmos-query._tcp     IN TXT  "api_ver=v1.3" "api_proto=https" "pri=0" "api_auth=true"

; Node API via HTTPS (proxy)
_nmos-node._tcp                IN PTR  node-api-1._nmos-node._tcp
node-api-1._nmos-node._tcp     IN SRV  0 50 443 nmos-virtnode.easyebu.com.
node-api-1._nmos-node._tcp     IN TXT  "api_ver=v1.3" "api_proto=https" "pri=10" "api_auth=true"

; IS-10 Authorization API via HTTPS (proxy / Keycloak)
_nmos-auth._tcp                IN PTR  auth-api-1._nmos-auth._tcp
auth-api-1._nmos-auth._tcp     IN SRV  0 50 443 keycloak.easyebu.com.
auth-api-1._nmos-auth._tcp     IN TXT  "api_ver=v1.0" "api_proto=https" "pri=10" "api_selector=x-nmos/auth/v1.0"

; A records (Bind, proxy, infra)
dns1            IN A    10.100.64.20
proxy           IN A    10.100.64.11
nmos-registry   IN A    10.100.64.11
nmos-virtnode   IN A    10.100.64.11
keycloak        IN A    10.100.64.11
postgres        IN A    10.100.64.14
