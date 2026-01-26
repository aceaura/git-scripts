#!/bin/bash
# git-lf: 显示详细的 git log，包含文件变更统计
# 用法: git lf

git -c color.ui=always log --oneline -n 20 --format="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)" --date=relative --stat | awk -v cols="$(tput cols)" '
BEGIN {
    indent="        "
    first=1
}
/^\033/ {
    if(line) {
        print line
        printFiles()
        if(!first) print ""
    }
    first=0
    line=$0
    delete arr
    n=0
    stat=""
}
!/^\033/ && /file.*changed/ {
    stat=$0
}
!/^\033/ && !/file.*changed/ && / \| / {
    split($1,a," ")
    arr[++n]=a[1]
}
END {
    if(line) {
        print line
        printFiles()
    }
}
function printFiles() {
    if(n==0) return
    maxw=cols-8
    cur=""
    for(i=1;i<=n;i++) {
        f="["arr[i]"]"
        if(cur=="") cur=f
        else if(length(cur" "f)>maxw) {
            print indent"\033[35m"cur"\033[0m"
            cur=f
        } else cur=cur" "f
    }
    gsub(/^ +/,"",stat)
    if(cur) print indent"\033[35m"cur" \033[33m"stat"\033[0m"
}'
