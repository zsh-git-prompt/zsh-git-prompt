
# https://stackoverflow.com/a/18558871/1562506
beginswith() { 
    case "$1" in "$2"*) true;; *) false;; esac; 
}

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
    } << EOF
$(git rev-parse --abbrev-ref HEAD --git-dir 2> /dev/null)
EOF

    if [ "$branch" = "" ]; then
        return
    fi

    local untracked=0
    local changed=0
    local staged=0
    local conflicts=0
    local hashid=""
    local branch=""
    local ahead=0
    local behind=0
    git --no-optional-locks status --porcelain=v2 --branch | while IFS= read -r line; do
        if beginswith "$line" "#"; then
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
        fi

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

    local stashed=$(git stash list | wc -l)

    echo "GIT_IS_REPOSITORY 1"
    echo "GIT_BRANCH $branch"
        
    echo "GIT_UNTRACKED $untracked"
    echo "GIT_CHANGED $changed"
    echo "GIT_CONFLICTS $conflicts"
    echo "GIT_STAGED $staged"

    echo "GIT_STASHED $stashed"

    if [ "$upstream" != "" ]; then
        echo "GIT_LOCAL_ONLY 0"
        echo "GIT_AHEAD $ahead"
        echo "GIT_BEHIND $behind"
        echo "GIT_UPSTREAM $upstream"
    else
        echo "GIT_LOCAL_ONLY 1"
        echo "GIT_AHEAD 0"
        echo "GIT_BEHIND 0"
    fi

    if [ -e "$git_dir/MERGE_HEAD" ]; then
        echo "GIT_MERGING 1"
    else
        echo "GIT_MERGING 0"
    fi

    if [ -d "$git_dir/rebase-apply" ]; then
        local next=$(cat $git_dir/rebase-apply/next 2> /dev/null)
        local last=$(cat $git_dir/rebase-apply/last 2> /dev/null)
        echo "GIT_REBASE $next/$last"
    else
        echo "GIT_REBASE 0"
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
        echo "GIT_BISECT $bisect"
    else
        echo "GIT_BISECT 0"
    fi
}


analyze_git_repository

# vim: filetype=zsh: tabstop=4 shiftwidth=4 expandtab
