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
    filecount[idx]=0
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
    # 提取文件名和修改量
    fname=$1
    # 提取修改行数 (+ 和 - 的数量)
    fchanges=0
    for(k=3;k<=NF;k++) {
        gsub(/[^+-]/,"",$k)
        fchanges += length($k)
    }
    filecount[idx]++
    filenames[idx,filecount[idx]]=fname
    filechanges[idx,filecount[idx]]=fchanges
    next
}
END {
    for(i=1; i<=idx; i++) {
        if(i>1) print ""
        printCommit(i)
        printFiles(i)
    }
}
function calcColor(tc) {
    # 96级颜色渐变: 232-255(灰度24级) + 彩色(黄->橙->红)
    if(tc <= 47) {
        c = 232 + int(tc / 2)
        if(c > 255) c = 255
    } else if(tc <= 100) {
        c = 229 - int((tc - 48) * 9 / 52)
    } else if(tc <= 200) {
        c = 220 - int((tc - 100) * 12 / 100)
    } else if(tc <= 500) {
        c = 208 - int((tc - 200) * 6 / 300)
    } else {
        c = 202 - int((tc - 500) * 6 / 500)
        if(c < 196) c = 196
    }
    return c
}
function calcPurple(tc) {
    # 紫色渐变: 从深紫(53)到亮紫(177)
    # tc: 0-5 -> 53, 5-15 -> 89, 15-30 -> 125, 30-60 -> 128, 60-100 -> 134, 100+ -> 177
    if(tc <= 5) return 53
    else if(tc <= 15) return 89
    else if(tc <= 30) return 125
    else if(tc <= 60) return 128
    else if(tc <= 100) return 134
    else if(tc <= 200) return 170
    else return 177
}
function printCommit(i) {
    tc=changes[i]
    color=calcColor(tc)
    
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
    if(filecount[i]==0) return
    maxw=cols-indentlen
    stat=stats[i]
    gsub(/^ +/,"",stat)
    statlen=length(stat)
    
    n=filecount[i]
    
    # 构建带颜色的文件列表
    delete lines
    linecount=0
    cur=""
    curlen=0
    
    for(j=1;j<=n;j++) {
        fname=filenames[i,j]
        fc=filechanges[i,j]
        pc=calcPurple(fc)
        f="\033[38;5;" pc "m[" fname "]\033[0m"
        flen=length(fname)+2  # 实际显示长度
        
        if(cur=="") {
            cur=f
            curlen=flen
        } else if(curlen+1+flen>maxw) {
            lines[++linecount]=cur
            cur=f
            curlen=flen
        } else {
            cur=cur " " f
            curlen=curlen+1+flen
        }
    }
    if(cur!="") {
        lines[++linecount]=cur
        linelens[linecount]=curlen
    }
    
    # 检查最后一行加 stat 是否超宽
    if(linecount>0 && linelens[linecount]+1+statlen>maxw) {
        # 需要重新分配，简化处理：直接截断
    }
    
    if(linecount>maxlines) {
        for(j=1;j<=2;j++) print indent lines[j]
        print indent "... \033[33m" stat "\033[0m"
    } else {
        for(j=1;j<linecount;j++) print indent lines[j]
        if(linecount>0) print indent lines[linecount] " \033[33m" stat "\033[0m"
    }
}'
