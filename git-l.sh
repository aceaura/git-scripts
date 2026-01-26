#!/bin/bash
# git-l: 显示简洁的 git log，带图形和装饰
# 用法: git l

git log --graph --decorate -n 20 --format='%C(yellow)%h %C(cyan)%ar%C(reset)%C(auto)%d%C(reset) %s %C(green)(%an)%C(reset)' --reverse "$@"
