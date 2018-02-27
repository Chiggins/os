#!/bin/bash
# Chiggins bootstrap script for Kali
# Based off of https://github.com/Raikia/os-scripts along with plenty of
# personal modifications

# Change some keybindings if we're using an Apple keyboard or not
appleKeyboard=false

# Timezone
timezone="America/Chicago"

# (Cosmetic) Colour output
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

# Setup some basic functins
print_good () {
    echo -e "${GREEN}[+]${RESET} $1"
}

print_bad () {
    echo -e "${RED}[!]${RESET} $1"
}

print_caution () {
    echo -e "${YELLOW}[*]${RESET} $1"
}

print_info () {
    echo -e "${BLUE}[>]${RESET} $1"
}

install () {
    apt -qq -y install $* \
      || print_bad "Error installing $1"
}

# GNOME changes
print_info "GNOME changes"
## Disable upgrade notification
timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-format 12h

## Disable screensaver
xset s 0 0
xset s off
echo "xset s off" >> /root/.xinitrc
gsettings set org.gnome.desktop.session idle-delay 0

# Make sure we have internet access
print_info "Verifying internet access"
for i in {1..10}; do ping -c 1 -W ${i} www.google.com &>/dev/null && break; done
if [[ "$?" -ne 0 ]]; then
    print_bad "Cannot access internet"
    exit 1
fi

# Grab wallpaper and set
wget -q https://i.imgur.com/ybtytfq.jpg -O /root/Pictures/wallpaper.jpg
gsettings set org.gnome.desktop.background picture-uri file:///root/Pictures/wallpaper.jpg

# Are we in a VM?
print_info "VM check"
## Only going to check VMware because who uses VirtualBox?
if (dmidecode | grep -iq vmware); then
    print_info "VMware"
    install open-vm-tools-desktop make

    # Setup shared folders
    file=/usr/local/sbin/mount-shared-folders; [ -e "${file}" ] && cp -n $file{,.backup}
    cat <<EOF > "${file}" \
#!/bin/bash

vmware-hgfsclient | while read folder; do
    echo "[i] Mounting \${folder}   (/mnt/hgfs/\${folder})"
    mkdir -p "/mnt/hgfs/\${folder}"
    umount -f "/mnt/hgfs/\${folder}" 2>/dev/null
    vmhgfs-fuse -o allow_other -o auto_unmount ".host:/\${folder}" "/mnt/hgfs/\${folder}"
done

sleep 2s
EOF
    chmod +x "${file}"
    ln -sf "${file}" /root/Desktop/mount-shared-folders.sh
fi

# Change location settings
print_info "Configurating location"
## Apple Keyboard
if [[ -n "${appleKeyboard}" ]]; then
    file=/etc/default/keyboard;
    sed -i 's/XKBVARIANT=".*"/XKBVARIANT="mac"/' "${file}"
fi

## Set timezone to Chicago as the default
echo $timezone > /etc/timezone
ln -sf "/usr/share/zoneinfo/$(cat /etc/timezone)" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata > /dev/null

## install and configure NTP
print_info "Configuring NTP"
install ntp ntpdate
ntpdate -b -s -u pool.ntp.org
systemctl restart ntp
#systemctl disable ntp 2>/dev/null

# Running upgrade on everything currently installed
# Also cleaning up whatever can be removed
print_info "Running full system upgrade and cleanup"
export DEBIAN_FRONTEN=noninteractive
apt -qq -y autoremove || print_bad "Error running first autoremove"
apt -qq update && APT_LIST_CHANGES_FRONTEND=none apt -qq -o Dpkg::Options::="--force-confnew" -y dist-upgrade --fix-missing \
    || print_bad "Error performing the mass OS upgrade"
apt -qq -y autoremove || print_bad "Error running second autoremove"

# Install Linux headers and build tools
print_info "Installing Linux headers and build tools"
install make gcc linux-headers-$(uname -r)

# Kali Linux full
print_info "Install the full Kali Linux meta-package if it isn't already installed"
install kali-linux-full

