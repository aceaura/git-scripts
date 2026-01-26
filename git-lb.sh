#!/bin/bash
# git-lb: 在浏览器中打开当前仓库
# 用法: git lb

# 获取远程 URL
url=$(git remote get-url origin 2>/dev/null)

if [ -z "$url" ]; then
    echo "错误: 没有找到 origin 远程仓库"
    exit 1
fi

# 转换 SSH URL 为 HTTPS URL
# git@github.com:user/repo.git -> https://github.com/user/repo
# https://github.com/user/repo.git -> https://github.com/user/repo
url=$(echo "$url" | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')

# 打开浏览器
case "$(uname -s)" in
    Darwin*)  open "$url" ;;
    Linux*)   xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null || echo "请手动打开: $url" ;;
    MINGW*|MSYS*|CYGWIN*)  start "$url" ;;
    *)        echo "请手动打开: $url" ;;
esac
