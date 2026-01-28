# ReconTool - Interactive Reconnaissance Framework

## Overview
An improved, interactive reconnaissance tool with a Mr. Robot-inspired interface for educational security testing and bug bounty research.

## Key Improvements

### 1. **Interactive Interface**
- Mr. Robot-style terminal aesthetics with colored output
- Menu-driven operation with multiple scan modes
- Real-time progress indicators
- Typing effects for immersive experience

### 2. **Modular Architecture**
- Separate modules for each reconnaissance function
- Easy to enable/disable specific modules
- Custom scan builder for tailored reconnaissance

### 3. **Enhanced Error Handling**
- Graceful degradation when tools are missing
- Timeout protections to prevent hanging
- Better validation of inputs and outputs
- Non-fatal errors with continue option

### 4. **Better Resource Management**
- Limits on number of hosts scanned
- Timeout controls on long-running operations
- Organized output directory structure
- Incremental report numbering

### 5. **Additional Features**
- Report viewing system
- Multiple scan intensity levels
- URL discovery from archives
- Better subdomain deduplication
- Sample output display during scans

## Installation

### Required Tools
```bash
# Core tools (required)
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
sudo apt install nmap ffuf

# Enhanced tools (recommended)
go install -v github.com/owasp-amass/amass/v4/...@master
go install -v github.com/tomnomnom/waybackurls@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

### Wordlists
```bash
# Install SecLists for better fuzzing
sudo apt install seclists
# or
git clone https://github.com/danielmiessler/SecLists.git /usr/share/seclists
```

### Make Executable
```bash
chmod +x recon_tool.sh
```

## Usage

### Basic Usage
```bash
./recon_tool.sh example.com
```

### Interactive Mode (Recommended)
```bash
./recon_tool.sh
# Then enter target when prompted
```

## Scan Types

### 1. Quick Scan (~2-5 minutes)
- Subdomain enumeration
- HTTP probing
- Best for initial reconnaissance

### 2. Standard Scan (~10-15 minutes)
- Everything in Quick Scan
- Directory fuzzing
- Port scanning
- Best for general use

### 3. Deep Scan (~20-30 minutes)
- Everything in Standard Scan
- URL discovery from archives
- Extended enumeration
- Best for comprehensive recon

### 4. Custom Scan
- Choose specific modules
- Tailored to your needs
- Skip unnecessary steps

## Output Structure

```
recon_output/
├── hsociety_1_2026-01-28_12-30-45_example.com.txt  # Main report
├── subfinder_example.com.txt                        # Subdomain results
├── amass_example.com.txt                           # Amass results
├── all_subdomains_example.com.txt                  # Combined subdomains
├── httpx_example.com.txt                           # Live hosts
├── ffuf_example.com.json                           # Fuzzing results
├── wayback_example.com.txt                         # Archived URLs
├── gau_example.com.txt                             # URL collection
└── nmap_*.txt                                      # Port scan results
```

## Module Details

### Subdomain Enumeration
- Uses subfinder and amass in parallel
- Combines and deduplicates results
- Timeout protection on amass (5 minutes)

### HTTP Probing
- Identifies live hosts
- Extracts titles and status codes
- Detects technologies
- Multi-threaded for speed

### URL Discovery
- Wayback Machine archives
- Common Crawl data
- AlienVault OTX
- URLScan data

### Directory Fuzzing
- Common directory wordlist
- Multiple HTTP status codes
- Timeout protection
- JSON output for parsing

### Port Scanning
- Common web ports (80, 443, 8080, 8443)
- Limits scans to first 5 hosts
- Identifies open services

## Security & Ethics

### ⚠️ IMPORTANT DISCLAIMERS

1. **Authorization Required**: Only scan domains you own or have explicit permission to test
2. **Legal Compliance**: Unauthorized scanning may be illegal in your jurisdiction
3. **Rate Limiting**: Tool includes protections, but monitor your traffic
4. **Educational Purpose**: This tool is for learning security concepts
5. **Responsible Disclosure**: Report vulnerabilities through proper channels

### Best Practices

- Always get written permission before scanning
- Use VPS/cloud for intensive scans (not home IP)
- Respect rate limits and server resources
- Keep detailed logs of authorized testing
- Follow responsible disclosure practices
- Stay within scope of bug bounty programs

## Troubleshooting

### "Command not found" errors
```bash
# Check your PATH includes Go binaries
echo $PATH | grep go/bin

