#!/bin/bash -x

set -o errexit
set -o nounset

LC_ALL=C.UTF-8

PACKAGE_DIR=$1

TMPDIR=$(mktemp -d)

trap "rm -rf $TMPDIR" EXIT

rsync -avzP $PACKAGE_DIR/ $TMPDIR/

NAME=$(jq -r .name $TMPDIR/info.json)
VERSION=$(jq -r .version $TMPDIR/info.json)

DATE=$(date --date "$(stat --format=%y $TMPDIR/info.json)" --iso-8601=seconds)

function archive () {
    tar --sort=name --owner=0 --group=0 --numeric-owner --mode=go=rX,u+rw,a-s --mtime=$DATE $*
}

CURRENT_DIR=$(pwd)

pushd $TMPDIR
    cat info.json | jq '.files={}' | tee info.json
    for part in $(find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort) ; do
        cat info.json | jq ".files.${part}=[]" | tee info.json
	pushd ${part}
	    for element in $(find . -type f -printf '%P\n' | sort) ; do
		cat ../info.json | jq ".files.${part} += [\"$element\"]" | tee ../info.json
	    done
	    archive -cf ../${part}.tar *
	popd
	rm -rf ${part}
    done
    COUNT=$(find . -mindepth 2 -type f | wc -l)
    cat info.json | jq ".num_files=${COUNT}" | tee info.json
    MIN_VERSION=$(jq -r .\"version.min_required\" info.json)
    cat info.json | jq ".\"version.packaged\"=\"${MIN_VERSION}\"" | tee info.json
    cat info.json | jq --compact-output . | tee info.json
    python3 -c 'import json; import pprint; pprint.pprint(json.load(open("info.json")), open("info","w"))'
    archive -cf - * | gzip --best > ${CURRENT_DIR}/${NAME}-${VERSION}.mkp
popd
