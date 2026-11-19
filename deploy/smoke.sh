#!/bin/sh
# Confere um nó subido pelo Compose. Uso: deploy/smoke.sh [domínio]
set -eu

domain="${1:-localhost}"
base="https://$domain"
failures=0

check() {
	if [ "$2" = "$3" ]; then
		echo "ok    $1"
	else
		echo "FALHA $1: esperado '$3', veio '$2'"
		failures=$((failures + 1))
	fi
}

status() {
	curl -sk -o /dev/null -w '%{http_code}' --max-time 5 "$@"
}

header() {
	curl -sk -D - -o /dev/null --max-time 5 "$base$2" | tr -d '\r' | sed -n "s/^$1: //Ip"
}

upgrade() {
	status --http1.1 \
		-H 'Connection: Upgrade' -H 'Upgrade: websocket' \
		-H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
		-H "Origin: $1" "$base/api/ws"
}

for _ in $(seq 30); do
	[ "$(status "$base/")" = 200 ] && break
	sleep 1
done

check "página inicial" "$(status "$base/")" 200
check "rota da SPA" "$(status "$base/canal/qualquer")" 200
check "HTTP redireciona para HTTPS" "$(status "http://$domain/")" 308
check "WebSocket com a origem do nó" "$(upgrade "$base")" 101
check "WebSocket com outra origem" "$(upgrade "https://outra.example")" 400
check "HSTS" "$(header Strict-Transport-Security /)" "max-age=31536000; includeSubDomains"
check "frame-ancestors no CSP" "$(header Content-Security-Policy / | grep -o "frame-ancestors 'none'")" "frame-ancestors 'none'"
check "index.html sem cache" "$(header Cache-Control /)" "no-cache"

[ "$failures" -eq 0 ]
