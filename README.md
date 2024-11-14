# Bash-PortScanner

A customizable, lightweight port scanner built entirely in Bash. This tool allows scanning of single IP addresses, subnets (CIDR notation), and multiple hosts from a file. Supports:

- Full port scans (1-65535) or specific ranges (20-80).
- Customizable port lists (e.g., 20,30,80,443).
- Random timeouts between scans for stealth.
- Easy integration with IP lists from a file.
- Every step parses the output via terminal and on a file 

No external dependencies required – designed for simplicity, speed, and flexibility.

## Usage Examples

```
./port_scanner.sh [-i <IP or subnet>] [-f <file>] [-p <ports>] [-t <min>-<max>]
./portscanner.sh -i 192.168.1.1 -p 20-80 -t 100-500
./portscanner.sh -i 192.168.1.1/24  
./portscanner.sh -f hosts.txt -p 20,30,50 -t 200-800
```
