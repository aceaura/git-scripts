#!/bin/bash
# git-s: 同步本地和远端的 git alias
# - 本地多的上传到远端
# - 远端多的安装到本地
# 用法: git s

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

# 获取本地所有 alias
LOCAL_ALIASES=$(git config --global --get-regexp '^alias\.' | sort)

# 获取远端所有 alias
REMOTE_ALIASES=""
if [ -f "$REPO_DIR/$ALIAS_FILE" ]; then
    REMOTE_ALIASES=$(cat "$REPO_DIR/$ALIAS_FILE" | sort)
fi

UPLOADED=0
DOWNLOADED=0

# 本地有但远端没有的 -> 上传
while IFS= read -r line; do
    [ -z "$line" ] && continue
    alias_name=$(echo "$line" | cut -d' ' -f1)
    if ! grep -q "^$alias_name " "$REPO_DIR/$ALIAS_FILE" 2>/dev/null; then
        echo "上传: $alias_name"
        echo "$line" >> "$REPO_DIR/$ALIAS_FILE"
        UPLOADED=1
    fi
done <<< "$LOCAL_ALIASES"

# 远端有但本地没有的 -> 安装
while IFS= read -r line; do
    [ -z "$line" ] && continue
    alias_name=$(echo "$line" | cut -d' ' -f1 | sed 's/alias\.//')
    alias_value=$(echo "$line" | cut -d' ' -f2-)
    if ! git config --global --get "alias.$alias_name" >/dev/null 2>&1; then
        echo "安装: alias.$alias_name"
        git config --global "alias.$alias_name" "$alias_value"
        DOWNLOADED=1
    fi
done <<< "$REMOTE_ALIASES"

# 如果有新上传的，提交并推送
if [ $UPLOADED -eq 1 ]; then
    cd "$REPO_DIR"
    # 重新整理文件，去重排序
    sort -u "$ALIAS_FILE" -o "$ALIAS_FILE"
    git add -A
    git commit -m "sync: upload local aliases"
    git push origin HEAD
    echo "已上传本地新增 alias 到远端"
fi

if [ $DOWNLOADED -eq 1 ]; then
    echo "已安装远端新增 alias 到本地"
fi

if [ $UPLOADED -eq 0 ] && [ $DOWNLOADED -eq 0 ]; then
    echo "本地和远端已同步，无需操作"
fi
