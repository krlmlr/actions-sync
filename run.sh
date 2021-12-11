#!/bin/bash

. lib/lib.sh

if [ "$1" = "" ]; then
  echo "Usage: $0 command ..."
  echo
  echo "with command one of:"
  echo
  gsed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//- \1: \2/; p }' lib/lib.sh
  exit 1
fi

echo ">" "$@"

"$@"
