#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
repo_dir="${1:-$(dirname "$project_dir")/medical-config-repo}"

if [[ ! -e "$repo_dir" ]]; then
    mkdir -p "$repo_dir"
    git -C "$repo_dir" init -b main
fi
repo_dir="$(cd "$repo_dir" && pwd -P)"
if [[ "$(git -C "$repo_dir" rev-parse --show-toplevel)" != "$repo_dir" ]]; then
    echo "Thu muc phai la thu muc goc cua kho Git: $repo_dir" >&2
    exit 1
fi
if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "Kho Git dang co thay doi chua commit; hay luu chung truoc: $repo_dir" >&2
    exit 1
fi
if [[ "$(git -C "$repo_dir" symbolic-ref --short HEAD)" != main ]]; then
    echo "Hay chuyen kho cau hinh sang nhanh main truoc khi chay script." >&2
    exit 1
fi
cp "$project_dir/config-repo/patient-service.properties" "$repo_dir/patient-service.properties"
git -C "$repo_dir" add patient-service.properties
if ! git -C "$repo_dir" diff --cached --quiet -- patient-service.properties; then
    git -C "$repo_dir" commit -m "Move patient PostgreSQL configuration to Config Server" --only -- patient-service.properties
fi
echo "Kho cau hinh da san sang: $repo_dir"
