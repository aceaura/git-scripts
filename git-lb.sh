#!/bin/bash
# git-lb: 交互式浏览 git commit 历史
# 用法: git lb
# 依赖: fzf
# 三级导航: commit -> 文件 -> diff

# 生成带颜色的 commit 列表（优化版：单个 awk 处理）
generate_commits() {
    {
        git log -n 100 --format="%h" --shortstat --reverse
        echo "---SEPARATOR---"
        git log --oneline --color=always --format="%C(yellow)%h%C(reset) %C(cyan)%ad %C(green)%an%C(reset) %s" --date=relative -n 100 --reverse
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
    phase==2 && /\033\[/ {
        line=$0
        hash=""
        if(match(line, /\033\[33m[a-f0-9]+/)) {
            hash=substr(line, RSTART+5, RLENGTH-5)
        }
        
        tc=0
        for(i=1;i<=idx;i++) {
            if(hashes[i]==hash) { tc=changes[i]; break }
        }
        
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
}

# 生成文件列表（带颜色）
generate_files() {
    local hash=$1
    git diff-tree --no-commit-id --numstat -r "$hash" | awk '
    {
        add=$1; del=$2; filename=$3
        if(filename=="") next
        if(add=="-") add=0
        if(del=="-") del=0
        tc=add+del
        
        if(tc <= 47) color = 232 + int(tc / 2)
        else if(tc <= 100) color = 229 - int((tc - 48) * 9 / 52)
        else if(tc <= 200) color = 220 - int((tc - 100) * 12 / 100)
        else if(tc <= 500) color = 208 - int((tc - 200) * 6 / 300)
        else { color = 202 - int((tc - 500) * 6 / 500); if(color < 196) color = 196 }
        
        if(del==0 && add>0) status="\033[32m[+" add "]"
        else if(add==0 && del>0) status="\033[31m[-" del "]"
        else status="\033[33m[+" add " -" del "]"
        
        printf "%s\t%s \033[38;5;%dm%s\033[0m\n", filename, status, color, filename
    }'
}

# 第一级：选择 commit
while true; do
    commit=$(generate_commits | fzf --ansi --no-sort --tac --height=100% --no-hscroll \
        --preview 'git show --stat --color=always {1}' \
        --preview-window=right:38%:wrap \
        --bind 'pgdn:preview-page-down' \
        --bind 'pgup:preview-page-up' \
        --bind 'left:page-up' \
        --bind 'right:page-down' \
        --header '↑↓选择 | ←→翻页 | Enter详情 | PgUp/PgDn预览 | Esc退出')
    
    [ -z "$commit" ] && break
    
    hash=$(echo "$commit" | awk '{print $1}')
    
    # 第二级：选择文件
    while true; do
        file=$(generate_files "$hash" | \
            fzf --ansi --no-sort --height=100% \
                --with-nth=2.. \
                --delimiter='\t' \
                --preview "git show --color=always $hash -- {1}" \
                --preview-window=right:62%:wrap \
                --bind 'pgdn:preview-page-down' \
                --bind 'pgup:preview-page-up' \
                --bind 'left:page-up' \
                --bind 'right:page-down' \
                --header "↑↓选择 | ←→翻页 | Enter详情 | PgUp/PgDn预览 | Esc返回")
        
        [ -z "$file" ] && break
        
        # 第三级：查看文件 diff
        filename=$(echo "$file" | cut -f1)
        git show --color=always "$hash" -- "$filename" | less -R
    done
done
