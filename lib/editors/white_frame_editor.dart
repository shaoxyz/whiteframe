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
    bool initialMode,
    Function(FrameSettings, File?, bool, bool) onResult,
    Function(FrameSettings, bool)? onSettingsChanged
  ) {
    return _FrameEditorUI(
      imageService: _imageService,
      image: image,
      initialSettings: initialSettings,
      initialMode: initialMode,
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
     Function()? onCanceled,
     Function(FrameSettings, bool)? onSettingsSaved} // 添加新的回调参数
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
              
              // 调用新的回调来保存设置
              if (onSettingsSaved != null) {
                onSettingsSaved(settings, mode);
              }
              
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
              
              // 如果用户通过滑动关闭，也保存最后的设置
              if (onSettingsSaved != null) {
                onSettingsSaved(_tempFrameSettings[image.path] ?? initialSettings, mode);
              }
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
  Timer? _debounceTimer;
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
    }
    
    setState(() {
      isProcessing = false;
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            // 标题栏和操作按钮
            _buildHeaderBar(),
            
            // 模式选择器（统一/自定义边框）
            _buildModeSelector(),
            
            // 控制面板内容
            Flexible(
              child: _buildSettingsPanel(),
            ),
          ],
        ),
      ),
    );
  }
  
  // 标题栏和操作按钮
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.border_outer, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                '调整白框',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // 取消按钮
              TextButton(
                onPressed: isProcessing ? null : () {
                  widget.onResult(tempSettings, null, true, useUniformWidth);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              // 应用按钮
              ElevatedButton(
                onPressed: isProcessing ? null : _applyChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(60, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing 
                    ? SizedBox(
                        width: 18,
                        height: 18,
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
    );
  }
  
  // 模式选择器（统一/自定义边框）
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: isProcessing ? null : () {
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: useUniformWidth ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.crop_square,
                      size: 18,
                      color: useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '统一边框',
                      style: TextStyle(
                        fontWeight: useUniformWidth ? FontWeight.w600 : FontWeight.normal,
                        color: useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: isProcessing ? null : () {
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !useUniformWidth ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_ethernet_rounded,
                      size: 18,
                      color: !useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '自定义边框',
                      style: TextStyle(
                        fontWeight: !useUniformWidth ? FontWeight.w600 : FontWeight.normal,
                        color: !useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade800,
                      ),
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
  
  // 设置面板内容
  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示当前编辑模式的设置
            if (useUniformWidth)
              _buildUniformWidthControlNew()
            else
              _buildCustomEdgesControlNew(),
            
            const SizedBox(height: 20),
            
            // 圆角控制（两种模式都显示）
            _buildCornerRadiusControlNew(),
            
            const SizedBox(height: 20),
            
            // 预设模板（快速选择）
            _buildPresets(),
            
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
  
  // 统一边框控制 - 新设计
  Widget _buildUniformWidthControlNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.crop_free, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '白框宽度',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_uniformWidth * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: isProcessing || _uniformWidth <= 0 ? null : () {
                final newValue = (_uniformWidth - 0.01).clamp(0.0, 1.0);
                _uniformWidth = newValue; 
                final newSettings = FrameSettings.uniform(
                  newValue, 
                  cornerRadius: tempSettings.cornerRadius
                );
                _debouncedPreviewUpdate(newSettings);
              },
              icon: Icon(Icons.remove_circle, 
                color: isProcessing || _uniformWidth <= 0 
                    ? Colors.grey.shade300 
                    : Theme.of(context).primaryColor),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: SliderTheme(
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
                          _uniformWidth = newValue; 
                          final newSettings = FrameSettings.uniform(
                            newValue, 
                            cornerRadius: tempSettings.cornerRadius
                          );
                          _debouncedPreviewUpdate(newSettings);
                        },
                ),
              ),
            ),
            IconButton(
              onPressed: isProcessing || _uniformWidth >= 1.0 ? null : () {
                final newValue = (_uniformWidth + 0.01).clamp(0.0, 1.0);
                _uniformWidth = newValue; 
                final newSettings = FrameSettings.uniform(
                  newValue, 
                  cornerRadius: tempSettings.cornerRadius
                );
                _debouncedPreviewUpdate(newSettings);
              },
              icon: Icon(Icons.add_circle, 
                color: isProcessing || _uniformWidth >= 1.0 
                    ? Colors.grey.shade300 
                    : Theme.of(context).primaryColor),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
  
  // 自定义边框控制 - 新设计
  Widget _buildCustomEdgesControlNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings_ethernet_rounded, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '自定义边框',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 使用网格布局显示四个边框设置
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            children: [
              // 上边框控制
              _buildEdgeControlNew(
                label: '上边框',
                icon: Icons.border_top,
                value: tempSettings.top,
                onChanged: (value) {
                  _debouncedPreviewUpdate(tempSettings.copyWith(top: value));
                  _customSettings = tempSettings.copyWith(top: value);
                },
              ),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              // 中间一行显示左右边框
              IntrinsicHeight(
                child: Row(
                  children: [
                    // 左边框控制
                    Expanded(
                      child: _buildEdgeControlNew(
                        label: '左边框',
                        icon: Icons.border_left,
                        value: tempSettings.left,
                        onChanged: (value) {
                          _debouncedPreviewUpdate(tempSettings.copyWith(left: value));
                          _customSettings = tempSettings.copyWith(left: value);
                        },
                      ),
                    ),
                    
                    VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                    
                    // 右边框控制
                    Expanded(
                      child: _buildEdgeControlNew(
                        label: '右边框',
                        icon: Icons.border_right,
                        value: tempSettings.right,
                        onChanged: (value) {
                          _debouncedPreviewUpdate(tempSettings.copyWith(right: value));
                          _customSettings = tempSettings.copyWith(right: value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              // 下边框控制
              _buildEdgeControlNew(
                label: '下边框',
                icon: Icons.border_bottom,
                value: tempSettings.bottom,
                onChanged: (value) {
                  _debouncedPreviewUpdate(tempSettings.copyWith(bottom: value));
                  _customSettings = tempSettings.copyWith(bottom: value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 单个边框宽度控制 - 新设计
  Widget _buildEdgeControlNew({
    required String label,
    required IconData icon,
    required double value,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey.shade200,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                            elevation: 2,
                          ),
                          overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
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
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 圆角控制 - 新设计
  Widget _buildCornerRadiusControlNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.rounded_corner, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '圆角大小',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(tempSettings.cornerRadius * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 预设圆角按钮
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCornerPresetButton(0.0, '无圆角'),
              _buildCornerPresetButton(0.03, '小'),
              _buildCornerPresetButton(0.06, '中'),
              _buildCornerPresetButton(0.09, '大'),
              _buildCornerPresetButton(0.12, '特大'),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 滑块控制
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
            max: 0.15,
            divisions: 15,
            onChanged: isProcessing 
                ? null 
                : (newValue) {
                    final newSettings = tempSettings.copyWith(cornerRadius: newValue);
                    
                    // 同时更新另一种模式的圆角
                    if (useUniformWidth) {
                      // 保持不变
                    } else {
                      _customSettings = _customSettings.copyWith(cornerRadius: newValue);
                    }
                    
                    _debouncedPreviewUpdate(newSettings);
                  },
          ),
        ),
      ],
    );
  }
  
  // 圆角预设按钮
  Widget _buildCornerPresetButton(double value, String label) {
    final isSelected = (tempSettings.cornerRadius * 100).round() == (value * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: isProcessing ? null : () {
          final newSettings = tempSettings.copyWith(cornerRadius: value);
          
          // 同时更新另一种模式的圆角
          if (useUniformWidth) {
            // 保持宽度不变
          } else {
            _customSettings = _customSettings.copyWith(cornerRadius: value);
          }
          
          _debouncedPreviewUpdate(newSettings);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
  
  // 添加预设模板
  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bookmarks_outlined, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              '快速预设',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 预设模板网格
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85, // 调整宽高比
          children: [
            _buildPresetItem(
              '标准',
              FrameSettings.uniform(0.08, cornerRadius: 0),
              true, // 统一边框模式
            ),
            _buildPresetItem(
              '拍立得',
              FrameSettings(top: 0.08, right: 0.08, bottom: 0.25, left: 0.08, cornerRadius: 0),
              false, // 自定义边框模式
            ),
            _buildPresetItem(
              '圆角',
              FrameSettings.uniform(0.12, cornerRadius: 0.06),
              true, // 统一边框模式
            ),
            _buildPresetItem(
              '窄边框',
              FrameSettings.uniform(0.04, cornerRadius: 0.02),
              true, // 统一边框模式
            ),
          ],
        ),
      ],
    );
  }
  
  // 单个预设模板项
  Widget _buildPresetItem(String name, FrameSettings settings, bool mode) {
    return InkWell(
      onTap: isProcessing ? null : () {
        setState(() {
          useUniformWidth = mode;
          tempSettings = settings;
          
          // 同时更新对应模式的设置
          if (mode) {
            _uniformWidth = settings.top;
          } else {
            _customSettings = settings;
          }
        });
        _updatePreview(settings);
        if (widget.onSettingsChanged != null) {
          widget.onSettingsChanged!(settings, mode);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(settings.cornerRadius * 24),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: mode
                ? Center(
                    child: Icon(
                      Icons.crop_square,
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      size: 30,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.settings_ethernet_rounded,
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      size: 22,
                    ),
                  ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 