import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor/editors/editor_base.dart';
import 'package:image_editor/services/image_service.dart';
import 'package:image_editor/utils/toast_utils.dart';

// 添加一个新的数据类用于存储框架设置
class FrameSettings {
  final double top;
  final double right;
  final double bottom;
  final double left;
  final double cornerRadius;
  
  const FrameSettings({
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
    this.cornerRadius = 0.0,
  });
  
  // 用于创建所有边都相等的设置
  factory FrameSettings.uniform(double width, {double cornerRadius = 0.0}) {
    return FrameSettings(
      top: width,
      right: width,
      bottom: width,
      left: width,
      cornerRadius: cornerRadius,
    );
  }
  
  // 复制构造函数
  FrameSettings copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
    double? cornerRadius,
  }) {
    return FrameSettings(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }
  
  // 获取最大边框宽度的辅助方法
  double get maxWidth => [top, right, bottom, left].reduce((a, b) => a > b ? a : b);
  
  // 检查是否为统一宽度
  bool get isUniform => top == right && right == bottom && bottom == left;
}

class WhiteFrameEditor implements ImageEditor {
  final ImageService _imageService = ImageService();
  
  // 修改为使用 FrameSettings 保存应用到图像的设置
  final Map<String, FrameSettings> _appliedFrameSettings = {};
  
  // 添加临时编辑中的设置值
  final Map<String, FrameSettings> _tempFrameSettings = {};
  
  // 添加实时预览回调支持
  Function(File)? _currentPreviewCallback;
  
  // 添加模式跟踪映射
  final Map<String, bool> _frameEditorModes = {}; // true 表示统一边框模式, false 表示自定义边框模式
  
  @override
  String get name => '加白';
  
  @override
  IconData get icon => Icons.border_outer;
  
  @override
  Future<File?> processImage(File image, BuildContext context) async {
    File? resultImage;
    _currentPreviewCallback = null;
    
    // 获取初始设置
    FrameSettings initialSettings = _tempFrameSettings[image.path] ?? 
                          _appliedFrameSettings[image.path] ?? 
                          FrameSettings.uniform(0.0);
    
    // 获取初始模式
    bool initialMode = _frameEditorModes[image.path] ?? initialSettings.isUniform;
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (BuildContext context) {
        return _buildFrameEditorUI(
          context, 
          image,
          initialSettings,
          initialMode, // 传递初始模式
          (settings, result, canceled, mode) { // 更新回调函数签名
            if (result != null) {
              // 保存应用的设置
              _appliedFrameSettings[image.path] = settings;
              _frameEditorModes[image.path] = mode; // 保存模式
              resultImage = result;
            }
          },
          (settings, mode) { // 更新回调函数签名
            // 添加设置变化回调
            _tempFrameSettings[image.path] = settings;
            _frameEditorModes[image.path] = mode; // 保存模式
          }
        );
      },
    );
    
