#!/usr/bin/env python3
import os, subprocess, sys

def get_sys_info():
    try:
        ip = subprocess.check_output("ip -4 a show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1", shell=True).decode().strip()
    except: ip = "Offline"
    try:
        boot = subprocess.check_output("systemd-analyze | awk -F'=' '{print $2}' | awk '{print $1}'", shell=True).decode().strip()
    except: boot = "N/A"
    return f"\n\033[1;36m?? Boot:\033[0m {boot}s  |  \033[1;32m?? IP:\033[0m {ip}"

def show_help():
    os.system('clear')
    help_data = [
        ("GESTIONE FINESTRE", "APP / SISTEMA"),
        ("SUPER+Q", "Kill Active",   "SUPER+RET", "Terminal"),
        ("SUPER+F", "Fullscreen",    "SUPER+D",   "Launcher"),
        ("SUPER+O", "Toggle Float",  "SUPER+E",   "Exit Hypr"),
        ("SUPER+M", "Alacritty",     "SUPER+B",   "Browser"),
        ("SUPER+L/H", "Focus L/R",   "SUPER+P",   "Pseudo Mode"),
        ("SUPER+S", "Screenshot",    "SUPER+N",   "Files"),
        ("SUPER+W", "Waybar Reset",  "SUPER+DEL", "Power Menu"),
        ("F1-F4",   "Audio/Mic",     "F11/F12",   "Luminosidade")
    ]
    print("\033[1;35m?? HYPRLAND QUICK HELP\033[0m\n")
    for i, row in enumerate(help_data):
        if i == 0:
            print(f"\033[1;4;37m{row[0]:<28}  {row[1]:<28}\033[0m")
            continue
        l = f"\033[33m{row[0]:<10}\033[0m \033[36m?? {row[1]:<14}\033[0m"
        r = f"\033[33m{row[2]:<10}\033[0m \033[32m?? {row[3]:<14}\033[0m"
        print(f"{l}  {r}")
    input("\n\033[90mPremi INVIO per tornare...\033[0m")

def main_loop():
    while True:
        os.system('clear')
        subprocess.run(["fastfetch", "--logo-type", "kitty", "--logo-width", "30", "--logo-height", "15"])
        print(get_sys_info())
        print("\n\033[1;33m[q]\033[0m Esci  |  \033[1;32m[h]\033[0m Help Keybindings")
        
        # Uso input() standard per evitare conflitti con la shell (zsh)
        choice = input().strip().lower()
        if choice == 'q':
            break
        elif choice == 'h':
            show_help()

if __name__ == "__main__":
    if os.environ.get("TERM") != "xterm-kitty":
        # Lancio Kitty con i parametri corretti per la regola
        subprocess.run(['kitty', '--class', 'floating_term', '--title', 'Arch Info', 'python3', __file__])
    else:
        main_loop()
