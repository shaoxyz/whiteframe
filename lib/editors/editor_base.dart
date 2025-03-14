import 'dart:io';
import 'package:flutter/material.dart';

abstract class ImageEditor {
  /// 编辑器名称
  String get name;
  
  /// 编辑器图标
  IconData get icon;
  
  /// 处理图片的方法
  Future<File?> processImage(File image, BuildContext context);
  
  /// 编辑器界面构建
  Widget buildEditorUI(BuildContext context, File image, Function(File) onImageUpdated);
  
  /// 支持实时预览的处理方法 (默认实现调用普通处理方法)
  Future<File?> processImageWithPreview(File image, BuildContext context, Function(File) onPreviewUpdate) {
    return processImage(image, context);
  }
} 