# Run upgrade and then install some software
print_info "Installing other specified software"
apt -qq -y install zsh ctags shutter bless htop tmux crackmapexec docker docker-compose \
    libldns-dev freerdp-x11 unzip curl firefox-esr exe2hexbat msfpc wdiff \
    wdiff-doc vbindiff virtualenvwrapper golang wireshark libreoffice \
    shutter psmisc htop pwgen ca-certificates testssl.sh windows-binaries \
    ncftp hashid wafw00f pixiewps bully wifite gobuster stunnel gcc \
    gcc-multilib g++ mingw-w64 veil-evasion responder

# Setup firefox
print_info "Setting up Firefox"

# Configure firefox
timeout 25 firefox >/dev/null 2>&1                # Start and kill. Files needed for first time run
timeout 15 killall -9 -q -w firefox-esr >/dev/null
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)
[ -e "${file}" ] \
  && cp -n $file{,.bkup}   #/etc/firefox-esr/pref/*.js
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's/^.network.proxy.socks_remote_dns.*/user_pref("network.proxy.socks_remote_dns", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("network.proxy.socks_remote_dns", true);' >> "${file}"
sed -i 's/^.browser.safebrowsing.enabled.*/user_pref("browser.safebrowsing.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.malware.enabled.*/user_pref("browser.safebrowsing.malware.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.malware.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.remoteLookups.enabled.*/user_pref("browser.safebrowsing.remoteLookups.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.remoteLookups.enabled", false);' >> "${file}"
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.startup.page", 0);' >> "${file}"
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> "${file}"
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.showQuitWarning", true);' >> "${file}"
sed -i 's/^.*extensions.https_everywhere._observatory.popup_shown.*/user_pref("extensions.https_everywhere._observatory.popup_shown", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("extensions.https_everywhere._observatory.popup_shown", true);' >> "${file}"
sed -i 's/^.network.security.ports.banned.override/user_pref("network.security.ports.banned.override", "1-65455");' "${file}" 2>/dev/null \
  || echo 'user_pref("network.security.ports.banned.override", "1-65455");' >> "${file}"
#--- Replace bookmarks (base: http://pentest-bookmarks.googlecode.com)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit)
[ -e "${file}" ] \
  && cp -n $file{,.bkup}   #/etc/firefox-esr/profile/bookmarks.html
timeout 300 curl --progress -k -L -f "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pentest-bookmarks/bookmarksv1.5.html" > /tmp/bookmarks_new.html \
  || print_bad "Issue downloading bookmarks_new.html" #***!!! hardcoded version! Need to manually check for updates
#--- Configure bookmarks
#awk '!a[$0]++' /tmp/bookmarks_new.html \
#  | \egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" \
#  | \egrep -v "^    </DL><p>" \
#  | \egrep -v "^<DD>Add" > "${file}"
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n</DL><p>#' "${file}"                                          # Fix import issues from pentest-bookmarks...
sed -i 's#^    <DL><p>#    <DL><p>\n    <DT><A HREF="http://127.0.0.1/">localhost</A>#' "${file}"                 # Add localhost to bookmark toolbar (before hackery folder)
sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>\n</DL><p>#' "${file}"                    # Add Nessus UI bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1:3000/ui/panel">BeEF</A>\n</DL><p>#' "${file}"               # Add BeEF UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>\n</DL><p>#' "${file}"                       # Add RIPs to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://paulschou.com/tools/xlate/">XLATE</A>\n</DL><p>#' "${file}"          # Add XLATE to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://hackvertor.co.uk/public">HackVertor</A>\n</DL><p>#' "${file}"        # Add HackVertor to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://www.irongeek.com/skiddypad.php">SkiddyPad</A>\n</DL><p>#' "${file}"   # Add Skiddypad to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://www.exploit-db.com/search/">Exploit-DB</A>\n</DL><p>#' "${file}"     # Add Exploit-DB to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://offset-db.com/">Offset-DB</A>\n</DL><p>#' "${file}"                   # Add Offset-DB to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://shell-storm.org/shellcode/">Shelcodes</A>\n</DL><p>#' "${file}"       # Add Shelcodes to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://ropshell.com/">ROP Shell</A>\n</DL><p>#' "${file}"                    # Add ROP Shell to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://ifconfig.io/">ifconfig</A>\n</DL><p>#' "${file}"                     # Add ifconfig.io to bookmark toolbar
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' "${file}"
#--- Clear bookmark cache
find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name "places.sqlite" -delete
find ~/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete

