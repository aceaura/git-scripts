#!/bin/bash
# git-sa: 显示所有 git alias 及说明
# 用法: git sa

echo "Git Aliases:"
echo "============"
echo ""
echo "  l     - 简洁 log，带图形和颜色"
echo "  lf    - 详细 log，显示文件变更"
echo "  lb    - 浏览器打开仓库"
echo ""
echo "  t     - 创建 patch 版本 tag (x.y.Z+1)"
echo "  tt    - 创建 minor 版本 tag (x.Y+1.0)"
echo "  ttt   - 创建 major 版本 tag (X+1.0.0)"
echo ""
echo "  s     - 双向同步 alias (本地<->远端)"
echo "  sr    - 强制上传本地 alias 到远端"
echo "  sl    - 强制下载远端 alias 到本地"
echo "  sd    - 删除指定 alias (git sd <name>)"
echo "  sa    - 显示此帮助信息"
echo ""
echo "当前已安装的 alias:"
git config --global -l | grep ^alias | cut -d= -f1 | sed 's/alias\./  /' | sort
