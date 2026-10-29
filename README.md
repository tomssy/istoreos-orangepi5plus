# Orange Pi 5 Plus · iStoreOS 25.12 云编译

使用 GitHub Actions，从 [iStoreOS 官方 `istoreos-25.12` 分支](https://github.com/istoreos/istoreos/tree/istoreos-25.12)编译 **Orange Pi 5 Plus（RK3588）** 固件。每次构建获取该分支的最新源码并记录准确提交。

## 配置来源

采用官方 **25.12.6-2026102312** Rockchip 发布配置。该配置由 [官方固件目录](https://fw.koolcenter.com/iStoreOS/r6s/)提供，在多设备目标中明确包含 `xunlong_orangepi-5-plus`。

- `config/official.seed`：官方发布的原始 `config.seed`，完整保留作为配置来源。
- `config/feeds.conf`：官方发布的软件源列表；基础软件源跟随 25.12 源码，其他软件源沿用官方列表。
- `config/provenance.json`：下载地址、日期、发布版本及原文件 SHA256。
- `config/seed.config`：本项目的构建覆盖项。只选择 Orange Pi 5 Plus，关闭多设备镜像、SDK 和 ImageBuilder 构建，设置编译缓存与日志。保留官方 `CONFIG_ALL_KMODS=y`，让视频 DMA 等隐式内核依赖由完整模块选择带入。
- `config/required.config`：最终配置必须满足的设备、分区与核心软件检查。

官方的内核选项、内置软件、文件系统和分区大小沿用发布配置。未自行扩大系统分区，未修改官方启动程序、设备树或分区生成脚本。内核与软件的实际版本随最新 25.12 源码而变，因此这是一份按官方发布配置自行编译的固件，并非官方二进制固件的逐字节复刻。

## 分区与系统

| 项目 | 参数来源及配置 |
|---|---|
| 设备 | `xunlong_orangepi-5-plus` |
| 平台 | `rockchip/armv8` |
| 内核 | 官方 25.12 分支的 Rockchip 6.12 内核 |
| 文件系统 | SquashFS，沿用官方发布配置 |
| 启动分区 | 64 MiB |
| 系统分区 | 256 MiB |
| 可写分区 | 官方镜像脚本默认生成 2048 MiB 的独立分区 |
| 其他空间 | 由运行后的官方存储管理流程处理；镜像不预置 57 GiB 数据分区 |

按全新安装使用，不以现有 24.10 的分区布局或配置作为兼容目标。25.12 使用 APK 包管理器，旧版 IPK 软件包和完整系统备份不能直接作为新版的软件环境恢复。

## 运行与下载

1. 打开 **Actions → Build iStoreOS 25.12 for Orange Pi 5 Plus**。
2. 点击 **Run workflow**，保留默认源码分支 `istoreos-25.12`。
3. 等待完整源码构建。首次编译可能需要数小时，GitHub 标准运行器的单次任务存在时间限制。
4. 成功后在运行页面底部 **Artifacts** 下载 `iStoreOS-25.12-OrangePi5Plus-运行序号`。

解压 ZIP 后，`*xunlong_orangepi-5-plus-squashfs-sysupgrade.img.gz` 是固件，附带 SHA256、升级元数据、源码和 feeds 提交、构建配置与配置来源。固件保留 45 天，诊断日志保留 14 天；下载 Actions 附件需要登录 GitHub。

每月 **1 日北京时间 04:00** 自动构建一次，同时保留手动构建入口。首次计划运行时间为 **2026-11-01 04:00（Asia/Shanghai）**。定时构建使用默认分支上的工作流，拉取 `istoreos-25.12` 分支最新源码；官方发布配置基线仍使用仓库保存的版本。GitHub 高负载时可能延迟执行。

月度任务结束后，将结果和运行链接写入 `.github/monthly-build.json`，形成仓库活动记录，避免公开仓库因连续 60 天无活动而被 GitHub 自动停用定时工作流。编译任务保持只读权限，只有写记录的独立任务有仓库内容写入权限。

不需要 PAT、ACCESS_TOKEN 或第三方编译服务。公开仓库使用 GitHub 标准 Ubuntu 运行器，无需本地电脑保持开机。

## 安装与验证

固件仅用于 **Orange Pi 5 Plus**。建议先用空闲 microSD 卡验证启动、网口、存储和散热，再决定安装到当前系统盘。将镜像写入存储设备会覆盖目标数据；eMMC、NVMe、microSD 与 SPI 的启动组合应按实际设备确认。

用户于 **2026-10-30** 确认[第 5 次构建](https://github.com/tomssy/istoreos-orangepi5plus/actions/runs/40805315060)已刷入 Orange Pi 5 Plus，启动及功能正常。后续月份的源码可能变化，仍需验证新版本实际表现。刷入设备、重启和清除现有存储不属于本仓库自动工作流。

## 排查失败

查看失败步骤的 Actions 控制台日志，并下载 `build-logs-运行序号`。日志包含最终配置、源码及 feeds 提交、下载与编译输出。并行编译失败后自动尝试一次单线程详细编译。超时、取消或运行器故障时附件可能不完整。

流程位于 `scripts/build.sh`。运行器清理仅在 GitHub 临时 Linux 虚拟机上执行；GitHub 官方 Actions 固定到提交版本。

## 来源与许可

iStoreOS、OpenWrt 和各软件包遵循各自上游许可证。本仓库提供独立的编译自动化与配置记录，不是官方固件发布站。
