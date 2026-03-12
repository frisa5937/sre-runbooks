#!/usr/bin/env bash
# backup_verify.sh
# 目的：今日のバックアップの存在確認（冪等性の確保）
# 使い方：./backup_verify.sh <バックアップ先>

set -euo pipefail

BACKUP_DIR="${1:?ERROR: バックアップディレクトリを指定してください}"
TODAY=$(date +"%Y%m%d")

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# 今日のバックアップが存在するか確認
if ls "${BACKUP_DIR}"/backup_"${TODAY}"* 1>/dev/null 2>&1; then
    log "INFO: 本日のバックアップは既に存在します。スキップします。"
    exit 0
fi

log "ERROR: 本日のバックアップが見つかりません"
exit 1