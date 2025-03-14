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
  bool _isEditing = false;
  ImageEditor? _activeEditor;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '调整参数' : '加白', 
                  style: TextStyle(fontWeight: FontWeight.w500)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: _isEditing ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isEditing = false;
              _previewImage = null;
              _activeEditor = null;
            });
          },
          tooltip: '取消',
        ) : null,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                _applyEdit();
              },
              tooltip: '应用',
            ),
          if (_selected && !_isEditing)
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
                    if (_isEditing && _previewImage != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('预览模式', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            if (!_isEditing)
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
      setState(() {
        _isEditing = true;
        _activeEditor = editor;
        _previewImage = null;
      });
      
      if (editor is WhiteFrameEditor) {
        editor.processImageWithPreview(
          _image!,
          context,
          (previewFile) {
            if (mounted) {
              setState(() {
                _previewImage = previewFile;
              });
            }
          },
          onComplete: null,
        );
      } else {
        File? result = await editor.processImage(_image!, context);
        if (result != null) {
          setState(() {
            _image = result;
            _isEditing = false;
            _activeEditor = null;
          });
        }
      }
    } else {
      ToastUtils.showToast('请先选择图片');
    }
  }
  
  void _applyEdit() async {
    if (_activeEditor is WhiteFrameEditor && _previewImage != null) {
      setState(() {
        _image = _previewImage;
        _previewImage = null;
        _isEditing = false;
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
      final success = await _imageService.saveToGallery(_image!);
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
      ToastUtils.showToast('请先选择图片');
    }
  }
  
  Future<void> _handleImageSelected(File file) async {
    _originalImage = file;
    
    _previewImage = await _imageService.createPreviewImage(file);
    
    setState(() {
      _image = file;
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