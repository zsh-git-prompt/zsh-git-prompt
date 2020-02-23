
extract_arg() {
    n=$1
    shift
    echo $$n
}

analyze_git_repository() {
    # read line by line, see https://www.etalabs.net/sh_tricks.html
    {
        read -r branch
        read -r git_dir
        read -r common_dir
    } << EOF
$(git rev-parse --abbrev-ref HEAD --git-dir --git-common-dir 2> /dev/null)
EOF

    if [ "$branch" = "" ]; then
        return
    fi

    local PREFIX="REPO_"
    local local_only=1
    local untracked=0
    local ignored=0
    local changed=0
    local staged=0
    local conflicts=0
    local hashid=""
    local branch=""
    local ahead=0
    local behind=0
    git --no-optional-locks status --porcelain=v2 --branch | while IFS= read -r line; do
        case "$line" in 
            "#"*)
                case "$line" in
                    *"branch.oid "*)
                        hashid="${line:13}";;
                    *"branch.head "*)
                        branch="${line:14}";;
                    *"branch.upstream "*)
                        upstream="${line:18}";;
                    *"branch.ab "*)
                        local ab="${line:13}"
                        ahead="${ab%% *}"
                        behind="${ab#* -}"
                        ;;
                esac
                continue
                ;;

            "? "*)
                ((untracked++))
                continue
                ;;

            "! "*)
                ((ignored++))
                continue
                ;;
        esac

        code="${line:2:2}"

        case "$code" in 
            ..)
                ((untracked++))
                continue;;

            AA|AU|DD|DU|UA|UD|UU)
                ((conflicts++))
                continue;;
        esac

        case "$code" in
            A?|C?|D?|M?|R?)
                ((staged++));;
        esac

        case "$code" in
            ?C|?D|?M|?R)
                ((changed++));;
        esac
    done

    if [ "$branch" = "HEAD" ] || [ "$branch" = "(detached)" ]; then
        branch=":${hashid:0:7}"
    fi

    local stashed=$(git stash list | wc -l | sed 's/^ *//')

    echo "${PREFIX}IS_REPOSITORY 1"
    echo "${PREFIX}BRANCH $branch"
        
    echo "${PREFIX}UNTRACKED $untracked"
    echo "${PREFIX}CHANGED $changed"
    echo "${PREFIX}CONFLICTS $conflicts"
    echo "${PREFIX}STAGED $staged"

    echo "${PREFIX}STASHED $stashed"

    if [ -n "$upstream" ]; then
        local_only=0
    fi
    if [ -e "$common_dir/svn/.metadata" ]; then
        if [ -n "$upstream" ]; then
            upstream="$upstream "
        fi
        local svn_stat="$(git log --pretty=format:%h:%w\(0,2,2\)%b --first-parent | awk '
            # count lines that start with a hash
            /^[^ ]/ { count += 1 } 

            # find svn branch and revision
            match($0, /^[0-9a-f]*:?  git-svn-id: .*\/([^/]*)@([0-9]*) /, m) { 
                print count " " m[1] "@" m[2] 
            }' | head)"
        ahead=$(( ${svn_stat%% *}-1 ))
        upstream="${upstream}svn:${svn_stat#* }"
        local_only=0
    fi

    echo "${PREFIX}LOCAL_ONLY $local_only"
    echo "${PREFIX}AHEAD $ahead"
    echo "${PREFIX}BEHIND $behind"
    if [ -n "$local_only" ]; then
        echo "${PREFIX}UPSTREAM $upstream"
    fi

    if [ -e "$git_dir/MERGE_HEAD" ]; then
        echo "${PREFIX}MERGING 1"
    else
        echo "${PREFIX}MERGING 0"
    fi

    if [ -d "$git_dir/rebase-apply" ]; then
        local next=$(cat $git_dir/rebase-apply/next 2> /dev/null)
        local last=$(cat $git_dir/rebase-apply/last 2> /dev/null)
        echo "${PREFIX}REBASE $next/$last"
    else
        echo "${PREFIX}REBASE 0"
    fi

    if [ -e "$git_dir/BISECT_START" ]; then
        local bisect=$(git bisect visualize --format=format:%d | awk '
            BEGIN {
                count=0
            } 
            !/\(refs\/bisect\//{
                count++
            } 
            END {
                print count "; " int(log(count)/log(2)) " steps"
            }')
        echo "${PREFIX}BISECT $bisect"
    else
        echo "${PREFIX}BISECT 0"
    fi
}


analyze_git_repository

# vim: filetype=zsh: tabstop=4 shiftwidth=4 expandtab
