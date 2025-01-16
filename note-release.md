### note


0. 环境配置
```
apt update

apt install -y zip openjdk-17-jdk libpulse0


# 如果需要可视化，需要安装qt和vnc
apt install -y qtbase5-dev qt5-qmake
apt install -y  libxcb-cursor0 \
     libxcb1 \
     libxcb-glx0 \
     libxcb-icccm4 \
     libxcb-image0 \
     libxcb-keysyms1 \
     libxcb-randr0 \
     libxcb-render-util0 \
     libxcb-render0 \
     libxcb-shape0 \
     libxcb-shm0 \
     libxcb-sync1 \
     libxcb-xfixes0 \
     libxcb-xinerama0 \
     libxkbcommon-x11-0

apt install -y tigervnc-standalone-server tigervnc-common
apt install -y novnc websockify
```


1. 下载并解压
```
unzip commandlinetools-linux-11076708_latest.zip -d ~/android-sdk
```

2. 配置环境变量
```
export ANDROID_HOME=~/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
```
3. 安装sdk
```
mkdir -p $ANDROID_HOME/cmdline-tools/latest 
mv $ANDROID_HOME/cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/
```
为什么需要这一步？
这是Android SDK的安装方式，需要将下载的sdk解压到cmdline-tools/latest目录下，然后才能使用sdkmanager命令安装sdk，这样能允许在同一个系统上存在多个版本的cmdline-tools

如果是使用android world，因为android world需要API33，可以通过这个方式安装
```
# 安装 Android 13 (API 33) 平台
sdkmanager "platforms;android-33"

# 安装 API 33 的系统镜像
sdkmanager "system-images;android-33;google_apis;x86_64"

# 可选：接受许可
sdkmanager --licenses
```

4. 创建avd
```
# 创建 Pixel 6 设备
avdmanager create avd \
    -n Pixel6_API33 \
    -k "system-images;android-33;google_apis;x86_64" \
    -d "pixel_6"
```

5. 如果需要可视化，要配置和启动vnc

设置密码
```
vncpasswd
```
设置启动脚本
```
mkdir -p ~/.vnc
vim ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
```
启动脚本内容如下：
```
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"

# 设置 Android SDK 环境变量
export ANDROID_HOME=$HOME/android-sdk
export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey

# 启动基本的窗口管理器
openbox &

# 启动 Android 模拟器，使用 -no-accel 参数
emulator -avd MyAVD4 &

# 保持会话运行
while true; do
    sleep 10
done
```

启动vnc
```
vncserver
```
如果需要杀掉vnc
```
vncserver -kill :1
```

启动websockify，方便浏览器访问vnc
```
websockify --web=/usr/share/novnc/ 6080 localhost:5901
```

6. 如果不需要nvc，可以直接-no-window启动
```
emulator -avd Pixel6_API33  -no-window -grpc 8554 -debug-init -verbose   -port 5554   -no-snapshot   -no-boot-anim
```

7. 启动之后，可以利用adb进行截图

如果adb没有启动：
```
adb start-server
```
启动之后，进行截图

```
adb -s emulator-5554 shell screencap -p /sdcard/screenshot.png
adb -s emulator-5554 pull /sdcard/screenshot.png ./
```

8. 怎样启动多个avd并通过adb控制？

创建多个avd
```
avdmanager create avd     -n AndroidWorldAvd001     -k "system-images;android-33;google_apis;x86_64"     -d "pixel_6"
avdmanager create avd     -n AndroidWorldAvd002     -k "system-images;android-33;google_apis;x86_64"     -d "pixel_6"
avdmanager create avd     -n AndroidWorldAvd003     -k "system-images;android-33;google_apis;x86_64"     -d "pixel_6"
```
启动多个avd
```
emulator -avd AndroidWorldAvd001  -no-window -grpc 8554 -debug-init -verbose   -port 5554   -no-snapshot   -no-boot-anim
emulator -avd AndroidWorldAvd002  -no-window -grpc 8556 -debug-init -verbose   -port 5556   -no-snapshot   -no-boot-anim
emulator -avd AndroidWorldAvd003  -no-window -grpc 8558 -debug-init -verbose   -port 5558   -no-snapshot   -no-boot-anim
```
利用adb对多个avd进行截图
```
adb -s emulator-5554 shell screencap -p /sdcard/screenshot_5554.png
adb -s emulator-5554 pull /sdcard/screenshot_5554.png ./

adb -s emulator-5556 shell screencap -p /sdcard/screenshot_5556.png
adb -s emulator-5556 pull /sdcard/screenshot_5556.png ./
```
同样adb也可以模拟点击、拖动等行为，android world也是通过这个方式进行控制





