#!/bin/bash -e

CHROOT=/buildchroot

for dir in $(aur-graph */.SRCINFO | tsort | tac); do
	pushd "$dir" > /dev/null

	# directory may also reference the pkgbase, in which case test if the
	# first package in pkgname is up to date
	remotever="$(expac -S1 "%v" "custom/$dir" || expac -S1 "%v" "custom/$(source PKGBUILD; printf %s "$pkgname")" || echo NONE)"

	# TODO: there should be EPOCH in here somewhere
	if [ $(vercmp "$remotever" $(source PKGBUILD; printf %s "$pkgver-$pkgrel")) -lt 0 ]; then
		echo "=== Building $dir ==="
		makechrootpkg -c -u -U build -D /repository -r "$CHROOT"
		repo-add -s /repository/custom.db.tar.gz *.pkg.tar*
		mv *.pkg.tar* /repository/
	fi
	popd > /dev/null
done
