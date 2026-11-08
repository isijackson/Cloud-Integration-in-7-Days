#!/bin/bash
# Every web VM: NGINX serves the store page and a static file, and proxies /buy to a small Python
# "checkout" service that does real CPU work per request (price calculation + hashing), so a load test
# raises CPU and the autoscaler has something to react to.
apt-get update && apt-get install -y nginx python3
cat > /opt/checkout.py <<'PY'
import hashlib, http.server, socketserver, socket, json, random
HOST = socket.gethostname()
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # simulate pricing: 12k iterations of hashing per request (about 5 ms on an e2-small vCPU)
        h = b"snowbird"
        for i in range(12000): h = hashlib.sha256(h + str(i).encode()).digest()
        body = json.dumps({"server": HOST, "pass": "adult-season", "price": 1299 + (h[0] % 50), "receipt": h.hex()[:12]}).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
class S(socketserver.ThreadingMixIn, http.server.HTTPServer): daemon_threads = True
S(("127.0.0.1", 8080), H).serve_forever()
PY
cat > /etc/systemd/system/checkout.service <<'UNIT'
[Unit]
Description=Snowbird checkout service
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/checkout.py
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now checkout
echo "<h1>Snowbird Pass Sales</h1><p>served by $(hostname)</p>" > /var/www/html/index.html
echo ok > /var/www/html/static.txt
cat > /etc/nginx/sites-available/default <<'NG'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    location / { try_files $uri $uri/ =404; }
    # static.txt is cacheable for an hour: Cloudflare and Cloud CDN both honour this header (the HTML page has none, so it stays dynamic)
    location = /static.txt { add_header Cache-Control "public, max-age=3600"; }
    location /buy { proxy_pass http://127.0.0.1:8080; }
}
NG
systemctl enable --now nginx && systemctl restart nginx
