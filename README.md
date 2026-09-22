# AWS Terraform 高可用Web基盤ハンズオン

Terraformを使用して、AWS上に2つのAvailability Zoneを利用した高可用Web基盤を構築し、負荷分散・監視・障害復旧・RDS Multi-AZフェイルオーバーを検証したハンズオンです。

## 構成概要

- Region: ap-northeast-1
- Availability Zone
  - ap-northeast-1a
  - ap-northeast-1c
- VPC: 10.0.0.0/16
- Application Load Balancer
- EC2 × 2
- NAT Gateway × 2
- RDS PostgreSQL Multi-AZ
- AWS Systems Manager Session Manager
- Amazon CloudWatch
- AWS Secrets Manager
- Terraform

## アーキテクチャ

                         Internet
                            |
                            v
                    Application Load
                       Balancer
                    /             \
                   /               \
          Public Subnet         Public Subnet
          ap-northeast-1a       ap-northeast-1c
          10.0.1.0/24           10.0.2.0/24
               |                     |
          NAT Gateway           NAT Gateway
               |                     |
               v                     v
          App Subnet             App Subnet
          10.0.11.0/24          10.0.12.0/24
               |                     |
             EC2                   EC2
           web-1a                web-1c
               \                   /
                \                 /
                 v               v
                    RDS PostgreSQL
                       Multi-AZ
                  /               \
        DB Subnet                 DB Subnet
        10.0.21.0/24              10.0.22.0/24
        ap-northeast-1a           ap-northeast-1c

## ネットワーク設計

| 用途 | AZ | CIDR |
|---|---|---|
| Public Subnet | ap-northeast-1a | 10.0.1.0/24 |
| Public Subnet | ap-northeast-1c | 10.0.2.0/24 |
| App Subnet | ap-northeast-1a | 10.0.11.0/24 |
| App Subnet | ap-northeast-1c | 10.0.12.0/24 |
| DB Subnet | ap-northeast-1a | 10.0.21.0/24 |
| DB Subnet | ap-northeast-1c | 10.0.22.0/24 |

Public SubnetはInternet Gatewayへルーティングしています。

App SubnetはAZごとに同一AZのNAT Gatewayを利用し、Private Subnet内のEC2から外部への通信を可能にしています。

DB SubnetにはInternet向けのデフォルトルートを設定していません。

## セキュリティ設計

Security Group間参照を利用し、必要な通信のみ許可しています。

    Internet
       |
       | HTTP/80
       v
    ALB Security Group
       |
       | HTTP/80
       v
    EC2 Security Group
       |
       | PostgreSQL/5432
       v
    RDS Security Group

EC2にはPublic IPを付与せず、SSHポートも開放していません。

管理接続にはAWS Systems Manager Session Managerを使用します。

RDSはPublic Accessを無効化し、EC2のSecurity GroupからのTCP/5432のみ許可しています。

RDSのマスターパスワードはTerraformコードへ直接記載せず、AWS Secrets Managerによる管理を使用しています。

## Terraformで構築した主なリソース

- VPC
- Internet Gateway
- Public Subnet × 2
- Private App Subnet × 2
- Private DB Subnet × 2
- Elastic IP × 2
- NAT Gateway × 2
- Route Table
- Application Load Balancer
- Target Group
- HTTP Listener
- EC2 × 2
- IAM Role / Instance Profile
- Security Group
- RDS PostgreSQL Multi-AZ
- DB Subnet Group
- CloudWatch Alarm

## Webサーバー

Amazon Linux 2023を使用し、EC2起動時のuser_dataでApacheをインストールしています。

各EC2のWebページにはサーバー名とAvailability Zoneを表示し、ALBによる振り分け先を確認できるようにしました。

    web-1a
    ap-northeast-1a

    web-1c
    ap-northeast-1c

## Terraformによる構築

TerraformでAWSリソースを構築しました。

    Apply complete! Resources: 40 added, 0 changed, 0 destroyed.

構築・検証後に再度 terraform plan を実行し、TerraformコードとAWS上のリソースに差分がないことを確認しました。

    No changes. Your infrastructure matches the configuration.

## ALB負荷分散

Target GroupでEC2 2台がhealthyになることを確認しました。

    web-1a : healthy
    web-1c : healthy

ALBへ複数回HTTPアクセスを行い、ap-northeast-1aとap-northeast-1cのEC2へリクエストが分散されることを確認しました。

## Systems Manager Session Manager

Private Subnet内のEC2へAWS Systems Manager Session Managerを使用して接続しました。

2台ともSSM Managed InstanceとしてOnlineであることを確認しています。

    PingStatus : Online
    Platform   : Amazon Linux

これにより、SSHポートをインターネットへ公開せずにPrivate EC2を管理できる構成としています。

## EC2からRDSへの疎通

Private EC2からRDS PostgreSQLのTCP/5432へ疎通確認を実施しました。

    timeout 5 bash -c "</dev/tcp/$RDS_HOST/5432"
    echo $?

    0

