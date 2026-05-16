*This project has been created as part of the 42 curriculum by tbaniatt*

## Description

Inception is a system administration project where a complete WordPress stack is built with Docker Compose on a VM. This repository implements the mandatory architecture with three custom images:
- NGINX (TLS entrypoint on port 443)
- WordPress + PHP-FPM
- MariaDB

The stack uses one custom bridge network and two named volumes persisted on the host under `/home/tbaniatt/data`.

### Project Design Choices

- Base images: `debian:bookworm` for all mandatory services (penultimate stable Debian release).
- One Dockerfile per service, no prebuilt service image from DockerHub.
- Secrets are stored in local files (`secrets/*.txt`) and injected as Compose secrets.
- Non-sensitive values are kept in `srcs/.env`.

### Required Comparisons

- Virtual Machines vs Docker:
  - VM virtualizes full OS instances with a dedicated kernel boundary and larger resource cost.
  - Docker isolates processes with shared host kernel, faster startup, smaller footprint, and easier service composition.

- Secrets vs Environment Variables:
  - Env vars are easy but broadly exposed in process environments and inspection outputs.
  - Secrets are mounted as files per service and reduce accidental leakage in command history and config dumps.

- Docker Network vs Host Network:
  - Docker bridge network isolates service traffic and keeps internal ports private by default.
  - Host networking bypasses isolation and is forbidden in this project requirements.

- Docker Volumes vs Bind Mounts:
  - Named volumes are managed by Docker and make persistence lifecycle explicit.
  - Bind mounts directly map host paths into containers; for mandatory WP/DB storage this project uses named volumes as required.

## Instructions

### 1. Prepare configuration

1. Copy `srcs/.env.example` to `srcs/.env` and adjust values if needed.
2. Create local secret files from templates in `secrets/`:
   - `db_root_password.txt`
   - `db_password.txt`
   - `wp_admin_password.txt`
   - `wp_user_password.txt`
3. Add local DNS mapping for `tbaniatt.42.fr` to your VM IP (or `127.0.0.1` for local-only access).

### 2. Run the project

- Start/build: `make`
- Stop: `make down`
- Restart services: `make restart`
- Follow logs: `make logs`
- Validate Compose config: `make config`

## Resources

- Docker Compose documentation: https://docs.docker.com/compose/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- NGINX docs: https://nginx.org/en/docs/
- WordPress CLI docs: https://developer.wordpress.org/cli/commands/
- MariaDB docs: https://mariadb.com/kb/en/documentation/

### AI Usage

AI was used for:
- Turning subject requirements into an implementation checklist.
- Drafting initial container/script structures.
- Reviewing compliance points (network rules, env/secrets split, documentation completeness).

All generated content was manually reviewed, adapted, and tested in this repository.
