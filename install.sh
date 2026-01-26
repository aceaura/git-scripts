#!/bin/bash
# install.sh: 从远端下载并安装所有 git alias
# 用法: curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash

set -e

REPO_URL="https://github.com/aceaura/git-scripts"
REPO_DIR="$HOME/.git-scripts-sync"
BIN_DIR="$HOME/.git-scripts-bin"

# 确保 bin 目录存在
mkdir -p "$BIN_DIR"

# 自动添加 PATH
add_to_path() {
    local shell_rc=""
    local path_line="export PATH=\"\$HOME/.git-scripts-bin:\$PATH\""
    
    # 检测当前 shell 配置文件
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -f "$HOME/.profile" ]; then
        shell_rc="$HOME/.profile"
    fi
    
    # 如果找到配置文件且未添加过，则添加
    if [ -n "$shell_rc" ]; then
        if ! grep -q ".git-scripts-bin" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# git-scripts bin path" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            echo "已添加 PATH 到 $shell_rc"
            echo "请运行: source $shell_rc 或重新打开终端"
        fi
    fi
    
    # 当前会话也添加
    export PATH="$BIN_DIR:$PATH"
}

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

# 安装脚本到 bin 目录，并创建对应的 alias
echo "安装远端所有 git alias..."
for script in "$REPO_DIR"/git-*.sh; do
    [ -f "$script" ] || continue
    name=$(basename "$script" .sh)
    alias_name=$(echo "$name" | sed 's/^git-//')
    
    # 跳过同步相关的脚本
    case "$alias_name" in s|sr|sl|sd) continue ;; esac
    
    # 复制脚本到 bin 目录
    cp "$script" "$BIN_DIR/$name"
    chmod +x "$BIN_DIR/$name"
    
    # 创建 alias 指向脚本
    echo "安装: alias.$alias_name -> $name"
    git config --global "alias.$alias_name" "!$name"
done

# 安装同步命令
echo "安装同步命令..."

git config --global alias.s '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; mkdir -p "$BIN_DIR"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; UPLOADED=0; DOWNLOADED=0; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh); alias_name=$(echo "$name" | sed "s/^git-//"); case "$alias_name" in s|sr|sl|sd) continue ;; esac; if [ ! -f "$BIN_DIR/$name" ]; then echo "下载: $alias_name"; cp "$script" "$BIN_DIR/$name"; chmod +x "$BIN_DIR/$name"; git config --global "alias.$alias_name" "!$name"; DOWNLOADED=1; fi; done; for bin_script in "$BIN_DIR"/git-*; do [ -f "$bin_script" ] || continue; name=$(basename "$bin_script"); alias_name=$(echo "$name" | sed "s/^git-//"); case "$alias_name" in s|sr|sl|sd) continue ;; esac; if [ ! -f "$REPO_DIR/$name.sh" ]; then echo "上传: $alias_name"; cp "$bin_script" "$REPO_DIR/$name.sh"; UPLOADED=1; fi; done; if [ $UPLOADED -eq 1 ]; then cd "$REPO_DIR"; git add -A; git commit -m "sync: upload local aliases"; git push origin HEAD; fi; if [ $UPLOADED -eq 0 ] && [ $DOWNLOADED -eq 0 ]; then echo "已同步，无需操作"; else echo "同步完成"; fi; }; f'

git config --global alias.sr '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; rm -f "$REPO_DIR"/git-*.sh; for bin_script in "$BIN_DIR"/git-*; do [ -f "$bin_script" ] || continue; name=$(basename "$bin_script"); echo "上传: $name"; cp "$bin_script" "$REPO_DIR/$name.sh"; done; cd "$REPO_DIR"; git add -A; git commit -m "sync: force upload all local aliases"; git push origin HEAD --force; echo "已强制用本地覆盖远端"; }; f'

git config --global alias.sl '!f() { curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash; }; f'

git config --global alias.sd '!f() { if [ -z "$1" ]; then echo "用法: git sd <name>"; exit 1; fi; NAME="$1"; REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; SCRIPT="git-$NAME"; if [ -f "$BIN_DIR/$SCRIPT" ]; then rm -f "$BIN_DIR/$SCRIPT"; echo "已删除本地: $SCRIPT"; fi; if git config --global --get "alias.$NAME" >/dev/null 2>&1; then git config --global --unset "alias.$NAME"; echo "已删除本地 alias: $NAME"; fi; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; if [ -f "$REPO_DIR/$SCRIPT.sh" ]; then rm -f "$REPO_DIR/$SCRIPT.sh"; git add -A; git commit -m "sync: delete $SCRIPT"; git push origin HEAD; echo "已删除远端: $SCRIPT.sh"; fi; }; f'

# 自动添加 PATH
add_to_path

echo ""
echo "安装完成！"
echo ""
echo "当前所有 git alias:"
git config --global --get-regexp '^alias\.' | sort
