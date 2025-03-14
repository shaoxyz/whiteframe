import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isError 
          ? Colors.red.shade600 
          : Colors.black.withValues(alpha: 204, red: 0, green: 0, blue: 0),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
  
  static void showSuccessToast(String message) {
    showToast(message, isError: false);
  }
  
  static void showErrorToast(String message) {
    showToast(message, isError: true);
  }
} 