#!/bin/bash
# git-lf: 显示详细的 git log，包含文件变更统计
# 用法: git lf

cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}

git -c color.ui=always log --oneline -n 20 --format="%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)" --date=relative --stat --reverse "$@" | awk -v cols="$cols" '
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
    
    # 构建所有行，最后一行要预留 stat 空间
    delete lines
    linecount=0
    cur=""
    
    for(i=1;i<=n;i++) {
        f="["arr[i]"]"
        if(cur=="") {
            cur=f
        } else if(length(cur" "f)>maxw) {
            lines[++linecount]=cur
            cur=f
        } else {
            cur=cur" "f
        }
    }
    if(cur!="") lines[++linecount]=cur
    
    # 重新计算：最后一行需要加上 stat，如果放不下就把 stat 单独放一行
    # 检查最后一行加上 stat 是否超宽
    if(linecount>0 && length(lines[linecount])+1+statlen>maxw) {
        # stat 放不下，需要重新分配
        # 把最后一行的部分文件移到新行，或者 stat 单独一行
        lastline=lines[linecount]
        # 尝试拆分最后一行
        delete newarr
        split(lastline, newarr, " ")
        newlast=""
        for(j in newarr) {
            if(newlast=="") newlast=newarr[j]
            else if(length(newlast" "newarr[j])+1+statlen<=maxw) {
                newlast=newlast" "newarr[j]
            } else {
                # 放不下了，把之前的作为新行
                lines[linecount]=newlast
                linecount++
                newlast=newarr[j]
            }
        }
        if(newlast!="") {
            lines[linecount]=newlast
        }
    }
    
    # 现在输出，最多3行
    if(linecount>maxlines) {
        # 超过3行，前2行正常打印，第3行截断
        for(i=1;i<=2;i++) {
            print indent"\033[35m"lines[i]"\033[0m"
        }
        # 第3行：截断 + ... + stat
        available=maxw-statlen-5
        if(available>0) {
            print indent"\033[35m"substr(lines[3],1,available)"... \033[33m"stat"\033[0m"
        } else {
            print indent"\033[35m""... \033[33m"stat"\033[0m"
        }
    } else {
        # <=3行，正常打印
        for(i=1;i<linecount;i++) {
            print indent"\033[35m"lines[i]"\033[0m"
        }
        # 最后一行加 stat
        if(linecount>0) {
            print indent"\033[35m"lines[linecount]" \033[33m"stat"\033[0m"
        }
    }
}'