## Setup firefox's plugins
print_info "Installing ${GREEN}firefox's plugins${RESET} ~ useful addons"
## Configure firefox
## Download extensions
ffpath="$(find ~/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -name '*.default*' -print -quit)/extensions"
[ "${ffpath}" == "/extensions" ] \
  && echo -e ' '${RED}'[!]'${RESET}" Couldn't find Firefox folder" 1>&2
mkdir -p "${ffpath}/"
#--- plug-n-hack
#curl --progress -k -L -f "https://github.com/mozmark/ringleader/blob/master/fx_pnh.xpi?raw=true????????????????"  \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'plug-n-hack' 1>&2
#--- HttpFox
#curl --progress -k -L -f "https://addons.mozilla.org/en-GB/firefox/addon/httpfox/??????????????"  \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HttpFox' 1>&2
#--- SQLite Manager
echo -n '[1/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/SQLiteManager@mrinalkant.blogspot.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'SQLite Manager'" 1>&2
#--- Cookies Manager+
echo -n '[2/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Cookies Manager+'" 1>&2
#--- Firebug
echo -n '[3/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/firebug@software.joehewitt.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Firebug'" 1>&2
#--- FoxyProxy Basic
echo -n '[4/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/foxyproxy-basic@eric.h.jung.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'FoxyProxy Basic'" 1>&2
#--- User Agent Overrider
echo -n '[5/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/useragentoverrider@qixinglu.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'User Agent Overrider'" 1>&2
#--- HTTPS Everywhere
echo -n '[6/11]'; timeout 300 curl -S -k -L -f "https://www.eff.org/files/https-everywhere-latest.xpi" \
  -o "${ffpath}/https-everywhere@eff.org.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HTTPS Everywhere'" 1>&2
#--- Live HTTP Headers
echo -n '[7/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Live HTTP Headers'" 1>&2
#---Tamper Data
echo -n '[8/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/966/addon-966-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Tamper Data'" 1>&2
#--- Disable Add-on Compatibility Checks
echo -n '[9/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/check-compatibility@dactyl.googlecode.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Disable Add-on Compatibility Checks'" 1>&2
#--- Disable HackBar
echo -n '[10/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3899/addon-3899-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{F5DDF39C-9293-4d5e-9AA8-E04E6DD5E9B4}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HackBar'" 1>&2
#--- uBlock
echo -n '[11/11]'; timeout 300 curl -S -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/607454/addon-607454-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'uBlock'" 1>&2
#--- Installing extensions
for FILE in $(find "${ffpath}" -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename "${FILE}" .xpi)"
  mkdir -p "${ffpath}/${d}/"
  unzip -q -o -d "${ffpath}/${d}/" "${FILE}"
  rm -f "${FILE}"
done
#--- Enable Firefox's addons/plugins/extensions
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 3s
#--- Method #1 (Works on older versions)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #1 - extensions.sqlite)"
  apt -y -qq install sqlite3 \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
  rm -f /tmp/firefox.sql
  touch /tmp/firefox.sql
  echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/firefox.sql    # Force them all!
  sqlite3 "${file}" < /tmp/firefox.sql      #fuser extensions.sqlite
fi
#--- Method #2 (Newer versions)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #2 - extensions.json)"
  sed -i 's/"active":false,/"active":true,/g' "${file}"                # Force them all!
  sed -i 's/"userDisabled":true,/"userDisabled":false,/g' "${file}"    # Force them all!
fi
#--- Remove cache
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
[ -n "${file}" ] \
  && sed -i '/extensions.installCache/d' "${file}"
