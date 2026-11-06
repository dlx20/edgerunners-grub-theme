# Edgerunners GRUB Theme

A cyberpunk neon theme for the GRUB2 boot menu, inspired by the look of *Cyberpunk: Edgerunners*. Works on most Linux distributions that use GRUB2, including Fedora, Ubuntu, Debian, Arch and openSUSE.

![Edgerunners GRUB theme preview](preview.png)


## Features

- Neon yellow, cyan and magenta palette with a glitched sunset skyline
- Original hooded netrunner character on a rooftop
- Cut-corner menu frame, yellow selection bar and boot countdown bar
- Neon icons for Linux, Windows and UEFI entries
- Prebuilt fonts, so no extra tools are needed
- One-command installer and uninstaller, with a backup of your GRUB settings

## Install

```bash
git clone https://github.com/dlx20/edgerunners-grub-theme.git
cd edgerunners-grub-theme
sudo bash install.sh --always-show-menu
sudo reboot
```

The `--always-show-menu` flag is optional. Many distros hide the boot menu after a successful boot, and this keeps it visible so you can see the theme.

## Uninstall

```bash
sudo bash install.sh --uninstall
```

## Manual install

1. Copy the `edgerunners` folder into your GRUB themes directory (`/boot/grub2/themes/` or `/boot/grub/themes/`).
2. In `/etc/default/grub`, set:
   ```
   GRUB_TERMINAL_OUTPUT="gfxterm"
   GRUB_GFXMODE="1920x1080,1280x720,auto"
   GRUB_THEME="/boot/grub2/themes/edgerunners/theme.txt"
   ```
3. Regenerate the GRUB config:
   - Fedora, RHEL, openSUSE: `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`
   - Debian, Ubuntu, Arch: `sudo grub-mkconfig -o /boot/grub/grub.cfg`

## What's included

```
install.sh            installer and uninstaller
validate_theme.py     checks theme files before install
preview.png
edgerunners/          the theme itself
  theme.txt           layout, colors and text
  background.png      1920x1080 background
  menu_*.png          menu frame
  select_*.png        selection bar
  terminal_box_*.png  command-line box
  scrollbar_*.png
  *.pf2               fonts
  icons/              OS icons
```

## Customizing

Edit `edgerunners/theme.txt` to change colors, positions or text, or replace any image, then reinstall. GRUB ignores a broken theme without telling you, so keep to two rules:

- Image patterns need the extension: `"select_*.png"`, not `"select_*"`.
- Positions must be whole numbers: `31%`, not `31.5%`.

Check your changes before installing:

```bash
python3 validate_theme.py edgerunners
```

## Compatibility

- Works with GRUB2 on BIOS and UEFI systems.
- Does not work with other bootloaders such as systemd-boot or rEFInd.
- Immutable and declarative systems (Fedora Atomic, NixOS, openSUSE MicroOS) manage GRUB differently, so the installer is not suitable for them.
- Best on 16:9 screens. Other aspect ratios crop the background instead of stretching it.

## Troubleshooting

- **No menu appears:** your distro is hiding it. Re-run the installer with `--always-show-menu`, or tap `Esc` (UEFI) or hold `Shift` (BIOS) at power-on.
- **Plain text menu, no background:** the theme isn't loading. Check `/etc/default/grub` and `/etc/default/grub.d/` for a `GRUB_TERMINAL=console` override, and confirm `grub.cfg` contains a `set theme=` line.
- **Background but no frame or selection bar:** an image failed to load. Run `python3 validate_theme.py edgerunners`.

## Credits

Fonts are rendered from [DejaVu Sans Mono Bold](https://dejavu-fonts.github.io/). This is an unofficial fan project and is not affiliated with CD PROJEKT RED, Studio Trigger or Netflix.

## License

MIT. 
