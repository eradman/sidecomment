#!/bin/sh

trap 'printf "$0: exit code $? on line $LINENO\n" >&2; exit 1' ERR
cd $(dirname $0)

rm -f /tmp/cdp.trace.*
minitest integration.rb
ls -l /tmp/cdp.trace.*
