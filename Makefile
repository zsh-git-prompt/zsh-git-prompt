ZSH="zsh"

all: test

test:
	@$(ZSH) -n zshrc.sh shell/gitstatus.sh
	@$(ZSH) tests/run_tests.sh

.PHONY: all test
