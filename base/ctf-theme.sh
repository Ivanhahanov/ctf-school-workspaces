#!/bin/bash
# Applied via XFCE4 autostart after session is ready
sleep 3

# GTK + window manager dark theme
xfconf-query -c xsettings -p /Net/ThemeName         -s "Arc-Dark"
xfconf-query -c xsettings -p /Net/IconThemeName     -s "Papirus-Dark"
xfconf-query -c xsettings -p /Gtk/FontName          -s "Hack 10"
xfconf-query -c xfwm4     -p /general/theme         -s "Arc-Dark"
xfconf-query -c xfwm4     -p /general/title_font    -s "Hack Bold 9"
xfconf-query -c xfwm4     -p /general/use_compositing -t bool -s false

# Desktop icons — show launcher/file icons (style 2), proper size, hide "File System"
xfconf-query -c xfce4-desktop -p /desktop-icons/style                         -t int  -s 2 --create
xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size                     -t uint -s 52 --create
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem    -t bool -s false --create
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home          -t bool -s true --create
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash         -t bool -s false --create
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable     -t bool -s false --create

# Wallpaper
for path in \
  "/backdrop/screen0/monitorVNC-0/workspace0" \
  "/backdrop/screen0/monitor0/workspace0"; do
    xfconf-query -c xfce4-desktop -p "${path}/image-style" -t int    -s 5 --create 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p "${path}/last-image"  -t string -s "/etc/ctf-wallpaper.png" --create 2>/dev/null || true
done
xfdesktop --reload 2>/dev/null || true
