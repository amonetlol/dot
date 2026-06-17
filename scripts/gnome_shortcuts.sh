#!/usr/bin/env bash

# =====================================================
# Instalação de dependências
# =====================================================
echo "📦 Instalando ulauncher e dependências para Wayland..."
sudo pacman -S --needed ulauncher wmctrl --noconfirm
echo "✅ Instalação concluída"
echo ""

# =====================================================
# Configurações GNOME
# =====================================================

# -- Button --
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

  # -- Plano de energia --
  # ----- Tuned-adm :: Fedora e mais novos
  # tuned-adm list  ## lista os planos disponiveis
  # tuned-adm profile virtual-guest # Para VM
  #tuned-adm profile throughput-performance # Desempenho
  # ---- Performance não é instalado
  #powerprofilesctl set performance
  # ---- Arch
  powerprofilesctl set balanced
  
  # -- Desligamento de Tela --
  gsettings set org.gnome.desktop.session idle-delay 0

  # Doar Gnome:
  # gsettings set org.gnome.settings-daemon.plugins.housekeeping donation-reminder-enabled false

  # Super + Q = close app
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"

  # Atalhos: foot / kitty / Firefox
  # Primeiro: kitty com Shift+Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'alacritty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Shift><Super>Return'

  # Segundo: foot com Super+Enter
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'foot'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'foot'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>Return'

  # Terceiro: Firefox com Super+W
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Firefox'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'firefox'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>W'

  # Quarto: Ulauncher com Super+D
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'ulauncher'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'ulauncher-toggle'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Super>d'

  # Ativa a lista de atalhos personalizados
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"
