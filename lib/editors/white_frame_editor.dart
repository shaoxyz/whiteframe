import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor/editors/editor_base.dart';
import 'package:image_editor/services/image_service.dart';
import 'package:image_editor/utils/toast_utils.dart';

class WhiteFrameEditor implements ImageEditor {
  final ImageService _imageService = ImageService();
  
  // 保存应用到图像的白框宽度，用于状态维护
  final Map<String, double> _appliedFrameWidths = {};
  
  // 添加实时预览回调支持
  Function(File)? _currentPreviewCallback;
  
  @override
  String get name => '加白';
  
  @override
  IconData get icon => Icons.border_outer;
  
  @override
  Future<File?> processImage(File image, BuildContext context) async {
    File? resultImage;
    _currentPreviewCallback = null;
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildFrameEditorUI(
          context, 
          image, 
          (width, result) {
            if (result != null) {
              // 保存应用的宽度
              _appliedFrameWidths[image.path] = width;
              resultImage = result;
            }
          }
        );
      },
    );
    
    _currentPreviewCallback = null;
    return resultImage;
  }
  
  @override
  Widget buildEditorUI(BuildContext context, File image, Function(File) onImageUpdated) {
    return _buildFrameEditorUI(context, image, (width, result) {
      if (result != null) {
        // 保存应用的宽度
        _appliedFrameWidths[image.path] = width;
        onImageUpdated(result);
      }
    });
  }
  
  Widget _buildFrameEditorUI(BuildContext context, File image, Function(double, File?) onResult) {
    // 获取当前图像已应用的白框宽度（如果有）
    double initialFrameWidth = _appliedFrameWidths[image.path] ?? 0.0;
    
    return _FrameEditorUI(
      imageService: _imageService,
      image: image,
      initialFrameWidth: initialFrameWidth,
      onResult: onResult,
      onPreviewUpdate: (File previewFile) {
        // 确保即使在底部菜单打开的情况下也能持续更新预览
        if (_currentPreviewCallback != null) {
          _currentPreviewCallback!(previewFile);
        }
      },
    );
  }

  // 完全重写这个方法，确保预览回调持续工作
  Future<File?> processImageWithPreview(
    File image,
    BuildContext context,
    Function(File previewFile) onPreview,
    {Function(File resultFile)? onComplete}
  ) async {
    // 直接保存预览回调，不要在后续清除它
    _currentPreviewCallback = onPreview;
    
    // 立即生成一个初始预览
    File? previewFile = await _imageService.createPreviewImage(image);
    if (previewFile != null) {
      // 如果有已保存的宽度设置，立即应用预览
      double initialWidth = _appliedFrameWidths[image.path] ?? 0.0;
      if (initialWidth > 0) {
        File? initialPreview = await _imageService.addWhiteFrame(
          previewFile, 
          initialWidth,
          isPreview: true
        );
        if (initialPreview != null && _currentPreviewCallback != null) {
          _currentPreviewCallback!(initialPreview);
        }
      }
    }
    
    File? resultImage;
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildFrameEditorUI(
          context, 
          image, 
          (width, result) {
            if (result != null) {
              _appliedFrameWidths[image.path] = width;
              resultImage = result;
              if (onComplete != null) {
                onComplete(result);
              }
            }
          }
        );
      },
    );
    
    return resultImage;
  }
}

// 提取UI部分为独立的StatefulWidget以更好地管理状态
class _FrameEditorUI extends StatefulWidget {
  final ImageService imageService;
  final File image;
  final double initialFrameWidth;
  final Function(double, File?) onResult;
  final Function(File)? onPreviewUpdate;

  const _FrameEditorUI({
    required this.imageService,
    required this.image,
    required this.initialFrameWidth,
    required this.onResult,
    this.onPreviewUpdate,
  });

  @override
  _FrameEditorUIState createState() => _FrameEditorUIState();
}

class _FrameEditorUIState extends State<_FrameEditorUI> {
  late double tempFrameWidth;
  bool isProcessing = false;
  File? previewImage;
  Timer? _debounceTimer;
  bool showPreview = false;
  
  // 低分辨率预览图
  File? _previewFile;
  
  @override
  void initState() {
    super.initState();
    tempFrameWidth = widget.initialFrameWidth;
    
    // 初始化时就生成预览图
    _generateInitialPreview();
  }
  
  Future<void> _generateInitialPreview() async {
    setState(() {
      isProcessing = true;
    });
    
    // 创建低分辨率预览版本用于实时更新
    _previewFile = await widget.imageService.createPreviewImage(widget.image);
    
    // 如果有初始宽度，则显示对应的预览
    if (tempFrameWidth > 0) {
      await _updatePreview(tempFrameWidth);
    } else {
      previewImage = widget.image;
    }
    
    setState(() {
      isProcessing = false;
      showPreview = true;
    });
  }
  
  // 防抖处理滑块变化，避免频繁处理图像
  void _debouncedPreviewUpdate(double newValue) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    setState(() {
      tempFrameWidth = newValue;
    });
    
    // 使用更短的延迟，确保预览更加顺滑
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _updatePreview(newValue);
    });
  }
  
  Future<void> _updatePreview(double frameWidth) async {
    if (isProcessing || _previewFile == null) return;
    
    setState(() {
      isProcessing = true;
    });
    
    // 使用低分辨率图像进行预览处理
    File? preview = await widget.imageService.addWhiteFrame(
      _previewFile!,
      frameWidth,
      isPreview: true,
    );
    
    if (preview != null) {
      setState(() {
        previewImage = preview;
        isProcessing = false;
      });
      
      // 确保回调被执行，将预览发送到主屏幕
      if (widget.onPreviewUpdate != null) {
        widget.onPreviewUpdate!(preview);
      }
    } else {
      setState(() {
        isProcessing = false;
      });
      ToastUtils.showErrorToast('预览生成失败');
    }
  }
  
  Future<void> _applyChanges() async {
    setState(() {
      isProcessing = true;
    });
    
    final result = await widget.imageService.addWhiteFrame(
      widget.image, 
      tempFrameWidth,
    );
    
    if (result != null) {
      widget.onResult(tempFrameWidth, result);
      Navigator.pop(context);
    } else {
      ToastUtils.showErrorToast('处理图片时出错');
      setState(() {
        isProcessing = false;
      });
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // 增加高度以适应新增控件
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 顶部拖动条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '调整白框',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: isProcessing ? null : () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isProcessing ? null : _applyChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isProcessing 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('应用'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 控制区域 - 使用 Expanded 包裹滚动区域解决溢出问题
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '白框宽度',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 25, red: null, green: null, blue: null),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(tempFrameWidth * 100).round()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.grey.shade200,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 4,
                        ),
                        overlayColor: Theme.of(context).primaryColor.withValues(alpha: 25, red: null, green: null, blue: null),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: tempFrameWidth,
                        min: 0,
                        max: 0.25,
                        divisions: 25,
                        onChanged: isProcessing 
                            ? null 
                            : (newValue) => _debouncedPreviewUpdate(newValue),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '25%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '实时预览',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Switch(
                          value: true, // 默认开启
                          onChanged: (value) {
                            // 如果关闭，则不会发送预览更新
                            if (value && !isProcessing) {
                              _updatePreview(tempFrameWidth);
                            }
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 