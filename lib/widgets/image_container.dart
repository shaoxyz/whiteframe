import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_editor/utils/toast_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageContainer extends StatefulWidget {
  final File? image;
  final File? originalImage;
  final File? previewImage;
  final bool selected;
  final Function(File originalImage, File thumbnailImage) onImageSelected;

  const ImageContainer({
    Key? key,
    this.image,
    this.originalImage,
    this.previewImage,
    required this.selected,
    required this.onImageSelected,
  }) : super(key: key);

  @override
  _ImageContainerState createState() => _ImageContainerState();
}

class _ImageContainerState extends State<ImageContainer> {
  bool _isShowingOriginal = false;
  bool _hasShownTip = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.selected) {
      return InkWell(
        onTap: () => _selectImage(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '点击选择图片',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final imageToShow = widget.previewImage ?? widget.image;
      
      return imageToShow != null
        ? GestureDetector(
            onLongPressStart: (_) {
              setState(() {
                _isShowingOriginal = true;
              });
              
              if (!_hasShownTip) {
                ToastUtils.showToast('松开手指返回预览');
                _hasShownTip = true;
              }
            },
            onLongPressEnd: (_) {
              setState(() {
                _isShowingOriginal = false;
              });
            },
            child: Hero(
              tag: 'image',
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Image.file(
                        _isShowingOriginal 
                            ? widget.originalImage! 
                            : imageToShow,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (_isShowingOriginal)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '原图预览',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
    }
  }

  void _selectImage(BuildContext context) async {
    try {
      final result = await getImageWithThumbnail();
      if (result != null) {
        widget.onImageSelected(result.originalImage, result.thumbnailImage);
      }
    } catch (e) {
      ToastUtils.showErrorToast('选择图片失败: $e');
    }
  }

  Future<ImageResult?> getImageWithThumbnail() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);
        
        // 创建缩略图用于编辑预览
        final thumbnailFile = await _createThumbnail(originalFile);
        
        // 返回包含原图和缩略图的对象
        return ImageResult(
          originalImage: originalFile,
          thumbnailImage: thumbnailFile
        );
      }
      return null;
    } catch (e) {
      ToastUtils.showErrorToast('选择图片失败: $e');
      return null;
    }
  }

  Future<File> _createThumbnail(File originalImage) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';
      
      // 尝试使用 flutter_image_compress
      try {
        final result = await FlutterImageCompress.compressAndGetFile(
          originalImage.path,
          targetPath,
          quality: 70,
          minWidth: 600,
          minHeight: 600,
        );
        
        if (result != null) {
          return File(result.path);
        }
      } catch (e) {
        print('压缩失败，使用原图作为缩略图: $e');
      }
      
      // 如果压缩失败，复制原图作为缩略图
      return originalImage.copy(targetPath);
    } catch (e) {
      print('创建缩略图失败: $e');
      return originalImage;
    }
  }
}

// 用于存储原始图片和缩略图的数据类
class ImageResult {
  final File originalImage;
  final File thumbnailImage;
  
  ImageResult({required this.originalImage, required this.thumbnailImage});
} 