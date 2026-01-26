#!/bin/bash
# git-lf: 显示详细的 git log，包含文件变更统计
# 用法: git lf

cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}

git -c color.ui=always log --oneline -n 20 --format="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)" --date=relative --stat "$@" | awk -v cols="$cols" '
BEGIN {
    indent="        "
    first=1
    maxlines=3
    indentlen=8
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
    maxw=cols-indentlen
    gsub(/^ +/,"",stat)
    statlen=length(stat)
    
    # 构建所有行
    delete lines
    linecount=0
    cur=""
    for(i=1;i<=n;i++) {
        f="["arr[i]"]"
        if(cur=="") cur=f
        else if(length(cur" "f)>maxw) {
            lines[++linecount]=cur
            cur=f
        } else cur=cur" "f
    }
    if(cur!="") lines[++linecount]=cur
    
    # 计算最后一行需要的空间（文件名 + 空格 + stat）
    lastline_available=maxw-statlen-1
    
    if(linecount>maxlines) {
        # 超过3行，截断
        for(i=1;i<=2;i++) {
            print indent"\033[35m"lines[i]"\033[0m"
        }
        # 第三行截断
        if(lastline_available>6) {
            print indent"\033[35m"substr(lines[3],1,lastline_available-4)"... \033[33m"stat"\033[0m"
        } else {
            print indent"\033[35m""... \033[33m"stat"\033[0m"
        }
    } else if(linecount>1) {
        # 2-3行
        for(i=1;i<linecount;i++) {
            print indent"\033[35m"lines[i]"\033[0m"
        }
        # 最后一行
        if(length(lines[linecount])>lastline_available) {
            print indent"\033[35m"substr(lines[linecount],1,lastline_available-4)"... \033[33m"stat"\033[0m"
        } else {
            print indent"\033[35m"lines[linecount]" \033[33m"stat"\033[0m"
        }
    } else if(linecount==1) {
        # 只有一行，检查总长度
        if(length(lines[1])+1+statlen>maxw) {
            # 需要截断
            print indent"\033[35m"substr(lines[1],1,lastline_available-4)"... \033[33m"stat"\033[0m"
        } else {
            print indent"\033[35m"lines[1]" \033[33m"stat"\033[0m"
        }
    }
}'
