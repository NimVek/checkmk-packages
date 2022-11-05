#!/bin/bash -x

set -o errexit
set -o nounset

LC_ALL=C.UTF-8

PACKAGE_DIR=$1

pushd $PACKAGE_DIR
    NAME=$(basename $(pwd))
    cat info.json | jq ".name=\"${NAME}\"" | tee info.json
    cat info.json | jq '.files={}' | tee info.json
    for part in $(find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort) ; do
        cat info.json | jq ".files.${part}=[]" | tee info.json
	pushd ${part}
	    for element in $(find . -type f -printf '%P\n' | sort) ; do
		cat ../info.json | jq ".files.${part} += [\"$element\"]" | tee ../info.json
	    done
	popd
    done
    COUNT=$(find . -mindepth 2 -type f | wc -l)
    cat info.json | jq ".num_files=${COUNT}" | tee info.json
    MIN_VERSION=$(jq -r .\"version.min_required\" info.json)
    cat info.json | jq ".\"version.packaged\"=\"${MIN_VERSION}\"" | tee info.json

    cat info.json | jq '.author="NimVek <NimVek@users.noreply.github.com>"' | tee info.json
    cat info.json | jq ".download_url=\"https://github.com/NimVek/checkmk-packages/tree/main/${NAME}\"" | tee info.json

    cat info.json | jq --sort-keys . | tee info.json

    find . -type f -name "*.py" -print0 | xargs -0 -n 1 --no-run-if-empty black
    find . -type f -name "*.py" -print0 | xargs -0 -n 1 --no-run-if-empty isort --profile black
popd