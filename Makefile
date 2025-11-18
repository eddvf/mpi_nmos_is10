.PHONY: render certs mac up down logs

render:
	./scripts/render.sh
certs:
	./scripts/generate_certs.sh
mac:
	./scripts/macvlan_host.sh
up:
	docker compose up -d
down:
	docker compose down
logs:
	docker compose logs -f
