import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ImageService {
  // 跟踪临时文件以便清理
  final List<String> _tempFilePaths = [];
  
  void dispose() {
    _cleanupTempFiles();
  }
  
  // 清理所有临时文件
  Future<void> _cleanupTempFiles() async {
    for (var path in _tempFilePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('清除临时文件失败: $e');
      }
    }
    _tempFilePaths.clear();
  }

  /// 创建预览图像
  Future<File?> createPreviewImage(File image) async {
    try {
      // 获取图像字节数据
      final Uint8List bytes = await image.readAsBytes();
      
      // 正确使用ui.decodeImageFromList，它需要一个回调函数
      final ui.Image decodedImg = await _decodeImageFromList(bytes);
      
      // 降低分辨率，保持原始宽高比
      int previewWidth = 600; // 预览宽度，可根据需要调整
      double aspectRatio = decodedImg.width / decodedImg.height;
      int previewHeight = (previewWidth / aspectRatio).round();
      
      // 创建临时文件
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _tempFilePaths.add(tempPath);
      final File previewFile = File(tempPath);
      
      // 使用compute隔离处理图像但不使用其返回值
      await compute(_resizeAndSaveImage, {
        'inputPath': image.path,
        'outputPath': previewFile.path,
        'width': previewWidth,
        'height': previewHeight,
      });
      
      // 检查文件是否成功创建
      if (await previewFile.exists()) {
        return previewFile;
      }
      return null;
    } catch (e) {
      print('创建预览图像出错: $e');
      return null;
    }
  }
  
  /// 添加白色边框
  Future<File?> addWhiteFrame(File image, double frameWidth, {bool isPreview = false}) async {
    try {
      // 获取临时输出路径
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/framed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _tempFilePaths.add(outputPath); // 跟踪临时文件
      
      // 使用compute在隔离中处理图像
      final outputFile = await compute(_addWhiteFrameInIsolate, {
        'inputPath': image.path,
        'outputPath': outputPath,
        'frameWidth': frameWidth,
        'quality': isPreview ? 80 : 100,
      });
      
      return outputFile;
    } catch (e) {
      print('添加白色边框出错: $e');
      return null;
    }
  }
  
  /// 保存图片到相册
  Future<bool> saveToGallery(File image) async {
    bool success = false;
    
    try {
      success = await GallerySaver.saveImage(
        image.path,
        albumName: '加白'
      ) ?? false;
      
      // 保存成功后可以清理临时文件
      if (success) {
        _cleanupTempFiles();
      }
    } catch (e) {
      print('保存图片到相册出错: $e');
    }
    
    return success;
  }

  // 添加辅助方法将ui.decodeImageFromList转换为返回Future<ui.Image>的形式
  Future<ui.Image> _decodeImageFromList(Uint8List list) {
    Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(list, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }
}

// 在独立的isolate中处理白框添加
Future<File> _addWhiteFrameInIsolate(Map<String, dynamic> params) async {
  final String inputPath = params['inputPath'];
  final String outputPath = params['outputPath'];
  final double frameWidth = params['frameWidth'];
  final int quality = params['quality'];
  
  final File inputFile = File(inputPath);
  final List<int> bytes = await inputFile.readAsBytes();
  final img.Image? originalImage = img.decodeImage(bytes);
  
  if (originalImage == null) {
    throw Exception('无法解码图像');
  }
  
  if (frameWidth <= 0.001) {
    // 如果白框宽度为0，直接复制原图
    await File(outputPath).writeAsBytes(bytes);
    return File(outputPath);
  }
  
  // 计算白框像素宽度
  final int frameWidthPixels = (originalImage.width * frameWidth).round();
  
  // 创建新图像尺寸
  final newWidth = originalImage.width + (frameWidthPixels * 2);
  final newHeight = originalImage.height + (frameWidthPixels * 2);
  
  // 创建带白框的新图像
  final framedImage = img.Image.rgb(newWidth, newHeight);
  img.fill(framedImage, img.getColor(254, 254, 254));
  img.copyInto(framedImage, originalImage, dstX: frameWidthPixels, dstY: frameWidthPixels);
  
  // 编码并保存
  final List<int> outputBytes = img.encodeJpg(framedImage, quality: quality);
  await File(outputPath).writeAsBytes(outputBytes);
  
  return File(outputPath);
}

// 图像缩放处理
Future<void> _resizeAndSaveImage(Map<String, dynamic> params) async {
  final String inputPath = params['inputPath'];
  final String outputPath = params['outputPath'];
  final int width = params['width'];
  final int height = params['height'];
  
  // 实现图像缩放逻辑
  final File inputFile = File(inputPath);
  final List<int> inputBytes = await inputFile.readAsBytes();
  
  // 解码图像
  final img.Image? originalImage = img.decodeImage(inputBytes);
  if (originalImage == null) return;
  
  // 调整大小
  final img.Image resizedImage = img.copyResize(
    originalImage,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
  
  // 编码并保存
  final List<int> outputBytes = img.encodeJpg(resizedImage, quality: 85);
  await File(outputPath).writeAsBytes(outputBytes);
} 