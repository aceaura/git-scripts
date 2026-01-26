#!/bin/bash
# git-sr: 强制用本地 alias 覆盖远端
# - 删除远端所有 alias 记录
# - 上传本地所有 alias
# 用法: git sr

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

# 清空远端 alias 文件
> "$REPO_DIR/$ALIAS_FILE"

# 导出本地所有 alias 到文件
git config --global --get-regexp '^alias\.' | sort >> "$REPO_DIR/$ALIAS_FILE"

# 提交并推送
cd "$REPO_DIR"
git add -A
git commit -m "sync: force upload all local aliases"
git push origin HEAD --force

echo "已强制用本地 alias 覆盖远端"
