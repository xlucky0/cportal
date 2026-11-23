include $(TOPDIR)/rules.mk

PKG_NAME:=cportal
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=xlucky0

include $(INCLUDE_DIR)/package.mk

define Package/cportal
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Captive portal ringan (nftables + UCI + ucode)
  DEPENDS:=+firewall4 +uhttpd +ucode +ucode-mod-fs +ucode-mod-uci
  PKGARCH:=all
endef

define Package/cportal/description
  Captive portal untuk OpenWrt 25.12: whitelist MAC tanpa login,
  akun user:password dengan batas waktu, dan petunjuk login di halaman.
endef

define Package/cportal/conffiles
/etc/config/cportal
endef

define Build/Compile
endef

define Package/cportal/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/libexec/cportal $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/cportal/www/cgi-bin
	$(INSTALL_CONF) ./files/etc/config/cportal $(1)/etc/config/cportal
	$(INSTALL_BIN) ./files/etc/init.d/cportal $(1)/etc/init.d/cportal
	$(INSTALL_BIN) ./files/usr/libexec/cportal/nft.sh $(1)/usr/libexec/cportal/nft.sh
	$(INSTALL_BIN) ./files/usr/sbin/cportalctl $(1)/usr/sbin/cportalctl
	$(INSTALL_BIN) ./files/usr/share/cportal/www/cgi-bin/portal $(1)/usr/share/cportal/www/cgi-bin/portal
endef

define Package/cportal/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/cportal enable
exit 0
endef

$(eval $(call BuildPackage,cportal))
