#!/bin/bash
# git-ttt: 自动创建并推送 major 版本 tag (X+1.0.0)
# 用法: git ttt

latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
major=$(echo $latest | sed "s/v//" | cut -d. -f1)
new="v$((major+1)).0.0"
git tag $new && git push origin $new && echo "Tagged and pushed: $new"
