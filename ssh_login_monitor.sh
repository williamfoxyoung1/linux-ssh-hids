#!/usr/bin/env bash

# ============================================================
# Failed SSH Login Monitor
# Displays failed SSH authentication attempts in a console table
#
# Supports:
#   Ubuntu / Debian  -> /var/log/auth.log
#   RHEL / CentOS    -> /var/log/secure
#
# Run:
#   sudo ./ssh_login_monitor.sh
# ============================================================

# -----------------------------
# Colors
# -----------------------------

RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

# -----------------------------
# Check root
# -----------------------------

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script as root."
    echo
    echo "sudo $0"
    exit 1
fi

# -----------------------------
# Locate authentication log
# -----------------------------

if [[ -f "/var/log/auth.log" ]]; then
    AUTH_LOG="/var/log/auth.log"

elif [[ -f "/var/log/secure" ]]; then
    AUTH_LOG="/var/log/secure"

else
    echo "ERROR: Authentication log not found."
    echo
    echo "Checked:"
    echo "  /var/log/auth.log"
    echo "  /var/log/secure"
    exit 1
fi

# -----------------------------
# Failure counter
# -----------------------------

declare -A FAILURE_COUNT

# -----------------------------
# Header
# -----------------------------

clear

echo -e "${CYAN}"
echo "=============================================================================================="
echo "                           FAILED SSH LOGIN MONITOR"
echo "=============================================================================================="
echo -e "${RESET}"

echo "Authentication Log : $AUTH_LOG"
echo "Destination Host   : $(hostname)"
echo "Status             : Monitoring"
echo
echo "Press Ctrl+C to stop."
echo

printf "${WHITE}%-20s %-18s %-16s %-8s %-18s %-10s %-8s${RESET}\n" \
    "TIMESTAMP" \
    "USERNAME" \
    "SOURCE IP" \
    "PORT" \
    "DESTINATION" \
    "PROTOCOL" \
    "FAILURES"

printf "%-20s %-18s %-16s %-8s %-18s %-10s %-8s\n" \
    "-------------------" \
    "-----------------" \
    "---------------" \
    "-------" \
    "-----------------" \
    "---------" \
    "--------"

# -----------------------------
# Process login failure
# -----------------------------

process_failure() {

    local line="$1"

    # -------------------------
    # Source IP
    # -------------------------

    source_ip=$(echo "$line" |
        sed -nE 's/.* from ([0-9a-fA-F:.]+) port .*/\1/p')

    if [[ -z "$source_ip" ]]; then
        return
    fi

    # -------------------------
    # Source Port
    # -------------------------

    source_port=$(echo "$line" |
        sed -nE 's/.* port ([0-9]+).*/\1/p')

    [[ -z "$source_port" ]] && source_port="N/A"

    # -------------------------
    # Username
    # -------------------------

    if [[ "$line" =~ Failed\ password\ for\ invalid\ user\ ([^[:space:]]+) ]]; then

        username="${BASH_REMATCH[1]}"

    elif [[ "$line" =~ Failed\ password\ for\ ([^[:space:]]+) ]]; then

        username="${BASH_REMATCH[1]}"

    else

        username="unknown"

    fi

    # -------------------------
    # Timestamp
    # -------------------------

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # -------------------------
    # Destination
    # -------------------------

    destination=$(hostname)

    # Keep hostname from breaking table
    destination="${destination:0:17}"

    # -------------------------
    # Protocol
    # -------------------------

    protocol="SSH"

    # -------------------------
    # Increment failure count
    # -------------------------

    ((FAILURE_COUNT["$source_ip"]++))

    failures="${FAILURE_COUNT[$source_ip]}"

    # -------------------------
    # Display result
    # -------------------------

    if (( failures >= 10 )); then
        COLOR="$RED"

    elif (( failures >= 5 )); then
        COLOR="$YELLOW"

    else
        COLOR="$RESET"
    fi

    printf "${COLOR}%-20s %-18s %-16s %-8s %-18s %-10s %-8s${RESET}\n" \
        "$timestamp" \
        "${username:0:17}" \
        "$source_ip" \
        "$source_port" \
        "$destination" \
        "$protocol" \
        "$failures"
}

# -----------------------------
# Monitor
# -----------------------------

tail -Fn0 "$AUTH_LOG" 2>/dev/null |
while IFS= read -r line; do

    if [[ "$line" == *"Failed password"* ]]; then
        process_failure "$line"
    fi

done