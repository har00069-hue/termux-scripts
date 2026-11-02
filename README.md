# Termux scripts

Three small bash scripts for [Termux](https://termux.dev) on Android. Plain, commented bash, MIT licence, no root needed. None of them download anything; they only use Termux's own packages.

| Script | What it does |
|---|---|
| [bootstrap.sh](bootstrap.sh) | Fresh install to ready in one run: updates packages, links phone storage, installs the tools you pick and adds a few aliases. |
| [backup.sh](backup.sh) | Saves your home folder and package list to phone storage as one file. `--keep 5` removes old backups. |
| [ssh-setup.sh](ssh-setup.sh) | Starts the SSH server and prints the exact command to type on your PC, with your phone's address filled in. |

## Run one

Read a script before you run it. Each line below downloads the script, opens it in `less` (press `q` to quit), then runs it:

```
curl -fsSLO https://raw.githubusercontent.com/har00069-hue/termux-scripts/main/bootstrap.sh && less bootstrap.sh && bash bootstrap.sh
```

```
curl -fsSLO https://raw.githubusercontent.com/har00069-hue/termux-scripts/main/backup.sh && less backup.sh && bash backup.sh
```

```
curl -fsSLO https://raw.githubusercontent.com/har00069-hue/termux-scripts/main/ssh-setup.sh && less ssh-setup.sh && bash ssh-setup.sh
```

Every script has `--help`.

Tested on Termux 0.118 (F-Droid) on Android 17. Use the F-Droid or GitHub build of Termux; the Google Play one is outdated.

## Problems

Open an [issue](https://github.com/har00069-hue/termux-scripts/issues) with your Android version, Termux version and the error you see.

## More

These are free samples from the [Termux Pro Pack](https://dt5uyt1957630.cloudfront.net/pro.html), a separate paid set of 20+ scripts.

## Licence

MIT, see [LICENSE](LICENSE).
