# Runbook: Near MissレポートをGitHubにpushする手順

作成日: 2026-03-10
作成者: 柳澤
対象リポジトリ: `ai-context`（`near-miss-reports/` ディレクトリ）

---

## 概要

Near Missレポート（Markdownファイル）をローカルで作成し、GitHubにpushするための手順書。
ミスなく効率的に作業できるよう、確認ポイントを含めて手順を記載している。

---

## 前提条件

- macOSのターミナルが使える状態であること
- VSCodeがインストール済みであること（`code --version` で確認）
- `~/Downloads/ai-context` にリポジトリがclone済みであること
- Personal Access Token（PAT）が有効であること

---

## ファイル命名規則

```
NM-YYYY-NNN_簡潔な説明.md
```

例：
```
NM-2026-001_ホームディレクトリのGitリポジトリ化とクレデンシャル露出.md
NM-2026-002_SQLクエリWHERE句欠落.md
```

- `NNN` は3桁の連番（001, 002, 003...）
- 説明部分は日本語可。スペースは使わず `_` で区切る

---

## 手順

### Step 1: 作業前の確認

#### 1-1. リポジトリの場所を確認する

```bash
cd ~/Downloads/ai-context
pwd
```

✅ `/Users/（ユーザー名）/Downloads/ai-context` と表示されることを確認する。
表示されない場合は作業を中断し、正しいディレクトリに移動する。

#### 1-2. リモートの最新状態を取り込む

```bash
git pull origin main
```

✅ `Already up to date.` または変更ファイルの一覧が表示されることを確認する。
コンフリクトが発生した場合は作業を中断する。

#### 1-3. 現在の状態を確認する

```bash
git status
```

✅ `nothing to commit, working tree clean` と表示されることを確認する。
未コミットの変更がある場合は内容を確認してから進む。

---

### Step 2: Markdownファイルを作成する

#### 2-1. VSCodeでリポジトリを開く

```bash
code .
```

#### 2-2. ファイルを作成する

1. 左のファイルツリーで `near-miss-reports` フォルダを右クリック
2. **New File** を選択
3. ファイル名を命名規則に従って入力する（例：`NM-2026-002_説明.md`）
4. `../templates/near_miss_template.md` の内容をコピー＆ペーストして記入する

#### 2-3. 内容を確認する（プレビュー）

`Cmd + Shift + V` でMarkdownプレビューを開き、以下を確認する。

- [ ] 報告書IDと日付が正しいか
- [ ] タイムラインが時系列順になっているか
- [ ] 根本原因分析（なぜなぜ分析）が完了しているか
- [ ] アクションアイテムが具体的か
- [ ] 企業名・システム名・個人名が匿名化されているか
- [ ] **クレデンシャル（PAT・パスワード・秘密鍵）が含まれていないか** ← 最重要

#### 2-4. ファイルを保存する

`Cmd + S`

---

### Step 3: GitHubにpushする

#### 3-1. 変更内容を確認する

```bash
git status
```

✅ `near-miss-reports/NM-2026-NNN_...md` が `Untracked files` に表示されることを確認する。

```bash
git diff
```

✅ 追加したファイルの内容を最終確認する。`q` キーで終了。

#### 3-2. ステージングする

```bash
git add near-miss-reports/
```

#### 3-3. ステージング内容を確認する

```bash
git status
```

✅ 対象ファイルが `Changes to be committed` に表示されることを確認する。
**意図しないファイルが含まれていないかを必ず確認する。**

#### 3-4. コミットする

```bash
git commit -m "docs: Near Missレポート NM-2026-NNN を追加"
```

メッセージの `NNN` は実際の番号に置き換える。

#### 3-5. pushする

```bash
git push origin main
```

✅ 以下のような出力が表示されることを確認する。

```
Writing objects: 100% ...
main -> main
```

---

### Step 4: GitHubで最終確認する

ブラウザで以下のURLを開く。

```
https://github.com/frisa5937/ai-context/tree/main/near-miss-reports
```

✅ 追加したファイルが表示されることを確認する。
✅ ファイルをクリックし、内容が正しく表示されることを確認する。

---

## トラブルシューティング

### `! [rejected] main -> main` が表示された場合

リモートに自分が持っていない変更がある。以下を実行する。

```bash
git pull --rebase origin main
git push origin main
```

### `remote: Invalid username or token` が表示された場合

PATの期限切れまたは無効化されている。GitHub上でPATを再発行し、以下を実行する。

```bash
git remote set-url origin https://（新しいPAT）@github.com/frisa5937/ai-context.git
git push origin main
```

⚠️ PATはチャット・メール・ドキュメントに貼り付けない。漏洩した場合は即座に無効化・再発行する。

### `CONFLICT` が表示された場合

自分では解決せず、内容を確認してから対処方法を調べる。
急いでいる場合は以下でrebaseを中断して元の状態に戻す。

```bash
git rebase --abort
```

---

## 注意事項

| 項目 | 内容 |
|------|------|
| 作業ディレクトリ | コマンド実行前は必ず `pwd` で確認する |
| クレデンシャル | PAT・パスワード・秘密鍵をファイルに含めない |
| push前の確認 | `git status` と `git diff` で意図しない変更が含まれていないか確認する |
| PATの管理 | 漏洩した場合は手間を惜しまず即座に無効化・再発行する |
| ファイル命名 | 命名規則に従う。スペースは使わない |