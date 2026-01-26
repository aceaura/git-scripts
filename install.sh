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
    local os_type=""
    local need_source=0
    
    # 检测操作系统
    case "$(uname -s)" in
        Darwin*)  os_type="macos" ;;
        Linux*)   os_type="linux" ;;
        MINGW*|MSYS*|CYGWIN*) os_type="windows" ;;
        *)        os_type="unknown" ;;
    esac
    
    # 根据操作系统和 shell 选择配置文件
    if [ "$os_type" = "macos" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -f "$HOME/.zshrc" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_rc="$HOME/.bash_profile"
        fi
    elif [ "$os_type" = "linux" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -f "$HOME/.profile" ]; then
            shell_rc="$HOME/.profile"
        fi
    elif [ "$os_type" = "windows" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_rc="$HOME/.bash_profile"
        else
            shell_rc="$HOME/.bashrc"
        fi
        
        # Windows: 尝试添加到用户环境变量（永久生效）
        if command -v setx >/dev/null 2>&1; then
            local win_path=$(cygpath -w "$HOME/.git-scripts-bin" 2>/dev/null || echo "$HOME/.git-scripts-bin")
            # 检查是否已在 Windows PATH 中
            if ! echo "$PATH" | grep -qi "git-scripts-bin"; then
                setx PATH "%PATH%;$win_path" >/dev/null 2>&1 || true
            fi
        fi
    else
        if [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -f "$HOME/.profile" ]; then
            shell_rc="$HOME/.profile"
        fi
    fi
    
    # 写入配置文件（永久生效）
    if [ -n "$shell_rc" ]; then
        touch "$shell_rc"
        if ! grep -q ".git-scripts-bin" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# git-scripts bin path" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            need_source=1
        fi
    fi
    
    # 当前会话添加 PATH
    export PATH="$BIN_DIR:$PATH"
    
    # 提示用户
    if [ $need_source -eq 1 ]; then
        echo ""
        echo "PATH 已配置到 $shell_rc (永久生效)"
        echo ""
        echo "立即生效请运行:"
        echo "  source $shell_rc"
        echo ""
        echo "或重新打开终端"
    fi
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
    case "$alias_name" in s|sr|sl|sd|sa|sc) continue ;; esac
    
    # 复制脚本到 bin 目录
    cp "$script" "$BIN_DIR/$name"
    chmod +x "$BIN_DIR/$name"
    
    # 创建 alias 指向脚本
    echo "安装: alias.$alias_name -> $name"
    git config --global "alias.$alias_name" "!$name"
done

# 安装同步命令
echo "安装同步命令..."

git config --global alias.s '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; mkdir -p "$BIN_DIR"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; UPLOADED=0; DOWNLOADED=0; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh); alias_name=$(echo "$name" | sed "s/^git-//"); case "$alias_name" in s|sr|sl|sd|sa|sc) continue ;; esac; if [ ! -f "$BIN_DIR/$name" ]; then echo "下载: $alias_name"; cp "$script" "$BIN_DIR/$name"; chmod +x "$BIN_DIR/$name"; git config --global "alias.$alias_name" "!$name"; DOWNLOADED=1; fi; done; for bin_script in "$BIN_DIR"/git-*; do [ -f "$bin_script" ] || continue; name=$(basename "$bin_script"); alias_name=$(echo "$name" | sed "s/^git-//"); case "$alias_name" in s|sr|sl|sd|sa|sc) continue ;; esac; if [ ! -f "$REPO_DIR/$name.sh" ]; then echo "上传: $alias_name"; cp "$bin_script" "$REPO_DIR/$name.sh"; UPLOADED=1; fi; done; if [ $UPLOADED -eq 1 ]; then cd "$REPO_DIR"; git add -A; git commit -m "sync: upload local aliases"; git push origin HEAD; fi; if [ $UPLOADED -eq 0 ] && [ $DOWNLOADED -eq 0 ]; then echo "已同步，无需操作"; else echo "同步完成"; fi; }; f'

git config --global alias.sr '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; rm -f "$REPO_DIR"/git-*.sh; for bin_script in "$BIN_DIR"/git-*; do [ -f "$bin_script" ] || continue; name=$(basename "$bin_script"); echo "上传: $name"; cp "$bin_script" "$REPO_DIR/$name.sh"; done; cd "$REPO_DIR"; git add -A; git commit -m "sync: force upload all local aliases"; git push origin HEAD --force; echo "已强制用本地覆盖远端"; }; f'

git config --global alias.sl '!f() { curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash; }; f'

git config --global alias.sd '!f() { if [ -z "$1" ]; then echo "用法: git sd <name>"; exit 1; fi; NAME="$1"; REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; BIN_DIR="$HOME/.git-scripts-bin"; SCRIPT="git-$NAME"; if [ -f "$BIN_DIR/$SCRIPT" ]; then rm -f "$BIN_DIR/$SCRIPT"; echo "已删除本地: $SCRIPT"; fi; if git config --global --get "alias.$NAME" >/dev/null 2>&1; then git config --global --unset "alias.$NAME"; echo "已删除本地 alias: $NAME"; fi; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin; git reset --hard origin/main 2>/dev/null || git reset --hard origin/master; else git clone "$REPO_URL" "$REPO_DIR"; cd "$REPO_DIR"; fi; if [ -f "$REPO_DIR/$SCRIPT.sh" ]; then rm -f "$REPO_DIR/$SCRIPT.sh"; git add -A; git commit -m "sync: delete $SCRIPT"; git push origin HEAD; echo "已删除远端: $SCRIPT.sh"; fi; }; f'

git config --global alias.sa '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin >/dev/null 2>&1; git reset --hard origin/main >/dev/null 2>&1 || git reset --hard origin/master >/dev/null 2>&1; else git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; cd "$REPO_DIR"; fi; REMOTE=""; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh | sed "s/^git-//"); case "$name" in s|sr|sl|sd|sa|sc) continue ;; esac; REMOTE="$REMOTE $name"; done; LOCAL=$(git config --global -l 2>/dev/null | grep ^alias | cut -d= -f1 | sed "s/alias\\.//" | grep -v "^s$" | grep -v "^sr$" | grep -v "^sl$" | grep -v "^sd$" | grep -v "^sa$" | grep -v "^sc$" | tr "\\n" " "); echo "用法: git <alias> [<args>]"; echo ""; echo "可用命令 (远端):"; for name in $REMOTE; do desc=$(sed -n "2p" "$REPO_DIR/git-$name.sh" 2>/dev/null | sed "s/^# git-[^:]*: //" | sed "s/^# //"); printf "   %-14s %s\\n" "$name" "$desc"; done; echo ""; echo "同步命令 (内置):"; echo "   s              双向同步本地和远端的 alias"; echo "   sr             强制上传本地 alias 到远端"; echo "   sl             强制下载远端 alias 到本地"; echo "   sd <name>      同时删除本地和远端的指定 alias"; echo "   sc             比较本地和远端的 alias 差异"; echo "   sa             显示此帮助信息"; NI=""; for name in $REMOTE; do if ! echo " $LOCAL " | grep -q " $name "; then NI="$NI $name"; fi; done; if [ -n "$NI" ]; then echo ""; echo "未安装 (运行 git sl 安装):"; for name in $NI; do echo "   $name"; done; fi; NP=""; for name in $LOCAL; do if ! echo " $REMOTE " | grep -q " $name "; then NP="$NP $name"; fi; done; if [ -n "$NP" ]; then echo ""; echo "未发布 (运行 git sr 发布):"; for name in $NP; do echo "   $name"; done; fi; }; f'

git config --global alias.sc '!f() { REPO_URL="https://github.com/aceaura/git-scripts"; REPO_DIR="$HOME/.git-scripts-sync"; if [ -d "$REPO_DIR" ]; then cd "$REPO_DIR"; git fetch origin >/dev/null 2>&1; git reset --hard origin/main >/dev/null 2>&1 || git reset --hard origin/master >/dev/null 2>&1; else git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; cd "$REPO_DIR"; fi; REMOTE=""; for script in "$REPO_DIR"/git-*.sh; do [ -f "$script" ] || continue; name=$(basename "$script" .sh | sed "s/^git-//"); case "$name" in s|sr|sl|sd|sa|sc) continue ;; esac; REMOTE="$REMOTE $name"; done; LOCAL=$(git config --global -l 2>/dev/null | grep ^alias | cut -d= -f1 | sed "s/alias\\.//" | grep -v "^s$" | grep -v "^sr$" | grep -v "^sl$" | grep -v "^sd$" | grep -v "^sa$" | grep -v "^sc$" | tr "\\n" " "); NI=""; for name in $REMOTE; do if ! echo " $LOCAL " | grep -q " $name "; then NI="$NI $name"; fi; done; NP=""; for name in $LOCAL; do if ! echo " $REMOTE " | grep -q " $name "; then NP="$NP $name"; fi; done; if [ -z "$NI" ] && [ -z "$NP" ]; then echo "本地和远端已完全同步"; exit 0; fi; if [ -n "$NI" ]; then echo "未安装 (远端有本地没有):"; for name in $NI; do desc=$(sed -n "2p" "$REPO_DIR/git-$name.sh" 2>/dev/null | sed "s/^# git-[^:]*: //" | sed "s/^# //"); printf "   %-14s %s\\n" "$name" "$desc"; done; echo ""; echo "运行 git sl 安装全部，或 git s 同步"; fi; if [ -n "$NP" ]; then if [ -n "$NI" ]; then echo ""; fi; echo "未发布 (本地有远端没有):"; for name in $NP; do echo "   $name"; done; echo ""; echo "运行 git sr 发布全部，或 git s 同步"; fi; }; f'

# 自动添加 PATH
add_to_path

echo ""
echo "安装完成！"
echo ""
echo "当前所有 git alias:"
git config --global --get-regexp '^alias\.' | sort
