# EC2でDockerを動かすRunbook

## 目的
AWS EC2上にDockerをインストールし動作確認を行う。
作業完了後は必ずインスタンスを削除して費用を最小化する。

## 前提条件
- AWS CLIがインストール済みであること
- IAMユーザー（EC2FullAccess権限）のアクセスキーが設定済みであること
- `~/.ssh/` ディレクトリが存在すること

## 注意事項
- 作業前に必ずリージョンを確認すること（東京：ap-northeast-1）
- 作業完了後は必ずインスタンスを削除すること
- アクセスキー・シークレットキーは絶対にGitにコミットしないこと
- キーペア・セキュリティグループが既に存在する場合はStep1・Step2は不要

---

## 手順

### Step1：キーペアの作成
```bash
mkdir -p ~/.ssh
aws ec2 create-key-pair \
  --key-name sre-practice-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/sre-practice-key.pem

chmod 600 ~/.ssh/sre-practice-key.pem
```

### Step2：セキュリティグループの確認・作成

既存のセキュリティグループを確認する。
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sre-practice-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text
```

`GroupId` が表示された場合は既存のものを再利用する。次のコマンドはスキップしてStep3へ進む。
表示されない場合は以下のコマンドで新規作成する。


この確認コマンドを最初に実行することで、既存のGroupIdを取得できます。再利用か新規作成かをその場で判断できます。

セキュリティグループの作成
```bash
aws ec2 create-security-group \
  --group-name sre-practice-sg \
  --description "SRE practice security group"
```

表示された `GroupId` をメモする。

SSH接続を許可する。
```bash
aws ec2 authorize-security-group-ingress \
  --group-id  \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

### Step3：AMI IDの取得
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-kernel-*-arm64" \
  "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text
```

表示された `AMI ID` をメモする。

### Step4：EC2インスタンスの起動
```bash
aws ec2 run-instances \
  --image-id  \
  --instance-type t4g.micro \
  --key-name sre-practice-key \
  --security-group-ids  \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sre-practice}]'
```

表示された `InstanceId` をメモする。

### Step5：インスタンスの起動待ち
```bash
aws ec2 wait instance-running \
  --instance-ids 
```

### Step6：パブリックIPアドレスの取得
```bash
aws ec2 describe-instances \
  --instance-ids  \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Step7：SSH接続
```bash
ssh -i ~/.ssh/sre-practice-key.pem ec2-user@
```

### Step8：Dockerのインストール
```bash
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

SSH接続を切って再接続する。
```bash
exit
ssh -i ~/.ssh/sre-practice-key.pem ec2-user@
```

### Step9：動作確認
```bash
docker --version
docker run --rm hello-world
```

### Step10：SSH接続を切る
```bash
exit
```

### Step11：インスタンスの停止・削除（必須）
```bash
aws ec2 terminate-instances --instance-ids 
```

削除確認。
```bash
aws ec2 describe-instances \
  --instance-ids  \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

`terminated` と表示されれば完了。

---

## トラブルシューティング

### コンソールにインスタンスが表示されない
リージョンが正しいか確認する。東京リージョン（ap-northeast-1）を選択する。

### SSH接続できない
セキュリティグループのインバウンドルールで22番ポートが許可されているか確認する。

---

## 対応するWBSタスク
Task 1-4：Docker基礎
```