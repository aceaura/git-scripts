#!/bin/bash
# git-l: 显示简洁的 git log，带图形和装饰
# 用法: git l

git -c color.ui=always log --decorate -n 100 --format='%C(yellow)%h %C(cyan)%ar %C(green)%an%C(reset)%C(auto)%d%C(reset) %s' --reverse "$@" | awk '{
    line=$0
    # 匹配绿色 ANSI: ESC[32m (ESC = \033)
    if(match(line, /\033\[32m/)) {
        prefix=substr(line, 1, RSTART+RLENGTH-1)
        rest=substr(line, RSTART+RLENGTH)
        # 找到 reset: ESC[m 或 ESC[0m
        if(match(rest, /\033\[0?m/)) {
            author=substr(rest, 1, RSTART-1)
            suffix=substr(rest, RSTART)
            # 截断作者名：只保留字母数字，最多8个
            if(match(author, /^[a-zA-Z0-9]+/)) {
                short=substr(author, 1, RLENGTH)
                if(length(short)>8) short=substr(short,1,8)
                print prefix short suffix
            } else print line
        } else print line
    } else print line
}'
