# Database Stack - Docker Swarm Deployment

## Stack Components

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| PostgreSQL | `postgres:17-alpine` | 5432 | Relational database |
| MySQL | `mysql:8.4` (LTS) | 3306 | Relational database |
| phpMyAdmin | `phpmyadmin:5.2.3-apache` | 80 (internal) | MySQL web admin UI |
| Qdrant | `qdrant/qdrant:v1.18.2` | 6333 / 6334 | Vector database + built-in Web UI (`/dashboard`) |

## Prerequisites

- Docker Engine v25.0+ with Swarm mode initialized
- At least one manager node

```bash
docker swarm init
```

## Quick Deploy

```bash
# 1. Copy and edit environment variables
cp .env.example .env
# Edit .env with secure passwords

# 2. Deploy the stack
docker stack deploy -c docker-compose.yml database_stack

# 3. Check deployment status
docker stack services database_stack
docker stack ps database_stack
```

## Access

| Service | Internal (Swarm network) | External (with published ports) | Notes |
|---------|--------------------------|----------------------------------|-------|
| PostgreSQL | `postgres:5432` | `host:5432` | user: `postgres` |
| MySQL | `mysql:3306` | `host:3306` | root user or `appuser` |
| phpMyAdmin | `phpmyadmin:80` | Behind reverse proxy (Traefik labels included) | Login with MySQL credentials |
| Qdrant REST | `qdrant:6333` | `host:6333` | Web UI at `http://host:6333/dashboard` |
| Qdrant gRPC | `qdrant:6334` | `host:6334` | For production client connections |

## Access Details

### PostgreSQL

| Item | Value |
|------|-------|
| Host | `localhost` or `postgres` (from Swarm network) |
| Port | `5432` |
| User | `${POSTGRES_USER}` (default: `postgres`) |
| Password | `${POSTGRES_PASSWORD}` |
| Database | `${POSTGRES_DB}` (default: `postgres`) |
| Connection string | `postgresql://postgres:changeme_postgres@localhost:5432/postgres` |

```bash
# CLI
docker exec -it $(docker ps --filter name=database_stack_postgres -q) psql -U postgres

# Remote (psql)
psql -h localhost -U postgres -d postgres

# Remote (connection string)
psql "postgresql://postgres:changeme_postgres@localhost:5432/postgres"
```

### MySQL

| Item | Value |
|------|-------|
| Host | `localhost` or `mysql` (from Swarm network) |
| Port | `3306` |
| Root user | `root` / `${MYSQL_ROOT_PASSWORD}` |
| App user | `${MYSQL_USER}` / `${MYSQL_PASSWORD}` |
| Database | `${MYSQL_DATABASE}` (default: `appdb`) |

```bash
# CLI
docker exec -it $(docker ps --filter name=database_stack_mysql -q) mysql -uroot -p

# Remote
mysql -h localhost -u root -p
```

### phpMyAdmin

| Item | Value |
|------|-------|
| URL | `http://localhost:8080` |
| Server input | `mysql` (service name, leave as-is) |
| User | `root` (or `${MYSQL_USER}`) |
| Password | `${MYSQL_ROOT_PASSWORD}` (or `${MYSQL_PASSWORD}`) |

Login with your MySQL credentials at `http://localhost:8080`.

### Qdrant

| Item | Value |
|------|-------|
| REST API | `http://localhost:6333` |
| gRPC API | `localhost:6334` |
| Web UI Dashboard | `http://localhost:6333/dashboard` |
| Health check | `http://localhost:6333/healthz` |

```bash
# Verify Qdrant is running
curl http://localhost:6333/

# Create a test collection
curl -X PUT http://localhost:6333/collections/test \
  -H 'Content-Type: application/json' \
  -d '{"vectors": {"size": 4, "distance": "Cosine"}}'
```

**Security note**: Do not expose databases directly to the internet. Use a reverse proxy (Traefik, Nginx) for phpMyAdmin and keep databases internal.

## phpMyAdmin with Traefik (Alternative)

To expose phpMyAdmin via Traefik instead of `localhost:8080`, uncomment the labels in `docker-compose.yml` and remove the ports section from phpmyadmin service:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.phpmyadmin.rule=Host(`pma.yourdomain.com`)"
  - "traefik.http.services.phpmyadmin.loadbalancer.server.port=80"
```

## Health Checks

All services have built-in health checks. Monitor with:

```bash
docker service ps database_stack_postgres --no-trunc
docker service ps database_stack_mysql --no-trunc
docker service ps database_stack_qdrant --no-trunc
```

## Data Persistence

Data volumes are created locally on the node where each service runs:

| Service | Volume | Mount point |
|---------|--------|-------------|
| PostgreSQL | `postgres_data` | `/var/lib/postgresql/data` |
| MySQL | `mysql_data` | `/var/lib/mysql` |
| Qdrant | `qdrant_data` | `/qdrant/storage` |

**Multi-node limitation**: Local volumes bind to a single node. For multi-node Swarm, replace `driver: local` with a shared storage driver (NFS, GlusterFS, etc.).

## Scaling

Stateful services (PostgreSQL, MySQL, Qdrant) are pinned to the manager node with `replicas: 1`. Do not scale them without setting up replication/clustering.

phpMyAdmin is stateless and can be scaled:

```bash
docker service scale database_stack_phpmyadmin=2
```

## Resource Limits

Current limits (adjust in `docker-compose.yml`):

| Service | Memory limit | Memory reservation |
|---------|-------------|-------------------|
| PostgreSQL | 512 MB | 256 MB |
| MySQL | 512 MB | 256 MB |
| phpMyAdmin | 256 MB | 128 MB |
| Qdrant | 512 MB | 256 MB |

## Update Stack

```bash
# After editing docker-compose.yml or .env
docker stack deploy -c docker-compose.yml database_stack
```

## Remove Stack

```bash
docker stack rm database_stack
```

Volumes will persist. Remove them manually if needed:

```bash
docker volume rm database_stack_postgres_data database_stack_mysql_data database_stack_qdrant_data
```

## Troubleshooting

```bash
# View logs for a service
docker service logs database_stack_postgres

# Inspect a specific task
docker service ps database_stack_mysql --no-trunc

# Check node placement
docker node ls

# Enter a running container
docker exec -it $(docker ps --filter name=database_stack_postgres -q) psql -U postgres
```