    _currentPreviewCallback = null;
    return resultImage;
  }
  
  @override
  Widget buildEditorUI(BuildContext context, File image, Function(File) onImageUpdated) {
    // 获取初始设置
    FrameSettings initialSettings = _tempFrameSettings[image.path] ?? 
                          _appliedFrameSettings[image.path] ?? 
                          FrameSettings.uniform(0.0);
    
    // 获取初始模式
    bool initialMode = _frameEditorModes[image.path] ?? initialSettings.isUniform;
    
    return _buildFrameEditorUI(
      context, 
      image,
      initialSettings,
      initialMode, // 传递初始模式
      (settings, result, canceled, mode) { // 更新回调函数签名
        if (result != null) {
          // 保存应用的设置
          _appliedFrameSettings[image.path] = settings;
          _frameEditorModes[image.path] = mode; // 保存模式
          onImageUpdated(result);
        }
      },
      (settings, mode) { // 更新回调函数签名
        // 添加设置变化回调
        _tempFrameSettings[image.path] = settings;
        _frameEditorModes[image.path] = mode; // 保存模式
      }
    );
  }
  
  Widget _buildFrameEditorUI(
    BuildContext context, 
    File image, 
    FrameSettings initialSettings,
    bool initialMode, // 添加初始模式参数
    Function(FrameSettings, File?, bool, bool) onResult, // 更新回调函数签名，添加模式参数
    Function(FrameSettings, bool)? onSettingsChanged // 更新回调函数签名，添加模式参数
  ) {
    return _FrameEditorUI(
      imageService: _imageService,
      image: image,
      initialSettings: initialSettings,
      initialMode: initialMode, // 传递初始模式
      onResult: onResult,
      onSettingsChanged: onSettingsChanged,
      onPreviewUpdate: (File previewFile) {
        if (_currentPreviewCallback != null) {
          _currentPreviewCallback!(previewFile);
        }
      },
    );
  }

  // 修改预览方法以使用新的数据结构
  Future<File?> processImageWithPreview(
    File image,
    BuildContext context,
    Function(File previewFile) onPreview,
    {Function(File resultFile)? onComplete, 
     Function()? onCanceled}
  ) async {
    _currentPreviewCallback = onPreview;
    
    // 立即生成一个初始预览
    File? previewFile = await _imageService.createPreviewImage(image);
    if (previewFile != null) {
      // 获取之前保存的临时值或已应用的值
      FrameSettings initialSettings = _tempFrameSettings[image.path] ?? 
                            _appliedFrameSettings[image.path] ?? 
                            FrameSettings.uniform(0.0);
      
      if (initialSettings.maxWidth > 0) {
        File? initialPreview = await _imageService.addWhiteFrameAdvanced(
          previewFile, 
          initialSettings,
          isPreview: true
        );
        if (initialPreview != null && _currentPreviewCallback != null) {
          _currentPreviewCallback!(initialPreview);
        }
      }
    }
    
    File? resultImage;
    bool userCanceled = false;
    
    FrameSettings initialSettings = _tempFrameSettings[image.path] ?? 
                         _appliedFrameSettings[image.path] ?? 
                         FrameSettings.uniform(0.0);
    
    // 获取保存的模式，如果没有则根据设置是否统一来决定
    bool initialMode = _frameEditorModes[image.path] ?? initialSettings.isUniform;
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return _buildFrameEditorUI(
          context, 
          image,
          initialSettings,
          initialMode,
          (settings, result, canceled, mode) {
            if (result != null) {
              // 应用了更改
              _appliedFrameSettings[image.path] = settings;
              _tempFrameSettings[image.path] = settings;
              _frameEditorModes[image.path] = mode; // 保存使用的模式
              resultImage = result;
              if (onComplete != null) {
                onComplete(result);
              }
            } else if (canceled) {
              // 用户点击取消按钮关闭
              userCanceled = true;
              _tempFrameSettings.remove(image.path);
              if (onCanceled != null) {
                onCanceled();
              }
            } else {
              // 滑动关闭
              _frameEditorModes[image.path] = mode; // 保存当前模式
            }
          },
          (currentSettings, mode) {
            _tempFrameSettings[image.path] = currentSettings;
            _frameEditorModes[image.path] = mode; // 实时更新模式
          }
        );
      },
    );
    
    return resultImage;
  }
}

// 更新StatefulWidget以支持圆角和独立边框宽度
class _FrameEditorUI extends StatefulWidget {
  final ImageService imageService;
  final File image;
  final FrameSettings initialSettings;
  final bool initialMode; // 添加初始模式
  final Function(FrameSettings, File?, bool, bool) onResult; // 增加模式参数
  final Function(FrameSettings, bool)? onSettingsChanged; // 增加模式参数
  final Function(File)? onPreviewUpdate;

  const _FrameEditorUI({
    required this.imageService,
    required this.image,
    required this.initialSettings,
    required this.initialMode, // 初始模式
    required this.onResult,
    this.onPreviewUpdate,
    this.onSettingsChanged,
  });

  @override
  _FrameEditorUIState createState() => _FrameEditorUIState();
}

