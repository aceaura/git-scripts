#!/bin/bash
# git-t: 自动创建并推送 patch 版本 tag (x.y.Z+1)
# 用法: git t

latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
major=$(echo $latest | sed "s/v//" | cut -d. -f1)
minor=$(echo $latest | sed "s/v//" | cut -d. -f2)
patch=$(echo $latest | sed "s/v//" | cut -d. -f3)
new="v${major}.${minor}.$((patch+1))"
git tag $new && git push origin $new && echo "Tagged and pushed: $new"
