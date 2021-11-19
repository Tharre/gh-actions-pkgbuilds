#!/bin/bash -e

CHROOT=/github/home/chroot

for dir in $(aur graph */.SRCINFO | tsort | tac); do
	echo testing "$dir"

	pushd "$dir" > /dev/null

	# directory may also reference the pkgbase, in which case test if the
	# first package in pkgname is up to date
	remotever="$(expac -S1 "%v" "custom/$dir" || expac -S1 "%v" "custom/$(source PKGBUILD; printf %s "$pkgname")" || echo NONE)"
	echo DEBUG: $remotever

	# TODO: there should be EPOCH in here somewhere
	if [ $(vercmp "$remotever" $(source PKGBUILD; printf %s "$pkgver-$pkgrel")) -lt 0 ]; then
		echo "=== Building $dir ==="
		makechrootpkg -c -r "$CHROOT"
		#aur build -c -r /home/build/custom -d custom -- --noprogressbar
	fi
	popd > /dev/null
done
