#!/bin/bash
set -eux

# Update and install prerequisites
apt-get update
apt-get install -y curl gnupg apt-transport-https software-properties-common

# -----------------------------
# Install ClickHouse
# -----------------------------
apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
echo "deb https://packages.clickhouse.com/deb stable main" > /etc/apt/sources.list.d/clickhouse.list
apt-get update
apt-get install -y clickhouse-server clickhouse-client

# Enable and start ClickHouse
systemctl enable clickhouse-server
systemctl start clickhouse-server

# -----------------------------
# Install Fluent Bit
# -----------------------------
curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor -o /usr/share/keyrings/fluentbit.gpg
echo "deb [signed-by=/usr/share/keyrings/fluentbit.gpg] https://packages.fluentbit.io/ubuntu/jammy jammy main" > /etc/apt/sources.list.d/fluentbit.list
apt-get update
apt-get install -y td-agent-bit

# Fluent Bit basic config (syslog input → ClickHouse output)
cat <<EOF > /etc/td-agent-bit/td-agent-bit.conf
[SERVICE]
    Flush        5
    Log_Level    info

[INPUT]
    Name         syslog
    Listen       0.0.0.0
    Port         514
    Mode         udp
    Tag          syslog.udp

[INPUT]
    Name         syslog
    Listen       0.0.0.0
    Port         514
    Mode         tcp
    Tag          syslog.tcp

[OUTPUT]
    Name         stdout
    Match        *

# ClickHouse output can be configured later
EOF

systemctl enable td-agent-bit
systemctl restart td-agent-bit

# -----------------------------
# Install Grafana
# -----------------------------
mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana

systemctl enable grafana-server
systemctl start grafana-server