#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Colors for Mr. Robot style interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Banner
show_banner() {
  clear
  echo -e "${RED}"
  cat << "EOF"
    ____                      ______            __
   / __ \___  _________  ____/_  __/___  ____  / /
  / /_/ / _ \/ ___/ __ \/ __ \/ / / __ \/ __ \/ / 
 / _, _/  __/ /__/ /_/ / / / / / / /_/ / /_/ / /  
/_/ |_|\___/\___/\____/_/ /_/_/  \____/\____/_/   
                                                   
    [*] Educational Reconnaissance Framework
    [*] Use responsibly. Stay ethical.
EOF
  echo -e "${NC}"
}

# Typing effect for messages
type_text() {
  local text="$1"
  local delay="${2:-0.03}"
  for ((i=0; i<${#text}; i++)); do
    echo -n "${text:$i:1}"
    sleep "$delay"
  done
  echo ""
}

# Progress indicator
show_progress() {
  local task="$1"
  echo -ne "${CYAN}[${YELLOW}*${CYAN}]${NC} $task"
  for i in {1..3}; do
    echo -n "."
    sleep 0.3
  done
  echo ""
}

# Check dependencies with progress
check_dependencies() {
  echo -e "${CYAN}[${YELLOW}INIT${CYAN}]${NC} Checking system dependencies..."
  sleep 0.5
  
  local dependencies=(subfinder httpx ffuf nmap amass nuclei waybackurls gau)
  local missing=()
  
  for cmd in "${dependencies[@]}"; do
    if command -v "$cmd" &>/dev/null; then
      echo -e "${GREEN}[✓]${NC} $cmd ${GREEN}installed${NC}"
    else
      echo -e "${RED}[✗]${NC} $cmd ${RED}missing${NC}"
      missing+=("$cmd")
    fi
    sleep 0.1
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}[!]${NC} Missing dependencies: ${missing[*]}"
    echo -e "${YELLOW}[?]${NC} Continue anyway? Some features will be disabled. (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo -e "${RED}[EXIT]${NC} Aborted by user."
      exit 1
    fi
  else
    echo -e "${GREEN}[✓]${NC} All dependencies satisfied."
  fi
  sleep 0.5
}

# Interactive menu
show_menu() {
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}     ${WHITE}RECONNAISSANCE OPTIONS${NC}        ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}[1]${NC} Quick Scan (subdomains + http probing)"
  echo -e "${CYAN}[2]${NC} Standard Scan (adds fuzzing + port scan)"
  echo -e "${CYAN}[3]${NC} Deep Scan (full reconnaissance suite)"
  echo -e "${CYAN}[4]${NC} Custom Scan (choose modules)"
  echo -e "${CYAN}[5]${NC} View Previous Reports"
  echo -e "${CYAN}[0]${NC} Exit"
  echo ""
  echo -ne "${YELLOW}[>]${NC} Select option: "
}

# Subdomain enumeration module
module_subdomains() {
  local target="$1"
  local output_dir="$2"
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}MODULE: SUBDOMAIN ENUMERATION${NC}      ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  if command -v subfinder &>/dev/null; then
    show_progress "Running subfinder"
    subfinder -d "$target" -silent -o "$output_dir/subfinder_$target.txt" 2>/dev/null || true
    local count=$(wc -l < "$output_dir/subfinder_$target.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}[✓]${NC} Found $count subdomains via subfinder"
  fi
  
  if command -v amass &>/dev/null; then
    show_progress "Running amass (passive)"
    timeout 300 amass enum -passive -d "$target" -o "$output_dir/amass_$target.txt" 2>/dev/null || true
    local count=$(wc -l < "$output_dir/amass_$target.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}[✓]${NC} Found $count subdomains via amass"
  fi
  
  # Combine and deduplicate
  cat "$output_dir/subfinder_$target.txt" "$output_dir/amass_$target.txt" 2>/dev/null | \
    sort -u > "$output_dir/all_subdomains_$target.txt"
  
  local total=$(wc -l < "$output_dir/all_subdomains_$target.txt" 2>/dev/null || echo 0)
  echo -e "${GREEN}[✓]${NC} Total unique subdomains: ${WHITE}$total${NC}"
}

# HTTP probing module
module_http_probe() {
  local target="$1"
  local output_dir="$2"
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}MODULE: HTTP PROBING${NC}               ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  if command -v httpx &>/dev/null && [ -f "$output_dir/all_subdomains_$target.txt" ]; then
    show_progress "Probing live hosts"
    cat "$output_dir/all_subdomains_$target.txt" | \
      httpx -title -status-code -tech-detect -threads 50 -silent \
      -o "$output_dir/httpx_$target.txt" 2>/dev/null || true
    
    local count=$(wc -l < "$output_dir/httpx_$target.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}[✓]${NC} Found $count live hosts"
    
    # Show sample of results
    if [ "$count" -gt 0 ]; then
      echo -e "${YELLOW}[SAMPLE]${NC} Top 5 live hosts:"
      head -5 "$output_dir/httpx_$target.txt" | while read -r line; do
        echo -e "  ${BLUE}→${NC} $line"
      done
    fi
  fi
}

# Directory fuzzing module
module_fuzzing() {
  local target="$1"
  local output_dir="$2"
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}MODULE: DIRECTORY FUZZING${NC}          ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  if command -v ffuf &>/dev/null; then
    # Find wordlist
    local wordlist=""
    for path in "/usr/share/wordlists/dirb/common.txt" \
                "/usr/share/seclists/Discovery/Web-Content/common.txt" \
                "/usr/share/wordlists/dirbuster/directory-list-2.3-small.txt"; do
      if [ -f "$path" ]; then
        wordlist="$path"
        break
      fi
    done
    
    if [ -z "$wordlist" ]; then
      echo -e "${YELLOW}[!]${NC} No wordlist found, skipping fuzzing"
      return
    fi
    
    show_progress "Fuzzing directories (this may take a while)"
    
    # Get first live host to fuzz
    local fuzz_target=$(head -1 "$output_dir/httpx_$target.txt" 2>/dev/null | awk '{print $1}')
    
    if [ -n "$fuzz_target" ]; then
      timeout 300 ffuf -w "$wordlist" -u "$fuzz_target/FUZZ" \
        -mc 200,201,202,301,302,307,401,403 \
        -t 40 -o "$output_dir/ffuf_$target.json" -of json -s 2>/dev/null || true
      
      if [ -f "$output_dir/ffuf_$target.json" ]; then
        local count=$(jq '.results | length' "$output_dir/ffuf_$target.json" 2>/dev/null || echo 0)
        echo -e "${GREEN}[✓]${NC} Found $count interesting paths on $fuzz_target"
      fi
    fi
  fi
}

