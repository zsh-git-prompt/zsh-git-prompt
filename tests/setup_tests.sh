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

TEST_REPO_DIR="${__RUN_TEST_DIR}/test_repo"
MARKER_FILE_NAME="zsh-git-prompt-marker"

git_commit() {
    GIT_CONFIG_GLOBAL="${__RUN_TEST_DIR}/.gitconfig" git commit --no-gpg-sign -q $@
}

prepare_test_env() {
    autoload -U colors
    colors

    unset PS1
    unset GIT_PROMPT_EXECUTABLE

    mkdir "${TEST_REPO_DIR}" && (cd "${TEST_REPO_DIR}" && git init -q && git symbolic-ref HEAD refs/heads/main && touch "$MARKER_FILE_NAME" && git add "$MARKER_FILE_NAME" && git_commit -m "Initial Commit")
}

cleanup_test_env() {
    if [[ "$(id -u)" -eq "0" ]]; then
        echo "Refusing to cleanup as root; risk of damage is unacceptable. Remove '${TEST_REPO_DIR}' manually if safe."
        return 1
    elif [[ ! -f "${TEST_REPO_DIR}/${MARKER_FILE_NAME}" ]]; then
        echo "Cannot find marker file in '${TEST_REPO_DIR}', refusing to delete; risk of wrong folder is unacceptable. Remove '${TEST_REPO_DIR}' manually if safe."
        return 2
    fi
    rm -rf "${TEST_REPO_DIR}"
}
