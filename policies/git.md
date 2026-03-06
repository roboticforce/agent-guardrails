# Git Policy

## Blocked commands

| Command | Why |
|---------|-----|
| `git push --force origin main/master/production` | Overwrites shared branch history. Can destroy teammates' work. |
| `git push -f origin main/master/production` | Same as above, short flag |
| `git push --force-with-lease` to protected branches | Still rewrites history on shared branches |
| `git reset --hard` | Discards all uncommitted changes permanently |
| `git clean -fd` / `git clean -fx` | Deletes untracked files permanently |
| `git checkout -- .` | Discards all unstaged changes |
| `git branch -D main/master/production` | Deletes protected branch locally |

## What agents CAN do safely

- `git status`, `git diff`, `git log` - Inspection
- `git add`, `git commit` - Creating commits
- `git push` (non-force to feature branches) - Publishing work
- `git checkout -b` / `git switch -c` - Creating branches
- `git pull`, `git fetch` - Syncing with remote
- `git stash` - Temporarily shelving changes
- `git branch -d` (lowercase, non-protected) - Deleting merged branches
