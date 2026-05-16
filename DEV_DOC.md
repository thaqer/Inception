# DEV_DOC

## Environment Setup from Scratch

### Prerequisites

- Linux VM (42 requirement)
- Docker Engine + Docker Compose plugin
- Make

### Configuration Files

- Copy `srcs/.env.example` to `srcs/.env`.
- Fill required non-sensitive variables in `srcs/.env`.
- Create real secret files in `secrets/` from `*.example` templates.

## Build and Launch

- Full build + run:
  - `make`
- Build only:
  - `make build`
- Stop:
  - `make down`
- Rebuild from scratch:
  - `make re`

## Useful Operational Commands

- Compose config validation:
  - `make config`
- Service status:
  - `make ps`
- Tail logs:
  - `make logs`
- Remove stack + volumes:
  - `make clean`

## Data Persistence Layout

Mandatory persistent data is stored in Docker named volumes mapped to host directories:
- MariaDB data: `/home/tbaniatt/data/mariadb`
- WordPress files: `/home/tbaniatt/data/wordpress`

These are configured as named volumes in `srcs/docker-compose.yml` and survive container recreation unless removed explicitly.
