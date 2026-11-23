#!/bin/sh
# Menyusun aturan nftables untuk cportal (tabel sendiri: inet cportal)
. /lib/functions.sh

NFT=/usr/sbin/nft
STATE=/tmp/cportal
RULES=$STATE/rules.nft
IFACES=""
WL=""

add_if() {
	case "$1" in
		''|*[!A-Za-z0-9._-]*) logger -t cportal "interface tidak valid: $1"; return ;;
	esac
	IFACES="${IFACES:+$IFACES, }\"$1\""
}

add_wl() {
	local mac
	config_get mac "$1" mac
	mac=$(echo "$mac" | tr 'A-F' 'a-f')
	if echo "$mac" | grep -Eq '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'; then
		WL="${WL:+$WL, }$mac"
	else
		logger -t cportal "MAC whitelist tidak valid: $mac"
	fi
}

up() {
	local port
	mkdir -p "$STATE"
	config_load cportal
	config_get port main portal_port 2050
	config_list_foreach main interface add_if
	config_foreach add_wl whitelist

	if [ -z "$IFACES" ]; then
		logger -t cportal "tidak ada interface di /etc/config/cportal"
		return 1
	fi

	cat > "$RULES" <<EOF
add table inet cportal
add set inet cportal whitelist { type ether_addr; }
add set inet cportal authed { type ether_addr; flags timeout; }
add chain inet cportal prerouting { type nat hook prerouting priority -101; policy accept; }
add chain inet cportal forward { type filter hook forward priority -1; policy accept; }
flush set inet cportal whitelist
flush chain inet cportal prerouting
flush chain inet cportal forward
add rule inet cportal prerouting iifname { $IFACES } ether saddr @whitelist return
add rule inet cportal prerouting iifname { $IFACES } ether saddr @authed return
add rule inet cportal prerouting iifname { $IFACES } fib daddr type local return
add rule inet cportal prerouting iifname { $IFACES } tcp dport 80 redirect to :$port
add rule inet cportal forward iifname { $IFACES } ether saddr @whitelist accept
add rule inet cportal forward iifname { $IFACES } ether saddr @authed accept
add rule inet cportal forward iifname { $IFACES } meta l4proto tcp reject with tcp reset
add rule inet cportal forward iifname { $IFACES } drop
EOF
	[ -n "$WL" ] && echo "add element inet cportal whitelist { $WL }" >> "$RULES"

	"$NFT" -f "$RULES"
}

down() {
	"$NFT" delete table inet cportal 2>/dev/null
	rm -rf "$STATE"
	return 0
}

case "$1" in
	up) up ;;
	down) down ;;
	*) echo "usage: $0 up|down" >&2; exit 1 ;;
esac
