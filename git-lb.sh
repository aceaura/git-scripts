#!/bin/bash
# git-lb: 交互式浏览 git commit 历史
# 用法: git lb
# 依赖: fzf

git log --oneline --color=always --format="%C(yellow)%h%C(reset) %C(cyan)%ad %C(green)%an%C(reset) %s" --date=relative -n 100 | \
awk '{
    line=$0
    if(match(line, /\033\[32m[^\033]+\033\[0m/)) {
        prefix=substr(line, 1, RSTART+4)
        rest=substr(line, RSTART+5)
        if(match(rest, /[^\033]*/)) {
            author=substr(rest, 1, RLENGTH)
            suffix=substr(rest, RLENGTH+1)
            if(match(author, /^[a-zA-Z0-9]+/)) {
                short=substr(author, 1, RLENGTH)
                if(length(short)>8) short=substr(short,1,8)
                print prefix short suffix
            } else print line
        } else print line
    } else print line
}' | \
fzf --ansi --no-sort --reverse --height=100% \
    --preview 'git show --color=always {1}' \
    --preview-window=right:60%:wrap \
    --bind 'enter:execute(git show --color=always {1} | less -R)' \
    --bind 'pgdn:preview-page-down' \
    --bind 'pgup:preview-page-up' \
    --header '↑↓选择 | Enter查看详情 | PageUp/PageDown翻页预览 | Esc退出'
