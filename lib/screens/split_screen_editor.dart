import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor/editors/white_frame_editor.dart';
import 'package:image_editor/editors/editor_base.dart';

class EditorResult {
  final File? image;
  final FrameSettings? settings;
  final bool? mode;
  
  EditorResult({this.image, this.settings, this.mode});
}

class SplitScreenEditor extends StatefulWidget {
  final ImageEditor editor;
  final File image;
  final File? originalImage;
  final FrameSettings? initialSettings;
  final bool initialMode;
  
  const SplitScreenEditor({
    Key? key,
    required this.editor,
    required this.image,
    this.originalImage,
    this.initialSettings,
    required this.initialMode,
  }) : super(key: key);
  
  @override
  _SplitScreenEditorState createState() => _SplitScreenEditorState();
}

class _SplitScreenEditorState extends State<SplitScreenEditor> {
  late File _currentImage;
  late File? _previewImage;
  double _splitRatio = 0.6; // 预览区域初始占比60%
  bool _isDragging = false;
  FrameSettings? _currentSettings;
  bool _currentMode = true;
  
  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
    _previewImage = null;
    
    // 确保初始设置中圆角默认为0（无）
    if (widget.initialSettings != null) {
      _currentSettings = widget.initialSettings;
    } else {
      // 如果没有初始设置，创建一个默认设置，圆角为0
      _currentSettings = FrameSettings.uniform(0.08, cornerRadius: 0.0);
    }
    
    _currentMode = widget.initialMode;
    
