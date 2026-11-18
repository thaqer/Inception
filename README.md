*This project has been created as part of the 42 curriculum by tbaniatt*

# Inception

## Description

A 42 Amman system administration project: a WordPress site served over HTTPS, built from three Docker containers that I wrote from scratch (no ready-made images from Docker Hub, only `debian:bookworm` as a base).

```
            port 443 (TLS 1.2 / 1.3 only)
                       │
                ┌──────▼──────┐
                │    NGINX    │  self-signed certificate, made at startup
                └──────┬──────┘
                       │ FastCGI, port 9000
                ┌──────▼──────┐
                │  WordPress  │  PHP-FPM 8.2, installed with WP-CLI
                └──────┬──────┘
                       │ port 3306
                ┌──────▼──────┐
                │   MariaDB   │
                └─────────────┘
     all three on one private bridge network: "inception"
```

- Only port 443 is open to the host. WordPress and MariaDB can only be reached from inside the network.
- Two named volumes keep the database and the site files in `/home/tbaniatt/data`, so nothing is lost when the containers are rebuilt.
- Passwords are Docker secrets: files mounted under `/run/secrets/`, never written in the Compose file or `.env`, and never committed to Git.
- Every container restarts on its own if it crashes, and each one has a health check, so they start in order: MariaDB, then WordPress, then NGINX.
- On first start, the entrypoint scripts create the database and its user, download and install WordPress, and add two users: an administrator (whose name cannot contain "admin", as the subject requires) and an author.

### Design choices

- **Virtual machines vs Docker:** a VM runs a whole operating system with its own kernel, so it is heavier and slower to start. Docker containers share the host kernel and isolate only processes, so they are light, start in seconds and are easy to combine.
- **Secrets vs environment variables:** environment variables show up in `docker inspect`, process listings and logs. Secrets are mounted as files, one per service, so they are much harder to leak by accident.
- **Docker network vs host network:** a bridge network keeps internal traffic private and lets containers find each other by name (`mariadb`, `wordpress`). Host networking removes that isolation, and the subject forbids it.
- **Docker volumes vs bind mounts:** named volumes are managed by Docker, which makes the data lifecycle explicit. A bind mount maps a host folder straight into a container. Here the named volumes store their data in `/home/tbaniatt/data`, as the subject asks.

### Files

| Path | Contents |
| --- | --- |
| `Makefile` | build, start, stop and clean the stack |
| `srcs/docker-compose.yml` | the three services, network, volumes and secrets |
| `srcs/.env` | settings that are not secret: domain, database name, user names |
| `srcs/requirements/<service>/` | `Dockerfile`, config files and `tools/entrypoint.sh` for each service |
| `secrets/` | password templates; the real `*.txt` files are git-ignored |
| `USER_DOC.md` | how to use and manage the running site |
| `DEV_DOC.md` | how to set up, build and work on the project |

## Instructions

You need Docker with the Compose plugin and `make`.

1. Create the four password files (the `.example` files show the names):

   ```sh
   for s in db_root_password db_password wp_admin_password wp_user_password; do
       openssl rand -base64 18 > secrets/$s.txt
   done
   ```

2. Point the domain at your machine:

   ```sh
   echo "127.0.0.1 tbaniatt.42.fr" | sudo tee -a /etc/hosts
   ```

3. Start everything:

   ```sh
   make
   ```

4. Open <https://tbaniatt.42.fr> and accept the self-signed certificate. The admin panel is at `/wp-admin`.

| Command | What it does |
| --- | --- |
| `make` | create the data folders, build the images, start the stack |
| `make down` | stop and remove the containers (data is kept) |
| `make restart` | restart the containers |
| `make logs` | follow the logs |
| `make ps` | show container status |
| `make config` | print the resolved Compose file |
| `make clean` | stop and remove the volumes (the files in the data folder stay) |
| `make fclean` | `clean`, then delete the data folder contents and the images |
| `make re` | `fclean`, then start again |

## Resources

- Docker Compose: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- NGINX: https://nginx.org/en/docs/
- WP-CLI commands: https://developer.wordpress.org/cli/commands/
- MariaDB: https://mariadb.com/kb/en/documentation/

### AI usage

AI was used to:
- turn the subject requirements into an implementation checklist,
- draft the first versions of the Dockerfiles and entrypoint scripts,
- review the project against the rules (networks, environment variables vs secrets, documentation).

All generated content was reviewed, adapted and tested by me.

## Author

[thaqer](https://github.com/thaqer) (42 login: tbaniatt), 42 Amman.
