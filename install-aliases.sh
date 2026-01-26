#!/bin/bash
# 安装所有 git alias
# 用法: bash install-aliases.sh

# git l - 简洁 log
git config --global alias.l "log --graph --decorate -n 20 --format='%C(yellow)%h %C(cyan)%ar%C(reset)%C(auto)%d%C(reset) %s %C(green)(%an)%C(reset)'"

# git lf - 详细 log 带文件变更
git config --global alias.lf "! git -c color.ui=always log --oneline -n 20 --format=\"%C(yellow)%h%C(reset) %C(cyan)%ad%C(reset) %s %C(green)(%an)%C(reset)\" --date=relative --stat | awk -v cols=\"\$(tput cols)\" 'BEGIN{indent=\"        \"; first=1} /^\033/ {if(line) {print line; printFiles(); if(!first) print \"\"} first=0; line=\$0; delete arr; n=0; stat=\"\"} !/^\033/ && /file.*changed/ {stat=\$0} !/^\033/ && !/file.*changed/ && / \\| / {split(\$1,a,\" \"); arr[++n]=a[1]} END {if(line) {print line; printFiles()}} function printFiles() {if(n==0) return; maxw=cols-8; cur=\"\"; for(i=1;i<=n;i++){f=\"[\"arr[i]\"]\"; if(cur==\"\") cur=f; else if(length(cur\" \"f)>maxw){print indent\"\\033[35m\"cur\"\\033[0m\"; cur=f} else cur=cur\" \"f} gsub(/^ +/,\"\",stat); if(cur) print indent\"\\033[35m\"cur\" \\033[33m\"stat\"\\033[0m\"}'"

# git lb - 浏览器打开仓库
git config --global alias.lb '!git-browse'

# git t - patch 版本 tag
git config --global alias.t '!f() { latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); major=$(echo $latest | sed "s/v//" | cut -d. -f1); minor=$(echo $latest | sed "s/v//" | cut -d. -f2); patch=$(echo $latest | sed "s/v//" | cut -d. -f3); new="v${major}.${minor}.$((patch+1))"; git tag $new && git push origin $new && echo "Tagged and pushed: $new"; }; f'

# git tt - minor 版本 tag
git config --global alias.tt '!f() { latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); major=$(echo $latest | sed "s/v//" | cut -d. -f1); minor=$(echo $latest | sed "s/v//" | cut -d. -f2); new="v${major}.$((minor+1)).0"; git tag $new && git push origin $new && echo "Tagged and pushed: $new"; }; f'

# git ttt - major 版本 tag
git config --global alias.ttt '!f() { latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); major=$(echo $latest | sed "s/v//" | cut -d. -f1); new="v$((major+1)).0.0"; git tag $new && git push origin $new && echo "Tagged and pushed: $new"; }; f'

# git s - 双向同步 alias
git config --global alias.s '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; ALIAS_FILE="git_aliases.txt"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; LOCAL_ALIASES=$(git config --global --get-regexp "^alias\\." | sort); REMOTE_ALIASES=""; if [ -f "$REPO_DIR/$ALIAS_FILE" ]; then REMOTE_ALIASES=$(cat "$REPO_DIR/$ALIAS_FILE" | sort); fi; UPLOADED=0; DOWNLOADED=0; echo "$LOCAL_ALIASES" | while IFS= read -r line; do [ -z "$line" ] && continue; alias_name=$(echo "$line" | cut -d" " -f1); if ! grep -q "^$alias_name " "$REPO_DIR/$ALIAS_FILE" 2>/dev/null; then echo "上传: $alias_name"; echo "$line" >> "$REPO_DIR/$ALIAS_FILE"; fi; done; if [ -f "$REPO_DIR/$ALIAS_FILE" ]; then sort -u "$ALIAS_FILE" -o "$ALIAS_FILE"; git add -A; git diff --cached --quiet || { git commit -m "sync: upload local aliases"; git push origin HEAD; echo "已上传本地新增 alias 到远端"; }; fi; echo "$REMOTE_ALIASES" | while IFS= read -r line; do [ -z "$line" ] && continue; alias_name=$(echo "$line" | cut -d" " -f1 | sed "s/alias\\.//"); alias_value=$(echo "$line" | cut -d" " -f2-); if ! git config --global --get "alias.$alias_name" >/dev/null 2>&1; then echo "安装: alias.$alias_name"; git config --global "alias.$alias_name" "$alias_value"; fi; done; }; f'

# git sr - 强制上传本地 alias
git config --global alias.sr '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; ALIAS_FILE="git_aliases.txt"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; > "$REPO_DIR/$ALIAS_FILE"; git config --global --get-regexp "^alias\\." | sort >> "$REPO_DIR/$ALIAS_FILE"; git add -A; git commit -m "sync: force upload all local aliases"; git push origin HEAD --force; echo "已强制用本地 alias 覆盖远端"; }; f'

# git sl - 强制下载远端 alias
git config --global alias.sl '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; ALIAS_FILE="git_aliases.txt"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; if [ ! -f "$REPO_DIR/$ALIAS_FILE" ]; then echo "远端没有 alias 文件"; exit 1; fi; echo "删除本地所有 git alias..."; git config --global --get-regexp "^alias\\." | while read -r line; do alias_name=$(echo "$line" | cut -d" " -f1); git config --global --unset "$alias_name" 2>/dev/null || true; done; echo "安装远端所有 git alias..."; while IFS= read -r line; do [ -z "$line" ] && continue; alias_name=$(echo "$line" | cut -d" " -f1 | sed "s/alias\\.//"); alias_value=$(echo "$line" | cut -d" " -f2-); echo "安装: alias.$alias_name"; git config --global "alias.$alias_name" "$alias_value"; done < "$REPO_DIR/$ALIAS_FILE"; echo "已强制用远端 alias 覆盖本地"; }; f'

# git sd - 删除指定 alias
git config --global alias.sd '!f() { if [ -z "$1" ]; then echo "用法: git sd <name>"; exit 1; fi; ALIAS_NAME="$1"; REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; ALIAS_FILE="git_aliases.txt"; if git config --global --get "alias.$ALIAS_NAME" >/dev/null 2>&1; then git config --global --unset "alias.$ALIAS_NAME"; echo "已删除本地: alias.$ALIAS_NAME"; else echo "本地不存在: alias.$ALIAS_NAME"; fi; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; if [ -f "$REPO_DIR/$ALIAS_FILE" ] && grep -q "^alias\\.$ALIAS_NAME " "$REPO_DIR/$ALIAS_FILE"; then sed -i "/^alias\\.$ALIAS_NAME /d" "$REPO_DIR/$ALIAS_FILE"; git add -A; git commit -m "sync: delete alias.$ALIAS_NAME"; git push origin HEAD; echo "已删除远端: alias.$ALIAS_NAME"; else echo "远端不存在: alias.$ALIAS_NAME"; fi; }; f'

echo "所有 alias 安装完成！"
git config --global --get-regexp '^alias\.' | sort
