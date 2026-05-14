# Runbook: GKEでPrometheusを構築する手順

作成日: 2026-04-26
対象: GKEクラスター上へのPrometheusデプロイ

---

## 概要

GKE（Google Kubernetes Engine）上にPrometheusをデプロイする手順。
Cloud Runはコールドスタートによりスクレイピングが止まるため、
常時稼働が必要なPrometheusにはGKEを使用する。

---

## 前提条件

- gcloud CLIがインストール済みであること
- gcloud auth loginでログイン済みであること
- Docker Desktopが起動していること
- gke-gcloud-auth-pluginがインストール済みであること

---

## デプロイ前チェックリスト（必ず確認すること）

```bash
# 1. Artifact Registryのリポジトリが存在するか確認
gcloud artifacts repositories list --location=asia-northeast1

# 2. イメージがpush済みか確認
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/$(gcloud config get project)/sre-practice-repo
```

✅ リポジトリとイメージが存在することを確認してから次に進む。
存在しない場合はStep 2からイメージを作成する。

---

## Step 1: 必要なAPIを有効化する

```bash
# GKEのAPIを有効化
gcloud services enable container.googleapis.com

# Artifact RegistryのAPIを有効化（未実施の場合）
gcloud services enable artifactregistry.googleapis.com
```

---

## Step 2: Artifact Registryにイメージをpushする

### 2-1. リポジトリを作成する

```bash
gcloud artifacts repositories create sre-practice-repo \
  --repository-format=docker \
  --location=asia-northeast1
```

### 2-2. Docker認証を設定する

```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

### Docker認証について
gcloud auth configure-docker は一度設定すれば ~/.docker/config.json に
永続化されるため、2回目以降は「already registered correctly」と表示される。
新しいリポジトリを作成しても再設定不要。
 
### Docker認証が必要なケース
以下の場合は gcloud auth configure-docker を再実行する：
・別の端末で作業する場合
・~/.docker/config.json を削除した場合
・Docker Desktopを再インストールした場合

### 2-3. イメージをビルドしてpushする

```bash
cd ~/practice/prometheus

# M1 Macの場合は --platform linux/amd64 が必須
docker buildx build \
  --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/$(gcloud config get project)/sre-practice-repo/prometheus:latest \
  --push \
  .
```

⚠️ `--platform linux/amd64` を忘れるとCloud Run・GKEでエラーになる。

---

## Step 3: GKEクラスターを作成する

```bash
gcloud container clusters create sre-practice-cluster \
  --zone asia-northeast1-a \
  --num-nodes 1 \
  --machine-type e2-small
```

⏱️ 3〜5分かかる。完了まで待つ。

---

## Step 4: kubectlの認証を設定する

```bash
gcloud container clusters get-credentials sre-practice-cluster \
  --zone asia-northeast1-a
```

ノードの状態を確認する。

```bash
kubectl get nodes
```

✅ STATUS が Ready になっていることを確認する。

---

## Step 5: Prometheusをデプロイする

### 5-1. prometheus-deployment.yamlを作成する

```bash
cd ~/practice/prometheus
code prometheus-deployment.yaml
```

以下の内容を貼り付けて保存する。
`<PROJECT_ID>` は実際のプロジェクトIDに置き換える。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: asia-northeast1-docker.pkg.dev/<PROJECT_ID>/sre-practice-repo/prometheus:latest
        ports:
        - containerPort: 9090
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
```

### 2回目以降の注意事項
prometheus-deployment.yaml は初回作成後に保存済みのため
2回目以降は新規作成不要。
ただし以下を必ず確認する：
 
```bash
cat ~/practice/prometheus/prometheus-deployment.yaml
```
 
プロジェクトIDが現在のプロジェクトと一致しているか確認する。
異なる場合はYAML内のPROJECT_IDを修正してから進む。

### 5-2. デプロイする

```bash
kubectl apply -f prometheus-deployment.yaml
```

Podの状態を確認する。

```bash
kubectl get pods
```

✅ STATUS が Running になっていることを確認する。
❌ ErrImagePull が出た場合はStep 2からやり直す。

外部IPを確認する。

```bash
kubectl get services
```

✅ EXTERNAL-IP に IPアドレスが表示されることを確認する（pendingの場合は待つ）。

---

## Step 6: ファイアウォールを設定する

**重要：先にノードの実際のタグを確認してから設定する**

```bash
# ノード名を確認する
kubectl get nodes

# ノードのタグを確認する（ハッシュ値が含まれるため必ず確認する）
gcloud compute instances describe <ノード名> \
  --zone asia-northeast1-a \
  --format="get(tags.items)"
```

確認したタグを使ってファイアウォールルールを作成する。

