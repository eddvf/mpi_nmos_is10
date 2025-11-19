SHELL := /bin/bash

render:
	./scripts/render.sh

certs:
	./scripts/generate_certs.sh

mac:
	sudo ./scripts/macvlan_host.sh

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps
