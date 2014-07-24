#!/bin/bash

set -o nounset

declare -A default="($(< /etc/hardening-wrapper.conf))"

force_bindnow="${HARDENING_BINDNOW:-"${default[HARDENING_BINDNOW]:-1}"}"
force_fPIE="${HARDENING_PIE:-"${default[HARDENING_PIE]:-1}"}"
force_fortify="${HARDENING_FORTIFY:-"${default[HARDENING_FORTIFY]:-2}"}"
force_pie="${HARDENING_PIE:-"${default[HARDENING_PIE]:-1}"}"
force_relro="${HARDENING_RELRO:-"${default[HARDENING_RELRO]:-1}"}"
force_stack_check="${HARDENING_STACK_CHECK:-"${default[HARDENING_STACK_CHECK]:-0}"}"
force_stack_protector="${HARDENING_STACK_PROTECTOR:-${default[HARDENING_STACK_PROTECTOR]:-2}}"

error() {
  echo "$1" >&2
  exit 1
}

linking=1
optimizing=0

for opt; do
  case "$opt" in
    -fno-PIC|-fno-pic|-fno-PIE|-fno-pie|-nopie|-static|--static|-shared|--shared|-D__KERNEL__|-nostdlib|-nostartfiles)
      force_fPIE=0
      force_pie=0
      ;;
    -fPIC|-fpic|-fPIE|-fpie)
      force_fPIE=0
      ;;
    -c)
      linking=0
      ;;
    -nostdlib|-ffreestanding)
      force_stack_protector=0
      ;;
    -D_FORTIFY_SOURCE*)
      force_fortify=0
      ;;
    -O0)
      optimizing=0
      ;;
    -O*)
      optimizing=1
      ;;
  esac
done

arguments=()

case "$force_bindnow" in
  0) ;;
  1) (( linking )) && arguments+=(-Wl,-z,now) ;;
  *) error 'invalid value for HARDENING_BINDNOW' ;;
esac

case "$force_fPIE" in
  0) ;;
  1) arguments+=(-fPIE) ;;
  *) error 'invalid value for HARDENING_PIE' ;;
esac

case "$force_fortify" in
  0) ;;
  1|2) (( optimizing )) && arguments+=(-D_FORTIFY_SOURCE=$force_fortify) ;;
  *) error 'invalid value for HARDENING_FORTIFY' ;;
esac

case "$force_pie" in
  0) ;;
  1) (( linking )) && arguments+=(-pie) ;;
  *) error 'invalid value for HARDENING_PIE' ;;
esac

case "$force_relro" in
  0) ;;
  1) (( linking )) && arguments+=(-Wl,-z,relro) ;;
  *) error 'invalid value for HARDENING_RELRO' ;;
esac

case "$force_stack_check" in
  0) ;;
  1) arguments+=(-fstack-check) ;;
  *) error 'invalid value for HARDENING_STACK_CHECK' ;;
esac

case "$force_stack_protector" in
  0) ;;
  1) arguments+=(-fstack-protector) ;;
  2) arguments+=(-fstack-protector-strong) ;;
  3) arguments+=(-fstack-protector-all) ;;
  *) error 'invalid value for HARDENING_STACK_PROTECTOR' ;;
esac

unwrapped=false
IFS=: read -ra path <<< "$PATH";
for p in "${path[@]}"; do
  binary="$p/${0##*/}"
  if [[ "$binary" != "$0" && -x "$binary" ]]; then
    unwrapped="$binary"
    break
  fi
done

exec "$unwrapped" "${arguments[@]}" "$@"
