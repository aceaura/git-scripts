#!/bin/bash
# git-lb: 交互式浏览 git commit 历史
# 用法: git lb
# 依赖: fzf

git log --oneline --color=always --format="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)" --date=relative -n 100 | \
fzf --ansi --no-sort --reverse --height=100% \
    --preview 'git show --color=always {1}' \
    --preview-window=right:60%:wrap \
    --bind 'enter:execute(git show --color=always {1} | less -R)' \
    --bind 'pgdn:preview-page-down' \
    --bind 'pgup:preview-page-up' \
    --header '↑↓选择 | Enter查看详情 | PageUp/PageDown翻页预览 | Esc退出'
