import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

Future<File?> AddWhiteFrame(BuildContext context, File imageFile) async {
  double frameWidth = 20.0;
  bool isProcessing = false;
  File? resultFile;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // 允许底部面板更大
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder( // 使用 StatefulBuilder 来管理状态
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.4, // 占屏幕高度的40%
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '调整白框宽度',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: isProcessing ? null : () async {
                          setState(() {
                            isProcessing = true;
                          });
                          
                          resultFile = await _addWhiteFrameToImage(
                            imageFile, 
                            frameWidth.toInt()
                          );
                          
                          if (resultFile != null) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('处理图片时出错'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() {
                              isProcessing = false;
                            });
                          }
                        },
                        child: Text(
                          '完成',
                          style: TextStyle(
                            color: isProcessing 
                                ? Colors.grey 
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '相框宽度: ${frameWidth.toInt()}px',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: frameWidth,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: frameWidth.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              frameWidth = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '提示：滑动调节相框宽度',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  return resultFile;
}

Future<File?> _addWhiteFrameToImage(File imageFile, int frameWidth) async {
  try {
    // 读取原始图片
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    
    if (originalImage == null) return null;
    
    // 计算新图片尺寸
    final newWidth = originalImage.width + (frameWidth * 2);
    final newHeight = originalImage.height + (frameWidth * 2);
    
    // 创建带白色边框的新图片
    final framedImage = img.Image.rgb(newWidth, newHeight);
    
    // 填充白色背景，添加一点灰度使其不那么刺眼
    img.fill(framedImage, img.getColor(254, 254, 254)); // 极浅的灰色
    
    // 在白色边框中央绘制原始图片
    img.copyInto(framedImage, originalImage, dstX: frameWidth, dstY: frameWidth);
    
    // 将处理后的图片保存到临时文件
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/framed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(framedImage, quality: 90));
    
    return outputFile;
  } catch (e) {
    print('添加白色边框出错: $e');
    return null;
  }
} 