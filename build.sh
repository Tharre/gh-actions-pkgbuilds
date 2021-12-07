#!/bin/bash -e

CHROOT=/buildchroot

for dir in $(aur-graph */.SRCINFO | tsort | tac); do
	pushd "$dir" > /dev/null

	# directory may also reference the pkgbase, in which case test if the
	# first package in pkgname is up to date
	remotever="$(expac -S1 "%v" "custom/$dir" || expac -S1 "%v" "custom/$(source PKGBUILD; printf %s "$pkgname")" || echo NONE)"

	if [ $(vercmp "$remotever" $(source PKGBUILD; printf %s "${epoch:-0}:$pkgver-$pkgrel")) -lt 0 ]; then
		echo "=== Creating build chroot ==="
		if [ ! -d "$CHROOT" ]; then
			mkdir $CHROOT
			mkarchroot -C /etc/pacman.conf $CHROOT/root base-devel
		fi

		echo "=== Building $dir ==="
		makechrootpkg -c -u -U build -D /repository -r "$CHROOT"

		sudo -u build SRCDEST=/tmp makepkg --packagelist | while IFS="" read -r pkg
		do
			repo-add -s /repository/custom.db.tar.gz "$pkg"
			gpg --detach-sign "$pkg"
		done
	fi
	popd > /dev/null
done
