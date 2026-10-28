#!/bin/sh -x

BUILDROOT="$1"
SPEC="$2"

. $(dirname $0)/common.sh

# The package was originally published by epm play as mimocode.
add_obsoletes mimocode
add_provides mimocode