# Add to .bashrc or .zshrc if needed
export PATH=$PATH:~/go/bin
```

### Slow scans
```bash
# Reduce threads in the script
# httpx: -threads 25 (instead of 50)
# ffuf: -t 20 (instead of 40)
```

### No results found
```bash
# Verify target is accessible
ping example.com

# Check DNS resolution
nslookup example.com

# Test tools individually
subfinder -d example.com
```

### Permission errors
```bash
# Ensure script is executable
chmod +x recon_tool.sh

# Run with appropriate permissions
# (nmap may need sudo for some scans)
```

## Advanced Configuration

### Customize Timeouts
Edit these lines in the script:
```bash
# Line ~142: Amass timeout
timeout 300 amass enum...  # 300 seconds = 5 minutes

# Line ~226: ffuf timeout
timeout 300 ffuf...  # Adjust as needed
```

### Change Wordlists
Edit line ~211:
```bash
local wordlist="/path/to/your/wordlist.txt"
```

### Adjust Port Ranges
Edit line ~245:
```bash
nmap -p 80,443,8080,8443,3000,8000...  # Add more ports
```

### Modify Scan Limits
Edit line ~243:
```bash
local max_scans=5  # Increase for more hosts
```

## Integration Examples

### With Other Tools
```bash
# Feed results to other tools
cat recon_output/all_subdomains_example.com.txt | nuclei -t cves/

# Extract URLs for parameter fuzzing
cat recon_output/wayback_example.com.txt | grep "=" | qsreplace FUZZ

# Check for subdomain takeover
cat recon_output/all_subdomains_example.com.txt | subjack -w domains.txt -t 100 -timeout 30 -o results.txt
```

### Automation
```bash
# Run daily scans
0 2 * * * /path/to/recon_tool.sh example.com

# Multiple targets
for domain in $(cat targets.txt); do
    ./recon_tool.sh "$domain"
done
```

## Tips & Tricks

1. **Start Small**: Begin with Quick Scan, escalate if needed
2. **Monitor Progress**: Watch for errors in real-time
3. **Save Reports**: Use the report viewer to compare historical data
4. **Combine Tools**: Export results to other tools in your workflow
5. **Stay Updated**: Keep all tools updated for best results
6. **Cloud Scanning**: Use cloud VPS to avoid IP blocks
7. **Respect Robots.txt**: Honor website policies

## Comparison with Original

| Feature | Original | Improved |
|---------|----------|----------|
| Interface | Basic CLI | Interactive Menu |
| Error Handling | Exit on error | Graceful degradation |
| Scan Options | Single mode | 4 scan modes |
| Resource Control | None | Timeouts & limits |
| Progress Feedback | Minimal | Real-time updates |
| Report Management | Basic | Viewing & history |
| Modularity | Monolithic | Modular design |
| URL Discovery | No | Yes |
| Customization | Limited | Extensive |

## Contributing

Feel free to enhance this tool:
- Add new reconnaissance modules
- Improve error handling
- Add integration with more tools
- Enhance the UI/UX
- Optimize performance

## License & Credits

- Created for educational purposes
- Inspired by Mr. Robot aesthetics
- Built on excellent open-source tools:
  - ProjectDiscovery (subfinder, httpx, nuclei)
  - OWASP (amass)
  - ffuf, nmap, and many others

## Support

For issues, improvements, or questions:
- Check tool documentation
- Verify tool installations
- Review error messages carefully
- Test tools independently

---

**Remember: With great power comes great responsibility. Use wisely. Stay ethical.**