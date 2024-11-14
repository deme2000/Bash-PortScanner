#!/bin/bash

# Usage: ./port_scanner.sh [-i <IP or subnet>] [-f <file>] [-p <ports>] [-t <min>-<max>] [-o <output_file>]
# Example: ./port_scanner.sh -i 192.168.1.1/24 -p 20-80 -o output.txt

TARGETS=()
PORTS=()
MIN_TIMEOUT=0
MAX_TIMEOUT=0
OUTPUT_FILE=""

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--ip)
      TARGETS+=("$2")
      shift 2
      ;;
    -f|--file)
      while IFS= read -r line; do
        TARGETS+=("$line")
      done < "$2"
      shift 2
      ;;
    -p|--ports)
      if [[ "$2" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS="-" read START_PORT END_PORT <<< "$2"
        for ((port=START_PORT; port<=END_PORT; port++)); do
          PORTS+=($port)
        done
      elif [[ "$2" =~ ^[0-9,]+$ ]]; then
        IFS="," read -r -a PORTS <<< "$2"
      fi
      shift 2
      ;;
    -t|--timeout)
      IFS="-" read MIN_TIMEOUT MAX_TIMEOUT <<< "$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if targets are provided
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "Usage: $0 [-i <IP or subnet>] [-f <file>] [-p <ports>] [-t <min>-<max>] [-o <output_file>]"
  exit 1
fi

# Set default port range if no ports are specified
if [[ ${#PORTS[@]} -eq 0 ]]; then
  for ((port=1; port<=65535; port++)); do
    PORTS+=($port)
  done
fi

# Function to check if a port is open
scan_port() {
  local target=$1
  local port=$2
  (echo > /dev/tcp/$target/$port) &>/dev/null && echo "Port $port on $target is open"
}

# Convert CIDR notation to a list of IPs
cidr_to_ips() {
  local cidr=$1
  local ip mask
  IFS=/ read ip mask <<< "$cidr"

  # Convert IP and mask to binary
  IFS=. read -r i1 i2 i3 i4 <<< "$ip"
  ip_bin=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
  ip_min=$((ip_bin & (0xFFFFFFFF << (32 - mask))))
  ip_max=$((ip_bin | ~(0xFFFFFFFF << (32 - mask))))

  # Generate all IPs in range
  for ((i = ip_min; i <= ip_max; i++)); do
    echo "$(( (i >> 24) & 0xFF )).$(( (i >> 16) & 0xFF )).$(( (i >> 8) & 0xFF )).$(( i & 0xFF ))"
  done
}

# Resolve target to individual IPs
resolve_targets() {
  local target=$1
  if [[ "$target" =~ "/" ]]; then
    cidr_to_ips "$target"
  else
    echo "$target"
  fi
}

# Main scanning loop
echo "Starting scan on targets: ${TARGETS[@]}..."
for target in "${TARGETS[@]}"; do
  for ip in $(resolve_targets "$target"); do
    echo "Scanning host: $ip"
    for port in "${PORTS[@]}"; do
      if scan_port $ip $port; then
        result="Port $port on $ip is open"
        echo "$result"
        # Output to file if output file is provided
        if [[ -n "$OUTPUT_FILE" ]]; then
          echo "$result" >> "$OUTPUT_FILE"
        fi
      fi
      # Wait between scans if timeout is set
      if (( MIN_TIMEOUT > 0 || MAX_TIMEOUT > 0 )); then
        sleep $((RANDOM % (MAX_TIMEOUT - MIN_TIMEOUT + 1) + MIN_TIMEOUT))ms
      fi
    done
    echo "Completed scan for host: $ip"
  done
done

echo "Scan complete!"
