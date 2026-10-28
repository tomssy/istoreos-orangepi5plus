# Orange Pi 5 Plus 的 iStoreOS 云编译

通过 GitHub Actions 从 [iStoreOS 官方源码](https://github.com/istoreos/istoreos/tree/istoreos-24.10) 编译香橙派 **Orange Pi 5 Plus（RK3588）** 固件。默认使用 `istoreos-24.10` 分支，设备目标为 `rockchip/armv8` 下的 `xunlong_orangepi-5-plus`。

## 开始编译

1. 打开本仓库 **Actions** → **Build iStoreOS for Orange Pi 5 Plus**。
2. 点击 **Run workflow**，保留默认源码分支，再点击运行。
3. 等待构建完成。完整源码首次构建可能需要数小时；GitHub 标准运行器的单次任务存在时间限制。
4. 在本次运行页面底部 **Artifacts** 下载 `iStoreOS-OrangePi5Plus-运行序号`。

解压下载的 ZIP，里面的 `*xunlong_orangepi-5-plus-squashfs-sysupgrade.img.gz` 是目标固件，同时附带 `sha256sums`、构建配置及源码/feeds 提交记录。固件下载保留 30 天，诊断日志保留 14 天。下载 Actions 附件需要登录 GitHub。

本仓库仅在手动触发时编译，不配置定时任务。使用公开仓库的标准 Ubuntu 运行器；不需要另行配置 PAT、ACCESS_TOKEN 或第三方编译服务。

## 默认内容

- 官方内核、启动程序、Orange Pi 5 Plus 设备树及设备默认驱动。
- 中文 LuCI、iStore 商店、快速配置、OTA 页面、磁盘管理、Docker 管理。
- SquashFS 系统镜像，根分区大小设置为 1024 MiB。
- 保留官方网络与初始化设置，不预置个人网络信息。

软件选择在 `config/seed.config` 修改。每次构建会检查必需的设备与软件选项是否在 `make defconfig` 后保留，避免配置项失效却继续生成其他设备镜像。

## 刷写与首次使用

固件只适用于 **Orange Pi 5 Plus**。构建成功代表编译与镜像格式检查通过，仍需在实际开发板上验证启动、网口和存储设备。

初次验证建议先将镜像写入一张空闲 microSD 卡，并保留已有系统。写入会覆盖所选卡的数据；应按 Orange Pi 5 Plus 与 iStoreOS 对应的启动说明操作。eMMC、NVMe 和 SPI 的启动组合不同，需要先确认当前引导方式，再决定安装方法。

不要在自己的源码构建上直接安装来自其他固件的内核模块。OTA 页面保留官方行为；执行在线更新前应确认它将切换到的版本及来源，定制包可能被覆盖。

## 构建失败

打开失败步骤查看日志，并下载 `build-logs-运行序号`。构建会保留源码提交、feeds 提交、最终 `.config` 与编译日志。并行编译失败后自动尝试一次单线程详细输出；超时、被取消或运行器故障时，附件可能不完整，应以 Actions 控制台日志为准。

编译流程在 `scripts/build.sh`。运行器清理仅用于 GitHub 提供的临时 Linux 虚拟机。工作流使用固定提交版本的 GitHub 官方 Actions。

## 来源与许可

固件源码及其软件包遵循各自上游许可证；iStoreOS 主仓库包含 OpenWrt 的 GPL-2.0 许可及各组件许可信息。这里提供独立编译配置，不是官方固件发布站。
