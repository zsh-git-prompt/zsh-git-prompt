#!/bin/zsh

if [ -n "$ZSH_VERSION" ]; then
    # Always has path to this directory
    # A: finds the absolute path, even if this is symlinked
    # h: equivalent to dirname
    export __RUN_TEST_DIR=${0:A:h}
else
    echo "Must use ZSH to run tests!"
    exit 1
fi

source "${__RUN_TEST_DIR}/setup_tests.sh"

ZSHRCSH_PATH="${__RUN_TEST_DIR}/../zshrc.sh"

run_super_status() {
    (cd "${TEST_REPO_DIR}" && zsh -f "$ZSHRCSH_PATH" --debug)
}

# https://stackoverflow.com/a/15612499
function assertEquals()
{
    msg=$1; shift
    expected=$1; shift
    actual=$1; shift
    if [ "$expected" != "$actual" ]; then
        echo "$msg EXPECTED=$expected ACTUAL=$actual"
        exit 1
    fi
}

FAILURES=0

prepare_test_env && (
    assertEquals "Clean" "%{${reset_color}%}[%{$fg_bold[magenta]%}main%{${reset_color}%} L%{${reset_color}%}|%{$fg_bold[green]%}%{✔%G%}%{${reset_color}%}]%{${reset_color}%}" "$(run_super_status)"
); ((FAILURES+=$?)); cleanup_test_env

prepare_test_env && (
    touch "${TEST_REPO_DIR}/untracked_file_1"
    touch "${TEST_REPO_DIR}/untracked_file_2"

    assertEquals "Two untracked files" "%{${reset_color}%}[%{$fg_bold[magenta]%}main%{${reset_color}%} L%{${reset_color}%}|%{$fg[cyan]%}%{…%G%}2%{${reset_color}%}]%{${reset_color}%}" "$(run_super_status)"
); ((FAILURES+=$?)); cleanup_test_env

if [[ "$FAILURES" -eq "0" ]]; then
    echo "PASS"
fi

exit $FAILURES
