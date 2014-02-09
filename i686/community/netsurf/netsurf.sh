#!/bin/sh
shortname=`echo $LANG | cut -b1-2`
if [[ -d /usr/share/netsurf/$shortname ]]; then
	/usr/bin/netsurf.elf "$@"
else
	LANG=en /usr/bin/netsurf.elf "$@"
fi
