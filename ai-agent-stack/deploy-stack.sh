#!/usr/bin/env bash
set -euo pipefail

# Folder tempat file compose disimpan (default: folder tempat script ini berada)
DIR="${1:-$(dirname "$(readlink -f "$0")")}"

SWARM_STATE="$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)"
if [ "$SWARM_STATE" != "active" ]; then
  echo "Node ini belum swarm mode. Jalankan: docker swarm init"
  exit 1
fi

# Kumpulkan semua file *.yml / *.yaml di folder
mapfile -t FILES < <(find "$DIR" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | sort)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "Tidak ada file .yml/.yaml di: $DIR"
  exit 1
fi

echo "Pilih compose file yang mau di-deploy di: $DIR"
echo
select FILE in "${FILES[@]}" "Batal"; do
  if [ "$REPLY" -eq $(( ${#FILES[@]} + 1 )) ] 2>/dev/null; then
    echo "Dibatalkan."
    exit 0
  fi
  if [ -n "${FILE:-}" ]; then
    break
  fi
  echo "Pilihan tidak valid, coba lagi."
done

# Load .env di folder yang sama kalau ada (untuk secrets/env compose)
ENV_FILE="$DIR/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  echo "Env dimuat dari: $ENV_FILE"
fi

# Nama stack: default dari nama file (tanpa ekstensi), atau override lewat argumen ke-2
DEFAULT_STACK="$(basename "$FILE")"
DEFAULT_STACK="${DEFAULT_STACK%.*}"
read -rp "Nama stack [$DEFAULT_STACK]: " STACK_NAME
STACK_NAME="${STACK_NAME:-$DEFAULT_STACK}"

echo
echo "Deploy '$FILE' sebagai stack '$STACK_NAME' ..."
docker stack deploy -c "$FILE" "$STACK_NAME"

echo
echo "Selesai. Cek status dengan:"
echo "  docker stack services $STACK_NAME"
echo "  docker stack ps $STACK_NAME"
