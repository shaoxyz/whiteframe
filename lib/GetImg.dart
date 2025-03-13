import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<File?> GetImg(BuildContext context) async { // 添加 context 参数
  // 创建选择器实例
  final ImagePicker picker = ImagePicker();
  
  // 显示选择对话框
  XFile? pickedFile;
  
  // 创建底部弹出菜单
  await showModalBottomSheet<void>(
    context: context, // 使用传入的 context
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍摄照片'),
              onTap: () async {
                // 先选择图片，再关闭菜单
                pickedFile = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                // 先选择图片，再关闭菜单
                pickedFile = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (pickedFile != null) {
    return File(pickedFile!.path); // 添加空安全检查
  }
  
  return null;
}