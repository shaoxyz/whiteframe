import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

Future<File?> EditImg(File _image) async {
  try {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _image.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪图片',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black,
          activeControlsWidgetColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          statusBarColor: Colors.white,
          dimmedLayerColor: Colors.black.withOpacity(0.5),
          cropFrameColor: Colors.white,
          cropFrameStrokeWidth: 2,
          cropGridColor: Colors.white,
          cropGridStrokeWidth: 1,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: '裁剪图片',
          minimumAspectRatio: 1.0,
          rectX: 0.0,
          rectY: 0.0,
          rectWidth: 1.0,
          rectHeight: 1.0,
          rotateButtonsHidden: false,
          resetButtonHidden: false,
          aspectRatioPickerButtonHidden: false,
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioLockDimensionSwapEnabled: true,
          doneButtonTitle: '完成',
          cancelButtonTitle: '取消',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    } else {
      return null;
    }
  } catch (e) {
    print('裁剪图片出错: $e');
    return null;
  }
}
