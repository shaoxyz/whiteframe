import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor/editors/editor_base.dart';
import 'package:image_editor/editors/white_frame_editor.dart';
import 'package:image_editor/services/image_service.dart';
import 'package:image_editor/utils/toast_utils.dart';
import 'package:image_editor/widgets/tool_button.dart';
import 'package:image_editor/widgets/image_container.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  final List<ImageEditor> _editors = [WhiteFrameEditor()];
  
  File? _image;
  File? _originalImage;
  File? _previewImage;
  bool _selected = false;
  bool _isPreviewActive = false;
  ImageEditor? _activeEditor;
  FrameSettings? _currentFrameSettings;
  bool? _currentFrameMode;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('加白', 
                  style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (_isPreviewActive)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                _applyEdit();
              },
              tooltip: '应用',
            ),
          if (_selected)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                onPressed: () {
                  setState(() {
                    _selected = false;
                    _image = null;
                    _originalImage = null;
                    _previewImage = null;
                    _isPreviewActive = false;
                    _activeEditor = null;
                  });
                },
                tooltip: '重置',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 图片展示区
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(4),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    ImageContainer(
                      image: _image,
                      originalImage: _originalImage,
                      previewImage: _previewImage,
                      selected: _selected,
                      onImageSelected: _handleImageSelected,
                    ),
                  ],
                ),
              ),
            ),
            
            // 底部工具栏 - 始终显示
            Container(
              height: 56,
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ..._editors.map((editor) => Expanded(
                    child: ToolButton(
                      icon: editor.icon,
                      label: editor.name,
                      onTap: () => _handleEditorTap(editor),
                    ),
                  )).toList(),
                  
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  
                  Expanded(
                    child: ToolButton(
                      icon: Icons.save_alt,
                      label: '保存',
                      onTap: _handleSave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleEditorTap(ImageEditor editor) async {
    if (_image != null) {
      if (editor is WhiteFrameEditor) {
        editor.processImageWithPreview(
          _image!,
          context,
          (previewFile) {
            if (mounted) {
              setState(() {
                _previewImage = previewFile;
                _isPreviewActive = true;
              });
            }
          },
          onCanceled: () {
            if (mounted) {
              setState(() {
                _isPreviewActive = false;
                _previewImage = null;
                _currentFrameSettings = null;
                _currentFrameMode = null;
              });
            }
          },
          onComplete: (resultFile) {
            if (mounted) {
              setState(() {
                _image = resultFile;
                _isPreviewActive = false;
                _previewImage = null;
              });
            }
          },
          onSettingsSaved: (settings, mode) {
            setState(() {
              _currentFrameSettings = settings;
              _currentFrameMode = mode;
            });
          },
        );
      } else {
        setState(() {
          _activeEditor = editor;
        });
        
        File? result = await editor.processImage(_image!, context);
        if (result != null) {
          setState(() {
            _image = result;
          });
        }
      }
    } else {
      ToastUtils.showToast('请先选择图片');
    }
  }
  
  void _applyEdit() async {
    if (_previewImage != null) {
      setState(() {
        _image = _previewImage;
        _previewImage = null;
        _isPreviewActive = false;
        _activeEditor = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('加白效果已应用'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  void _handleSave() async {
    if (_image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('正在处理并保存图片...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 30),
          margin: const EdgeInsets.all(20),
        ),
      );
      
      try {
        File? finalImage;
        
        if (_originalImage != null && _currentFrameSettings != null) {
          finalImage = await _imageService.addWhiteFrameAdvanced(
            _originalImage!,
            _currentFrameSettings!,
          );
        } else {
          finalImage = _image;
        }
        
        if (finalImage != null) {
          final success = await _imageService.saveToGallery(finalImage);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
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
          } else {
            ToastUtils.showErrorToast('保存失败，请检查权限后重试');
          }
        } else {
          ToastUtils.showErrorToast('处理图片时出错');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ToastUtils.showErrorToast('保存失败: $e');
      }
    } else {
      ToastUtils.showToast('请先选择图片');
    }
  }
  
  Future<void> _handleImageSelected(File originalFile, File thumbnailFile) async {
    _originalImage = originalFile;
    
    setState(() {
      _image = thumbnailFile;
      _selected = true;
    });
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