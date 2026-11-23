#!/bin/sh
# Pasang langsung ke router untuk uji coba (tanpa build paket).
# pemakaian: ./deploy.sh [ip-router]
set -e
R=${1:-192.168.1.1}

ssh "root@$R" 'apk add ucode ucode-mod-fs ucode-mod-uci uhttpd; [ -f /etc/config/cportal ] && cp /etc/config/cportal /tmp/cportal.bak || true'
tar -C files -cf - . | ssh "root@$R" 'tar -C / -xf -'
ssh "root@$R" '
chmod +x /etc/init.d/cportal /usr/libexec/cportal/nft.sh /usr/sbin/cportalctl /usr/share/cportal/www/cgi-bin/portal
[ -f /tmp/cportal.bak ] && mv /tmp/cportal.bak /etc/config/cportal
/etc/init.d/cportal enable
/etc/init.d/cportal restart
'
echo "selesai. edit /etc/config/cportal lalu: /etc/init.d/cportal reload"
