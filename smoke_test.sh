#!/bin/bash
set -e

APP_URL="http://localhost:8000"
FAILED=0

echo "== 1. App liveness (/health) =="
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")
if [ "$HEALTH_STATUS" -eq 200 ]; then
  echo "ok (200)"
else
  echo "FAILED — got status $HEALTH_STATUS"
  FAILED=1
fi

echo "== 2. Backend reachable (ollama via app network) =="
BACKEND_CHECK=$(docker compose exec -T app python -c "
import httpx
try:
    r = httpx.get('http://ollama:11434', timeout=5.0)
    print(r.status_code)
except Exception as e:
    print('000')
")
if [ "$BACKEND_CHECK" = "200" ]; then
  echo "ok"
else
  echo "FAILED — backend returned $BACKEND_CHECK"
  FAILED=1
fi

echo "== 3. End-to-end inference =="
RESPONSE=$(curl -s "$APP_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "messages": [{"role": "user", "content": "Say hello."}]}')

if echo "$RESPONSE" | grep -q '"content"'; then
  echo "ok — model answered"
else
  echo "FAILED — no valid response from model"
  echo "Response was: $RESPONSE"
  FAILED=1
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "ALL CHECKS PASSED."
  exit 0
else
  echo "SOME CHECKS FAILED."
  exit 1
fi