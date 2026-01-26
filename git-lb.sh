#!/bin/bash
# git-lb: 交互式浏览 git commit 历史
# 用法: git lb
# 依赖: fzf

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
done < <(git log -n 100 --format="%h" --shortstat)

# 生成带颜色的列表
git log --oneline --color=always --format="%C(yellow)%h%C(reset) %C(cyan)%ad %C(green)%an%C(reset) %s" --date=relative -n 100 | while IFS= read -r line; do
    hash=$(echo "$line" | sed -n 's/.*\[33m\([a-f0-9]\{7,\}\).*/\1/p')
    tc=${changes[$hash]:-0}
    
    # 96级颜色渐变
    if [ $tc -le 47 ]; then
        color=$((232 + tc / 2))
        [ $color -gt 255 ] && color=255
    elif [ $tc -le 100 ]; then
        color=$((229 - (tc - 48) * 9 / 52))
    elif [ $tc -le 200 ]; then
        color=$((220 - (tc - 100) * 12 / 100))
    elif [ $tc -le 500 ]; then
        color=$((208 - (tc - 200) * 6 / 300))
    else
        color=$((202 - (tc - 500) * 6 / 500))
        [ $color -lt 196 ] && color=196
    fi
    
    echo "$line" | awk -v color="$color" '{
        line=$0
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
done | fzf --ansi --no-sort --reverse --height=100% \
    --preview 'git show --color=always {1}' \
    --preview-window=right:60%:wrap \
    --bind 'enter:execute(git show --color=always {1} | less -R)' \
    --bind 'pgdn:preview-page-down' \
    --bind 'pgup:preview-page-up' \
    --header '↑↓选择 | Enter查看详情 | PageUp/PageDown翻页预览 | Esc退出'
