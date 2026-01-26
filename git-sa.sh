#!/bin/bash
# git-sa: 显示所有 git alias 及说明
# 用法: git sa

cat << 'EOF'
usage: git <alias> [<args>]

Log commands:
   l              Show compact log with graph and colors
   lf             Show detailed log with file changes
   lb             Open repository in browser

Tag commands:
   t              Create and push patch version tag (x.y.Z+1)
   tt             Create and push minor version tag (x.Y+1.0)
   ttt            Create and push major version tag (X+1.0.0)

Sync commands:
   s              Sync aliases between local and remote
   sr             Force upload local aliases to remote
   sl             Force download remote aliases to local
   sd <name>      Delete alias from both local and remote
   sa             Show this help message

EOF

echo "Installed aliases:"
git config --global -l | grep ^alias | cut -d= -f1 | sed s/alias.// | sort | while read a; do echo "   $a"; done
