#!/bin/bash
# Regenerate HAProxy's backend list from the managed instance group every
# minute (run by cron on lb-vm). cron runs with PATH=/usr/bin:/bin, where
# haproxy (/usr/sbin) is not found; set the PATH first.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
IPS=$(gcloud compute instances list --filter='name~^web-group' \
  --format='value(networkInterfaces[0].networkIP)' 2>/dev/null)
[ -z "$IPS" ] && exit 0
{
  sed '/^backend web_pool/,$d' /etc/haproxy/haproxy.cfg
  echo 'backend web_pool'; echo '    balance roundrobin'
  echo '    option httpchk GET /'; echo '    http-check expect string Snowbird'
  echo '    default-server inter 3s fall 2 rise 2'
  i=1
  for ip in $IPS; do echo "    server web$i $ip:80 check"; i=$((i+1)); done
  echo 'listen stats'; echo '    bind *:8404'
  echo '    stats enable'; echo '    stats uri /'
} > /tmp/haproxy.cfg && haproxy -c -f /tmp/haproxy.cfg >/dev/null &&
  ! cmp -s /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg &&
  cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg && systemctl reload haproxy
