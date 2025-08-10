# Chrony Tools

NTP utilities suite for Linux using Chrony

## 🚀 Quick Install

```bash
./install.sh --user        # User install
sudo ./install.sh --system # System install
```

## 🛠️ Available Tools

### `gettime` - Get NTP time
```bash
gettime time.google.com                    # Get time from Google
gettime -f iso time.cloudflare.com         # ISO format
gettime -f unix pool.ntp.org               # Unix timestamp
gettime -v -t 15 time.apple.com            # Verbose, 15s timeout
```

### `ntpcheck` - Check NTP servers
```bash
ntpcheck time.google.com                   # Basic check
ntpcheck --nts time.cloudflare.com         # Check with NTS support
ntpcheck -a                                # All public servers
ntpcheck -p                                # NTP pool (0-3.pool.ntp.org)
ntpcheck server1.com server2.com           # Multiple servers
```

### `ntpdetail` - Detailed analysis
```bash
ntpdetail time.google.com                  # Full analysis
ntpdetail -s time.cloudflare.com           # Short format
ntpdetail -v pool.ntp.org                  # Verbose mode
```

### `monitor` - System monitoring
```bash
monitor --status                           # Sync status
monitor --watch                            # Continuous monitoring
monitor --once                             # Single measurement
```

### `timediff` - Time differences
```bash
timediff --local time.google.com           # Diff with local time
timediff server1.com server2.com           # Diff between servers
timediff -n 5 -s time.cloudflare.com       # 5 samples with stats
```

## 📋 Common Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help |
| `-v, --verbose` | Verbose mode |
| `-t, --timeout N` | Timeout in seconds |

## ⚡ Quick Examples

```bash
# Get current time
gettime

# Check NTP server with NTS
ntpcheck --nts time.cloudflare.com

# Monitor synchronization
monitor --status

# Compare with local time
timediff --local pool.ntp.org
```

## Dependencies

**Required**: bash, nc, host, ping  
**Optional**: chronyc, ntpdate, bc, openssl (for NTS)

## License

Unlicensed
