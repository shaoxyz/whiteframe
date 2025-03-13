import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

Future<bool> SaveImg(File _image) async {
  bool success = false;
  
  try {
    success = await GallerySaver.saveImage(
      _image.path,
      albumName: '加白'
    ) ?? false;
    
    Fluttertoast.showToast(
      msg: success 
        ? "图片已保存到相册/加白" 
        : "保存失败，请检查权限后重试",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: success 
        ? Colors.black87 
        : Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0
    );
  } catch (e) {
    Fluttertoast.showToast(
      msg: "保存过程中出错: ${e.toString()}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }
  
  return success;
}