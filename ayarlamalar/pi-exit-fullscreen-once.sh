#!/bin/sh
# Tam ekrandan cikis (F11) — print-agent calismiyorsa veya sadece kabuk isteniyorsa.
# wtype kurulu olmali (kioskyap.sh apt ile yukler).
command -v wtype >/dev/null 2>&1 || exit 1
wtype -k F11
exit 0
