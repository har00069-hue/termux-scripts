#!/data/data/com.termux/files/usr/bin/bash
# ssh-setup.sh: use your phone's Termux from your PC's terminal over Wi-Fi.
# Free sample from the Termux Pro Pack. MIT licence. Safe to run more than once.
#
#   bash ssh-setup.sh                set up (if needed), start the server, print how to connect
#   bash ssh-setup.sh --key "ssh-ed25519 AAAA… you@pc"   allow your PC's key (no password needed)
#   bash ssh-setup.sh --status
#   bash ssh-setup.sh --stop
#   bash ssh-setup.sh --help

set -u

VERSION=1.0
PORT=8022                         # Termux's sshd always listens on 8022 (no root for port 22)
MODE=start
PUBKEY=''

g=$'\e[32m'; y=$'\e[33m'; r=$'\e[31m'; b=$'\e[1m'; n=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$g" "$n" "$*"; }
warn() { printf '%s!!%s  %s\n' "$y" "$n" "$*"; }
die()  { printf '%sxx%s  %s\n' "$r" "$n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
ssh-setup.sh $VERSION: connect to Termux from your PC.

Your phone and PC must be on the same Wi-Fi.

Options:
  --key "PUBKEY"  add your PC's public key (from ~/.ssh/id_ed25519.pub on the PC)
  --status        show whether the server is running and the connect command
  --stop          stop the SSH server
  -h, --help      show this help

No key yet? On the PC run:  ssh-keygen -t ed25519
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --key) [ $# -ge 2 ] || die "--key needs the key text in quotes"; PUBKEY=$2; shift ;;
    --status) MODE=status ;;
    --stop) MODE=stop ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

case "${PREFIX:-}" in
  */com.termux/*) ;;
  *) die "This script is for the Termux app on Android." ;;
esac

running() { pgrep -x sshd >/dev/null 2>&1; }

# First non-loopback IPv4 address. Newer Android blocks some of these, so try a few ways.
phone_ip() {
  local ip
  ip=$(ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v '^127\.' | head -n1)
  [ -z "$ip" ] && ip=$(ip -4 addr show 2>/dev/null | awk '/inet /{sub(/\/.*/,"",$2); print $2}' | grep -v '^127\.' | head -n1)
  echo "${ip:-PHONE_IP}"
}

show_connect() {
  local ip; ip=$(phone_ip)
  printf '\n%sOn your PC, run:%s\n\n' "$b" "$n"
  printf '  %sssh -p %s %s@%s%s\n\n' "$g" "$PORT" "$(whoami)" "$ip" "$n"
  echo "Copy files:  scp -P $PORT file.txt $(whoami)@$ip:~/"
  [ "$ip" = PHONE_IP ] && warn "Couldn't read the phone's IP. Find it in Android Settings → Wi-Fi → your network."
  echo "Keep it running with the screen off:  termux-wake-lock"
  echo
}

case "$MODE" in
  stop)
    if running; then pkill -x sshd && say "SSH server stopped."; else say "SSH server isn't running."; fi
    exit 0 ;;
  status)
    if running; then say "SSH server is running on port $PORT."; show_connect
    else say "SSH server is not running. Start it with: bash ssh-setup.sh"; fi
    exit 0 ;;
esac

# ---------- install ----------
if ! command -v sshd >/dev/null; then
  say "Installing openssh…"
  pkg install -y openssh || die "Couldn't install openssh. Try: pkg update, then run this again."
fi
command -v passwd >/dev/null || pkg install -y termux-auth

# ---------- login method ----------
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
keys="$HOME/.ssh/authorized_keys"

if [ -n "$PUBKEY" ]; then
  [[ $PUBKEY =~ ^(ssh-(ed25519|rsa)|ecdsa-sha2-[a-z0-9-]+|sk-[a-z0-9@.-]+)\ [A-Za-z0-9+/=]+ ]] \
    || die "That doesn't look like a public key. It should start with ssh-ed25519 or ssh-rsa."
  if grep -qF "$PUBKEY" "$keys" 2>/dev/null; then
    say "That key is already allowed."
  else
    echo "$PUBKEY" >>"$keys"
    say "Key added. Your PC can now log in without a password."
  fi
  chmod 600 "$keys"
elif [ ! -s "$keys" ] && [ ! -e "$HOME/.termux_authinfo" ]; then
  say "No password or key set yet. Choose a password for SSH logins:"
  passwd || die "Password not set. Run 'passwd', or use --key with your PC's public key."
fi

# ---------- start ----------
if running; then
  say "SSH server already running on port $PORT."
else
  sshd || die "sshd failed to start. Run 'sshd -d' to see the error."
  say "SSH server started on port $PORT."
fi

show_connect
