#!/data/data/com.termux/files/usr/bin/bash
# bootstrap.sh: fresh Termux install to a ready-to-use setup in one run.
# Free sample from the Termux Pro Pack. MIT licence. Safe to run more than once.
#
#   bash bootstrap.sh            ask before each optional step
#   bash bootstrap.sh --yes      accept the defaults, no questions
#   bash bootstrap.sh --help

set -u

VERSION=1.0
ASSUME_YES=0
MARK_BEGIN='# >>> termux-pro-pack bootstrap >>>'
MARK_END='# <<< termux-pro-pack bootstrap <<<'

g=$'\e[32m'; y=$'\e[33m'; r=$'\e[31m'; b=$'\e[1m'; n=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$g" "$n" "$*"; }
warn() { printf '%s!!%s  %s\n' "$y" "$n" "$*"; }
die()  { printf '%sxx%s  %s\n' "$r" "$n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
bootstrap.sh $VERSION: set up a fresh Termux install.

Steps:
  1. update packages (keeps your existing config files)
  2. link phone storage (~/storage → /sdcard)
  3. install a starter toolkit; you pick which sets
  4. add a few handy aliases to ~/.bashrc (inside a marked block, easy to remove)

Options:
  -y, --yes    accept defaults (essentials + Python, aliases on)
  -h, --help   show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $arg (try --help)" ;;
  esac
done

# ask "Question" default(y|n) → returns 0 for yes
ask() {
  local q=$1 def=$2 reply hint
  [ "$def" = y ] && hint='Y/n' || hint='y/N'
  if [ "$ASSUME_YES" = 1 ]; then [ "$def" = y ]; return; fi
  read -r -p "$q [$hint] " reply </dev/tty || reply=''
  reply=${reply:-$def}
  [[ $reply =~ ^[Yy] ]]
}

# ---------- checks ----------
case "${PREFIX:-}" in
  */com.termux/*) ;;
  *) die "This script is for the Termux app on Android." ;;
esac
[ "$(id -u)" = 0 ] && die "Don't run this as root or with sudo. Termux doesn't need it."

if [ "${TERMUX_APK_RELEASE:-}" = GOOGLE_PLAY_STORE ]; then
  warn "You're using the Google Play build of Termux. Some packages may not work."
  warn "For the full version, install Termux from F-Droid or GitHub."
fi

printf '\n%sTermux bootstrap %s%s\n\n' "$b" "$VERSION" "$n"

# ---------- 1. update ----------
say "Updating packages (this can take a few minutes the first time)…"
pkg update -y || die "Package update failed. Run termux-change-repo, pick another mirror, then try again."
# --force-confold keeps any config files you've already edited instead of stopping to ask
apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef full-upgrade \
  || die "Upgrade failed. Run 'pkg upgrade' by hand to see the error."

# ---------- 2. storage ----------
if [ -d "$HOME/storage/shared" ]; then
  say "Phone storage already linked at ~/storage."
elif ask "Link phone storage (lets Termux read and save files in /sdcard)?" y; then
  termux-setup-storage
  say "Tap 'Allow' in the permission popup. ~/storage appears once you do."
fi

# ---------- 3. toolkit ----------
pkgs=()
ask "Install essentials: git, curl, wget, nano, openssh, zip, tree, htop?" y \
  && pkgs+=(git curl wget nano openssh zip unzip gzip tree htop)
ask "Install Python (python + pip)?" y && pkgs+=(python)
ask "Install Node.js (node + npm)?" n && pkgs+=(nodejs-lts)
ask "Install build tools (clang, make, cmake), needed to compile some pip/npm packages?" n \
  && pkgs+=(clang make cmake pkg-config)
ask "Install termux-api commands (needs the separate Termux:API app from F-Droid)?" n \
  && pkgs+=(termux-api)

if [ ${#pkgs[@]} -gt 0 ]; then
  say "Installing: ${pkgs[*]}"
  pkg install -y "${pkgs[@]}" || warn "Some packages failed to install. Run 'pkg install ${pkgs[*]}' to see why."
fi

# ---------- 4. shell ----------
rc="$HOME/.bashrc"
if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
  say "Aliases already in ~/.bashrc."
elif ask "Add handy aliases to ~/.bashrc (ll, la, .., up, sd, ports)?" y; then
  cat >>"$rc" <<EOF

$MARK_BEGIN
# Added by bootstrap.sh. Delete this block to remove.
alias ll='ls -lh'
alias la='ls -lha'
alias ..='cd ..'
alias up='pkg update && pkg upgrade'
alias sd='cd ~/storage/shared'
alias ports='netstat -tlnp 2>/dev/null'
export PATH="\$HOME/bin:\$PATH"
$MARK_END
EOF
  mkdir -p "$HOME/bin"
  say "Aliases added. They work in new sessions, or run: source ~/.bashrc"
fi

# ---------- done ----------
printf '\n%sDone.%s Next steps:\n' "$b" "$n"
command -v git >/dev/null && ! git config --global user.name >/dev/null \
  && echo "  • git config --global user.name \"Your Name\""
if command -v sshd >/dev/null; then
  # the Pro Pack installs it as a command; on its own it's a downloaded file
  if command -v ssh-setup >/dev/null; then ssh_cmd=ssh-setup; else ssh_cmd="bash ssh-setup.sh"; fi
  echo "  • Connect from your PC over SSH: $ssh_cmd"
fi
echo "  • Cheat sheet with more commands: the site you got this from"
echo
