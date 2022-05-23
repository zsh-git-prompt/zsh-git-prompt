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

ZSHRCSH_PATH="${__RUN_TEST_DIR}/../zshrc.sh"
TEST_CASE_DIR="${__RUN_TEST_DIR}/test_cases"

source "${__RUN_TEST_DIR}/setup_tests.sh"

run_super_status() {
    (cd "${TEST_REPO_DIR}" && zsh -f "$ZSHRCSH_PATH" --debug)
}

# https://stackoverflow.com/a/15612499
function assert_equals()
{
    msg=$1; shift
    expected=$1; shift
    actual=$1; shift
    if [ "$expected" != "$actual" ]; then
        echo "$msg EXPECTED=$expected ACTUAL=$actual"
        exit 1
    fi
}

function run_test()
{
    prepare_test_env && (
        cd "${TEST_REPO_DIR}"
        source "${TEST_CASE_DIR}/$1"
    )
    result="$?"
    cleanup_test_env

    return "$result"
}

function run_all_tests()
{
    TOTAL=0
    FAILURES=0

    for test_full_path in ${TEST_CASE_DIR}/*; do
        test_case="$(basename "$test_full_path")"
        echo "Testing: $test_case"
        ((TOTAL+=1))
        run_test $test_case
        ((FAILURES+=$?))
    done

    PASSED=$((TOTAL-FAILURES))
    echo "$PASSED/$TOTAL PASSED"
}

run_all_tests

exit $FAILURES
