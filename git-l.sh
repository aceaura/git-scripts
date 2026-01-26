#!/bin/bash
# git-l: 显示简洁的 git log，带图形和装饰
# 用法: git l

# 获取 commit hash 和修改行数的映射
declare -A changes
while IFS= read -r line; do
    if [[ $line =~ ^[a-f0-9]{7,} ]]; then
        hash="${line%% *}"
    elif [[ $line =~ ([0-9]+)\ insertion ]] || [[ $line =~ ([0-9]+)\ deletion ]]; then
        ins=0 del=0
        [[ $line =~ ([0-9]+)\ insertion ]] && ins="${BASH_REMATCH[1]}"
        [[ $line =~ ([0-9]+)\ deletion ]] && del="${BASH_REMATCH[1]}"
        changes[$hash]=$((ins + del))
    fi
done < <(git log -n 100 --format="%h" --shortstat --reverse "$@")

# 输出带颜色的 log
git -c color.ui=always log --decorate -n 100 --format='%C(yellow)%h %C(cyan)%ar %C(green)%an%C(reset)%C(auto)%d%C(reset) %s' --reverse "$@" | while IFS= read -r line; do
    # 提取 hash
    hash=$(echo "$line" | sed -n 's/.*\[33m\([a-f0-9]\{7,\}\).*/\1/p')
    tc=${changes[$hash]:-0}
    
    # 96级颜色渐变: 232-255(灰度24级) + 彩色72级
    # 0-1: 232, 2-3: 233, ... 46-47: 255 (灰度)
    # 48+: 彩色 228->220->214->208->202->196 (黄->橙->红)
    if [ $tc -le 47 ]; then
        color=$((232 + tc / 2))
        [ $color -gt 255 ] && color=255
    elif [ $tc -le 100 ]; then
        # 48-100: 浅黄到黄 (229-220)
        color=$((229 - (tc - 48) * 9 / 52))
    elif [ $tc -le 200 ]; then
        # 100-200: 黄到橙 (220-208)
        color=$((220 - (tc - 100) * 12 / 100))
    elif [ $tc -le 500 ]; then
        # 200-500: 橙到深橙 (208-202)
        color=$((208 - (tc - 200) * 6 / 300))
    else
        # 500+: 深橙到红 (202-196)
        color=$((202 - (tc - 500) * 6 / 500))
        [ $color -lt 196 ] && color=196
    fi
    
    # 截断作者名并着色描述
    echo "$line" | awk -v color="$color" '{
        line=$0
        # 截断作者名
        if(match(line, /\033\[32m/)) {
            p1=substr(line, 1, RSTART+RLENGTH-1)
            r1=substr(line, RSTART+RLENGTH)
            if(match(r1, /\033\[0?m/)) {
                author=substr(r1, 1, RSTART-1)
                s1=substr(r1, RSTART)
                if(match(author, /^[a-zA-Z0-9]+/)) {
                    short=substr(author, 1, RLENGTH)
                    if(length(short)>8) short=substr(short,1,8)
                    line=p1 short s1
                }
            }
        }
        # 找最后一个 reset，之后是描述
        lastpos=0; tmp=line
        while(match(tmp, /\033\[0?m/)) {
            lastpos=lastpos+RSTART+RLENGTH-1
            tmp=substr(tmp, RSTART+RLENGTH)
        }
        if(lastpos>0 && lastpos<length(line)) {
            prefix=substr(line,1,lastpos)
            desc=substr(line,lastpos+1)
            if(desc!="") line=prefix "\033[38;5;" color "m" desc "\033[0m"
        }
        print line
    }'
done
