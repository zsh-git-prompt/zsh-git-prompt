#!/bin/zsh

git_summary_candidates() {
	git worktree list --porcelain | grep '^worktree' | sed 's/^worktree //'
}

# include common.sh
SOURCE="${(%):-%x}"
MY_DIR=`dirname "$(readlink -f "${SOURCE}" 2>/dev/null||echo $0)"`
. "$MY_DIR/common.sh"

# default values
unset GIT_SUMMARY_MAX_ENTRIES

git_summary_process "$@"
