# git-scripts

一组全局可复用的 Git alias 脚本，安装后可以在任意 Git 仓库里通过 `git <alias>` 直接使用。

这个项目主要提供三类能力：

- 更好看的日志查看：`git l`、`git lf`、`git lb`
- 快速打开仓库页面：`git b`
- 自动创建并推送版本标签：`git t`、`git tt`、`git ttt`
- 本地与远端脚本同步：`git s`、`git sr`、`git sl`、`git sd`、`git sa`、`git sc`

## 安装

直接执行：

```bash
curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash
```

或者在仓库里执行：

```bash
bash install.sh
```

Windows Git Bash 也可以直接运行：

```bash
bash /w/github.com/aceaura/git-scripts/install.sh
```

## 安装后会发生什么

安装脚本会做这些事情：

- 把仓库克隆或更新到 `~/.git-scripts-sync`
- 把可执行脚本复制到 `~/.git-scripts-bin`
- 自动把 `~/.git-scripts-bin` 加入 `PATH`
- 如果缺少 `fzf`，会尝试自动安装
- 注册全局 Git alias，使你可以直接运行 `git b`、`git l` 之类的命令

注意：

- 安装脚本会重建当前全局 Git alias 配置
- 在 Windows 下，`PATH` 改动通常需要重新打开终端后才会生效
- `git lb` 依赖 `fzf`

安装完成后，可以先执行：

```bash
git sa
```

查看当前可用命令。

## 命令总览

### 日常命令

| 命令 | 作用 |
| --- | --- |
| `git b` | 在浏览器中打开当前仓库 |
| `git l` | 查看简洁版彩色提交历史 |
| `git lf` | 查看详细版提交历史和文件统计 |
| `git lb` | 交互式浏览提交、文件和 diff |
| `git t` | 创建并推送下一个 patch 版本 tag |
| `git tt` | 创建并推送下一个 minor 版本 tag |
| `git ttt` | 创建并推送下一个 major 版本 tag |

### 同步命令

| 命令 | 作用 |
| --- | --- |
| `git s` | 双向同步本地和远端脚本 |
| `git sr` | 强制用本地内容覆盖远端 |
| `git sl` | 重新执行安装流程，拉取远端最新脚本 |
| `git sd <name>` | 删除指定命令的本地和远端版本 |
| `git sa` | 查看所有命令和同步状态 |
| `git sc` | 比较本地和远端差异 |

## 每个命令怎么用

### `git b`

用途：在浏览器里打开当前仓库的远端页面。

用法：

```bash
git b
```

行为说明：

- 自动读取当前仓库的 `origin`
- 如果是 GitHub SSH 地址，会自动转成 HTTPS 地址
- 然后调用系统默认浏览器打开

适用场景：

- 快速打开仓库首页
- 复制仓库链接前先看一下远端页面

前提条件：

- 当前目录必须是 Git 仓库
- 必须存在 `origin` 远端

---

### `git l`

用途：显示简洁版的彩色提交历史。

用法：

```bash
git l
```

也可以附带标准 `git log` 参数：

```bash
git l --author=aceaura
git l main..HEAD
git l -- path/to/file
```

行为说明：

- 默认展示最近 100 条提交
- 显示 hash、相对时间、作者、分支装饰和提交信息
- 会根据改动量给提交描述着色，改动越大颜色越热

适用场景：

- 快速浏览提交历史
- 在终端里定位最近的关键提交

---

### `git lf`

用途：显示详细版提交历史，并带文件变更统计。

用法：

```bash
git lf
```

也支持传递 `git log` 参数：

```bash
git lf develop..HEAD
git lf --author=aceaura
git lf -- src/
```

行为说明：

- 默认展示最近 100 条提交
- 每条提交下面会显示变更文件列表
- 同时展示 `files changed / insertions / deletions` 统计
- 输出会根据终端宽度自动换行

适用场景：

- 想知道某次提交改了哪些文件
- 做代码回顾时快速扫一遍历史改动

---

### `git lb`

用途：交互式浏览提交历史、单个文件以及对应 diff。

用法：

```bash
git lb
```

依赖：

```bash
fzf
```

行为说明：

- 第一级：选择 commit
- 第二级：选择该 commit 下的某个文件
- 第三级：打开该文件在该 commit 中的 diff
- 支持预览窗口、翻页和全屏交互

常用操作：

- `↑↓` 选择项目
- `Enter` 进入下一层
- `Esc` 返回上一层或退出
- `PgUp` / `PgDn` 滚动预览
- `←` / `→` 翻页

适用场景：

- 看历史提交时想逐个文件钻进去
- 快速定位某次提交改动的具体内容

---

### `git t`

用途：自动创建并推送下一个 patch 版本 tag。

用法：

```bash
git t
```

行为说明：

- 读取当前最新 tag
- 按 `vX.Y.Z` 规则把 patch 加 1
- 自动执行 `git tag <new>` 和 `git push origin <new>`

例如：

- 当前最新 tag 是 `v1.2.3`
- 执行 `git t`
- 会创建并推送 `v1.2.4`

