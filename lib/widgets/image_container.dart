import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_editor/utils/toast_utils.dart';
import 'package:image_picker/image_picker.dart';

class ImageContainer extends StatefulWidget {
  final File? image;
  final File? originalImage;
  final File? previewImage;
  final bool selected;
  final Function(File) onImageSelected;

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
      final image = await getImageFromGallery();
      if (image != null) {
        widget.onImageSelected(image);
      }
    } catch (e) {
      ToastUtils.showErrorToast('选择图片失败: $e');
    }
  }

  Future<File?> getImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      ToastUtils.showErrorToast('选择图片失败: $e');
      return null;
    }
  }
}

class CheckerboardPainter extends CustomPainter {
  final double squareSize;
  final Color color1;
  final Color color2;

  CheckerboardPainter({
    required this.squareSize,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()..color = color1;
    final Paint paint2 = Paint()..color = color2;

    int rows = (size.height / squareSize).ceil();
    int cols = (size.width / squareSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final paint = (row + col) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
            col * squareSize,
            row * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 