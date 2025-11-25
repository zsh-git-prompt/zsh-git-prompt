#!/bin/zsh

_Z_CMD=${_Z_CMD:-z}
if ! type "$_Z_CMD" > /dev/null; then
	echo "This script depends on https://github.com/rupa/z."
	echo "Please call it as follows:"
	echo
	echo "  source $0"
	echo
	exit 1
fi

git_summary_candidates() {
	z | sort -r -g | awk '{print $2}'
}

# include common.sh
SOURCE="${(%):-%x}"
MY_DIR=`dirname "$(readlink -f "${SOURCE}" 2>/dev/null||echo $0)"`
. "$MY_DIR/common.sh"

# default values
GIT_SUMMARY_MAX_ENTRIES=5

git_summary_process "$@"