# Port scanning module
module_portscan() {
  local target="$1"
  local output_dir="$2"
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}MODULE: PORT SCANNING${NC}              ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  if command -v nmap &>/dev/null && [ -f "$output_dir/all_subdomains_$target.txt" ]; then
    show_progress "Scanning common ports"
    
    local scan_count=0
    local max_scans=5
    
    while IFS= read -r domain && [ $scan_count -lt $max_scans ]; do
      echo -e "${BLUE}[→]${NC} Scanning $domain"
      nmap -p 80,443,8080,8443 -Pn --open "$domain" \
        -oN "$output_dir/nmap_${domain}.txt" 2>/dev/null | \
        grep -E "Nmap scan report|open" || true
      ((scan_count++))
    done < "$output_dir/all_subdomains_$target.txt"
    
    echo -e "${GREEN}[✓]${NC} Scanned $scan_count hosts"
  fi
}

# URL discovery module
module_urls() {
  local target="$1"
  local output_dir="$2"
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}MODULE: URL DISCOVERY${NC}              ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  if command -v waybackurls &>/dev/null; then
    show_progress "Fetching URLs from Wayback Machine"
    echo "$target" | waybackurls > "$output_dir/wayback_$target.txt" 2>/dev/null || true
    local count=$(wc -l < "$output_dir/wayback_$target.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}[✓]${NC} Found $count archived URLs"
  fi
  
  if command -v gau &>/dev/null; then
    show_progress "Fetching URLs from multiple sources"
    echo "$target" | gau --threads 5 > "$output_dir/gau_$target.txt" 2>/dev/null || true
    local count=$(wc -l < "$output_dir/gau_$target.txt" 2>/dev/null || echo 0)
    echo -e "${GREEN}[✓]${NC} Found $count URLs via gau"
  fi
}

# Run selected scan type
run_scan() {
  local scan_type="$1"
  local target="$2"
  
  local date=$(date +%Y-%m-%d_%H-%M-%S)
  local output_dir="./recon_output"
  mkdir -p "$output_dir"
  
  # Find latest file number
  local latest_num=$(ls "$output_dir"/hsociety_*_*.txt 2>/dev/null | \
    grep -oP 'hsociety_(\d+)_.*' | \
    grep -oP '\d+' | sort -n | tail -1 || echo 0)
  local next_num=$((latest_num + 1))
  
  local output_file="$output_dir/hsociety_${next_num}_${date}_${target}.txt"
  
  echo ""
  type_text "[*] Initiating reconnaissance on: $target" 0.02
  echo -e "${YELLOW}[*]${NC} Output directory: $output_dir"
  echo -e "${YELLOW}[*]${NC} Report file: $output_file"
  sleep 1
  
  # Start logging
  exec > >(tee -a "$output_file") 2>&1
  
  echo "=== RECONNAISSANCE REPORT ==="
  echo "Target: $target"
  echo "Date: $date"
  echo "Scan Type: $scan_type"
  echo "================================"
  echo ""
  
  case $scan_type in
    quick)
      module_subdomains "$target" "$output_dir"
      module_http_probe "$target" "$output_dir"
      ;;
    standard)
      module_subdomains "$target" "$output_dir"
      module_http_probe "$target" "$output_dir"
      module_fuzzing "$target" "$output_dir"
      module_portscan "$target" "$output_dir"
      ;;
    deep)
      module_subdomains "$target" "$output_dir"
      module_http_probe "$target" "$output_dir"
      module_urls "$target" "$output_dir"
      module_fuzzing "$target" "$output_dir"
      module_portscan "$target" "$output_dir"
      ;;
  esac
  
  echo ""
  echo "================================"
  echo "=== RECONNAISSANCE COMPLETE ==="
  echo "================================"
  
  echo ""
  echo -e "${GREEN}[✓]${NC} Scan completed successfully!"
  echo -e "${YELLOW}[*]${NC} Full report saved to: ${WHITE}$output_file${NC}"
  echo ""
}

