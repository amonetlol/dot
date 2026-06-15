#!/usr/bin/env bash

#dir="$HOME/.config/rofi/cliphist"
dir="$HOME/.config/hypr/hypr-rox-vmware/.config/rofi/cliphist"
theme='theme'

## Run
rofi -modi clipboard:$dir/cliphist-img.sh -show clipboard -theme ${dir}/${theme}.rasi