RDSエンドポイントがVPC内のPrivate IPへ名前解決されることも確認しました。

## Webサーバー障害試験

web-1aのApacheを意図的に停止し、ALBのヘルスチェックと片系障害時のサービス継続を確認しました。

### 障害発生時

Target Groupの状態：

    web-1a : unhealthy
    web-1c : healthy

ALBへ10回HTTPアクセスした結果、すべて正常なweb-1cへ転送されました。

    10 web-1c

これにより、web-1aのApache停止時も正常系EC2によってWebアクセスを継続できることを確認しました。

### 復旧後

web-1aのApacheを起動し、再び2台ともhealthyになることを確認しました。

    web-1a : healthy
    web-1c : healthy

復旧後にALBへ10回アクセスした結果：

    5 web-1a
    5 web-1c

復旧したEC2が再びTarget Groupへ組み込まれ、2台へ負荷分散されることを確認しました。

## CloudWatch障害検知

ALBのUnHealthyHostCountをCloudWatch Alarmで監視しています。

Webサーバー障害試験では、以下の状態遷移を確認しました。

    INSUFFICIENT_DATA
            |
            v
           OK
            |
            v
         ALARM
            |
            v
           OK

実際のAlarm Historyでは以下を確認しました。

    Alarm updated from OK to ALARM
    Alarm updated from ALARM to OK

Apache停止によるTarget障害をCloudWatchが検知し、復旧後にAlarmがOKへ戻ることを確認しました。

## RDS Multi-AZ構成

RDS PostgreSQLをMulti-AZ構成で構築しています。

フェイルオーバー前：

    Primary   : ap-northeast-1c
    Secondary : ap-northeast-1a
    MultiAZ   : True
    Status    : available

## RDS Multi-AZフェイルオーバー試験

AWS CLIからRDSの強制フェイルオーバーを実施しました。

    aws rds reboot-db-instance \
      --db-instance-identifier ha-web-postgres \
      --force-failover

RDS Eventで以下のイベントを確認しました。

    Multi-AZ instance failover started.
    Multi-AZ instance failover completed
    The user requested a failover of the DB instance.

フェイルオーバー後：

    Primary   : ap-northeast-1a
    Secondary : ap-northeast-1c
    MultiAZ   : True
    Status    : available

これにより、Primaryがap-northeast-1cからap-northeast-1aへ切り替わったことを確認しました。

## RDSエンドポイントの切り替え確認

RDSのエンドポイント名はフェイルオーバー前後で変更されませんでした。

一方、名前解決先のPrivate IPは以下のように変更されました。

    Before : 10.0.22.88
    After  : 10.0.21.115

ネットワーク設計上、

    10.0.22.0/24 = ap-northeast-1c
    10.0.21.0/24 = ap-northeast-1a

であるため、同一RDSエンドポイントの接続先が別AZ側へ切り替わったことを確認しました。

フェイルオーバー完了後、EC2からRDSのTCP/5432へ再度疎通確認を行いました。

    echo $?
    0

これにより、フェイルオーバー完了後も同一RDSエンドポイントを利用して接続できることを確認しました。

※フェイルオーバー中の無停止接続を検証したものではなく、フェイルオーバー完了後の再接続を確認しています。

## CloudWatch Alarm

Terraformで以下のAlarmを作成しています。

- EC2 web-1a CPUUtilization
- EC2 web-1c CPUUtilization
- ALB UnHealthyHostCount

## Evidence

検証結果は evidence/ 配下に保存しています。

    evidence/
    ├── terraform-plan.txt
    ├── post-apply-state.txt
    ├── post-apply-plan.txt
    ├── final-terraform-plan.txt
    ├── ssm-status.txt
    ├── target-health.txt
    ├── alb-load-balancing.txt
    ├── web-1a-failure-target-health.txt
    ├── web-1a-failure-alb-test.txt
    ├── web-1a-recovery-target-health.txt
    ├── web-1a-recovery-alb-test.txt
    ├── cloudwatch-alarm-status.txt
    ├── cloudwatch-alarm-history.txt
    ├── rds-multiaz-before.txt
    ├── rds-multiaz-after.txt
    └── rds-failover-events.txt

## 学習・検証ポイント

- TerraformによるAWSリソースのコード化
- 2AZを利用した高可用構成
- Public / Private Subnetの役割分離
- AZごとのNAT Gateway構成
- ALBによる負荷分散
- Target Group Health Check
- Security Group間参照による通信制御
- Public IPを持たないEC2の運用
- Systems Manager Session Manager
- CloudWatchによる障害監視
- Webサーバー片系障害時のサービス継続
- RDS PostgreSQL Multi-AZ
- RDS Multi-AZフェイルオーバー
- RDSエンドポイントとDNS切り替え
- Terraformと実環境の差分確認

## 注意

本リポジトリはAWS学習・検証目的で作成しています。

NAT Gateway、Application Load Balancer、RDS Multi-AZなど料金が発生するリソースを含むため、検証終了後はTerraformでリソースを削除します。

    terraform destroy
