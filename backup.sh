#!/data/data/com.termux/files/usr/bin/bash
# backup.sh: save your Termux home folder and package list to phone storage.
# Free sample from the Termux Pro Pack. MIT licence.
#
#   bash backup.sh                 back up to ~/storage/shared/termux-backups
#   bash backup.sh --to DIR        back up somewhere else
#   bash backup.sh --keep 5        delete all but the 5 newest backups afterwards
#   bash backup.sh --help

set -u

VERSION=1.0
DEST="$HOME/storage/shared/termux-backups"
KEEP=0

g=$'\e[32m'; y=$'\e[33m'; r=$'\e[31m'; b=$'\e[1m'; n=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$g" "$n" "$*"; }
warn() { printf '%s!!%s  %s\n' "$y" "$n" "$*"; }
die()  { printf '%sxx%s  %s\n' "$r" "$n" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
backup.sh $VERSION: back up Termux to phone storage.

Saves one .tar.gz with:
  • your home folder (scripts, dotfiles, projects); skips caches and ~/storage
  • packages.txt, the list of packages you installed by hand

Options:
  --to DIR     where to save (default: $DEST)
  --keep N     keep only the N newest backups in that folder
  -h, --help   show this help

Restore on a new phone (after running termux-setup-storage):
  tar -xzf termux-backup-DATE.tar.gz -C ~
  pkg install \$(cat ~/packages.txt)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --to) [ $# -ge 2 ] || die "--to needs a folder"; DEST=$2; shift ;;
    --keep) [[ ${2:-} =~ ^[1-9][0-9]*$ ]] || die "--keep needs a number, e.g. --keep 5"; KEEP=$2; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

case "${PREFIX:-}" in
  */com.termux/*) ;;
  *) die "This script is for the Termux app on Android." ;;
esac

if [ "$DEST" = "$HOME/storage/shared/termux-backups" ] && [ ! -d "$HOME/storage/shared" ]; then
  die "Phone storage isn't linked yet. Run termux-setup-storage, tap Allow, then try again."
fi
mkdir -p "$DEST" || die "Can't create $DEST"

stamp=$(date +%Y%m%d-%H%M)
file="$DEST/termux-backup-$stamp.tar.gz"

say "Saving package list…"
# apt-mark showmanual = packages you asked for, not their dependencies
apt-mark showmanual 2>/dev/null | sort >"$HOME/packages.txt" \
  || warn "Couldn't read the package list; continuing with files only."

say "Packing your home folder…"
# next to the backup: $DEST is known to be writable, a temp folder may not be (cron)
errlog="$file.errors"
# gzip runs in a pipe, not started by tar: tar couldn't find it from the timer (status 127).
# Some phones only have Android's own gzip, which a timer's PATH doesn't reach.
gzip=$(command -v gzip || echo /system/bin/gzip)
tar -cf - -C "$HOME" \
  --exclude=./storage \
  --exclude=./.cache \
  --exclude='./.npm/_cacache' \
  --exclude='./.cargo/registry' \
  --exclude='./.cargo/git' \
  --exclude='*/node_modules' \
  --exclude='*/__pycache__' \
  . 2>"$errlog" | "$gzip" >"$file"
st=("${PIPESTATUS[@]}")
status=${st[0]}
[ "${st[1]}" = 0 ] || { echo "gzip failed (exit ${st[1]}); install it: pkg install gzip" >>"$errlog"; status=2; }
# tar exits 1 when a file changed while reading it; the backup is still usable
if [ "$status" -gt 1 ]; then
  rm -f "$file"
  # show tar's own reason, it says which file or folder it choked on
  tail -n 3 "$errlog" 2>/dev/null | sed 's/^/    /' >&2
  rm -f "$errlog"
  die "Backup failed (tar exit $status). Is there enough free space?"
fi
rm -f "$errlog"

size=$(du -h "$file" | cut -f1)
say "Backup saved: $file ($size)"

if [ "$KEEP" -gt 0 ]; then
  old=$(ls -1t "$DEST"/termux-backup-*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1)))
  if [ -n "$old" ]; then
    echo "$old" | while IFS= read -r f; do rm -f -- "$f"; done
    say "Removed $(echo "$old" | wc -l) older backup(s), kept the newest $KEEP."
  fi
fi

# the Pro Pack has a restore command; on its own the help explains the steps
if command -v restore-backup >/dev/null; then
  printf '\n%sTo restore%s, here or on a new phone: restore-backup\n' "$b" "$n"
else
  printf '\n%sTo restore%s on a new phone, see: bash backup.sh --help\n' "$b" "$n"
fi
