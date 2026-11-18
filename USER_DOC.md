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

1. Ensure `tbaniatt.42.fr` resolves locally:

   ```bash
   echo "127.0.0.1 tbaniatt.42.fr" | sudo tee -a /etc/hosts
   ```

   If browser runs outside the VM, add the same mapping on that machine using the VM IP.
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

Passwords are applied only on the first start, when the database and the site are created. Editing a secret file afterwards does not change them, and changing `db_password.txt` alone breaks the connection between WordPress and MariaDB.

To change passwords:
- **Start fresh (deletes all site content):** update the secret files, then run `make re`.
- **Keep the content:** change a WordPress user's password in the admin panel (or with `wp user update <user> --user_pass=<new> --allow-root` inside the `wordpress` container), then put the new value in the matching secret file so the two stay in sync.

## Health and Runtime Checks

- Container status and health:
  - `docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps`
- Live logs:
  - `make logs`
- TLS endpoint check:
  - `curl -kI https://tbaniatt.42.fr`