#--- For extensions that just work without restarting
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 3s
#--- For (most) extensions, as they need firefox to restart
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 5s
#--- Wipe session (due to force close)
find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Configure foxyproxy
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -z "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}' Something went wrong with the FoxyProxy firefox extension (did any extensions install?). Skipping...' 1>&2
else     # Create new
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="false" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > "${file}"
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> "${file}"
  echo -e '</proxies></foxyproxy>' >> "${file}"
fi

# Install Burp Suite
print_info "Installing ${GREEN}Burp Suite (Community Edition)${RESET} ~ web application proxy"
mkdir -p ~/.java/.userPrefs/burp/
file=~/.java/.userPrefs/burp/prefs.xml;   #[ -e "${file}" ] && cp -n $file{,.bkup}
[ -e "${file}" ] \
|| cat <<EOF > "${file}"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd" >
<map MAP_XML_VERSION="1.0">
  <entry key="eulafree" value="2"/>
  <entry key="free.suite.feedbackReportingEnabled" value="false"/>
</map>
EOF
#--- Extract CA
find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
# export DISPLAY=:0.0
timeout 120 burpsuite >/dev/null 2>&1 &
PID=$!
sleep 15s
#echo "-----BEGIN CERTIFICATE-----" > /tmp/PortSwiggerCA \
#  && awk -F '"' '/caCert/ {print $4}' ~/.java/.userPrefs/burp/prefs.xml | fold -w 64 >> /tmp/PortSwiggerCA \
#  && echo "-----END CERTIFICATE-----" >> /tmp/PortSwiggerCA
export http_proxy="http://127.0.0.1:8080"
rm -f /tmp/burp.crt
while test -d /proc/${PID}; do
sleep 1s
curl --progress -k -L -f "http://burp/cert" -o /tmp/burp.crt 2>/dev/null      # || echo -e ' '${RED}'[!]'${RESET}" Issue downloading burp.crt" 1>&2
[ -f /tmp/burp.crt ] && break
done
timeout 5 kill ${PID} 2>/dev/null \
|| echo -e ' '${RED}'[!]'${RESET}" Failed to kill ${RED}burpsuite${RESET}"
unset http_proxy
#--- Installing CA
if [[ -f /tmp/burp.crt ]]; then
apt -y -qq install libnss3-tools \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
folder=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
certutil -A -n Burp -t "CT,c,c" -d "${folder}" -i /tmp/burp.crt
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
#mkdir -p /usr/share/ca-certificates/burp/
#cp -f /tmp/burp.crt /usr/share/ca-certificates/burp/
#dpkg-reconfigure ca-certificates    # Not automated
echo -e " ${YELLOW}[i]${RESET} Installed ${YELLOW}Burp Suite CA${RESET}"
else
echo -e ' '${RED}'[!]'${RESET}' Did not install Burp Suite Certificate Authority (CA)' 1>&2
echo -e ' '${RED}'[!]'${RESET}' Skipping...' 1>&2
fi
#--- Remove old temp files
sleep 2s
find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete 2>/dev/null
find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
unset http_proxy

# Configure Wireshark
print_info "Configure Wireshark"
mkdir -p ~/.wireshark/
file=~/.wireshark/recent_common;
[ -e "${file}" ] \
    || echo "privs.warn_if_elevated: FALSE" > "${file}"
[ -e "/usr/share/wireshark/init.lua" ] \
    %% mv -f /usr/share/wireshark/init.lua{,.disabled}

# Configure ZSH
print_info "Configuring ZSH"
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
if [ -d ~/.zshrc ]
then
    rm ~/.zshrc
fi
wget https://github.com/Chiggins/DotFiles/raw/master/zsh/.zshrc -O ~/.zshrc --no-check-certificate
wget https://github.com/Chiggins/DotFiles/raw/master/zsh/chiggins.zsh-theme -O ~/.oh-my-zsh/themes/chiggins.zsh-theme --no-check-certificate
chsh -s /bin/zsh

# Configure VIM
print_info "Configuring VIM"
echo 'runtime vimrc' > ~/.vimrc
if [ ! -d ~/.vim ]
then
    mkdir ~/.vim
