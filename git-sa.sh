#!/bin/bash
# git-sa: 显示所有 git alias 状态
# 用法: git sa

REPO_URL="https://github.com/aceaura/git-scripts"
REPO_DIR="$HOME/.git-scripts-sync"

# 更新仓库
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git fetch origin >/dev/null 2>&1
    git reset --hard origin/main >/dev/null 2>&1 || git reset --hard origin/master >/dev/null 2>&1
else
    git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1
    cd "$REPO_DIR"
fi

# 获取远端所有 alias（从 .sh 文件）
REMOTE_ALIASES=""
for script in "$REPO_DIR"/git-*.sh; do
    [ -f "$script" ] || continue
    name=$(basename "$script" .sh | sed 's/^git-//')
    case "$name" in s|sr|sl|sd|sa) continue ;; esac
    REMOTE_ALIASES="$REMOTE_ALIASES $name"
done

# 获取本地所有 alias
LOCAL_ALIASES=$(git config --global -l 2>/dev/null | grep ^alias | cut -d= -f1 | sed 's/alias\.//' | grep -v '^s$\|^sr$\|^sl$\|^sd$\|^sa$' | tr '\n' ' ')

echo "用法: git <alias> [<args>]"
echo ""
echo "可用命令 (远端):"
for name in $REMOTE_ALIASES; do
    # 读取脚本第二行注释作为描述
    desc=$(sed -n '2p' "$REPO_DIR/git-$name.sh" 2>/dev/null | sed 's/^# git-[^:]*: //' | sed 's/^# //')
    printf "   %-14s %s\n" "$name" "$desc"
done
echo ""
echo "同步命令 (内置):"
echo "   s              双向同步本地和远端的 alias"
echo "   sr             强制上传本地 alias 到远端"
echo "   sl             强制下载远端 alias 到本地"
echo "   sd <name>      同时删除本地和远端的指定 alias"
echo "   sa             显示此帮助信息"

# 未安装（远端有但本地没有）
NOT_INSTALLED=""
for name in $REMOTE_ALIASES; do
    if ! echo " $LOCAL_ALIASES " | grep -q " $name "; then
        NOT_INSTALLED="$NOT_INSTALLED $name"
    fi
done
if [ -n "$NOT_INSTALLED" ]; then
    echo ""
    echo "未安装 (运行 git sl 安装):"
    for name in $NOT_INSTALLED; do
        echo "   $name"
    done
fi

# 未发布（本地有但远端没有）
NOT_PUBLISHED=""
for name in $LOCAL_ALIASES; do
    if ! echo " $REMOTE_ALIASES " | grep -q " $name "; then
        NOT_PUBLISHED="$NOT_PUBLISHED $name"
    fi
done
if [ -n "$NOT_PUBLISHED" ]; then
    echo ""
    echo "未发布 (运行 git sr 发布):"
    for name in $NOT_PUBLISHED; do
        echo "   $name"
    done
fi
