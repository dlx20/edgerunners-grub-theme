# Edgerunners GRUB theme

Cyberpunk neon theme (yellow / cyan / magenta) for GRUB2, made for Fedora. Original artwork, no characters or logos.

## Install

```bash
unzip edgerunners-grub-theme.zip && cd edgerunners-grub-theme
sudo bash install.sh --always-show-menu
sudo reboot
```

Uninstall: `sudo bash install.sh --uninstall`

## Folder layout

```
edgerunners-grub-theme/
  install.sh            installer (copies theme, edits /etc/default/grub, runs grub2-mkconfig)
  validate_theme.py     checks the theme files before install
  edgerunners/          <- the actual theme, goes to /boot/grub2/themes/edgerunners
    theme.txt
    background.png
    menu_{nw,n,ne,w,c,e,sw,s,se}.png        menu frame
    select_{w,c,e}.png                       yellow selection bar
    terminal_box_{nw,n,ne,w,c,e,sw,s,se}.png command-line box
    scrollbar_frame_c.png  scrollbar_thumb_c.png
    edgerunners_bold_{15,22,44}.pf2          prebuilt GRUB fonts
    icons/*.png                              generic neon OS icons
```

Manual install without the script: copy `edgerunners/` to `/boot/grub2/themes/`, set
`GRUB_THEME="/boot/grub2/themes/edgerunners/theme.txt"` and `GRUB_TERMINAL_OUTPUT="gfxterm"` in `/etc/default/grub`, then run `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`.

## Notes

- Fonts are prebuilt, so `grub2-mkfont` is not needed.
- Fedora hides the menu after a successful boot; use `--always-show-menu`, or tap Esc (UEFI) / hold Shift (BIOS) at power-on.
- Fedora Atomic editions (Silverblue/Kinoite) manage GRUB differently; this installer is for regular Fedora.
- Theme rules worth knowing if you edit `theme.txt`: image patterns need the extension (`"select_*.png"`), and positions must be whole numbers (`31%`, not `31.5%`). Run `python3 validate_theme.py edgerunners` after editing.
# edgerunners-grub-theme
