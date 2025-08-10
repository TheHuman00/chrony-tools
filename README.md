# Chrony Tools

NTP utilities suite for Linux using Chrony

## 🚀 Quick Install

```bash
./install.sh --user        # User install
sudo ./install.sh --system # System install
```

## 🛠️ Available Tools

### `chrony-time` - Get NTP time
```bash
chrony-time time.google.com                    # Get time from Google
chrony-time -f iso time.cloudflare.com         # ISO format
chrony-time -f unix pool.ntp.org               # Unix timestamp
chrony-time -v -t 15 time.apple.com            # Verbose, 15s timeout
```

### `chrony-check` - Check NTP servers
```bash
chrony-check time.google.com                   # Basic check
chrony-check --nts time.cloudflare.com         # Check with NTS support
chrony-check -a                                # All public servers
chrony-check -p                                # NTP pool (0-3.pool.ntp.org)
chrony-check server1.com server2.com           # Multiple servers
```

### `chrony-detail` - Detailed analysis
```bash
chrony-detail time.google.com                  # Full analysis
chrony-detail -s time.cloudflare.com           # Short format
chrony-detail -v pool.ntp.org                  # Verbose mode
```

### `chrony-monitor` - System monitoring
```bash
chrony-monitor --status                         # Sync status
chrony-monitor --watch                          # Continuous monitoring
chrony-monitor --once                           # Single measurement
```

### `chrony-diff` - Time differences
```bash
chrony-diff --local time.google.com            # Diff with local time
chrony-diff server1.com server2.com            # Diff between servers
chrony-diff -n 5 -s time.cloudflare.com        # 5 samples with stats
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
chrony-time

# Check NTP server with NTS
chrony-check --nts time.cloudflare.com

# Monitor synchronization
chrony-monitor --status

# Compare with local time
chrony-diff --local pool.ntp.org
```

## Dependencies

**Required**: bash, nc, host, ping  
**Optional**: chronyc, ntpdate, bc, openssl (for NTS)

## License

Unlicensed
