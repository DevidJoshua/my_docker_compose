# Database Management Guide

All commands below create databases **without entering the container** — they connect to the database server running inside the container from the host.

---

## PostgreSQL

Create a database:

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "CREATE DATABASE my_database;"
```

List databases:

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "\l"
```

Using host CLI (requires `psql` installed locally):

```bash
psql -h localhost -p 5432 -U postgres -c "CREATE DATABASE my_database;"
```

---

## MySQL

Create a database:

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "CREATE DATABASE my_database;"
```

List databases:

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "SHOW DATABASES;"
```

Using host CLI (requires `mysql` installed locally):

```bash
mysql -h localhost -P 3306 -uroot -p -e "CREATE DATABASE my_database;"
```

---

## Qdrant

Qdrant is a vector database — it does not use SQL. Collections are created via its REST API:

```bash
curl -X PUT http://localhost:6333/collections/my_collection \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine"
    }
  }'
```

Using Docker:

```bash
docker exec -it $(docker ps --filter name=qdrant -q) \
  wget --no-verbose --tries=1 --spider http://localhost:6333/healthz
```

List collections:

```bash
curl http://localhost:6333/collections
```

---

## phpMyAdmin (Web UI)

Access at: [http://localhost:8080](http://localhost:8080)

- **Server:** `mysql` (service name, resolves inside the stack network)
- **Username:** `root`
- **Password:** defined by `MYSQL_ROOT_PASSWORD` (default: `changeme_mysql`)
