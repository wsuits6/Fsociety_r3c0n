#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Check dependencies
dependencies=(subfinder httpx ffuf nmap amass)
for cmd in "${dependencies[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[!] ERROR: $cmd is not installed. Please install it before running the script."
    exit 1
  fi
done

# Usage check
if [ $# -ne 1 ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

TARGET=$1
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./recon_output"
mkdir -p "$OUTPUT_DIR"

# Find latest file number to increment
latest_num=$(ls $OUTPUT_DIR/hsociety_*_"$TARGET".txt 2>/dev/null | \
  grep -oP 'hsociety_(\d+)_.*' | \
  grep -oP '\d+' | sort -n | tail -1 || echo 0)
next_num=$((latest_num + 1))

OUTPUT_FILE="$OUTPUT_DIR/hsociety_${next_num}_${DATE}_${TARGET}.txt"

echo "[*] Starting full recon for $TARGET"
echo "[*] Output file: $OUTPUT_FILE"

{
  echo "=== Recon for $TARGET - $DATE ==="
  echo ""

  echo "[+] Subdomain Enumeration with subfinder"
  subfinder -d "$TARGET" -silent || echo "[!] subfinder failed or no results"

  echo ""
  echo "[+] Additional Subdomain Enumeration with amass"
  amass enum -passive -d "$TARGET" -oA "$OUTPUT_DIR/amass_$TARGET" || echo "[!] amass failed or no results"

  echo ""
  echo "[+] Combining subdomains..."
  cat <(subfinder -d "$TARGET" -silent 2>/dev/null) "$OUTPUT_DIR/amass_$TARGET.txt" 2>/dev/null | sort -u > "$OUTPUT_DIR/all_subdomains_$TARGET.txt"

  echo ""
  echo "[+] HTTP probing with httpx"
  cat "$OUTPUT_DIR/all_subdomains_$TARGET.txt" 2>/dev/null | httpx -title -status-code -tech-detect -threads 50 -silent || echo "[!] httpx failed"

  echo ""
  echo "[+] Directory fuzzing with ffuf (top 1000 directories)"
  # Make sure you have a wordlist; adjust path as necessary
  ffuf -w /usr/share/wordlists/dirb/common.txt -u https://FUZZ."$TARGET" -mc 200,301,302 -t 40 -o "$OUTPUT_DIR/ffuf_$TARGET.json" -of json || echo "[!] ffuf failed"

  echo ""
  echo "[+] Nmap scan on discovered subdomains (ports 80,443)"
  while read -r domain; do
    echo "[*] Scanning $domain"
    nmap -p 80,443 --open "$domain" | grep -E "Nmap scan report|open" || echo "[!] nmap failed on $domain"
  done < "$OUTPUT_DIR/all_subdomains_$TARGET.txt"

  echo ""
  echo "=== Recon Complete for $TARGET ==="
} | tee "$OUTPUT_FILE"

echo "[*] Recon saved to $OUTPUT_FILE"
