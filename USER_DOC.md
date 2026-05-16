# USER_DOC

## Provided Services

This stack provides:
- `nginx`: HTTPS entrypoint for the website on port `443`.
- `wordpress`: PHP-FPM + WordPress application.
- `mariadb`: database backend for WordPress.

## Start and Stop

- Start/build everything:
  - `make`
- Stop containers:
  - `make down`
- Restart running services:
  - `make restart`
- Show running state:
  - `make ps`

## Access the Website and Admin Panel

1. Ensure `tbaniatt.42.fr` points to your VM IP.
2. Open `https://tbaniatt.42.fr` in a browser.
3. Admin panel is available at:
   - `https://tbaniatt.42.fr/wp-admin`

## Credentials Location and Management

Credentials are local files in `secrets/`:
- `db_root_password.txt`
- `db_password.txt`
- `wp_admin_password.txt`
- `wp_user_password.txt`

Non-sensitive settings are in `srcs/.env`.

To rotate credentials:
1. Update the relevant secret file.
2. Recreate impacted services (`make down` then `make`).

## Health and Runtime Checks

- Container status and health:
  - `docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps`
- Live logs:
  - `make logs`
- TLS endpoint check:
  - `curl -kI https://tbaniatt.42.fr`
