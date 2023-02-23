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

# unset variables
unset GIT_SUMMARY_MAX_ENTRIES
unset GIT_SUMMARY_IGNORE
GIT_SUMMARY_IGNORE_ACTIVATE=false

declare -A GIT_SUMMARY_IGNORE
GIT_SUMMARY_IGNORE[REPO_IS_REPOSITORY]=true

ignore_defaults() {
	GIT_SUMMARY_IGNORE[REPO_BRANCH]=true
	GIT_SUMMARY_IGNORE[REPO_UPSTREAM]=true
}

# command line arguments
while :; do
	case $1 in 
		-n)
			shift
			GIT_SUMMARY_MAX_ENTRIES="$1"
			;;

		--ignore-stash)
			GIT_SUMMARY_IGNORE_ACTIVATE=true
			GIT_SUMMARY_IGNORE[REPO_STASHED]=true
			ignore_defaults
			;;

		--ignore-defaults)
			GIT_SUMMARY_IGNORE_ACTIVATE=true
			ignore_defaults
			;;

		-?*)
			printf "Unknown option: %s\n" "$1" >&2
			exit
			;;
		*)
			break
	esac
	shift
done

# default values
GIT_SUMMARY_MAX_ENTRIES=${GIT_SUMMARY_MAX_ENTRIES:-5}

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
		git_dir=$(git rev-parse --show-toplevel 2>/dev/null)
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

		if $GIT_SUMMARY_IGNORE_ACTIVATE; then
			# check repo status
			local showRepo=false
			for line in $(set | grep "^REPO"); do
				# excluding lines starting with a key from GIT_SUMMARY_IGNORE 
				local attr=${line%%=*}
				[[ ${GIT_SUMMARY_IGNORE[$attr]+_} ]] && continue
				# if value is 0, nothing interesting here
				local val=${line##*=}
				[[ "$val" == "0" ]] && continue
				# 
				showRepo=true
			done
			$showRepo || continue
		fi

		# print status
		printf "  %s\t%s\n" ${git_dir//$'\n'/} $stat

		# limit entries
		((count++))
		[ $count -ge $GIT_SUMMARY_MAX_ENTRIES ] && break
	done 

# format as table
) | awk -v FS=$'\t' '{printf "%-50s%s\n", $1, $2}'