class _FrameEditorUIState extends State<_FrameEditorUI> with SingleTickerProviderStateMixin {
  late FrameSettings tempSettings;
  // 分别保存两种模式的设置
  late FrameSettings _customSettings;
  late double _uniformWidth;
  
  bool isProcessing = false;
  File? previewImage;
  Timer? _debounceTimer;
  bool showPreview = true;
  late bool useUniformWidth; // 使用 late 关键字延迟初始化
  
  // 用于高级选项的Tab控制器
  late TabController _tabController;
  
  // 低分辨率预览图
  File? _previewFile;
  
  @override
  void initState() {
    super.initState();
    tempSettings = widget.initialSettings;
    
    // 初始化模式，使用传入的初始模式
    useUniformWidth = widget.initialMode;
    
    // 根据初始设置初始化两种模式的值
    if (widget.initialSettings.isUniform) {
      _uniformWidth = widget.initialSettings.top;
      // 初始化自定义设置为默认值
      _customSettings = FrameSettings(
        top: 0.08,
        right: 0.08,
        bottom: 0.25,
        left: 0.08,
        cornerRadius: widget.initialSettings.cornerRadius
      );
    } else {
      _customSettings = widget.initialSettings;
      // 使用最大边宽作为统一宽度的初始值
      _uniformWidth = widget.initialSettings.maxWidth;
    }
    
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化时就生成预览图
    _generateInitialPreview();
  }
  
  Future<void> _generateInitialPreview() async {
    setState(() {
      isProcessing = true;
    });
    
    // 创建低分辨率预览版本用于实时更新
    _previewFile = await widget.imageService.createPreviewImage(widget.image);
    
    // 如果有初始设置，则显示对应的预览
    if (tempSettings.maxWidth > 0) {
      await _updatePreview(tempSettings);
    } else {
      previewImage = widget.image;
    }
    
    setState(() {
      isProcessing = false;
      showPreview = true;
    });
  }
  
  // 防抖处理设置变化，避免频繁处理图像
  void _debouncedPreviewUpdate(FrameSettings newSettings) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    setState(() {
      tempSettings = newSettings;
      
      // 同时更新对应模式的设置
      if (useUniformWidth) {
        _uniformWidth = newSettings.top;
      } else {
        _customSettings = newSettings;
      }
    });
    
