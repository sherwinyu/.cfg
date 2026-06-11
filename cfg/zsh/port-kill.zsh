# Usage: ptkl <port> [port...]
# Kills all processes listening on / using the given port(s).
# Examples: ptkl 3000, ptkl 3000 8080

ptkl() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ptkl <port> [port...]"
    return 1
  fi

  local port pids
  for port in "$@"; do
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
      echo "Skipping '$port': not a port number"
      continue
    fi

    pids=$(lsof -ti ":$port" 2>/dev/null)
    if [[ -z "$pids" ]]; then
      echo "Port $port: nothing listening"
      continue
    fi

    echo "Port $port: killing $(echo "$pids" | tr '\n' ' ')"
    echo "$pids" | xargs kill -9 2>/dev/null
  done
}
