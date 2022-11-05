#!/bin/bash -x

set -o errexit
set -o nounset

PACKAGE=$1

TMPDIR=$(mktemp -d)

trap "rm -rf ${TMPDIR}" EXIT

tar -xzf ${PACKAGE} --directory=${TMPDIR}

pushd ${TMPDIR}
    for part in *.tar; do
	PARTNAME=$(basename ${part} .tar)
	mkdir ${PARTNAME}
	tar -xf ${part} --directory=${PARTNAME}
	rm -rf ${part}
    done
    rm info
    cat info.json | jq --sort-keys . | tee info.json
popd

PACKAGENAME=$(jq -r .name ${TMPDIR}/info.json)
rm -rf ${PACKAGENAME}
mkdir ${PACKAGENAME}
rsync -avzP ${TMPDIR}/ ${PACKAGENAME}/