如果当前没有 tag，则从 `v0.0.0` 开始计算，第一次会推送 `v0.0.1`

---

### `git tt`

用途：自动创建并推送下一个 minor 版本 tag。

用法：

```bash
git tt
```

行为说明：

- 读取当前最新 tag
- minor 加 1，patch 重置为 0

例如：

- 当前最新 tag 是 `v1.2.3`
- 执行 `git tt`
- 会创建并推送 `v1.3.0`

如果当前没有 tag，则第一次会推送 `v0.1.0`

---

### `git ttt`

用途：自动创建并推送下一个 major 版本 tag。

用法：

```bash
git ttt
```

行为说明：

- 读取当前最新 tag
- major 加 1，minor 和 patch 都重置为 0

例如：

- 当前最新 tag 是 `v1.2.3`
- 执行 `git ttt`
- 会创建并推送 `v2.0.0`

如果当前没有 tag，则第一次会推送 `v1.0.0`

---

### `git s`

用途：双向同步本地和远端脚本内容。

用法：

```bash
git s
```

行为说明：

- 远端有、本地没有的脚本会下载到本地
- 本地有、远端没有的脚本会上传到远端仓库
- 如果本地和远端都没有新增内容，会提示已经同步

适用场景：

- 你在另一台机器新增了脚本，当前机器想拉下来
- 你本地新增了脚本，想同步回远端

---

### `git sr`

用途：强制用本地脚本覆盖远端。

用法：

```bash
git sr
```

行为说明：

- 会把本地 `~/.git-scripts-bin` 中的脚本视为最终版本
- 远端同名脚本会被覆盖
- 推送时包含强制覆盖语义

适用场景：

- 你明确知道本地版本才是正确版本
- 想把当前机器上的脚本整体发布成远端最新版

注意：这个命令有覆盖性，使用前最好确认远端没有未保留内容。

---

### `git sl`

用途：重新执行安装流程，拉取并安装远端最新脚本。

用法：

```bash
git sl
```

行为说明：

- 会重新运行远端 `install.sh`
- 适合在你怀疑本地安装不完整时重新修复
- 也适合拿到远端新脚本后整体刷新本地环境

适用场景：

- 新增命令后想一键更新本地
- 安装过程出过问题，想重新安装

---

### `git sd <name>`

用途：删除某个命令的本地和远端版本。

用法：

```bash
git sd <name>
```

例如：

```bash
git sd ttt
```

行为说明：

- 删除本地对应的脚本和 alias
- 删除远端仓库中的对应脚本
- 自动提交并推送删除操作

适用场景：

- 某个命令废弃了
- 某个命令命名不合适，准备删掉重建

---

### `git sa`

用途：查看所有命令和当前同步状态。

用法：

```bash
git sa
```

行为说明：

- 列出远端可用命令
- 列出内置同步命令
- 显示哪些命令远端有但本地没安装
- 显示哪些命令本地有但远端没发布

适用场景：

- 新环境安装完成后做一次总检查
- 看看哪些命令还没同步

---

### `git sc`

用途：比较本地和远端差异。

用法：

```bash
git sc
```

行为说明：

- 如果本地和远端完全一致，会直接提示已同步
- 如果远端有但本地没有，会列出未安装项
- 如果本地有但远端没有，会列出未发布项

适用场景：

- 同步前先检查差异
- 作为日常状态巡检命令使用

## 典型使用流程

### 1. 新机器安装

```bash
curl -sSL https://raw.githubusercontent.com/aceaura/git-scripts/master/install.sh | bash
git sa
```

### 2. 查看当前仓库历史

```bash
git l
git lf
git lb
```

### 3. 打版本 tag

```bash
git t
git tt
git ttt
```

### 4. 同步新脚本

```bash
git sc
git s
```

### 5. 本地强制覆盖远端

```bash
git sr
```

### 6. 删除废弃命令

```bash
git sd old-command
```

## 文件结构

| 路径 | 说明 |
| --- | --- |
| `install.sh` | 主安装脚本 |
| `remote-install.sh` | 一键远端安装入口 |
| `git-*.sh` | 各个命令的源脚本 |
| `~/.git-scripts-sync` | 本地同步仓库 |
| `~/.git-scripts-bin` | 实际执行命令所在目录 |

## 常见问题

### `git lb` 不能用

先确认 `fzf` 是否可用：

```bash
fzf --version
```

如果当前终端识别不到，可以重新打开终端后再试。

### 安装完后命令找不到

先执行：

```bash
git sa
```

如果 alias 已经存在，但命令仍不可用，通常是 `PATH` 还没有在当前终端生效。重新打开终端即可。

### 想重新安装全部命令

直接执行：

```bash
git sl
```

### 想知道本地和远端是否一致

执行：

```bash
git sc
```

## 适合放新命令的格式

如果你后续要新增命令，建议保持这种脚本头部格式：

```bash
#!/bin/bash
# git-xxx: 这里写一句简短说明
# 用法: git xxx
```

这样 `git sa` 和 `git sc` 在展示命令列表时，能自动读取说明。
