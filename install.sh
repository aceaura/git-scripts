#!/bin/bash
# install.sh: 从远端下载并安装所有 git alias
# 用法: bash install.sh 或 curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/main/install.sh | bash

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

echo ""
echo "安装完成！当前所有 git alias:"
git config --global --get-regexp '^alias\.' | sort
