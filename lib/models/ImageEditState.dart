import 'dart:io';
import 'package:flutter/foundation.dart';

class ImageEditOperation {
  final File image;
  final String operationName;

  ImageEditOperation({required this.image, required this.operationName});
}

class ImageEditState with ChangeNotifier {
  File? _currentImage;
  List<ImageEditOperation> _history = [];
  int _currentHistoryIndex = -1;
  
  File? get currentImage => _currentImage;
  bool get canUndo => _currentHistoryIndex > 0;
  bool get canRedo => _currentHistoryIndex < _history.length - 1;
  
  // 设置初始图片
  void setInitialImage(File image) {
    _currentImage = image;
    _history = [ImageEditOperation(image: image, operationName: '原始图片')];
    _currentHistoryIndex = 0;
    notifyListeners();
  }
  
  // 添加新的编辑操作
  void addEditOperation(File newImage, String operationName) {
    // 如果当前不是历史记录的最后一项，则删除后面的历史
    if (_currentHistoryIndex < _history.length - 1) {
      _history = _history.sublist(0, _currentHistoryIndex + 1);
    }
    
    _history.add(ImageEditOperation(image: newImage, operationName: operationName));
    _currentHistoryIndex = _history.length - 1;
    _currentImage = newImage;
    notifyListeners();
  }
  
  // 撤销操作
  void undo() {
    if (canUndo) {
      _currentHistoryIndex--;
      _currentImage = _history[_currentHistoryIndex].image;
      notifyListeners();
    }
  }
  
  // 重做操作
  void redo() {
    if (canRedo) {
      _currentHistoryIndex++;
      _currentImage = _history[_currentHistoryIndex].image;
      notifyListeners();
    }
  }
} 