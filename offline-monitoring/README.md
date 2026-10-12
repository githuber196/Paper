# 将 RISC-V 监控离线包上传到 Paper 仓库

仓库：https://github.com/githuber196/Paper.git

此目录包含原始监控 ZIP 的 16 个分卷，每份最多 20 MiB。它们用于普通 Git 上传；全部合并后恢复同一份 ZIP，不涉及重新构建镜像。

原始 ZIP：rv-monitoring-offline-riscv64.zip
原始 ZIP 字节数：316743143
原始 ZIP SHA256：58a37d0bc2778bf66f82441e94fc7358451de704b9eee917d8e8826bd9bddedf

## 1. 电脑上：解压下载包

用 Windows 解压工具打开 rv-monitoring-git-upload.zip，解压得到 offline-monitoring 文件夹。

将 offline-monitoring 文件夹整体复制到电脑上的 Paper 仓库根目录。必须保留分卷、校验清单、combine.sh 和以点开头的配置文件。

上传的是解压后的文件夹。外层 rv-monitoring-git-upload.zip 约 302 MiB，不能作为普通 Git 文件上传到 GitHub。

目录应为：

```text
Paper/
  offline-monitoring/
    .gitattributes
    .gitignore
    README.md
    combine.sh
    parts.sha256
    rv-monitoring-offline-riscv64.zip.sha256
    rv-monitoring-offline-riscv64.zip.part-000
    ...
    rv-monitoring-offline-riscv64.zip.part-015
```

## 2. 电脑上：上传到原来的 GitHub 仓库

以下命令使用 Git Bash。已有 Paper 仓库时，在该目录右键打开 Git Bash Here。

如果电脑上还没有克隆仓库，在准备保存仓库的目录打开 Git Bash，执行：

```bash
git clone https://github.com/githuber196/Paper.git
```

```bash
cd Paper
```

将第 1 节的 offline-monitoring 文件夹复制进来后，执行：

```bash
git status --short
```

```bash
git add -- offline-monitoring
```

```bash
git diff --cached --stat -- offline-monitoring
```

```bash
git commit -m "Add RISC-V monitoring offline bundle" -- offline-monitoring
```

```bash
git push
```

根据 Git 提示完成 GitHub 登录。上传内容合计约 302 MiB，首次上传需要等待。

如果 git push 提示远程有新提交，按提示先同步；不要使用强制推送。

如果你一直用网页上传：在 Paper 仓库的 Add file → Upload files 中，将解压后的 offline-monitoring 文件夹拖入；确认页面显示分卷和脚本的路径，再提交。每个分卷约 20 MiB，低于 GitHub 网页单文件 25 MiB 上限。

## 3. 控制端 k8smaster：下载并恢复离线文件

只有服务器能访问这个 GitHub 仓库时，才能从服务器运行以下 git clone。若无法访问，先在联网电脑下载，再使用 SFTP/SCP/移动存储传入控制端。

下面为此次下载单独使用 $HOME/rv-offline-download/Paper 目录，首次执行：

```bash
mkdir -p "$HOME/rv-offline-download"
```

```bash
git clone --depth 1 https://github.com/githuber196/Paper.git "$HOME/rv-offline-download/Paper"
```

如果这个下载目录之前已经克隆过，改为在该目录同步：

```bash
git -C "$HOME/rv-offline-download/Paper" pull --ff-only
```

克隆和更新两种方式按目录是否已有仓库选择一种。然后：

```bash
cd "$HOME/rv-offline-download/Paper/offline-monitoring"
```

```bash
bash combine.sh
```

脚本会校验 16 个分卷，合并并校验完整 ZIP。成功后最后一行以 Ready: 开头。

如果这一步提示分卷不存在或 SHA256 不一致，先补齐或重新下载对应分卷，校验成功后继续。

解压到当前用户家目录：

```bash
unzip -o rv-monitoring-offline-riscv64.zip -d "$HOME"
```

得到 $HOME/rv-monitoring-offline，包含 Helm、两个镜像 TAR、SHA256SUMS 和完整离线操作说明。若服务器没有 unzip，可以在联网电脑解压后上传文件夹。

## 4. 从控制端传给工作端 k8snode1

在控制端执行，下列复制命令的多行内容整块复制：

```bash
ssh lzu@192.168.102.125 'mkdir -p "$HOME/rv-monitoring-offline"'
```

```bash
scp \
  "$HOME/rv-monitoring-offline/rv-prometheus-3.13.4-riscv64.tar" \
  "$HOME/rv-monitoring-offline/rv-grafana-prebuilt-20250607-riscv64.tar" \
  "$HOME/rv-monitoring-offline/SHA256SUMS" \
  lzu@192.168.102.125:rv-monitoring-offline/
```

也可以使用已有的 SFTP 工具上传这三个文件到工作端 $HOME/rv-monitoring-offline。

控制端与工作端分别进入各自的目录校验：

```bash
cd "$HOME/rv-monitoring-offline"
```

```bash
sha256sum --ignore-missing -c SHA256SUMS
```

控制端应看到三个归档均为 OK；工作端应看到两个镜像归档均为 OK。

接着按 rv-monitoring-offline/README.md 分别安装控制端 Helm、导入工作端镜像并检查版本。该操作说明包含在合并后的 ZIP 内。

## 5. 校验范围

分卷 SHA256、合并后的完整 ZIP SHA256，以及压缩包内镜像归档和 Helm 的 SHA256 均已检查。镜像内主要程序的 ELF 头确认是 64 位 RISC-V。

这些检查没有替代目标 RISC-V 服务器上的运行验证。后续还需部署监控 Pod、确认采集正常，并联调 Grafana 与动态感知控制器。
