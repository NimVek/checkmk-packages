#!/bin/bash -x

set -o errexit
set -o nounset

LC_ALL=C.UTF-8

PACKAGE_DIR=$1

pushd "$PACKAGE_DIR"
    NAME=$(basename "$(pwd)")
    jq ".name=\"${NAME}\"" info.json| sponge info.json
    jq '.files={}' info.json | sponge info.json
    for part in $(find . -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | sort) ; do
        jq ".files.${part}=[]" info.json | sponge info.json
	pushd "${part}"
	    for element in $(find . -type f -printf '%P\n' | sort) ; do
		jq ".files.${part} += [\"$element\"]" ../info.json | sponge  ../info.json
	    done
	popd
    done
    COUNT=$(find . -mindepth 2 -type f | wc -l)
    jq ".num_files=${COUNT}" info.json | sponge info.json
    MIN_VERSION=$(jq -r .\"version.min_required\" info.json)
    jq ".\"version.packaged\"=\"${MIN_VERSION}\"" info.json | sponge info.json

    jq '.author="NimVek <NimVek@users.noreply.github.com>"' info.json | sponge info.json
    jq ".download_url=\"https://github.com/NimVek/checkmk-packages/tree/main/${NAME}\"" info.json | sponge info.json

    jq --sort-keys . info.json | sponge info.json

    find . -type f -name "*.py" -print0 | xargs -0 -n 1 --no-run-if-empty black
    find . -type f -name "*.py" -print0 | xargs -0 -n 1 --no-run-if-empty isort --profile black
popd
