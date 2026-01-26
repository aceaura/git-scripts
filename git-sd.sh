#!/bin/bash
# git-sd: 同时删除本地和远端的指定 alias
# 用法: git sd <name>
# 示例: git sd ttt

set -e

if [ -z "$1" ]; then
    echo "用法: git sd <name>"
    echo "示例: git sd ttt"
    exit 1
fi

ALIAS_NAME="$1"
REPO_URL="https://github.com/aceaura/git-scripts"
REPO_DIR="$HOME/.git-scripts-sync"
ALIAS_FILE="git_aliases.txt"

DELETED_LOCAL=0
DELETED_REMOTE=0

# 删除本地 alias
if git config --global --get "alias.$ALIAS_NAME" >/dev/null 2>&1; then
    git config --global --unset "alias.$ALIAS_NAME"
    echo "已删除本地: alias.$ALIAS_NAME"
    DELETED_LOCAL=1
else
    echo "本地不存在: alias.$ALIAS_NAME"
fi

# 克隆或更新仓库
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
else
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# 删除远端 alias
if [ -f "$REPO_DIR/$ALIAS_FILE" ] && grep -q "^alias\.$ALIAS_NAME " "$REPO_DIR/$ALIAS_FILE"; then
    sed -i "/^alias\.$ALIAS_NAME /d" "$REPO_DIR/$ALIAS_FILE"
    git add -A
    git commit -m "sync: delete alias.$ALIAS_NAME"
    git push origin HEAD
    echo "已删除远端: alias.$ALIAS_NAME"
    DELETED_REMOTE=1
else
    echo "远端不存在: alias.$ALIAS_NAME"
fi

if [ $DELETED_LOCAL -eq 0 ] && [ $DELETED_REMOTE -eq 0 ]; then
    echo "本地和远端都不存在 alias.$ALIAS_NAME"
fi
