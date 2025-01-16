#!/usr/bin/env bash
# config.sh

# 配置 Android SDK 相关环境变量
export ANDROID_HOME=~/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME

export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# 定义要管理的 AVD 列表及端口
# 注意 emulator 默认的 “-port” 要配对使用两个端口，比如 5554/5555 是一对

declare -A AVD_LIST=(
  ["AndroidWorldAvd001"]="5554"
  ["AndroidWorldAvd002"]="5556"
  ["AndroidWorldAvd003"]="5558"
)

# 启动参数：
#   -no-window       : 不打开图形界面
#   -no-boot-anim    : 不显示开机动画
#   -no-snapshot     : 不使用快照
#   -grpc 855x       : gRPC 端口，不一定都要
#   -port 555x       : 端口，与上面要一一对应

EMULATOR_COMMON_ARGS=(
  "-no-window"
  "-no-boot-anim"
  "-no-snapshot"
  "-debug-init"
  "-verbose"
)
