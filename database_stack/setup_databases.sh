#!/usr/bin/env bash
set -euo pipefail

# ========================================
# Interactive database setup script
# Prompts for custom names at each setup
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env if present (for root credentials only)
if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Root credentials from .env (used to connect)
PG_ROOT_USER="${POSTGRES_USER:-postgres}"
PG_ROOT_PASS="${POSTGRES_PASSWORD:-changeme_postgres}"
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASSWORD:-changeme_mysql}"

get_container_id() {
  docker ps --filter name="$1" -q | head -1
}

setup_postgres() {
  local db_name user_name user_pass
  echo ""
  echo "=== PostgreSQL Setup ==="
  PG_ID=$(get_container_id "postgres")
  if [ -z "$PG_ID" ]; then
    echo "  WARNING: PostgreSQL container not found."
    return
  fi
  read -rp "  Database name [app_db]: " db_name
  db_name="${db_name:-app_db}"
  read -rp "  Username [app_user]: " user_name
  user_name="${user_name:-app_user}"
  read -rsp "  Password [app_pass]: " user_pass
  user_pass="${user_pass:-app_pass}"
  echo ""

  docker exec -i "$PG_ID" psql -U "$PG_ROOT_USER" -c "CREATE DATABASE \"$db_name\";" 2>/dev/null &&
    echo "  Database '$db_name' created" || echo "  Database '$db_name' already exists"
  docker exec -i "$PG_ID" psql -U "$PG_ROOT_USER" -c "CREATE USER \"$user_name\" WITH PASSWORD '$user_pass';" 2>/dev/null &&
    echo "  User '$user_name' created" || echo "  User '$user_name' already exists"
  docker exec -i "$PG_ID" psql -U "$PG_ROOT_USER" -c "GRANT ALL PRIVILEGES ON DATABASE \"$db_name\" TO \"$user_name\";" &&
    echo "  Privileges granted"
  echo "  Done: user=$user_name / db=$db_name"
}

setup_mysql() {
  local db_name user_name user_pass
  echo ""
  echo "=== MySQL Setup ==="
  MYSQL_ID=$(get_container_id "mysql")
  if [ -z "$MYSQL_ID" ]; then
    echo "  WARNING: MySQL container not found."
    return
  fi
  read -rp "  Database name [app_db]: " db_name
  db_name="${db_name:-app_db}"
  read -rp "  Username [appuser]: " user_name
  user_name="${user_name:-appuser}"
  read -rsp "  Password [changeme_app]: " user_pass
  user_pass="${user_pass:-changeme_app}"
  echo ""

  docker exec -i "$MYSQL_ID" mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $db_name;" &&
    echo "  Database '$db_name' ready"
  docker exec -i "$MYSQL_ID" mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$user_name'@'%' IDENTIFIED BY '$user_pass';" &&
    echo "  User '$user_name' ready"
  docker exec -i "$MYSQL_ID" mysql -uroot -p"$MYSQL_ROOT_PASS" -e "GRANT ALL ON $db_name.* TO '$user_name'@'%'; FLUSH PRIVILEGES;" &&
    echo "  Privileges granted"
  echo "  Done: user=$user_name / db=$db_name"
}

setup_qdrant() {
  local col_name vec_size distance
  echo ""
  echo "=== Qdrant Setup ==="
  if ! curl -sf http://localhost:6333/healthz > /dev/null 2>&1; then
    echo "  WARNING: Qdrant not reachable at localhost:6333."
    return
  fi
  read -rp "  Collection name [app_collection]: " col_name
  col_name="${col_name:-app_collection}"
  read -rp "  Vector size [384]: " vec_size
  vec_size="${vec_size:-384}"
  read -rp "  Distance (Cosine/Euclidean/Dot) [Cosine]: " distance
  distance="${distance:-Cosine}"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "http://localhost:6333/collections/$col_name" \
    -H "Content-Type: application/json" \
    -d "{
      \"vectors\": {
        \"size\": $vec_size,
        \"distance\": \"$distance\"
      }
    }")
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "  Collection '$col_name' created"
  else
    echo "  Collection '$col_name' may already exist (HTTP $HTTP_STATUS)"
  fi
  echo "  Done: collection=$col_name (size=$vec_size, distance=$distance)"
}

shell_postgres() {
  echo ""
  echo "=== PostgreSQL Shell ==="
  PG_ID=$(get_container_id "postgres")
  if [ -z "$PG_ID" ]; then
    echo "  WARNING: PostgreSQL container not found."
    return
  fi
  echo "  Entering psql shell (type \q to exit)..."
  echo ""
  docker exec -it "$PG_ID" psql -U "$PG_ROOT_USER"
}

shell_mysql() {
  echo ""
  echo "=== MySQL Shell ==="
  MYSQL_ID=$(get_container_id "mysql")
  if [ -z "$MYSQL_ID" ]; then
    echo "  WARNING: MySQL container not found."
    return
  fi
  echo "  Entering mysql shell (type exit to quit)..."
  echo ""
  docker exec -it "$MYSQL_ID" mysql -uroot -p"$MYSQL_ROOT_PASS"
}

shell_qdrant() {
  echo ""
  echo "=== Qdrant Info ==="
  if ! curl -sf http://localhost:6333/healthz > /dev/null 2>&1; then
    echo "  WARNING: Qdrant not reachable at localhost:6333."
    return
  fi
  echo "  Qdrant is running."
  echo "  Collections:"
  curl -s http://localhost:6333/collections | python3 -m json.tool 2>/dev/null || curl -s http://localhost:6333/collections
  echo ""
  echo "  Dashboard: http://localhost:6333/dashboard"
}

menu() {
  echo ""
  echo "==================================="
  echo "  Database Setup - Select Option"
  echo "==================================="
  echo "  -- Setup --"
  echo "  1) PostgreSQL"
  echo "  2) MySQL"
  echo "  3) Qdrant"
  echo "  4) All databases"
  echo "  -- Shell --"
  echo "  5) Enter PostgreSQL shell (psql)"
  echo "  6) Enter MySQL shell (mysql)"
  echo "  7) Show Qdrant info"
  echo "  --"
  echo "  8) Exit"
  echo "==================================="
  read -rp "  Enter choice [1-8]: " choice
  echo ""

  case "$choice" in
    1) setup_postgres ;;
    2) setup_mysql ;;
    3) setup_qdrant ;;
    4) setup_postgres; setup_mysql; setup_qdrant ;;
    5) shell_postgres ;;
    6) shell_mysql ;;
    7) shell_qdrant ;;
    8) echo "  Exiting."; exit 0 ;;
    *) echo "  Invalid choice."; menu ;;
  esac

  echo ""
  read -rp "  Press Enter to return to menu..."
  menu
}

menu
