#!/bin/zsh

GIT_SUMMARY_MAX_ENTRIES=5

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

(
	local header="  === repository ===\t=== status ==="
	echo $header

	local count=0
	declare -A aseen
	for d in $(git_summary_candidates); do
		# try to find git base dir
		cd "$d"
		git_dir=$(git rev-parse --git-dir 2>/dev/null)
		[ $? != 0 ] && continue;

		# only one line for each git repo
		git_dir=$(realpath "$git_dir" | sed 's/.git$//')
		[[ ${aseen[$git_dir]} ]] && continue
		aseen[$git_dir]=x

		# check whether it is dirty
		cd "$git_dir"
		stat=$(repo_status)
		ret="$?"
		[[ $ret = 0 ]] && continue

		# print status
		printf "  %s\t%s\n" ${git_dir//\n/} $stat

		# limit entries
		((count++))
		[ $count -ge $GIT_SUMMARY_MAX_ENTRIES ] && break
	done 

# format as table
) | column -t -s $'\t'

