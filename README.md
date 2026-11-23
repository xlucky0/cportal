# cportal

Captive portal ringan untuk **OpenWrt 25.12** (apk, fw4/nftables). Dibuat dari nol, tanpa OpenNDS/Nodogsplash.

## Fitur

- **Whitelist MAC**: perangkat tertentu langsung konek tanpa halaman login.
- **Akun user:password** dengan durasi per akun (contoh `admin/admin` 60 menit, `user/user` 60 menit).
- **Hint di halaman login**: akun dengan `show_hint '1'` ditampilkan kredensial dan durasinya.
- **Cooldown** opsional: perangkat yang sama baru boleh login ulang dengan akun itu setelah N menit.
- Batas percobaan salah (5x per menit per perangkat).
- Semua pengaturan di `/etc/config/cportal`, tanpa dependency berat (uhttpd + ucode + nft).

## Cara kerja

- Tabel nftables sendiri `inet cportal` (tidak mengubah fw4).
- Klien yang belum login: HTTP (80) dialihkan ke portal di port 2050, trafik lain ke internet di-drop (HTTPS di-reset agar cepat gagal). DNS ke router tetap jalan.
- Login sukses: MAC klien dimasukkan ke set `authed` dengan `timeout`, nftables menghapusnya otomatis saat habis.

## Pasang (uji coba)

```sh
./deploy.sh 192.168.1.1
```

Atau build paket `.apk` dengan SDK OpenWrt 25.12: taruh folder ini di `package/cportal`, lalu `make package/cportal/compile`.

## Konfigurasi

```
config global 'main'
	option enabled '1'
	list interface 'br-lan'      # device yang dikunci
	option portal_port '2050'
	option title 'WiFi Gratis'
	option message 'Silakan login untuk mengakses internet.'

config whitelist
	option name 'HP Bapak'
	option mac 'AA:BB:CC:DD:EE:FF'

config account
	option username 'user'
	option password 'user'
	option duration '60'         # menit, 0 = tanpa batas
	option cooldown '0'
	option show_hint '1'
```

Terapkan perubahan: `/etc/init.d/cportal reload` (sesi login aktif tidak terputus).

## Perintah

```
cportalctl status             # whitelist + sesi aktif
cportalctl grant MAC [menit]  # akses sementara manual
cportalctl kick MAC           # putus sesi
cportalctl allow MAC [nama]   # whitelist permanen
cportalctl deny MAC           # hapus whitelist
```

## Catatan

- Port portal harus bisa diakses dari jaringan yang dikunci (zone lan biasanya sudah ACCEPT; untuk zone guest tambahkan rule input TCP 2050).
- Password disimpan plaintext di UCI. Cocok untuk akun tamu, jangan pakai password penting.
- Hanya IPv4 yang dialihkan ke portal. IPv6 klien belum login tetap diblok.
- Status: v0.1, belum diuji di perangkat. Ide berikutnya: halaman LuCI, voucher sekali pakai, kuota.

## Lisensi

MIT
