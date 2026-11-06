#!/usr/bin/env bash
# =============================================================================
#  EDGERUNNERS GRUB THEME - installer (Fedora and other GRUB2 distros)
#
#    sudo bash install.sh                      install
#    sudo bash install.sh --always-show-menu   install + stop Fedora hiding the menu
#    sudo bash install.sh --uninstall          remove the theme
#
#  Run it from the folder that contains the "edgerunners" theme directory.
# =============================================================================
set -euo pipefail

NAME=edgerunners
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/$NAME"
DEFAULTS=/etc/default/grub
C=$'\e[36m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
say(){ echo "${C}[$NAME]${N} $*"; }
die(){ echo "${R}[error]${N} $*" >&2; exit 1; }

UNINSTALL=0; SHOWMENU=0
for a in "$@"; do
  case "$a" in
    --uninstall) UNINSTALL=1 ;;
    --always-show-menu) SHOWMENU=1 ;;
    *) die "unknown option: $a" ;;
  esac
done

[[ $EUID -eq 0 ]] || die "Run as root:  sudo bash $0 $*"

if   command -v grub2-mkconfig >/dev/null 2>&1; then P=grub2; GRUB_DIR=/boot/grub2
elif command -v grub-mkconfig  >/dev/null 2>&1; then P=grub;  GRUB_DIR=/boot/grub
else die "GRUB tools not found (grub2-mkconfig / grub-mkconfig)."; fi
THEME_DIR="$GRUB_DIR/themes/$NAME"
[[ -f $DEFAULTS ]] || die "$DEFAULTS not found."

cfg_path(){
  # Fedora 34+ (BIOS and UEFI): /boot/grub2/grub.cfg. Old Fedora UEFI kept the real file on the ESP.
  local efi=/boot/efi/EFI/fedora/grub.cfg
  if [[ -f $efi ]] && grep -q '^menuentry' "$efi" 2>/dev/null; then echo "$efi"; else echo "$GRUB_DIR/grub.cfg"; fi
}
regen(){ local cfg; cfg="$(cfg_path)"; say "Regenerating $cfg ..."; "${P}-mkconfig" -o "$cfg"; }
set_var(){ sed -i -E "/^$1=/d" "$DEFAULTS"; echo "$1=$2" >> "$DEFAULTS"; }

# ---------------------------------------------------------------- uninstall
if [[ $UNINSTALL -eq 1 ]]; then
  say "Removing theme ..."
  rm -rf "$THEME_DIR"
  sed -i "\|^GRUB_THEME=.*$NAME|d" "$DEFAULTS"
  regen
  say "${G}Uninstalled.${N} Your original settings are saved in ${DEFAULTS}.bak-$NAME (if it exists)."
  exit 0
fi

# ---------------------------------------------------------------- install
[[ -f $SRC/theme.txt ]] || die "Theme folder not found next to the installer: $SRC"

if command -v python3 >/dev/null 2>&1 && [[ -f $HERE/validate_theme.py ]]; then
  say "Validating theme files ..."
  python3 "$HERE/validate_theme.py" "$SRC" || die "Theme validation failed - not installing."
fi

say "Copying theme to $THEME_DIR"
rm -rf "$THEME_DIR"
mkdir -p "$GRUB_DIR/themes"
cp -r "$SRC" "$THEME_DIR"
chmod -R a+rX "$THEME_DIR"

cp -n "$DEFAULTS" "${DEFAULTS}.bak-$NAME"
say "Updating $DEFAULTS (backup: ${DEFAULTS}.bak-$NAME)"
sed -i -E 's/^(GRUB_TERMINAL=)/#\1/; s/^(GRUB_BACKGROUND=)/#\1/' "$DEFAULTS"
set_var GRUB_TERMINAL_OUTPUT '"gfxterm"'
set_var GRUB_GFXMODE '"1920x1080,1280x720,auto"'
set_var GRUB_THEME "\"$THEME_DIR/theme.txt\""
if [[ $SHOWMENU -eq 1 ]]; then
  set_var GRUB_TIMEOUT_STYLE menu
  command -v "${P}-editenv" >/dev/null 2>&1 && "${P}-editenv" - unset menu_auto_hide || true
  say "Boot menu will always be shown."
fi

regen

CFG="$(cfg_path)"
echo
if grep -q "set theme=.*$NAME/theme.txt" "$CFG"; then say "grub.cfg points at the theme: ${G}OK${N}"
else say "${Y}WARNING:${N} no 'set theme=' line in $CFG - check $DEFAULTS for GRUB_TERMINAL / GRUB_TERMINAL_OUTPUT overrides."; fi
if grep -q "loadfont.*$NAME/.*\.pf2" "$CFG"; then say "theme fonts are loaded: ${G}OK${N}"
else say "${Y}WARNING:${N} theme fonts are not loaded in $CFG."; fi
echo
say "${G}Done.${N} Reboot to see it."
say "${Y}Tip:${N} Fedora hides the menu after a good boot. If you don't see it, re-run with --always-show-menu."
