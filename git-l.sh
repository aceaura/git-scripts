#!/bin/bash
# git-l: 显示简洁的 git log，带图形和装饰
# 用法: git l

# 合并两个 git log 输出，用 awk 一次性处理
{
    git log -n 100 --format="%h" --shortstat --reverse "$@"
    echo "---SEPARATOR---"
    git -c color.ui=always log --decorate -n 100 --format='%C(yellow)%h %C(cyan)%ar %C(green)%an%C(reset)%C(auto)%d%C(reset) %s' --reverse "$@"
} | awk '
BEGIN { phase=1; idx=0 }
/^---SEPARATOR---$/ { phase=2; next }
phase==1 && /^[a-f0-9]{7,}/ {
    idx++
    hashes[idx]=$1
    changes[idx]=0
    next
}
phase==1 && /insertion|deletion/ {
    tc=0
    if(match($0, /[0-9]+ insertion/)) tc+=substr($0, RSTART, RLENGTH-10)
    if(match($0, /[0-9]+ deletion/)) tc+=substr($0, RSTART, RLENGTH-9)
    changes[idx]=tc
    next
}
phase==2 && /^\033/ {
    # 提取 hash
    line=$0
    hash=""
    if(match(line, /\033\[33m[a-f0-9]+/)) {
        hash=substr(line, RSTART+5, RLENGTH-5)
    }
    
    # 查找对应的修改量
    tc=0
    for(i=1;i<=idx;i++) {
        if(hashes[i]==hash) { tc=changes[i]; break }
    }
    
    # 计算颜色
    if(tc <= 47) {
        color = 232 + int(tc / 2)
        if(color > 255) color = 255
    } else if(tc <= 100) {
        color = 229 - int((tc - 48) * 9 / 52)
    } else if(tc <= 200) {
        color = 220 - int((tc - 100) * 12 / 100)
    } else if(tc <= 500) {
        color = 208 - int((tc - 200) * 6 / 300)
    } else {
        color = 202 - int((tc - 500) * 6 / 500)
        if(color < 196) color = 196
    }
    
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
