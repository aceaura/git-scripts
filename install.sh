#!/bin/bash
# install.sh: 从远端下载并安装所有 git alias
# 用法: curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash

set -e

REPO_URL="https://github.com/aceaura/git-scripts"
REPO_DIR="$HOME/.git-scripts-sync"

# 克隆或更新仓库
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
else
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# 删除本地所有 alias
echo "删除本地所有 git alias..."
git config --global --get-regexp '^alias\.' 2>/dev/null | while read -r line; do
    alias_name=$(echo "$line" | cut -d' ' -f1)
    git config --global --unset "$alias_name" 2>/dev/null || true
done

# 从 .sh 文件动态安装 alias
echo "安装远端所有 git alias..."
for script in "$REPO_DIR"/git-*.sh; do
    [ -f "$script" ] || continue
    name=$(basename "$script" .sh | sed 's/^git-//')
    # 跳过同步相关的脚本，它们需要特殊处理
    case "$name" in s|sr|sl|sd) continue ;; esac
    
    # 读取脚本内容（跳过 shebang 和注释）
    content=$(sed '/^#!/d; /^#/d; /^$/d' "$script" | tr '\n' '; ' | sed 's/; $//')
    
    echo "安装: alias.$name"
    git config --global "alias.$name" "!$content"
done

# 安装同步命令（s, sr, sl, sd）- 这些需要内联
echo "安装同步命令..."

git config --global alias.s '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh | sed "s/^git-//"); case "$name" in s|sr|sl|sd) continue ;; esac; if ! git config --global --get "alias.$name" >/dev/null 2>&1; then content=$(sed "/^#!/d; /^#/d; /^$/d" "$script" | tr "\\n" "; " | sed "s/; $//"); echo "安装: alias.$name"; git config --global "alias.$name" "!$content"; fi; done; LOCAL=$(git config --global --get-regexp "^alias\\." 2>/dev/null | grep -v "alias\\.s[rld]\\? " | sort); cd "$REPO_DIR"; CHANGED=0; for alias_line in $LOCAL; do alias_name=$(echo "$alias_line" | cut -d" " -f1 | sed "s/alias\\.//"); script_file="$REPO_DIR/git-$alias_name.sh"; if [ ! -f "$script_file" ]; then echo "上传: $alias_name"; alias_value=$(git config --global --get "alias.$alias_name"); echo "#!/bin/bash" > "$script_file"; echo "$alias_value" | sed "s/^!//" >> "$script_file"; CHANGED=1; fi; done; if [ $CHANGED -eq 1 ]; then git add -A; git commit -m "sync: upload local aliases"; git push origin HEAD; fi; echo "同步完成"; }; f'

git config --global alias.sr '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; rm -f "$REPO_DIR"/git-*.sh; LOCAL=$(git config --global --get-regexp "^alias\\." 2>/dev/null | grep -v "alias\\.s[rld]\\? "); echo "$LOCAL" | while IFS= read -r line; do [ -z "$line" ] && continue; alias_name=$(echo "$line" | cut -d" " -f1 | sed "s/alias\\.//"); alias_value=$(git config --global --get "alias.$alias_name"); script_file="$REPO_DIR/git-$alias_name.sh"; echo "上传: $alias_name"; echo "#!/bin/bash" > "$script_file"; echo "$alias_value" | sed "s/^!//" >> "$script_file"; done; git add -A; git commit -m "sync: force upload all local aliases"; git push origin HEAD --force; echo "已强制用本地 alias 覆盖远端"; }; f'

git config --global alias.sl '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; echo "删除本地所有 git alias..."; git config --global --get-regexp "^alias\\." 2>/dev/null | while read -r line; do alias_name=$(echo "$line" | cut -d" " -f1); git config --global --unset "$alias_name" 2>/dev/null || true; done; echo "安装远端所有 git alias..."; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh | sed "s/^git-//"); case "$name" in s|sr|sl|sd) continue ;; esac; content=$(sed "/^#!/d; /^#/d; /^$/d" "$script" | tr "\\n" "; " | sed "s/; $//"); echo "安装: alias.$name"; git config --global "alias.$name" "!$content"; done; git config --global alias.s "!f() { REPO_URL=\"https://github.com/aceaura/git-scripts\"; REPO_DIR=\"\$HOME/.git-scripts-sync\"; if [ -d \"\$REPO_DIR\" ]; then cd \"\$REPO_DIR\"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone \"\$REPO_URL\" \"\$REPO_DIR\"; cd \"\$REPO_DIR\"; fi; echo \"同步完成\"; }; f"; git config --global alias.sr "!echo sr"; git config --global alias.sl "!echo sl"; git config --global alias.sd "!echo sd"; echo "已强制用远端 alias 覆盖本地"; }; f'

git config --global alias.sd '!f() { if [ -z "$1" ]; then echo "用法: git sd <name>"; exit 1; fi; ALIAS_NAME="$1"; REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if git config --global --get "alias.$ALIAS_NAME" >/dev/null 2>&1; then git config --global --unset "alias.$ALIAS_NAME"; echo "已删除本地: alias.$ALIAS_NAME"; else echo "本地不存在: alias.$ALIAS_NAME"; fi; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; script_file="$REPO_DIR/git-$ALIAS_NAME.sh"; if [ -f "$script_file" ]; then rm -f "$script_file"; git add -A; git commit -m "sync: delete alias.$ALIAS_NAME"; git push origin HEAD; echo "已删除远端: alias.$ALIAS_NAME"; else echo "远端不存在: alias.$ALIAS_NAME"; fi; }; f'

echo ""
echo "安装完成！当前所有 git alias:"
git config --global --get-regexp '^alias\.' | sort
