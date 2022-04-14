#!/bin/zsh
# To install source this file from your .zshrc file

if [ -n "$ZSH_VERSION" ]; then
    # Always has path to this directory
    # A: finds the absolute path, even if this is symlinked
    # h: equivalent to dirname
    export __GIT_PROMPT_DIR=${0:A:h}
elif [ -n "$BASH_VERSION" ]; then
    export __GIT_PROMPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
else
    export __GIT_PROMPT_DIR=$(dirname "$(readlink -f "$0")")
fi

# see documentation at http://linux.die.net/man/1/zshexpn
preexec_update_git_vars() {
    case "$2" in
    git*|hub*|gh*|stg*)
        __EXECUTED_GIT_COMMAND=1
        ;;
    esac
}

precmd_update_git_vars() {
    if [ -n "$__EXECUTED_GIT_COMMAND" ] || [ ! -n "$ZSH_THEME_GIT_PROMPT_CACHE" ]; then
        update_current_git_vars
        unset __EXECUTED_GIT_COMMAND
    fi
}

chpwd_update_git_vars() {
    update_current_git_vars
}

# https://unix.stackexchange.com/a/331490/153926
dynamic_assign() { 
    eval "$1"=\"\$2\"
}

update_current_git_vars() {
    unset REPO_IS_REPOSITORY

    # find which command to use
    GIT_PROMPT_EXECUTABLE=${GIT_PROMPT_EXECUTABLE:-"shell"}
    if [ "$GIT_PROMPT_EXECUTABLE" = "python" ]; then
        local py_bin=${ZSH_GIT_PROMPT_PYBIN:-"python"}
        __GIT_STATUS_CMD() {
            git --no-optional-locks status --porcelain --branch 2>/dev/null | ZSH_THEME_GIT_PROMPT_HASH_PREFIX=$ZSH_THEME_GIT_PROMPT_HASH_PREFIX $py_bin "$__GIT_PROMPT_DIR/python/gitstatus.py"
        }
    elif [ "$GIT_PROMPT_EXECUTABLE" = "haskell" ]; then
        __GIT_STATUS_CMD() {
            git --no-optional-locks status --porcelain --branch &> /dev/null | $__GIT_PROMPT_DIR/haskell/.bin/gitstatus
        }
    elif [ "$GIT_PROMPT_EXECUTABLE" = "shell" ]; then
        __GIT_STATUS_CMD() {
            zsh $__GIT_PROMPT_DIR/shell/gitstatus.sh
        }
    fi

    # reset git status variables
    local var
    for var in IS_REPOSITORY BRANCH AHEAD BEHIND \
            STAGED CHANGED CONFLICTS UNTRACKED STASHED \
            LOCAL_ONLY UPSTREAM MERGING REBASE BISECT; do
        unset REPO_$var
    done

    # analyze repository
    local has_stderr=false
    while IFS= read -r line; do 
        if [ "$line" = "" ]; then
            continue
        elif [[ "$line" =~ REPO_*=* ]]; then
            local VAR=${line%% *}
            local ARG=${line#* }
            dynamic_assign "$VAR" "$ARG"
        elif [ "$__GIT_PROMPT_DEBUG" = "yes" ]; then
            has_stderr=true
            echo "gitstatus: $line"
        fi
    done < <(__GIT_STATUS_CMD 2>&1)
 
    if $has_stderr; then
        echo "Unexpected output. Check the lines starting with gitstatus:"
    fi

    unset __GIT_STATUS_CMD
}

repo_check() {
    local repo_var="REPO_$1"
    local content="${(P)repo_var}"
    [ -n "$content" ] && [ "$content" != "0" ]
}

repo_check_not() {
    local repo_var="REPO_$1"
    local content="${(P)repo_var}"
    [ -n "$content" ] && [ "$content" = "0" ]
}


add_str() {
    STATUS="$STATUS$@"
}

add_color_reset() {
    STATUS="$STATUS%{${reset_color}%}"
}

add_repo_var() {
    local repo_var="REPO_$1"
    STATUS="${STATUS}${(P)repo_var}"
}

add_theme_var() {
    local theme_var="ZSH_THEME_GIT_PROMPT_$1"
    STATUS="${STATUS}${(P)theme_var}"
}

repo_info_with_check() {
    local show_var="ZSH_GIT_PROMPT_SHOW_$1"
    if [ "${(P)show_var}" -ne "0" ] && repo_check $1; then
        add_theme_var $1
        add_repo_var $1
        add_color_reset
    fi
}

git_build_status() {

    if [ -n "$REPO_IS_REPOSITORY" ]; then
        local STATUS=""
        add_color_reset
        add_theme_var PREFIX
        add_theme_var BRANCH
        add_repo_var BRANCH
        add_color_reset

        repo_info_with_check REBASE
        repo_info_with_check MERGING
        repo_info_with_check BISECT

        if repo_check LOCAL_ONLY; then
            add_theme_var LOCAL
            add_color_reset
        elif [[ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -gt "0" ]] && [ -n "$REPO_UPSTREAM" ] && [ "$REPO_UPSTREAM" != ".." ]; then
            local parts=( "${(s:/:)REPO_UPSTREAM}" )
            if [ "$ZSH_GIT_PROMPT_SHOW_UPSTREAM" -eq "2" ] && [ "${(j:/:)parts[@]:1}" = "$REPO_BRANCH" ]; then
                REPO_UPSTREAM="$parts[1]"
            fi
            add_theme_var UPSTREAM_FRONT
            add_repo_var UPSTREAM
            add_theme_var UPSTREAM_END
            add_color_reset
        fi

        if (repo_check BEHIND && [ "$ZSH_GIT_PROMPT_SHOW_BEHIND" -ne "0" ]) || (repo_check AHEAD && [ "$ZSH_GIT_PROMPT_SHOW_AHEAD" -ne "0" ]); then
            add_str " "
        fi

        repo_info_with_check BEHIND
        if repo_check BEHIND && repo_check AHEAD; then
            add_str "$ZSH_THEME_GIT_PROMPT_BEHIND_AHEAD_SEPARATOR"
        fi
        repo_info_with_check AHEAD

        add_str "$ZSH_THEME_GIT_PROMPT_SEPARATOR"

        repo_info_with_check STAGED
        repo_info_with_check CONFLICTS
        repo_info_with_check CHANGED
        repo_info_with_check UNTRACKED
        repo_info_with_check STASHED

        local clean=0
        if ([ "$ZSH_GIT_PROMPT_SHOW_STAGED" -eq "0" ] || repo_check_not STAGED) &&
               ([ "$ZSH_GIT_PROMPT_SHOW_CONFLICTS" -eq "0" ] || repo_check_not CONFLICTS) &&
               ([ "$ZSH_GIT_PROMPT_SHOW_CHANGED" -eq "0" ] || repo_check_not CHANGED) &&
               ([ "$ZSH_GIT_PROMPT_SHOW_UNTRACKED" -eq "0" ] || repo_check_not UNTRACKED) &&
               ([ "$ZSH_GIT_PROMPT_SHOW_STASHED" -eq "0" ] || repo_check_not STASHED); then
            add_theme_var CLEAN
            add_color_reset
            clean=1
        fi

        add_theme_var SUFFIX
        add_color_reset

        echo -n "$STATUS"

        [ "$clean" = "1" ] && return 0 || return 1
    fi

    return -1
}

repo_status() {
    stat=$(git_super_status)
    ret=$?
    echo "$stat" | sed 's/%G%}//g; s/%2G%}//g; s/%{//g; s/%}//g;' 
    return $ret
}

git_super_status() {
    git_build_status
}



if [ "$1" = "--debug" ]; then
    __GIT_PROMPT_DEBUG="yes"
    update_current_git_vars
    git_super_status
    echo
    exit
fi

# Load required modules
autoload -U add-zsh-hook
autoload -U colors
colors

# Allow for functions in the prompt
setopt PROMPT_SUBST

# Hooks to make the prompt
add-zsh-hook chpwd chpwd_update_git_vars
add-zsh-hook preexec preexec_update_git_vars
add-zsh-hook precmd precmd_update_git_vars

# Default values for the appearance of the prompt.
# The theme is identical to magicmonty/bash-git-prompt
ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX="]"
ZSH_THEME_GIT_PROMPT_HASH_PREFIX=":"
ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{●%G%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{✚%G%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%1G%}"
ZSH_THEME_GIT_PROMPT_BEHIND_AHEAD_SEPARATOR=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%1G%}"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[blue]%}%{⚑%G%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}%{…%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
ZSH_THEME_GIT_PROMPT_LOCAL=" L"
# The remote branch will be shown between these two
ZSH_THEME_GIT_PROMPT_UPSTREAM_FRONT=" {%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_END="%{${reset_color}%}}"
ZSH_THEME_GIT_PROMPT_MERGING="%{$fg_bold[magenta]%}|MERGING%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_REBASE="%{$fg_bold[magenta]%}|REBASE%{${reset_color}%} "
ZSH_THEME_GIT_PROMPT_BISECT="%{$fg_bold[magenta]%}|BISECT%{${reset_color}%} "

# Settings defaults
ZSH_GIT_PROMPT_SHOW_UPSTREAM=0
ZSH_GIT_PROMPT_SHOW_BEHIND=1
ZSH_GIT_PROMPT_SHOW_AHEAD=1
ZSH_GIT_PROMPT_SHOW_REBASE=1
ZSH_GIT_PROMPT_SHOW_MERGING=1
ZSH_GIT_PROMPT_SHOW_BISECT=1
ZSH_GIT_PROMPT_SHOW_STAGED=1
ZSH_GIT_PROMPT_SHOW_CONFLICTS=1
ZSH_GIT_PROMPT_SHOW_CHANGED=1
ZSH_GIT_PROMPT_SHOW_UNTRACKED=1
ZSH_GIT_PROMPT_SHOW_STASHED=1

# vim: filetype=zsh: tabstop=4 shiftwidth=4 expandtab
