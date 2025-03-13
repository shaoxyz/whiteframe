import 'package:flutter/material.dart';
import 'package:image_editor/ApplyFilters.dart';
import 'package:image_editor/EditImg.dart';
import 'package:image_editor/GetImg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_editor/SaveInGallery.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _selected = false;
  File? _image;
  File? _originalImage;
  File? _previewImage;
  double _imageContainerHeight = 450;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  double _frameWidth = 0.0;
  double _tempFrameWidth = 0.0;
  bool _isEditingFrame = false;
  bool _isShowingOriginal = false;
  bool _hasShownTip = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black.withValues(alpha: 204, red: 0, green: 0, blue: 0),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<File?> _createPreviewImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;
      
      final int maxWidth = 800;
      double ratio = originalImage.width > maxWidth 
          ? maxWidth / originalImage.width 
          : 1.0;
      
      final previewImage = img.copyResize(
        originalImage,
        width: (originalImage.width * ratio).round(),
        height: (originalImage.height * ratio).round(),
        interpolation: img.Interpolation.average,
      );
      
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/preview_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(previewImage, quality: 85));
      
      return outputFile;
    } catch (e) {
      print('创建预览图像出错: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('加白'),
        actions: [
          if (_selected)
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () {
                setState(() {
                  _controller.reverse().then((_) {
                    setState(() {
                      _selected = false;
                      _image = null;
                    });
                  });
                });
              },
              tooltip: '重置',
            ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 64 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Container(
                      height: _imageContainerHeight,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selected
                          ? GestureDetector(
                              onLongPressStart: (_) {
                                setState(() {
                                  _isShowingOriginal = true;
                                });
                                
                                if (!_hasShownTip) {
                                  _showToast('松开手指返回预览');
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: _isEditingFrame 
                                          ? _tempFrameWidth * MediaQuery.of(context).size.width * 0.003
                                          : _frameWidth * MediaQuery.of(context).size.width * 0.003,
                                    ),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Image.file(
                                            _isShowingOriginal ? _originalImage! : _image!,
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
                              ),
                            )
                          : InkWell(
                              onTap: () async {
                                var _Ifile = await GetImg(context);
                                if (_Ifile != null) {
                                  setState(() {
                                    _image = _Ifile;
                                    _originalImage = _Ifile;
                                    _selected = true;
                                    _controller.forward();
                                  });
                                  
                                  final previewFile = await _createPreviewImage(_Ifile);
                                  if (previewFile != null) {
                                    setState(() {
                                      _previewImage = previewFile;
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 80,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '点击选择或拍摄图片',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '支持JPG、PNG格式',
                                      style: TextStyle(
                                        color: Colors.black38,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(
                    icon: Icons.border_outer,
                    label: '加白',
                    onTap: () async {
                      if (_image != null) {
                        _tempFrameWidth = _frameWidth;
                        
                        setState(() {
                          _isEditingFrame = true;
                        });
                        
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setModalState) {
                                return Container(
                                  height: MediaQuery.of(context).size.height * 0.25,
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
                                            Row(
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _tempFrameWidth = _frameWidth;
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    '取消',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      _frameWidth = _tempFrameWidth;
                                                    });
                                                    final result = await _addWhiteFrameToImage(_originalImage!, _frameWidth);
                                                    if (result != null) {
                                                      setState(() {
                                                        _image = result;
                                                      });
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    '完成',
                                                    style: TextStyle(
                                                      color: Theme.of(context).primaryColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                                '相框宽度: ${(_tempFrameWidth * 100).round()}%',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Slider(
                                                value: _tempFrameWidth,
                                                min: 0,
                                                max: 0.25,
                                                divisions: 25,
                                                label: '${(_tempFrameWidth * 100).round()}%',
                                                onChanged: (newValue) async {
                                                  setModalState(() {
                                                    _tempFrameWidth = newValue;
                                                  });
                                                  
                                                  File? previewResult = await _addWhiteFrameToImage(
                                                    _previewImage ?? _originalImage!,
                                                    _tempFrameWidth
                                                  );
                                                  
                                                  if (previewResult != null) {
                                                    setState(() {
                                                      _image = previewResult;
                                                    });
                                                  }
                                                },
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
                        
                        setState(() {
                          _isEditingFrame = false;
                          _frameWidth = _tempFrameWidth;
                        });
                      } else {
                        _showToast('请先选择图片');
                      }
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.crop,
                    label: '裁剪',
                    onTap: () async {
                      if (_image != null) {
                        var _Ifile = await EditImg(_image!);
                        if (_Ifile != null) {
                          setState(() {
                            _image = _Ifile;
                          });
                        }
                      } else {
                        _showToast('请先选择图片');
                      }
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.filter,
                    label: '滤镜',
                    onTap: () async {
                      if (_image != null) {
                        var _Ifile = await ApplyFilters(context, _image!);
                        if (_Ifile != null) {
                          setState(() {
                            _image = _Ifile;
                          });
                        }
                      } else {
                        _showToast('请先选择图片');
                      }
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.save_alt,
                    label: '保存',
                    onTap: () async {
                      if (_image != null) {
                        final success = await SaveImg(_image!);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('图片已保存到相册'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              margin: const EdgeInsets.all(20),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        _showToast('请先选择图片');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _addWhiteFrameToImage(File image, double frameWidth) async {
    try {
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;
      
      if (frameWidth <= 0.001) {
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/original_copy_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(bytes);
        return outputFile;
      }
      
      final int frameWidthPixels = (originalImage.width * frameWidth).round();
      
      final newWidth = originalImage.width + (frameWidthPixels * 2);
      final newHeight = originalImage.height + (frameWidthPixels * 2);
      
      final framedImage = img.Image.rgb(newWidth, newHeight);
      
      img.fill(framedImage, img.getColor(254, 254, 254));
      
      img.copyInto(framedImage, originalImage, dstX: frameWidthPixels, dstY: frameWidthPixels);
      
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
}