    // 通知父组件设置和模式已更改
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!(tempSettings, useUniformWidth);
    }
    
    // 延迟更新预览
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _updatePreview(newSettings);
    });
  }
  
  Future<void> _updatePreview(FrameSettings settings) async {
    if (isProcessing || _previewFile == null) return;
    
    setState(() {
      isProcessing = true;
    });
    
    // 使用低分辨率图像进行预览处理
    File? preview = await widget.imageService.addWhiteFrameAdvanced(
      _previewFile!,
      settings,
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
    
    final result = await widget.imageService.addWhiteFrameAdvanced(
      widget.image, 
      tempSettings,
    );
    
    if (result != null) {
      // 传递当前设置、结果、取消状态和当前模式
      widget.onResult(tempSettings, result, false, useUniformWidth);
      Navigator.pop(context);
    } else {
      ToastUtils.showErrorToast('处理图片时出错');
      setState(() {
        isProcessing = false;
      });
    }
  }
  
  // 创建统一宽度控制器
  Widget _buildUniformWidthControl() {
    return Column(
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
                color: Theme.of(context).primaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_uniformWidth * 100).round()}%',
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
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.25),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: _uniformWidth,
            min: 0,
            max: 1.0,
            divisions: 100,
            onChanged: isProcessing 
                ? null 
                : (newValue) {
                    _uniformWidth = newValue; // 更新统一宽度
                    final newSettings = FrameSettings.uniform(
                      newValue, 
                      cornerRadius: tempSettings.cornerRadius
                    );
                    _debouncedPreviewUpdate(newSettings);
                  },
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
              '100%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 创建独立边框控件
  Widget _buildCustomEdgesControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自定义边框',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        
        // 上边框控制
        _buildEdgeControl(
          label: '上边框',
          value: tempSettings.top,
          onChanged: (value) {
            _debouncedPreviewUpdate(tempSettings.copyWith(top: value));
            // 更新自定义设置
            _customSettings = tempSettings.copyWith(top: value);
          },
        ),
        
        // 右边框控制
        _buildEdgeControl(
          label: '右边框',
          value: tempSettings.right,
          onChanged: (value) {
            _debouncedPreviewUpdate(tempSettings.copyWith(right: value));
            // 更新自定义设置
            _customSettings = tempSettings.copyWith(right: value);
          },
        ),
        
        // 下边框控制
        _buildEdgeControl(
          label: '下边框',
          value: tempSettings.bottom,
          onChanged: (value) {
            _debouncedPreviewUpdate(tempSettings.copyWith(bottom: value));
            // 更新自定义设置
            _customSettings = tempSettings.copyWith(bottom: value);
          },
        ),
        
        // 左边框控制
        _buildEdgeControl(
          label: '左边框',
          value: tempSettings.left,
          onChanged: (value) {
            _debouncedPreviewUpdate(tempSettings.copyWith(left: value));
            // 更新自定义设置
            _customSettings = tempSettings.copyWith(left: value);
          },
        ),
      ],
    );
  }
  
  // 创建单个边框宽度控制器
  Widget _buildEdgeControl({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 3,
            ),
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 14,
            ),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 1.0,
            divisions: 100,
            onChanged: isProcessing ? null : onChanged,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  
  // 创建圆角控制器
  Widget _buildCornerRadiusControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '圆角大小',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(tempSettings.cornerRadius * 100).round()}%',
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
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.25),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: tempSettings.cornerRadius,
            min: 0,
            max: 0.15, // 圆角最大值设为15%
            divisions: 15,
            onChanged: isProcessing 
                ? null 
                : (newValue) {
                    final newSettings = tempSettings.copyWith(cornerRadius: newValue);
                    
                    // 同时更新另一种模式的圆角
                    if (useUniformWidth) {
                      _uniformWidth = _uniformWidth; // 保持不变
                    } else {
                      _customSettings = _customSettings.copyWith(cornerRadius: newValue);
                    }
                    
                    _debouncedPreviewUpdate(newSettings);
                  },
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
              '15%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.onResult(tempSettings, null, false, useUniformWidth);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
            
            if (showPreview && previewImage != null)
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    previewImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            
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
                          widget.onResult(tempSettings, null, true, useUniformWidth);
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
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: useUniformWidth,
                          onChanged: isProcessing ? null : (value) {
                            setState(() {
                              useUniformWidth = true;
                              tempSettings = FrameSettings.uniform(
                                _uniformWidth,
                                cornerRadius: tempSettings.cornerRadius
                              );
                            });
                            _updatePreview(tempSettings);
                            if (widget.onSettingsChanged != null) {
                              widget.onSettingsChanged!(tempSettings, true);
                            }
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        const Text('统一边框'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: useUniformWidth,
                          onChanged: isProcessing ? null : (value) {
                            setState(() {
                              useUniformWidth = false;
                              tempSettings = _customSettings.copyWith(
                                cornerRadius: tempSettings.cornerRadius
                              );
                            });
                            _updatePreview(tempSettings);
                            if (widget.onSettingsChanged != null) {
                              widget.onSettingsChanged!(tempSettings, false);
                            }
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        const Text('自定义边框'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (useUniformWidth)
                        _buildUniformWidthControl()
                      else
                        _buildCustomEdgesControl(),
                      
                      const SizedBox(height: 24),
                      
                      _buildCornerRadiusControl(),
                      
                      const SizedBox(height: 24),
                      
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
                            value: showPreview,
                            onChanged: (value) {
                              setState(() {
                                showPreview = value;
                              });
                              if (value && !isProcessing) {
                                _updatePreview(tempSettings);
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
      ),
    );
  }
} 