```bash
gcloud compute firewall-rules create allow-prometheus \
  --allow tcp:9090 \
  --target-tags=<確認したタグ> \
  --description="Allow Prometheus access"
```

---

## Step 7: 動作確認する

ブラウザで以下のURLにアクセスする。

```
http://<EXTERNAL-IP>:9090
```

Prometheusの画面が表示されたら以下のクエリで動作確認する。

```
up
```

✅ `1` が返ってくれば正常。

## Step 8: Grafanaをデプロイする
 
### 8-1. grafana-deployment.yamlを作成する
 
```bash
code ~/practice/prometheus/grafana-deployment.yaml
```
 
以下の内容を貼り付けて保存する。
 
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    targetPort: 3000
  selector:
    app: grafana
```
 
### 8-2. デプロイする
 
```bash
kubectl apply -f ~/practice/prometheus/grafana-deployment.yaml
```
 
### 8-3. 外部IPを確認する
 
```bash
kubectl get services
```
 
✅ GrafanaのEXTERNAL-IPが表示されることを確認する。
 
### 8-4. ファイアウォールルールに3000番ポートを追加する
 
```bash
gcloud compute firewall-rules update allow-prometheus \
  --allow tcp:9090,tcp:3000
```
 
### 8-5. ブラウザでアクセスする
 
```
http://<EXTERNAL-IP>:3000
```
 
⚠️ ポート番号は3000。9090ではないので注意。
 
初期ログイン情報：
・ユーザー名：admin
・パスワード：admin
 
### 8-6. PrometheusをData Sourceとして追加する
 
```
左メニュー → Connections → Data Sources
→ Add data source → Prometheus
→ URL: http://prometheus:9090
→ Save & Test
```
 
✅ 「Data source is working」と表示されることを確認する。
 
⚠️ URLはEXTERNAL-IPではなくKubernetesのService名（prometheus）を使う。
  同じクラスター内のServiceにはService名でアクセスできる。
 
### 8-7. ダッシュボードを作成する
 
```
左メニュー → Dashboards → New Dashboard
→ Add visualization → Prometheusを選択
→ クエリを入力（例：up）
→ Apply → Save dashboard
```
 
推奨クエリ（4大シグナル）：
・up（監視対象の稼働状態）
・prometheus_tsdb_head_samples_appended_total（収集サンプル数）
・scrape_duration_seconds（スクレイピング時間）
```

---

## 削除手順（作業後は必ず実施する）

```bash
# Kubernetesリソースの削除
kubectl delete -f prometheus-deployment.yaml
kubectl delete -f ~/practice/prometheus/grafana-deployment.yaml

# ファイアウォールルールの削除
gcloud compute firewall-rules delete allow-prometheus --quiet

# GKEクラスターの削除（3〜5分かかる）
gcloud container clusters delete sre-practice-cluster \
  --zone asia-northeast1-a

# Artifact Registryのリポジトリを削除
gcloud artifacts repositories delete sre-practice-repo \
  --location asia-northeast1
```

### 重要：ファイアウォールルールはクラスター削除時に自動削除されない
 
クラスターを削除してもファイアウォールルールは残存する。
次回同じクラスター名で作成した場合、意図せず前回のルールが適用される
可能性があるため、必ず明示的に削除すること。
 
```bash
gcloud compute firewall-rules delete allow-prometheus --quiet
```

---

## トラブルシューティング

### ErrImagePull が出た場合

原因：Artifact Registryにイメージが存在しない

対処：
```bash
# イメージの存在を確認する
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/$(gcloud config get project)/sre-practice-repo

# 存在しない場合はStep 2からやり直す
# イメージを再作成後にPodを再起動する
kubectl rollout restart deployment prometheus
```

### ブラウザでアクセスできない場合

原因1：ファイアウォールのタグが不一致

対処：
```bash
# 既存のファイアウォールルールを削除する
gcloud compute firewall-rules delete allow-prometheus --quiet

# ノードの実際のタグを確認してから再作成する
gcloud compute instances describe <ノード名> \
  --zone asia-northeast1-a \
  --format="get(tags.items)"
```

原因2：外部IPがまだpendingの状態

対処：数分待ってから再度確認する。
```bash
kubectl get services
```

### ファイアウォールルールが既に存在する場合
 
症状：
```
ERROR: The resource 'projects/.../global/firewalls/allow-prometheus' already exists
```
 
対処：
```bash
# 既存ルールの内容を確認する
gcloud compute firewall-rules describe allow-prometheus --format=json
 
# targetTagsが今回のノードと一致していれば再作成不要
# 一致していない場合は削除して再作成する
gcloud compute firewall-rules delete allow-prometheus --quiet
```
 
注意：targetTagsが空の場合、ネットワーク内の全インスタンスに適用される。
学習環境では許容するが、本番環境では必ずtargetTagsを指定すること。