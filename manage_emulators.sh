#!/usr/bin/env bash

######################################################################
#       一个管理多台 Android Emulator 的脚本示例
#       包含启动/停止/状态检测/心跳检测/自动重启等逻辑
######################################################################

source "$(dirname "$0")/config.sh"

# 日志目录（可选）
LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"

######################################################################
#  1. 启动指定或全部 Emulator
######################################################################
start_emulator() {
  local avd_name="$1"
  local port="$2"

  # 判断是否已经在运行
  if adb -s "emulator-${port}" shell exit 2>/dev/null; then
    echo "[$(date +%T)] AVD $avd_name (port $port) 已经在运行..."
    return 0
  fi

  echo "[$(date +%T)] 正在启动 AVD: $avd_name, 端口: $port ..."
  # 组合启动参数
  emulator_args=("${EMULATOR_COMMON_ARGS[@]}" "-avd" "$avd_name" "-port" "$port")

  # 演示如何根据 port 调整 grpc 端口; 例如 grpc 端口 = 8554 + (port - 5554)
  local grpc_port=$((8554 + port - 5554))
  emulator_args+=("-grpc" "$grpc_port")

  # 后台启动 emulator，并把输出重定向到日志
  emulator "${emulator_args[@]}" >"$LOG_DIR/emulator_${port}.log" 2>&1 &

  # 可在此处加一个等待流程，等 emulator 真正启动完，比如等待 adb 可连接?
  echo "[$(date +%T)] 等待 $avd_name adb 可连接..."
  local try_count=0
  local max_try=20
  until adb -s "emulator-${port}" shell getprop sys.boot_completed 2>/dev/null | grep -m 1 "1" ; do
    ((try_count++))
    if [[ $try_count -ge $max_try ]]; then
      echo "[$(date +%T)] AVD $avd_name 超时未启动完成，请手动检查日志。"
      return 1
    fi
    sleep 5
  done
  echo "[$(date +%T)] $avd_name (port $port) 启动并完成开机。"
  return 0
}

######################################################################
#  2. 启动脚本：循环启动所有 AVD 或指定 AVD
######################################################################
start_all_emulators() {
  for avd_name in "${!AVD_LIST[@]}"; do
    local port="${AVD_LIST[$avd_name]}"
    start_emulator "$avd_name" "$port"
  done
}

######################################################################
#  3. 停止指定或全部 Emulator
######################################################################
stop_emulator() {
  local avd_name="$1"
  local port="$2"

  # 判断是否已经在运行
  if adb -s "emulator-${port}" shell exit 2>/dev/null; then
    echo "[$(date +%T)] 正在关闭 AVD: $avd_name (port $port)..."
    adb -s "emulator-${port}" emu kill
  else
    echo "[$(date +%T)] AVD $avd_name (port $port) 未在运行，无需关闭。"
  fi
}

stop_all_emulators() {
  for avd_name in "${!AVD_LIST[@]}"; do
    local port="${AVD_LIST[$avd_name]}"
    stop_emulator "$avd_name" "$port"
  done
}

######################################################################
#  4. 检测指定或全部 Emulator 状态
#     - 最简单的方式是看 adb 是否在线
#     - 也可以看 getprop sys.boot_completed 是否为 1
######################################################################
check_emulator() {
  local avd_name="$1"
  local port="$2"

  # 检查 AVD 是否在线
  if ! adb -s "emulator-${port}" shell exit 2>/dev/null; then
    echo "[$(date +%T)] AVD $avd_name (port $port) 状态: \033[31m离线\033[0m"
    return 1
  fi

  # 检查系统是否 boot completed
  local boot_completed
  boot_completed="$(adb -s "emulator-${port}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
  if [[ "$boot_completed" == "1" ]]; then
    echo "[$(date +%T)] AVD $avd_name (port $port) 状态: \033[32m在线并已启动完成\033[0m"
    return 0
  else
    echo "[$(date +%T)] AVD $avd_name (port $port) 状态: \033[33m在线但未完成启动\033[0m"
    return 2
  fi
}

check_all_emulators() {
  local offline_count=0
  for avd_name in "${!AVD_LIST[@]}"; do
    local port="${AVD_LIST[$avd_name]}"
    check_emulator "$avd_name" "$port" || ((offline_count++))
  done

  if [[ $offline_count -eq 0 ]]; then
    echo "[$(date +%T)] 所有 AVD 均在线。"
  else
    echo "[$(date +%T)] 有 $offline_count 台 AVD 离线或异常。"
  fi
}

######################################################################
#  5. 心跳检测 & 自动重启示例
#     - 可以结合 crontab 或者后台常驻脚本，每隔 N 秒循环检测
######################################################################
heartbeat_loop() {
  # 间隔秒数
  local interval=30
  echo "[$(date +%T)] 开始心跳检测，每 $interval 秒检测一次..."

  while true; do
    for avd_name in "${!AVD_LIST[@]}"; do
      local port="${AVD_LIST[$avd_name]}"
      if ! adb -s "emulator-${port}" shell exit 2>/dev/null; then
        echo "[$(date +%T)] 检测到 AVD $avd_name (port $port) 离线，尝试重启..."
        stop_emulator "$avd_name" "$port"
        start_emulator "$avd_name" "$port"
      else
        # 这里也可以写更复杂的逻辑，比如 adb 命令超时、CPU 占用异常等
        echo "[$(date +%T)] AVD $avd_name (port $port) 正常在线。"
      fi
    done
    sleep "$interval"
  done
}

######################################################################
#   命令行解析
######################################################################
usage() {
  cat <<EOF
用法: $0 [命令]

可用命令:
  start        启动所有 AVD
  stop         停止所有 AVD
  restart      先停止后再启动所有 AVD
  status       检查所有 AVD 状态
  heartbeat    进入心跳检测循环(自动重启)
  help         显示本帮助

示例:
  $0 start
  $0 status
  $0 heartbeat
EOF
}

main() {
  case "$1" in
    start)
      start_all_emulators
      ;;
    stop)
      stop_all_emulators
      ;;
    restart)
      stop_all_emulators
      start_all_emulators
      ;;
    status)
      check_all_emulators
      ;;
    heartbeat)
      heartbeat_loop
      ;;
    help|*)
      usage
      ;;
  esac
}

main "$@"