# View previous reports
view_reports() {
  local output_dir="./recon_output"
  
  if [ ! -d "$output_dir" ] || [ -z "$(ls -A "$output_dir"/*.txt 2>/dev/null)" ]; then
    echo -e "${YELLOW}[!]${NC} No previous reports found."
    return
  fi
  
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} ${WHITE}PREVIOUS REPORTS${NC}                   ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  echo ""
  
  local i=1
  for report in "$output_dir"/*.txt; do
    local filename=$(basename "$report")
    local size=$(du -h "$report" | cut -f1)
    echo -e "${CYAN}[$i]${NC} $filename ${YELLOW}($size)${NC}"
    ((i++))
  done
  
  echo ""
  echo -ne "${YELLOW}[>]${NC} Enter report number to view (0 to cancel): "
  read -r selection
  
  if [ "$selection" -gt 0 ] 2>/dev/null; then
    local report=$(ls "$output_dir"/*.txt | sed -n "${selection}p")
    if [ -n "$report" ]; then
      less "$report"
    fi
  fi
}

# Custom scan builder
custom_scan() {
  local target="$1"
  
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}     ${WHITE}CUSTOM SCAN BUILDER${NC}           ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo "Select modules to run (space-separated numbers):"
  echo -e "${CYAN}[1]${NC} Subdomain Enumeration"
  echo -e "${CYAN}[2]${NC} HTTP Probing"
  echo -e "${CYAN}[3]${NC} URL Discovery"
  echo -e "${CYAN}[4]${NC} Directory Fuzzing"
  echo -e "${CYAN}[5]${NC} Port Scanning"
  echo ""
  echo -ne "${YELLOW}[>]${NC} Modules (e.g., 1 2 3): "
  read -r -a modules
  
  local date=$(date +%Y-%m-%d_%H-%M-%S)
  local output_dir="./recon_output"
  mkdir -p "$output_dir"
  
  local latest_num=$(ls "$output_dir"/hsociety_*_*.txt 2>/dev/null | \
    grep -oP 'hsociety_(\d+)_.*' | \
    grep -oP '\d+' | sort -n | tail -1 || echo 0)
  local next_num=$((latest_num + 1))
  
  local output_file="$output_dir/hsociety_${next_num}_${date}_${target}.txt"
  
  exec > >(tee -a "$output_file") 2>&1
  
  echo "=== CUSTOM RECONNAISSANCE REPORT ==="
  echo "Target: $target"
  echo "Date: $date"
  echo "Selected Modules: ${modules[*]}"
  echo "===================================="
  echo ""
  
  for module in "${modules[@]}"; do
    case $module in
      1) module_subdomains "$target" "$output_dir" ;;
      2) module_http_probe "$target" "$output_dir" ;;
      3) module_urls "$target" "$output_dir" ;;
      4) module_fuzzing "$target" "$output_dir" ;;
      5) module_portscan "$target" "$output_dir" ;;
    esac
  done
  
  echo ""
  echo -e "${GREEN}[✓]${NC} Custom scan completed!"
  echo -e "${YELLOW}[*]${NC} Report saved to: ${WHITE}$output_file${NC}"
}

# Main execution
main() {
  show_banner
  check_dependencies
  
  # Get target if not provided
  if [ $# -eq 0 ]; then
    echo ""
    echo -ne "${YELLOW}[>]${NC} Enter target domain: "
    read -r TARGET
  else
    TARGET="$1"
  fi
  
  # Validate domain
  if [[ ! "$TARGET" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}[!]${NC} Invalid domain format: $TARGET"
    exit 1
  fi
  
  while true; do
    show_menu
    read -r choice
    
    case $choice in
      1)
        run_scan "quick" "$TARGET"
        echo ""
        read -p "Press Enter to continue..."
        show_banner
        ;;
      2)
        run_scan "standard" "$TARGET"
        echo ""
        read -p "Press Enter to continue..."
        show_banner
        ;;
      3)
        run_scan "deep" "$TARGET"
        echo ""
        read -p "Press Enter to continue..."
        show_banner
        ;;
      4)
        custom_scan "$TARGET"
        echo ""
        read -p "Press Enter to continue..."
        show_banner
        ;;
      5)
        view_reports
        echo ""
        read -p "Press Enter to continue..."
        show_banner
        ;;
      0)
        echo ""
        type_text "[*] Exiting ReconTool. Stay safe out there." 0.02
        echo ""
        exit 0
        ;;
      *)
        echo -e "${RED}[!]${NC} Invalid option. Please try again."
        sleep 1
        ;;
    esac
  done
}

# Run main function
main "$@"