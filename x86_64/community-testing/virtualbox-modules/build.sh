#!/bin/bash
# lazyness can be enhanced everyday

usage() {
  echo "usage: $0 extra"
  echo "       $0 testing"
  exit 1
}

# $1: reference package
update() {
  url="https://www.archlinux.org/packages/$1/x86_64/$2/"
  curkernel=$(wget -qO- "$url"|sed -nr "s/.*<h2>$2 ([0-9]+)\.([0-9]+).*<\/h2>.*/\1.\2/p")
  nextkernel=${curkernel%.*}.$(( ${curkernel#*.}+1))

  echo "** Current kernel: $curkernel"
  echo "** Next kernel: $nextkernel"

  sed -ri \
    -e "s/(_?extramodules=).*-(ARCH|lts).*/\1extramodules-$curkernel-\2/i" \
    -e "s/(linux.*>=)[0-9]+.[0-9]+/\1$curkernel/" \
    -e "s/(linux.*<)[0-9]+.[0-9]+/\1$nextkernel/" \
    PKGBUILD *.install
}

# $1: repo
# $2: arch
build() {
  _pwd=$PWD
  cd /var/empty
  makechrootpkg -cu -I "$_pwd"/../../virtualbox/trunk/virtualbox-host-dkms-*-$arch.pkg.tar.xz -r "$1"
  makechrootpkg -I "$_pwd"/../../virtualbox/trunk/virtualbox-guest-dkms-*-$arch.pkg.tar.xz  -r "$1"
  cd "$_pwd"
  makechrootpkg -n -r "$1"
}

(( $# == 1 )) || usage

# detect lts case
grep -q linux-lts PKGBUILD && suf=-lts

case $1 in
  extra)
    update core linux$suf-headers
    for arch in x86_64 i686; do
      build /var/lib/archbuild/extra-$arch $arch
    done
  ;;
  testing)
    update testing linux$suf-headers
    for arch in x86_64 i686; do
      build /var/lib/archbuild/testing-$arch $arch
    done
  ;;
  *)
    usage
  ;;
esac

# vim:set ts=2 sw=2 ft=sh et:
