#!/bin/bash
# git-lf: 显示详细的 git log，包含文件变更统计
# 用法: git lf

cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}

git -c color.ui=always log --oneline -n 100 --format="%C(yellow)%h%C(reset) %C(cyan)%ad %C(green)%an%C(reset) %s" --date=relative --stat --reverse "$@" | awk -v cols="$cols" '
BEGIN {
    indent="        "
    maxlines=3
    indentlen=8
    idx=0
}
/^\033/ {
    idx++
    commits[idx]=$0
    # 截断作者名
    line=$0
    if(match(line, /\033\[32m/)) {
        prefix=substr(line, 1, RSTART+RLENGTH-1)
        rest=substr(line, RSTART+RLENGTH)
        if(match(rest, /\033\[0?m/)) {
            author=substr(rest, 1, RSTART-1)
            suffix=substr(rest, RSTART)
            if(match(author, /^[a-zA-Z0-9]+/)) {
                shortname=substr(author, 1, RLENGTH)
                if(length(shortname)>8) shortname=substr(shortname,1,8)
                commits[idx]=prefix shortname suffix
            }
        }
    }
    files[idx]=""
    stats[idx]=""
    changes[idx]=0
    next
}
/file.*changed/ {
    stats[idx]=$0
    tmp=$0
    if(match(tmp, /[0-9]+ insertion/)) {
        changes[idx] += substr(tmp, RSTART, RLENGTH-10)
    }
    if(match(tmp, /[0-9]+ deletion/)) {
        changes[idx] += substr(tmp, RSTART, RLENGTH-9)
    }
    next
}
/ \| / {
    split($1,a," ")
    if(files[idx]=="") files[idx]=a[1]
    else files[idx]=files[idx]" "a[1]
    next
}
END {
    for(i=1; i<=idx; i++) {
        if(i>1) print ""
        printCommit(i)
        printFiles(i)
    }
}
function printCommit(i) {
    tc=changes[i]
    # 颜色渐变：灰->白->黄->橙->红
    if(tc <= 5) color = 240       # 深灰
    else if(tc <= 15) color = 245 # 灰
    else if(tc <= 30) color = 252 # 浅灰/白
    else if(tc <= 60) color = 228 # 浅黄
    else if(tc <= 100) color = 220 # 黄
    else if(tc <= 200) color = 214 # 橙
    else if(tc <= 500) color = 208 # 深橙
    else color = 196              # 红
    
    line=commits[i]
    lastpos = 0
    tmpline = line
    while(match(tmpline, /\033\[0?m/)) {
        lastpos = lastpos + RSTART + RLENGTH - 1
        tmpline = substr(tmpline, RSTART + RLENGTH)
    }
    if(lastpos > 0 && lastpos < length(line)) {
        prefix = substr(line, 1, lastpos)
        desc = substr(line, lastpos + 1)
        if(desc != "") {
            line = prefix "\033[38;5;" color "m" desc "\033[0m"
        }
    }
    print line
}
function printFiles(i) {
    if(files[i]=="") return
    maxw=cols-indentlen
    stat=stats[i]
    gsub(/^ +/,"",stat)
    statlen=length(stat)
    
    # 分割文件列表
    n=split(files[i], arr, " ")
    
    delete lines
    linecount=0
    cur=""
    
    for(j=1;j<=n;j++) {
        f="["arr[j]"]"
        if(cur=="") cur=f
        else if(length(cur" "f)>maxw) {
            lines[++linecount]=cur
            cur=f
        } else cur=cur" "f
    }
    if(cur!="") lines[++linecount]=cur
    
    if(linecount>0 && length(lines[linecount])+1+statlen>maxw) {
        lastline=lines[linecount]
        delete newarr
        nn=split(lastline, newarr, " ")
        newlast=""
        for(j=1;j<=nn;j++) {
            if(newlast=="") newlast=newarr[j]
            else if(length(newlast" "newarr[j])+1+statlen<=maxw) newlast=newlast" "newarr[j]
            else {
                lines[linecount]=newlast
                linecount++
                newlast=newarr[j]
            }
        }
        if(newlast!="") lines[linecount]=newlast
    }
    
    if(linecount>maxlines) {
        for(j=1;j<=2;j++) print indent"\033[35m"lines[j]"\033[0m"
        available=maxw-statlen-5
        if(available>0) print indent"\033[35m"substr(lines[3],1,available)"... \033[33m"stat"\033[0m"
        else print indent"\033[35m""... \033[33m"stat"\033[0m"
    } else {
        for(j=1;j<linecount;j++) print indent"\033[35m"lines[j]"\033[0m"
        if(linecount>0) print indent"\033[35m"lines[linecount]" \033[33m"stat"\033[0m"
    }
}'
