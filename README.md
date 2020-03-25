# .cfg

## What was done

```
git init --bare $HOME/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
```
[source](https://www.atlassian.com/git/tutorials/dotfiles)
