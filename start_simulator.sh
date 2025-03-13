#!/bin/bash

# 列出可用的模拟器并添加序号
echo "可用的模拟器："
devices=$(xcrun simctl list devices | grep -i iphone)
IFS=$'\n' read -d '' -r -a device_array <<< "$devices"

for i in "${!device_array[@]}"; do
    echo "$((i+1)). ${device_array[$i]}"
done

# 提示用户输入序号
echo "请输入您想启动的模拟器序号："
read selection

# 检查输入是否有效
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#device_array[@]}" ]; then
    echo "无效的选择。请输入有效的序号。"
    exit 1
fi

# 获取选中设备的信息
selected_device="${device_array[$((selection-1))]}"

# 从选中的设备信息中提取 UDID
simulator_udid=$(echo "$selected_device" | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})")

# 启动模拟器
echo "正在启动模拟器..."
xcrun simctl boot "$simulator_udid"

echo "模拟器已启动。请稍等片刻，让它完全加载。"