COMPOSE_FILE := srcs/docker-compose.yml
ENV_FILE := srcs/.env
DATA_PATH := /home/tbaniatt/data

.PHONY: all build up down restart logs ps clean fclean re config prepare check-secrets

all: up

prepare:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	@mkdir -p secrets
	@test -f $(ENV_FILE) || cp srcs/.env.example $(ENV_FILE)
	@$(MAKE) check-secrets

check-secrets:
	@test -f secrets/db_root_password.txt || (echo "Missing secrets/db_root_password.txt" && exit 1)
	@test -f secrets/db_password.txt || (echo "Missing secrets/db_password.txt" && exit 1)
	@test -f secrets/wp_admin_password.txt || (echo "Missing secrets/wp_admin_password.txt" && exit 1)
	@test -f secrets/wp_user_password.txt || (echo "Missing secrets/wp_user_password.txt" && exit 1)

build: prepare
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) build

up: prepare
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d --build

down:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

restart:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) restart

logs:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f

ps:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) ps

config:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) config

clean:
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down -v

# The volumes store their files in $(DATA_PATH), and removing a volume does not
# delete them. The files belong to root and mysql, so a container deletes them.
fclean: clean
	docker run --rm -v $(DATA_PATH):/data debian:bookworm sh -c 'rm -rf /data/mariadb /data/wordpress'
	docker image rm -f nginx:inception wordpress:inception mariadb:inception 2>/dev/null || true

re: fclean up
