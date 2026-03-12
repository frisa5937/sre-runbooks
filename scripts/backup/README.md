# backup_params.sh

## なぜこのスクリプトを書いたか

現職でGUI手順で行っていたパラメータバックアップをCLI化することで
再現性を高めた経験を元に作成。
人間のミスを前提にした設計を意識している。

## 設計で意識したこと

- `set -euo pipefail`：エラーの見逃し防止
- タイムスタンプ付きバックアップ：世代管理と追跡可能性の確保
- ログ出力：実行履歴の可視化

## 使い方
```bash
chmod +x backup_params.sh
./backup_params.sh <バックアップ元> <バックアップ先>
```

## 実行例
```bash
./backup_params.sh ~/practice/backup/source ~/practice/backup/dest
```

## 対応するWBSタスク

Task 1-3：Linux・Bash強化