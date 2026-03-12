#!/usr/bin/env bash
# backup_params.sh
# 目的：設定ファイルをタイムスタンプ付きでバックアップする
# 使い方：./backup_params.sh <バックアップ元> <バックアップ先>

set -euo pipefail

SOURCE_DIR="${1:?ERROR: バックアップ元を指定してください}"
BACKUP_DIR="${2:?ERROR: バックアップ先を指定してください}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/backup.log"
KEEP_GENERATIONS=7

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"; }

# 終了時に必ず実行される処理
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log "ERROR: バックアップが失敗しました（終了コード: ${exit_code}）"
    fi
}
trap cleanup EXIT

# バックアップ元の存在確認
if [[ ! -d "${SOURCE_DIR}" ]]; then
    log "ERROR: バックアップ元が存在しません: ${SOURCE_DIR}"
    exit 1
fi

log "バックアップ開始: ${SOURCE_DIR} → ${BACKUP_PATH}"
mkdir -p "${BACKUP_PATH}"
cp -r "${SOURCE_DIR}/." "${BACKUP_PATH}/"

# 世代管理：古いバックアップを削除
log "古いバックアップを削除（${KEEP_GENERATIONS}世代を保持）"
ls -dt "${BACKUP_DIR}"/backup_* | tail -n +$((KEEP_GENERATIONS + 1)) | xargs -r rm -rf

log "バックアップ完了: ${BACKUP_PATH}"