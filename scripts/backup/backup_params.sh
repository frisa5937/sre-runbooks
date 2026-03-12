#!/usr/bin/env bash
# backup_params.sh
# 目的：設定ファイルをタイムスタンプ付きでバックアップする
# 使い方：./backup_params.sh <バックアップ元> <バックアップ先>

set -euo pipefail

SOURCE_DIR="${1:?ERROR: バックアップ元を指定してください}"
BACKUP_DIR="${2:?ERROR: バックアップ先を指定してください}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "バックアップ開始: ${SOURCE_DIR} → ${BACKUP_PATH}"
mkdir -p "${BACKUP_PATH}"
cp -r "${SOURCE_DIR}/." "${BACKUP_PATH}/"
log "バックアップ完了: ${BACKUP_PATH}"