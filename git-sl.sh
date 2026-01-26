#!/bin/bash
# git-sl: 强制用远端 alias 覆盖本地
# - 删除本地所有 alias
# - 安装远端所有 alias
# 用法: git sl

set -e

REPO_URL="https://github.com/aceaura/git-scripts"
REPO_DIR="$HOME/.git-scripts-sync"
ALIAS_FILE="git_aliases.txt"

# 克隆或更新仓库
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
else
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

if [ ! -f "$REPO_DIR/$ALIAS_FILE" ]; then
    echo "远端没有 alias 文件"
    exit 1
fi

# 删除本地所有 alias
echo "删除本地所有 git alias..."
git config --global --get-regexp '^alias\.' | while read -r line; do
    alias_name=$(echo "$line" | cut -d' ' -f1)
    git config --global --unset "$alias_name" 2>/dev/null || true
done

# 安装远端所有 alias
echo "安装远端所有 git alias..."
while IFS= read -r line; do
    [ -z "$line" ] && continue
    alias_name=$(echo "$line" | cut -d' ' -f1 | sed 's/alias\.//')
    alias_value=$(echo "$line" | cut -d' ' -f2-)
    echo "安装: alias.$alias_name"
    git config --global "alias.$alias_name" "$alias_value"
done < "$REPO_DIR/$ALIAS_FILE"

echo "已强制用远端 alias 覆盖本地"
