import 'package:photofilters/photofilters.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:image/image.dart' as imageLib;
import 'dart:io';

Future<File?> ApplyFilters(BuildContext context, File _image) async {
  try {
    var image = imageLib.decodeImage(_image.readAsBytesSync());
    if (image == null) {
      throw Exception("无法解码图片");
    }
    
    // 最大宽度限制为600，保持图片质量
    image = imageLib.copyResize(image, width: 600);
    String fileName = basename(_image.path);
    
    Map? imagefile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoFilterSelector(
          title: const Text(
            "选择滤镜",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          image: image!,
          appBarColor: Theme.of(context).colorScheme.surface,
          filters: presetFiltersList,
          filename: fileName,
          loader: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text("正在处理图片...", 
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
    
    if (imagefile != null && imagefile.containsKey('image_filtered')) {
      return imagefile['image_filtered'] as File;
    } else {
      return null;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('处理图片出错: ${e.toString()}'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
    return null;
  }
}