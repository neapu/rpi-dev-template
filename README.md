# Raspberry Pi 交叉编译

在 VS Code 中打开此文件夹，然后选择 **Dev Containers: Reopen in Container**。
容器提供 C 和 C++ 交叉编译器以及 ARM64 开发库，用于 Raspberry Pi 上的
64 位 Linux。

例如，在容器中编译现有程序：

```sh
aarch64-linux-gnu-g++ src/main.cpp -o hello
file hello
```

将 `hello` 复制到 Raspberry Pi 并在设备上运行。容器的 `pkg-config`
搜索路径已设置为 ARM64 软件包目录。对于 CMake 项目，首次配置构建目录时，
请选择提供的工具链：

```sh
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/.devcontainer/aarch64-toolchain.cmake"
cmake --build build
```

容器使用 Debian Trixie 库，而不是从目标设备复制的 sysroot。
Raspberry Pi 必须具有兼容的 ARM64 运行时库（包括 glibc）；生成的二进制文件
可能无法在较旧的 Raspberry Pi OS 版本上运行。对于其他目标系统版本或
32 位 Raspberry Pi OS，请改用匹配的工具链和目标 sysroot。

## Qt 和 QML

镜像使用官方 Qt Base、Shader Tools 和 Declarative 源码构建 Qt 6.11.3。
主机构建工具安装在 `/opt/qt/host`，ARM64 Qt（包括 Qt Quick 和 QML）
安装在 `/opt/qt/6.11.3`。构建此镜像所需的时间比普通开发容器长得多。
镜像构建默认使用 8 个并行编译任务。如需更改，请在
`.devcontainer/devcontainer.json` 中设置 `build.args.QT_BUILD_JOBS`
（例如设为 `"12"`），或向 `docker build` 传入
`--build-arg QT_BUILD_JOBS=12`。如果构建时内存不足，请使用较小的值。

对于 Qt CMake 项目，使用目标 Qt 包装脚本选择其交叉工具链和主机工具：

```sh
/opt/qt/6.11.3/bin/qt-cmake -S src -B build-qt -G Ninja
cmake --build build-qt
```

在 VS Code 中，在开发容器中重新打开文件夹，并在 CMake Tools 提示时选择
`rpi-arm64` 配置和构建预设。然后使用 **CMake: Configure** 和
**CMake: Build**，或使用 CMake 状态栏按钮。
该预设使用系统 CMake 和与 `qt-cmake` 相同的 Qt 工具链，并在
`build-vscode/` 中构建，以避免复用现有构建缓存。默认构建类型为 Debug。
如果仍选中了旧配置，请重新选择 `rpi-arm64` 预设。

默认构建还会将目标 Qt 共享库、插件和 QML 模块复制到 `bin/`。
它包含所有这些 Qt 运行时组件（而不只是当前导入的模块），因此目录较大，
但也支持运行时加载的插件。复制整个目录时，请保留符号链接：

```sh
rsync -a bin/ pi@raspberrypi:~/rpi-dev/
ssh pi@raspberrypi 'cd ~/rpi-dev && QT_QPA_PLATFORM=eglfs ./rpi-dev'
```

可执行文件会根据自身位置查找库和 Qt 资源；Raspberry Pi 上无需将 Qt
安装到 `/opt/qt/6.11.3`，也无需设置 `LD_LIBRARY_PATH`。

### Raspberry Pi 运行时依赖

部署包不包含系统库。对于基于 Debian Trixie 的 64 位 Raspberry Pi OS，
请在 Raspberry Pi 上安装运行时软件包：

```sh
sudo apt update
sudo apt install \
  libc6 libgcc-s1 libstdc++6 zlib1g \
  libegl1 libegl-mesa0 libgles2 libgbm1 libgl1-mesa-dri libdrm2 \
  libinput10 libmtdev1t64 libudev1 libxkbcommon0 \
  libfontconfig1 libfreetype6 libharfbuzz0b fonts-dejavu-core \
  libbrotli1 libdbus-1-3 libglib2.0-0t64 libicu76 \
  libjpeg62-turbo libpcre2-16-0 libpng16-16t64
```

APT 会安装这些软件包的其他依赖项。这些软件包名称和部署包中的 Qt
二进制文件对应 Debian Trixie；较旧版本的软件包名称可能不同，或其 glibc
和 ICU 版本可能不兼容。仅安装这些软件包无法使为 Trixie 构建的二进制文件
兼容旧版本：请使用匹配的工具链和 sysroot 重新构建。
应用程序的其他功能或插件可能需要更多系统库。

如需排查 Raspberry Pi 上缺失的库，请在部署目录中运行 `ldd ./rpi-dev`；
也可以使用 `QT_DEBUG_PLUGINS=1 QT_QPA_PLATFORM=eglfs ./rpi-dev`
检查插件加载情况。此构建使用 EGLFS，而不是 X11 平台插件。
Raspberry Pi 上需要正常工作的 EGL/DRM 图形栈和适当的设备权限。

如果 DSI 屏幕报告 `Could not set cursor` 或 `Failed to move cursor`，
DRM 驱动可能不支持硬件光标。如需尝试 EGLFS KMS 软件光标，请在部署目录中
创建配置并运行：

```sh
printf '%s\n' '{"hwcursor": false}' > eglfs.json
QT_QPA_EGLFS_KMS_CONFIG="$PWD/eglfs.json" QT_QPA_PLATFORM=eglfs ./rpi-dev
```

`C` 区域设置警告与此无关：如果 `C.UTF-8` 可用，Qt 会回退到该区域设置。
如果屏幕仍然空白，请检查 DRM 显示配置和设备权限；禁用硬件光标无法解决
这些问题。
