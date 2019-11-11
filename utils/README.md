# Some utils

## git-summary

A script to show the status of the most recently visited git repositories. Requires [rupa/z](https://github.com/rupa/z).

<img src="https://github.com/zsh-git-prompt/zsh-git-prompt/raw/master/utils/git-summary.png"/>

Use it as follows:
```
source git-summary.sh
```

If you want to be reminded at the first login after booting,
you could add the following snippet to your `~/.zshrc`:
```
# show dirty git repositories
ZSH_GIT_PROMPT_DIR=~/software/zsh-git-prompt
if [ -e $ZSH_GIT_PROMPT_DIR/utils/git-summary.sh ]; then
	local lock_file="/tmp/.git_summary_$USER"
	if [ ! -e $lock_file ]; then
		touch $lock_file
		if [ -e $lock_file ]; then
			source $ZSH_GIT_PROMPT_DIR/utils/git-summary.sh
		fi
	fi
fi
```


