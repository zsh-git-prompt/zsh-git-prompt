#!/bin/zsh

git_summary_parse_args() {
	# unset variables
	unset GIT_SUMMARY_IGNORE

	declare -g GIT_SUMMARY_MAX_ENTRIES
	declare -g GIT_SUMMARY_IGNORE_ACTIVATE=false
	declare -g GIT_SUMMARY_INCLUDE_ALL=false
	declare -gA GIT_SUMMARY_IGNORE
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

			--all)
				GIT_SUMMARY_INCLUDE_ALL=true
				;;

			--help)
				printf "usage: source <summary-script> <options>\n"
				printf "\nOptions:\n"
				printf "  -n <number>          limit the output to <number> repositories\n"
				printf "  --all                print the summary for all repo candidates;\n"
				printf "                       this overrides the --ignore-* options\n"
				printf "  --ignore-defaults    do not consider standard info (e.g., REPO_BRANCH)\n"
				printf "                       for determining whether a repo is dirty\n"
				printf "  --ignore-stash       do not consider the stash as dirty;\n"
				printf "                       automatically adds --ignore-defaults\n"
				return 1
				;;

			-?*)
				printf "Unknown option: %s\n" "$1" >&2
				return 2
				;;
			*)
				break
		esac
		shift
	done
}

git_summary_process() {
	git_summary_parse_args "$@" || return $?

	{
		# temporarily change chpwd_functions
		# As the ()-block runs in a subshell, it does not affect the parent
		chpwd_functions=(chpwd_update_git_vars)

		local header="  === repository ===\t=== status ==="
		echo $header

		local count=0
		declare -A aseen
		for d in $(git_summary_candidates); do
			if [ ! -e "$d" ]; then
				continue
			fi

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
			if [[ "$GIT_SUMMARY_INCLUDE_ALL" != true ]]; then
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
			fi

			# print status
			printf "  %s\t%s\n" ${git_dir//$'\n'/} $stat

			# limit entries
			((count++))
			[[ "$GIT_SUMMARY_MAX_ENTRIES" =~ [0-9]+ ]] && [ $count -ge $GIT_SUMMARY_MAX_ENTRIES ] && break
		done

	# format as table
	} | awk -v FS=$'\t' '{printf "%-50s%s\n", $1, $2}'
}