    // 如果有初始设置，立即生成预览
    if (_currentSettings != null && widget.editor is WhiteFrameEditor) {
      _generateInitialPreview();
    }
  }
  
  Future<void> _generateInitialPreview() async {
    if (widget.editor is WhiteFrameEditor && _currentSettings != null) {
      final whiteFrameEditor = widget.editor as WhiteFrameEditor;
      whiteFrameEditor.generatePreview(
        _currentImage, 
        _currentSettings!, 
        (previewFile) {
          if (mounted) {
            setState(() {
              _previewImage = previewFile;
            });
          }
        }
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // 当 didPop 为 true 时，Flutter 已经处理了 pop 操作
        // 不需要再次调用 Navigator.pop
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('调整白框',
            style: TextStyle(fontWeight: FontWeight.w500)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context, 
                  EditorResult(
                    image: _previewImage ?? _currentImage,
                    settings: _currentSettings,
                    mode: _currentMode,
                  )
                );
              },
              child: const Text('完成'),
            ),
          ],
        ),
        body: Column(
          children: [
            // 添加顶部工具栏 - 圆角设置
            _buildCornerRadiusToolbar(),
            
            // 预览区域
            Flexible(
              flex: (_splitRatio * 100).round(),
              child: Container(
                color: Colors.grey.shade100,
                width: double.infinity,
                child: _buildPreviewArea(),
              ),
            ),
            
            // 可拖拽的分隔条
            GestureDetector(
              onVerticalDragStart: (_) => setState(() => _isDragging = true),
              onVerticalDragEnd: (_) => setState(() => _isDragging = false),
              onVerticalDragUpdate: (details) {
                final screenHeight = MediaQuery.of(context).size.height;
                final newRatio = _splitRatio + (details.delta.dy / screenHeight);
                
                setState(() {
                  // 限制拖动范围
                  _splitRatio = newRatio.clamp(0.3, 0.8);
                });
              },
              child: Container(
                height: 20,
                width: double.infinity,
                color: _isDragging 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            
            // 编辑区域
            Flexible(
              flex: (100 - _splitRatio * 100).round(),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: _buildEditorControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewArea() {
    final imageToShow = _previewImage ?? _currentImage;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * _splitRatio * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 创建棋盘背景表示透明区域
            Positioned.fill(
              child: GridPaper(
                color: Colors.grey.withOpacity(0.2),
                divisions: 1,
                subdivisions: 1,
                interval: 20,
              ),
            ),
            
            // 图片预览
            GestureDetector(
              onLongPressStart: (_) {
                // 长按显示原图
                setState(() {
                  _showingOriginal = true;
                });
              },
              onLongPressEnd: (_) {
                // 松开返回处理后的图片
                setState(() {
                  _showingOriginal = false;
                });
              },
              child: Image.file(
                _showingOriginal && widget.originalImage != null
                    ? widget.originalImage!
                    : imageToShow,
                fit: BoxFit.contain,
              ),
            ),
            
            // 长按提示
            if (_showingOriginal)
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '原图预览',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  bool _showingOriginal = false;
  
  Widget _buildEditorControls() {
    if (widget.editor is WhiteFrameEditor) {
      return _WhiteFrameControls(
        initialSettings: _currentSettings ?? FrameSettings.uniform(0.08),
        initialMode: _currentMode,
        onSettingsChanged: (settings, mode) {
          setState(() {
            _currentSettings = settings;
            _currentMode = mode;
          });
          
          // 生成预览
          final whiteFrameEditor = widget.editor as WhiteFrameEditor;
          whiteFrameEditor.generatePreview(
            _currentImage, 
            settings, 
            (previewFile) {
              if (mounted) {
                setState(() {
                  _previewImage = previewFile;
                });
              }
            }
          );
        },
      );
    } else {
      return const Center(
        child: Text('不支持的编辑器类型'),
      );
    }
  }
  
  // 新增：圆角设置工具栏
  Widget _buildCornerRadiusToolbar() {
    // 确保圆角值可读（避免null问题）
    final cornerRadius = _currentSettings?.cornerRadius ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.rounded_corner, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            '圆角：${(cornerRadius * 100).round()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 12),
          
          // 圆角预设按钮
          _buildCornerPresetButton(0.0, '无'),
          _buildCornerPresetButton(0.03, '小'),
          _buildCornerPresetButton(0.06, '中'),
          _buildCornerPresetButton(0.09, '大'),
        ],
      ),
    );
  }
  
  // 圆角预设按钮
  Widget _buildCornerPresetButton(double value, String label) {
    final cornerRadius = _currentSettings?.cornerRadius ?? 0.0;
    final isSelected = (cornerRadius * 100).round() == (value * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          // 更新当前设置的圆角值
          if (_currentSettings != null) {
            setState(() {
              _currentSettings = _currentSettings!.copyWith(cornerRadius: value);
            });
            
            // 添加指示器显示加载状态
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            // 生成圆角预览
            final whiteFrameEditor = widget.editor as WhiteFrameEditor;
            whiteFrameEditor.generatePreview(
              _currentImage, 
              _currentSettings!, 
              (previewFile) {
                // 关闭加载指示器
                Navigator.of(context).pop();
                
                if (mounted) {
                  setState(() {
                    _previewImage = previewFile;
                  });
                }
              }
            );
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

// 白框编辑控制面板
class _WhiteFrameControls extends StatefulWidget {
  final FrameSettings initialSettings;
  final bool initialMode;
  final Function(FrameSettings, bool) onSettingsChanged;
  
  const _WhiteFrameControls({
    required this.initialSettings,
    required this.initialMode,
    required this.onSettingsChanged,
  });
  
  @override
  _WhiteFrameControlsState createState() => _WhiteFrameControlsState();
}

class _WhiteFrameControlsState extends State<_WhiteFrameControls> with SingleTickerProviderStateMixin {
  late FrameSettings _settings;
  late bool _useUniformWidth;
  late FrameSettings _customSettings;
  late double _uniformWidth;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _useUniformWidth = widget.initialMode;
    
    if (_settings.isUniform) {
      _uniformWidth = _settings.top;
      _customSettings = FrameSettings(
        top: 0.08,
        right: 0.08,
        bottom: 0.25,
        left: 0.08,
        cornerRadius: _settings.cornerRadius,
      );
    } else {
      _customSettings = _settings;
      _uniformWidth = _settings.maxWidth;
    }
    
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 模式选择器（统一/自定义边框）
          _buildModeSelector(),
          
          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 根据模式显示不同的控制器
                    if (_useUniformWidth)
                      _buildUniformWidthControl()
                    else
                      _buildCustomEdgesControl(),
                    
                    const SizedBox(height: 24),
                    
                    // 预设模板
                    _buildPresets(),
                    
                    // 底部安全区域
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
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
              onTap: () {
                setState(() {
                  _useUniformWidth = true;
                  _settings = FrameSettings.uniform(
                    _uniformWidth,
                    cornerRadius: _settings.cornerRadius
                  );
                });
                widget.onSettingsChanged(_settings, _useUniformWidth);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _useUniformWidth ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.crop_square,
                      size: 18,
                      color: _useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '统一边框',
                      style: TextStyle(
                        fontWeight: _useUniformWidth ? FontWeight.w600 : FontWeight.normal,
                        color: _useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade800,
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
              onTap: () {
                setState(() {
                  _useUniformWidth = false;
                  _settings = _customSettings.copyWith(
                    cornerRadius: _settings.cornerRadius
                  );
                });
                widget.onSettingsChanged(_settings, _useUniformWidth);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_useUniformWidth ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.settings_ethernet_rounded,
                      size: 18,
                      color: !_useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '自定义边框',
                      style: TextStyle(
                        fontWeight: !_useUniformWidth ? FontWeight.w600 : FontWeight.normal,
                        color: !_useUniformWidth ? Theme.of(context).primaryColor : Colors.grey.shade800,
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
  
  // 统一边框控制
  Widget _buildUniformWidthControl() {
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
              onPressed: _uniformWidth <= 0 ? null : () {
                final newValue = (_uniformWidth - 0.01).clamp(0.0, 1.0);
                setState(() {
                  _uniformWidth = newValue;
                  _settings = FrameSettings.uniform(
                    newValue, 
                    cornerRadius: _settings.cornerRadius
                  );
                });
                widget.onSettingsChanged(_settings, _useUniformWidth);
              },
              icon: Icon(Icons.remove_circle, 
                color: _uniformWidth <= 0 
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
                  onChanged: (newValue) {
                    setState(() {
                      _uniformWidth = newValue;
                      _settings = FrameSettings.uniform(
                        newValue, 
                        cornerRadius: _settings.cornerRadius
                      );
                    });
                    widget.onSettingsChanged(_settings, _useUniformWidth);
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: _uniformWidth >= 1.0 ? null : () {
                final newValue = (_uniformWidth + 0.01).clamp(0.0, 1.0);
                setState(() {
                  _uniformWidth = newValue;
                  _settings = FrameSettings.uniform(
                    newValue, 
                    cornerRadius: _settings.cornerRadius
                  );
                });
                widget.onSettingsChanged(_settings, _useUniformWidth);
              },
              icon: Icon(Icons.add_circle, 
                color: _uniformWidth >= 1.0 
                    ? Colors.grey.shade300 
                    : Theme.of(context).primaryColor),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
  
  // 自定义边框控制
  Widget _buildCustomEdgesControl() {
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
              _buildEdgeControl(
                label: '上边框',
                icon: Icons.border_top,
                value: _settings.top,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(top: value);
                    _customSettings = _settings;
                  });
                  widget.onSettingsChanged(_settings, _useUniformWidth);
                },
              ),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              // 中间一行显示左右边框
              IntrinsicHeight(
                child: Row(
                  children: [
                    // 左边框控制
                    Expanded(
                      child: _buildEdgeControl(
                        label: '左边框',
                        icon: Icons.border_left,
                        value: _settings.left,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(left: value);
                            _customSettings = _settings;
                          });
                          widget.onSettingsChanged(_settings, _useUniformWidth);
                        },
                      ),
                    ),
                    
                    VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                    
                    // 右边框控制
                    Expanded(
                      child: _buildEdgeControl(
                        label: '右边框',
                        icon: Icons.border_right,
                        value: _settings.right,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(right: value);
                            _customSettings = _settings;
                          });
                          widget.onSettingsChanged(_settings, _useUniformWidth);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              
              // 下边框控制
              _buildEdgeControl(
                label: '下边框',
                icon: Icons.border_bottom,
                value: _settings.bottom,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(bottom: value);
                    _customSettings = _settings;
                  });
                  widget.onSettingsChanged(_settings, _useUniformWidth);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 单个边框宽度控制
  Widget _buildEdgeControl({
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
                          onChanged: onChanged,
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
  
  // 预设模板
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
      onTap: () {
        setState(() {
          _useUniformWidth = mode;
          // 保留当前的圆角设置而不是使用预设的圆角
          double currentCornerRadius = _settings.cornerRadius;
          _settings = settings.copyWith(cornerRadius: currentCornerRadius);
          
          // 同时更新对应模式的设置
          if (mode) {
            _uniformWidth = settings.top;
          } else {
            _customSettings = settings.copyWith(cornerRadius: currentCornerRadius);
          }
        });
        widget.onSettingsChanged(_settings, _useUniformWidth);
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
                // 正确显示预设项的圆角效果
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