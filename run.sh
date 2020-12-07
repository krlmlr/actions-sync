#!/bin/bash

. lib/lib.sh

if [ "$1" = "" ]; then
  echo "Usage: $0 command ..."
  echo
  echo "with command one of:"
  echo
  sed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//- \1: \2/; p }' $0
  exit 1
fi

"$@"
