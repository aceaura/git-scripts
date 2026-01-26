#!/bin/bash
# git-l: 显示简洁的 git log，带图形和装饰
# 用法: git l

git -c color.ui=always log --decorate -n 100 --format='%C(yellow)%h %C(cyan)%ar %C(green)%an%C(reset)%C(auto)%d%C(reset) %s' --reverse "$@" | awk '{
    # 找到绿色作者名 \033[32m....\033[0m 并截断
    line=$0
    if(match(line, /\033\[32m[^\033]+\033\[0m/)) {
        prefix=substr(line, 1, RSTART+4)
        rest=substr(line, RSTART+5)
        if(match(rest, /[^\033]*/)) {
            author=substr(rest, 1, RLENGTH)
            suffix=substr(rest, RLENGTH+1)
            # 截断到第一个非字母数字
            if(match(author, /^[a-zA-Z0-9]+/)) {
                short=substr(author, 1, RLENGTH)
                if(length(short)>8) short=substr(short,1,8)
                print prefix short suffix
            } else print line
        } else print line
    } else print line
}'