fi
git clone -q https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/vundle
wget -q https://github.com/Chiggins/DotFiles/raw/master/vim/vimrc -O ~/.vimrc --no-check-certificate
vim +PluginInstall +qall

# Configure tmux
print_info "Configure tmux"
wget -q https://raw.githubusercontent.com/Chiggins/DotFiles/master/tmux/.tmux.conf -O ~/.tmux.conf --no-check-certificate

# Wordlist stuff
[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt

###
# Custom tool installations
###

# UACScript
print_info "Installing UACScript"
git clone -q https://github.com/Vozzie/uacscript.git /opt/uacscript-git/
pushd /opt/uacscript-git/ > /dev/null
git pull -q
popd >/dev/null
ln -sf /usr/share/windows-binaries/uac-win7 /opt/uacscript-git/

# Asciinema - Used to record terminal
curl -s -L https://asciinema.org/install | sh

# Discover - Used to automating tasks
print_info "Installing Discover"
git clone -q https://github.com/leebaird/discover /opt/discover/
ln -s /opt/discover/discover.sh /usr/bin/discover

# domain - Better used to find domain names for a website
print_info "Installing Domain"
git clone -q https://github.com/jhaddix/domain /tmp/domain/
pushd /tmp/domain/ > /dev/null
echo "/opt/enumall/" | ./setup_enumall.sh
pip install -qr /opt/enumall/altdns/requirements.txt
pip install -qr /opt/enumall/recon-ng/REQUIREMENTS
ln -s /opt/enumall/domain/enumall.py /usr/bin/enumall
popd > /dev/null

# Sublist3r
print_info "Installing sublist3r"
git clone -q https://github.com/aboul3la/Sublist3r.git /opt/sublist3r/
pip install -qr /opt/sublist3r/requirements.txt
ln -s /opt/sublist3r/sublist3r.py /usr/bin/sublist3r
chmod +x /usr/bin/sublist3r

# MassDNS
print_info "Installing MassDNS"
git clone -q https://github.com/blechschmidt/massdns.git /opt/massdns
pushd /opt/massdns/ > /dev/null
make
ln -s /opt/massdns/bin/massdns /usr/bin/massdns
ln -s /opt/massdns/subbrute.py /usr/bin/subbrute
popd > /dev/null

# Parameth
print_info "Installing Parameth"
git clone -q https://github.com/mak-/parameth.git /opt/parameth/
ln -s /opt/parameth/parameth.py /usr/bin/parameth

# TPLMap
print_info "Installing TPLMap"
git clone -q https://github.com/epinna/tplmap.git /opt/tplmap/
ln -s /opt/tplmap/tplmap.py /usr/bin/tplmap

# Powershell Empire
print_info "Installing Powershell Empire"
git clone -q https://github.com/EmpireProject/Empire /opt/empire/
pushd /opt/empire/setup/ > /dev/null
./install.sh
echo "IyEvYmluL2Jhc2gKcHVzaGQgL29wdC9lbXBpcmUvICYmIC4vZW1waXJlIC0tcmVzdCAtLXVzZXJuYW1lIHVzZXIgLS1wYXNzd29yZCBwYXNzICYmIHBvcGQK" | base64 -d > /usr/bin/empire && chmod +x /usr/bin/empire
popd > /dev/null

# DeathStar
print_info "Installing DeathStar"
git clone -q https://github.com/byt3bl33d3r/DeathStar /opt/deathstar/
pip install -qr /opt/deathstar/requirements.txt

# EyeWitness
print_info "Installing EyeWitness"
git clone -q https://github.com/ChrisTruncer/EyeWitness /opt/eyewitness/
pushd /opt/eyewitness/setup/ > /dev/null
./setup.sh
popd > /dev/null

# Win Payloads
print_info "Installing WindPayloads"
git clone -q https://github.com/nccgroup/Winpayloads.git /opt/winpayloads
pushd /opt/winpayloads/ > /dev/null
chmod +x setup.sh
#./setup.s
popd > /dev/null

# DomainHunter
git clone -q https://github.com/threatexpress/domainhunter.git /opt/domainhunter
pip install -qr /opt/domainhunter/requirements.txt

##########
# Scripts to have locally

# MailSniper
print_info "Grabbing MailSniper"
mkdir -p ~/scripts/
wget -q https://raw.githubusercontent.com/dafthack/MailSniper/master/MailSniper.ps1 -O ~/scripts/MailSniper.ps1

# PowerSploit
git clone -q -b master https://github.com/PowerShellMafia/PowerSploit.git ~/scripts/PowerSploit-master/
git clone -q -b dev https://github.com/PowerShellMafia/PowerSploit.git ~/scripts/PowerSploit-dev/


# Stuff for Cobalt Strike
print_info "Cobalt Strike"
print_info "Java"
JDK_LINK=$(curl -s "http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html" | grep 'linux-x64.tar.gz' | head -n 1 | awk -F, '{print $3}' | awk -F'":' '{print $2}' | tr -d '"')
timeout 300 wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$JDK_LINK" -O /opt/jdk.tar.gz
tar -xzf /opt/jdk.tar.gz -C /opt/
JDK_DIR=$(ls -a /opt/ | grep jdk | head -n 1)
update-alternatives --install /usr/bin/java java /opt/$JDK_DIR/bin/java 1 > /dev/null
update-alternatives --install /usr/bin/javac javac /opt/$JDK_DIR/bin/javac 1 > /dev/null
update-alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so /opt/$JDK_DIR/jre/lib/amd64/libnpjp2.so 1 > /dev/null
update-alternatives --set java /opt/$JDK_DIR/bin/java > /dev/null
update-alternatives --set javac /opt/$JDK_DIR/bin/javac > /dev/null
update-alternatives --set mozilla-javaplugin.so /opt/$JDK_DIR/jre/lib/amd64/libnpjp2.so > /dev/null
rm -f /opt/jdk.tar.gz

print_info "Malleable C2"
mkdir -p /opt/cobaltstrike/malleable_c2/
git clone -q -b master https://github.com/rsmudge/Malleable-C2-Profiles.git /opt/cobaltstrike/malleable_c2/
pushd /opt/cobaltstrike/malleable_c2/ >/dev/null
git pull -q
popd >/dev/null

print_info "Various CS Scripts"
mkdir -p /opt/cs_scripts/cobaltstrike_toolkit/
git clone -q -b master https://github.com/killswitch-GUI/CobaltStrike-ToolKit.git /opt/cs_scripts/cobaltstrike_toolkit/
pushd /opt/cs_scripts/cobaltstrike_toolkit/ >/dev/null
git pull -q
popd >/dev/null
mkdir -p /opt/cs_scripts/kickass_bot/
git clone -q -b master https://github.com/kussic/CS-KickassBot.git /opt/cs_scripts/kickass_bot/
pushd /opt/cs_scripts/kickass_bot/ >/dev/null
git pull -q
popd >/dev/null
mkdir -p /opt/cs_scripts/persistence_aggressor_scripts/
git clone -q -b master https://github.com/ZonkSec/persistence-aggressor-script.git /opt/cs_scripts/persistence_aggressor_scripts/
pushd /opt/cs_scripts/persistence_aggressor_scripts/ >/dev/null
git pull -q
popd >/dev/null
mkdir -p /opt/cs_scripts/harleyqu1nn_aggressor_scripts/
git clone -q -b master https://github.com/harleyQu1nn/AggressorScripts.git /opt/cs_scripts/harleyqu1nn_aggressor_scripts/
pushd /opt/cs_scripts/harleyqu1nn_aggressor_scripts/ > /dev/null
git pull -q
popd >/dev/null
mkdir -p /opt/cs_scripts/ramen0x3f_scripts/
git clone -q -b master https://github.com/ramen0x3f/AggressorScripts.git /opt/cs_scripts/ramen0x3f_scripts/
pushd /opt/cs_scripts/ramen0x3f_scripts/ > /dev/null
git pull -q
popd >/dev/null

# Remove this script
print_info "Need to run setup.sh in /opt/winpayloads/"
print_good "Install finished!"
print_caution "Removing this script"
rm kali.sh
