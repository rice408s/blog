#!/bin/bash

# 创建backup文件夹（如果不存在）
mkdir -p backup

# 遍历当前目录下的所有图片文件
shopt -s nullglob
for file in *.jpg *.jpeg *.png *.gif; do
    # 获取文件名和扩展名
    filename=$(basename "$file")
    extension="${filename##*.}"

    # 获取文件大小（以KB为单位）
    size=$(du -k "$file" | cut -f1)

    # 如果文件大小大于2MB，则进行压缩
    if [[ -n $size ]] && ((size > 2048 )); then
        echo "压缩文件: $file"

        # 将原图移动到backup文件夹
        mv "$file" "backup/$filename"

        # 调整图片质量级别为80%（可以根据需要调整）
        convert "backup/$filename" -quality 80 "$file"
    fi
done
