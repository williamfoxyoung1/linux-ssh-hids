# Linux SSH HIDS

A lightweight **Host-Based Intrusion Detection System (HIDS)** written in Bash that monitors Linux authentication logs for failed SSH login attempts in real time.

The tool extracts authentication information from SSH logs, tracks repeated failures by source IP address, and displays suspicious activity in a color-coded console table to help identify potential SSH brute-force attacks.

![Linux SSH HIDS](screenshots/failed_ssh_monitor.png)

## Overview

SSH services exposed to a network are frequently targeted by password guessing and brute-force attacks. Linux SSH HIDS provides a simple way to monitor these authentication failures directly from the Linux command line.

The script continuously watches the system authentication log and displays failed SSH login attempts as they occur.

Each detected attempt includes:

- Timestamp
- Attempted username
- Source IP address
- Source port
- Destination hostname
- Protocol
- Cumulative failure count

The failure counter is maintained separately for each source IP address.

## Features

- Real-time SSH authentication monitoring
- Detects failed SSH password attempts
- Extracts attempted usernames
- Identifies source IP addresses
- Displays source TCP ports
- Tracks failures by source IP
- Color-coded severity indicators
- Clean console table
- Automatically detects common Linux authentication logs
- Supports Ubuntu/Debian and RHEL/CentOS-style logging
- No external APIs required
- Lightweight Bash implementation

## Detection Logic

Linux SSH HIDS monitors authentication logs for SSH messages containing:

```text
Failed password
```

For example:

```text
Failed password for bill from 10.0.2.5 port 50006 ssh2
```

The script extracts the relevant fields and displays them in the monitoring console.

Example:

```text
TIMESTAMP            USERNAME     SOURCE IP       PORT     DESTINATION        PROTOCOL   FAILURES
-------------------  -----------  --------------  -------  -----------------  ---------  --------
2026-10-04 00:12:38  bill         10.0.2.5        50006    admin-VirtualBox   SSH        1
2026-10-04 00:12:42  bill         10.0.2.5        50020    admin-VirtualBox   SSH        2
2026-10-04 00:12:45  bill         10.0.2.5        44808    admin-VirtualBox   SSH        3
```

## Severity Levels

The console changes the color of an event as repeated authentication failures are detected from the same source IP.

| Failed Attempts | Severity | Console Display |
|---:|---|---|
| 1–4 | Normal | Default |
| 5–9 | Warning | Yellow |
| 10+ | High | Red |

This provides a quick visual indication of hosts generating unusually high numbers of failed SSH authentication attempts.

> **Note:** The current counter represents failures observed during the lifetime of the script. A high failure count is an indicator for investigation and does not by itself prove malicious activity.

## How It Works

```text
             Linux SSH Service
                    |
                    v
          Authentication Attempt
                    |
                    v
        /var/log/auth.log
                 or
         /var/log/secure
                    |
                    v
         Linux SSH HIDS Script
                    |
           +--------+--------+
           |                 |
           v                 v
     Parse Event       Extract Source IP
           |                 |
           +--------+--------+
                    |
                    v
        Increment Failure Count
                    |
                    v
        Determine Severity Level
                    |
                    v
         Display Console Alert
```

The project is currently an **IDS rather than an IPS** because it detects and reports suspicious authentication activity without automatically blocking the source.

## Requirements

The script is intended for Linux systems running OpenSSH.

Requirements:

- Bash
- OpenSSH Server
- Root or sufficient permissions to read authentication logs

Supported authentication log locations:

```text
/var/log/auth.log
/var/log/secure
```

`/var/log/auth.log` is commonly used by Ubuntu and Debian-based distributions.

`/var/log/secure` is commonly found on RHEL-family distributions.

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/linux-ssh-hids.git
cd linux-ssh-hids
```

Make the script executable:

```bash
chmod +x ssh_login_monitor.sh
```

## Usage

Run the monitor with elevated privileges:

```bash
sudo ./ssh_login_monitor.sh
```

The program will begin monitoring new failed SSH authentication attempts.

Press:

```text
Ctrl+C
```

to stop monitoring.

## Example Detection

Suppose a remote system repeatedly attempts to authenticate as `bill`.

After several failed attempts, the monitor might display:

```text
2026-10-04 00:12:38  bill  10.0.2.5  50006  admin-VirtualBox  SSH   1
2026-10-04 00:12:42  bill  10.0.2.5  50020  admin-VirtualBox  SSH   2
2026-10-04 00:12:53  bill  10.0.2.5  48456  admin-VirtualBox  SSH   5
2026-10-04 00:13:10  bill  10.0.2.5  36638  admin-VirtualBox  SSH  10
2026-10-04 00:13:49  bill  10.0.2.5  47800  admin-VirtualBox  SSH  20
```

As the number of failures increases, the console changes from the default display to yellow and eventually red.

This makes repeated authentication failures immediately visible to an administrator or security analyst.

## Security Use Cases

Linux SSH HIDS can be used as a small defensive security tool for:

- SSH brute-force detection
- Authentication monitoring
- Security lab exercises
- Linux log analysis
- Blue-team training
- Incident detection demonstrations
- SOC fundamentals
- Bash scripting practice

## HIDS vs. HIPS

The current project functions as a **Host-Based Intrusion Detection System (HIDS)**.

It:

```text
Monitors -> Detects -> Counts -> Highlights -> Alerts
```

It does **not** currently:

```text
Detects -> Blocks
```

Automatically blocking suspicious IP addresses using technologies such as `nftables` would introduce intrusion-prevention functionality and move the project toward a **Host-Based Intrusion Prevention System (HIPS)**.

## Current Limitations

This project is intentionally lightweight.

The current implementation:

- Detects failed SSH password authentication
- Uses an in-memory failure counter
- Resets counters when the program restarts
- Does not currently use a rolling time window
- Does not automatically block source addresses
- Does not perform geolocation or reputation lookups
- Should not treat every repeated login failure as malicious

Legitimate users can mistype passwords, and multiple users can sometimes appear behind the same public IP address.

The output should therefore be treated as a security indicator rather than definitive evidence of an attack.

## Planned Improvements

Potential future improvements include:

- Rolling detection windows
- Configurable alert thresholds
- Events-per-minute tracking
- Persistent incident logging
- IP allowlisting
- IPv4 and IPv6 validation
- Detection of additional SSH authentication events
- Detection of username enumeration
- Severity scoring
- JSON/CSV output
- Syslog integration
- systemd service support
- `nftables` integration
- Temporary IP blocking
- Automatic block expiration

A future prevention mode could implement logic such as:

```text
5 failed SSH attempts
        +
within 60 seconds
        |
        v
HIGH severity alert
        |
        v
Temporary nftables block
```

## Defensive Security Purpose

This project is designed for defensive security monitoring, cybersecurity education, home labs, and systems owned or administered by the user.

It demonstrates how standard Linux authentication logs can be processed with Bash to identify potentially suspicious authentication behavior without requiring a full SIEM or commercial security platform.

## Skills Demonstrated

This project demonstrates practical experience with:

- Linux administration
- Bash scripting
- SSH security
- Linux authentication logs
- Log parsing
- Regular expressions
- Intrusion detection concepts
- Brute-force detection
- Security event monitoring
- IP-based event correlation
- Defensive security automation
- Blue-team security operations

## License

This project is intended for educational and defensive security purposes.

Consider adding an open-source license such as the MIT License if you plan to distribute or accept contributions to the project.
