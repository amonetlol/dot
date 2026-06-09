#!/usr/bin/env bash

## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)

dir="$HOME/.dotfiles/rofi/.config/rofi/rofi-catppuccin"
theme='theme'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
