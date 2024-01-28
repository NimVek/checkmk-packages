#!/bin/bash -x

set -o errexit
set -o nounset

LC_ALL=C.UTF-8

PACKAGE_DIR=$1

TMPDIR=$(mktemp -d)

# shellcheck disable=SC2064
trap "rm -rf $TMPDIR" EXIT

rsync -avzP "$PACKAGE_DIR/" "$TMPDIR/"

NAME=$(jq -r .name "$TMPDIR/info.json")
VERSION=$(jq -r .version "$TMPDIR/info.json")

DATE=$(date --date "$(stat --format=%y "$TMPDIR/info.json")" --iso-8601=seconds)

function archive () {
    tar --sort=name --owner=0 --group=0 --numeric-owner --mode=go=rX,u+rw,a-s --mtime="$DATE" "$@"
}

CURRENT_DIR=$(pwd)

pushd "$TMPDIR"
    jq '.files={}' info.json | sponge info.json
    for part in $(find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort) ; do
        jq ".files.${part}=[]" info.json | sponge info.json
	pushd "${part}"
	    for element in $(find . -type f -printf '%P\n' | sort) ; do
		jq ".files.${part} += [\"$element\"]" ../info.json | sponge ../info.json
	    done
	    archive -cf "../${part}.tar" -- *
	popd
	rm -rf "${part}"
    done
    COUNT=$(find . -mindepth 2 -type f | wc -l)
    jq ".num_files=${COUNT}" info.json | sponge info.json
    MIN_VERSION=$(jq -r .\"version.min_required\" info.json)
    jq ".\"version.packaged\"=\"${MIN_VERSION}\"" info.json | sponge info.json
    jq --compact-output . info.json | sponge info.json
    python3 -c 'import json; import pprint; pprint.pprint(json.load(open("info.json")), open("info","w"))'
    archive -cf - -- * | gzip --best > "${CURRENT_DIR}/${NAME}-${VERSION}.mkp"
popd
