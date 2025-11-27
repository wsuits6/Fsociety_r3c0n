# HSociety Recon Script

A lightweight reconnaissance automation script designed for **authorized security assessments** and **bug bounty workflows**.  
It chains together well‑known OSINT and scanning tools to streamline subdomain discovery, HTTP probing, directory fuzzing, and basic port scanning.

---

## Features

- Subdomain enumeration using **subfinder** and **amass**
- Combined subdomain list output
- HTTP probing with **httpx** (titles, status codes, tech detection)
- Directory fuzzing using **ffuf**
- Basic Nmap scanning on ports **80** and **443**
- Output automatically stored and versioned inside `./recon_output/`

---

## Requirements

Make sure the following tools are installed and available in your system PATH:

- `subfinder`
- `amass`
- `httpx`
- `ffuf`
- `nmap`

The script checks for these before running.

---

## Usage

```bash
./recon.sh <domain>
