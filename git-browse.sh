#!/bin/bash
# git-browse - 交互式浏览 git commit 历史
# 使用方向键上下选择，Enter 查看详情，Esc/q 退出

git log --oneline --color=always --format="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)" --date=relative -n 50 | \
fzf --ansi --no-sort --reverse --height=100% \
    --preview 'git show --color=always {1}' \
    --preview-window=right:60%:wrap \
    --bind 'enter:execute(git show --color=always {1} | less -R)' \
    --bind 'ctrl-d:preview-page-down' \
    --bind 'ctrl-u:preview-page-up' \
    --header '↑↓选择 | Enter查看详情 | Ctrl-D/U翻页预览 | Esc退出'
