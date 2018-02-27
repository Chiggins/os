#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "1920 or 3200"
fi

if [ "$1" == "3200" ]; then
    if grep -q "Arch" /etc/issue; then
        xrandr --newmode "3200x1800_60.00"  492.00  3200 3456 3800 4400  1800 1803 1808 1865 -hsync +vsync
        xrandr --addmode Virtual-1 "3200x1800_60.00"
        xrandr --output Virtual-1 --mode "3200x1800_60.00"
        sed -e '/^!.*dpi/s/^!//' -i ~/.Xresources
        xrdb ~/.Xresources
        feh --bg-scale --randomize ~/.wallpapers/
        killall polybar
    elif grep -q "Kali" /etc/issue; then
        gsettings set org.gnome.desktop.interface scaling-factor 2
    else
        echo "Not supported"
    fi
elif [ "$1" == "1920" ]; then
    if grep -q "Arch" /etc/issue; then
        xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
        xrandr --addmode Virtual-1 "1920x1080_60.00"
        xrandr --output Virtual-1 --mode "1920x1080_60.00"
        sed -e '/dpi/ s/^!*/!/' -i ~/.Xresources
        xrdb ~/.Xresources
        feh --bg-scale --randomize ~/.wallpapers/
        killall polybar
    elif grep -q "Kali" /etc/issue; then
        gsettings set org.gnome.desktop.interface scaling-factor 1
    else
        echo "Not supported"
    fi
fi


