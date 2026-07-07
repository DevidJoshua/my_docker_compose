# Database Management Guide

All commands below manage databases **without entering the container** — they connect to the database server running inside the container from the host.

---

## PostgreSQL

### Create Database

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "CREATE DATABASE my_database;"
```

### Create User

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "CREATE USER my_user WITH PASSWORD 'my_pass';"
```

### Grant Permissions

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE my_database TO my_user;"
```

### Run Query (single command)

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -d my_database -c "SELECT * FROM my_table;"
```

### Run Query (interactive shell)

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -d my_database
```

Then type SQL directly (exit with `\q`).

### List Databases

```bash
docker exec -it $(docker ps --filter name=postgres -q) \
  psql -U postgres -c "\l"
```

### Using Host CLI (requires `psql` installed locally)

```bash
# create
psql -h localhost -p 5432 -U postgres -c "CREATE DATABASE my_database;"

# query
psql -h localhost -p 5432 -U postgres -d my_database -c "SELECT * FROM my_table;"

# interactive
psql -h localhost -p 5432 -U postgres -d my_database
```

---

## MySQL

### Create Database

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "CREATE DATABASE my_database;"
```

### Create User

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "CREATE USER 'my_user'@'%' IDENTIFIED BY 'my_pass';"
```

### Grant Permissions

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "GRANT ALL ON my_database.* TO 'my_user'@'%';"
```

### Run Query (single command)

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" my_database -e "SELECT * FROM my_table;"
```

### Run Query (interactive shell)

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" my_database
```

### List Databases

```bash
docker exec -it $(docker ps --filter name=mysql -q) \
  mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-changeme_mysql}" -e "SHOW DATABASES;"
```

### Using Host CLI (requires `mysql` installed locally)

```bash
# create
mysql -h localhost -P 3306 -uroot -p -e "CREATE DATABASE my_database;"

# query
mysql -h localhost -P 3306 -uroot -p my_database -e "SELECT * FROM my_table;"

# interactive
mysql -h localhost -P 3306 -uroot -p my_database
```

---

## Qdrant

Qdrant is a vector database — it does not use SQL. Collections are created via its REST API.

### Create Collection

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

### List Collections

```bash
curl http://localhost:6333/collections
```

### Insert Points

```bash
curl -X PUT http://localhost:6333/collections/my_collection/points \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, 0.4],
        "payload": {"label": "example"}
      }
    ]
  }'
```

### Search (Query) Points

```bash
curl -X POST http://localhost:6333/collections/my_collection/points/search \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, 0.3, 0.4],
    "limit": 10
  }'
```

### Delete Collection

```bash
curl -X DELETE http://localhost:6333/collections/my_collection
```

---

## phpMyAdmin (Web UI)

Access at: [http://localhost:8080](http://localhost:8080)

- **Server:** `mysql` (service name, resolves inside the stack network)
- **Username:** `root`
- **Password:** defined by `MYSQL_ROOT_PASSWORD` (default: `changeme_mysql`)

Once logged in, you can create databases, run SQL queries, and manage users via the browser interface.
