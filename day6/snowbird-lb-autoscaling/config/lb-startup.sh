#!/bin/bash
# lb-vm startup: HAProxy with a round-robin pool of the web-group instances, health checks, a stats page,
# and a cron job that re-reads the group every minute so autoscaled instances join automatically.
apt-get update && apt-get install -y haproxy
cat > /etc/haproxy/haproxy.cfg <<'CFG'
global
    log /dev/log local0
defaults
    mode http
    timeout connect 5s
    timeout client 30s
    timeout server 30s
frontend web_in
    bind *:80
    default_backend web_pool
backend web_pool
    balance roundrobin
    option httpchk GET /
    default-server inter 3s fall 2 rise 2
listen stats
    bind *:8404
    stats enable
    stats uri /
CFG
curl -s -H 'Metadata-Flavor: Google' 'http://metadata.google.internal/computeMetadata/v1/instance/attributes/refresh-script' > /usr/local/bin/refresh-backends.sh
chmod +x /usr/local/bin/refresh-backends.sh
/usr/local/bin/refresh-backends.sh
systemctl enable --now haproxy
(crontab -l 2>/dev/null; echo '* * * * * /usr/local/bin/refresh-backends.sh') | crontab -
