#!/bin/bash
# git-sc: 比较本地和远端的 alias 差异
# 用法: git sc

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
    case "$name" in s|sr|sl|sd|sa|sc) continue ;; esac
    REMOTE_ALIASES="$REMOTE_ALIASES $name"
done

# 获取本地所有 alias
LOCAL_ALIASES=$(git config --global -l 2>/dev/null | grep ^alias | cut -d= -f1 | sed 's/alias\.//' | grep -v '^s$\|^sr$\|^sl$\|^sd$\|^sa$\|^sc$' | tr '\n' ' ')

# 未安装（远端有但本地没有）
NOT_INSTALLED=""
for name in $REMOTE_ALIASES; do
    if ! echo " $LOCAL_ALIASES " | grep -q " $name "; then
        NOT_INSTALLED="$NOT_INSTALLED $name"
    fi
done

# 未发布（本地有但远端没有）
NOT_PUBLISHED=""
for name in $LOCAL_ALIASES; do
    if ! echo " $REMOTE_ALIASES " | grep -q " $name "; then
        NOT_PUBLISHED="$NOT_PUBLISHED $name"
    fi
done

# 输出结果
if [ -z "$NOT_INSTALLED" ] && [ -z "$NOT_PUBLISHED" ]; then
    echo "本地和远端已完全同步"
    exit 0
fi

if [ -n "$NOT_INSTALLED" ]; then
    echo "未安装 (远端有本地没有):"
    for name in $NOT_INSTALLED; do
        desc=$(sed -n '2p' "$REPO_DIR/git-$name.sh" 2>/dev/null | sed 's/^# git-[^:]*: //' | sed 's/^# //')
        printf "   %-14s %s\n" "$name" "$desc"
    done
    echo ""
    echo "运行 git sl 安装全部，或 git s 同步"
fi

if [ -n "$NOT_PUBLISHED" ]; then
    if [ -n "$NOT_INSTALLED" ]; then
        echo ""
    fi
    echo "未发布 (本地有远端没有):"
    for name in $NOT_PUBLISHED; do
        echo "   $name"
    done
    echo ""
    echo "运行 git sr 发布全部，或 git s 同步"
fi
