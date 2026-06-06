#!/usr/bin/env bash
chmod +x install-all.sh
chmod +x 00-mod-stow.sh
chmod +x 01-mod-arch.sh
chmod +x 02-mod-nvim.sh
chmod +x 03-mod-extra.sh
chmod +x 04-mod-hyprland.sh
chmod +x 05-mod-hyprland-config.sh
chmod +x lib/common.sh

AUTO_YES=1 bash "$PWD/install-all.sh"