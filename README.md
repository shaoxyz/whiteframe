# 加白相框 (WhiteFrame)

## 项目简介 | Project Introduction

**中文**：
这是一个简单而实用的Flutter应用，专为给照片添加白色边框而设计，让照片呈现出类似拍立得的复古效果。无需复杂的照片编辑软件，只需几次点击，就能为照片增添优雅的白色相框。

**English**：
This is a simple yet practical Flutter application designed to add white frames to photos, giving them a vintage Polaroid-like effect. No need for complex photo editing software - with just a few taps, you can add elegant white frames to your photos.

## 功能特点 | Features

**中文**：

- ✨ 简洁直观的用户界面
- 🖼️ 可调节白色边框宽度（0-25%）
- 🔍 长按预览原图功能
- 💾 一键保存至相册
- 🚀 优化的性能，支持高分辨率图像处理
- 📱 适配不同屏幕尺寸

**English**：

- ✨ Clean and intuitive user interface
- 🖼️ Adjustable white frame width (0-25%)
- 🔍 Long press to preview original image
- 💾 One-tap save to gallery
- 🚀 Optimized performance for high-resolution images
- 📱 Responsive design for different screen sizes

## 使用说明 | How to Use

**中文**：

1. 点击主界面选择图片
2. 点击底部工具栏中的"加白"按钮
3. 使用滑块调整白框宽度
4. 点击"完成"应用白框效果
5. 长按图片可预览原图
6. 点击"保存"将编辑后的照片保存到相册

**English**：

1. Tap the main screen to select a photo
2. Tap the "Add Frame" button in the bottom toolbar
3. Use the slider to adjust the frame width
4. Tap "Done" to apply the white frame effect
5. Long press on the image to preview the original
6. Tap "Save" to store the edited photo to your gallery

## 项目结构 | Project Structure

**中文**：

```
lib/
├── main.dart                   # 应用程序入口
├── screens/                    # 屏幕界面
│   └── home_screen.dart        # 主屏幕
├── widgets/                    # 可复用组件
│   ├── tool_button.dart        # 工具按钮组件
│   └── image_container.dart    # 图片容器组件
├── services/                   # 服务
│   └── image_service.dart      # 图片服务
├── editors/                    # 编辑器插件
│   ├── editor_base.dart        # 编辑器基类
│   └── white_frame_editor.dart # 加白边框编辑器
├── utils/                      # 工具类
│   └── toast_utils.dart        # 提示工具
└── GetImg.dart                 # 获取图片工具（兼容旧版）
```

**English**：

```
lib/
├── main.dart                   # Application entry point
├── screens/                    # Screen interfaces
│   └── home_screen.dart        # Main screen
├── widgets/                    # Reusable components
│   ├── tool_button.dart        # Tool button component
│   └── image_container.dart    # Image container component
├── services/                   # Services
│   └── image_service.dart      # Image service
├── editors/                    # Editor plugins
│   ├── editor_base.dart        # Editor base class
│   └── white_frame_editor.dart # White frame editor
├── utils/                      # Utilities
│   └── toast_utils.dart        # Toast utilities
└── GetImg.dart                 # Image getter (legacy compatibility)
```

## 技术实现 | Technical Implementation

**中文**：

- 使用Flutter开发，支持iOS和Android平台
- 使用image库进行图像处理
- 优化的内存管理，通过预览图像减少处理大图像时的延迟
- 采用响应式设计，适配不同设备尺寸
- 模块化架构，方便扩展添加新功能
- 流畅的动画和过渡效果

**English**：

- Developed with Flutter, supporting both iOS and Android platforms
- Image processing using the image library
- Optimized memory management with preview images to reduce lag when processing large images
- Responsive design for various device sizes
- Modular architecture for easy extension and adding new features
- Smooth animations and transitions

## 未来拓展 | Future Extensions

**中文**：

要添加新的图片编辑功能:
1. 创建一个实现 `ImageEditor` 接口的新类
2. 在 `lib/editors/` 目录中添加新的编辑器实现
3. 在 `HomeScreen` 的 `_editors` 列表中添加新编辑器实例

**English**：

To add new image editing features:
1. Create a new class implementing the `ImageEditor` interface
2. Add the new editor implementation in the `lib/editors/` directory
3. Add the new editor instance to the `_editors` list in `HomeScreen`

## 依赖 | Dependencies

**中文**：

- Flutter SDK: >=2.17.0
- image_picker: ^0.8.6
- image: ^3.2.0
- path_provider: ^2.0.11
- gallery_saver: ^2.3.2
- fluttertoast: ^8.1.1

**English**：

- Flutter SDK: >=2.17.0
- image_picker: ^0.8.6
- image: ^3.2.0
- path_provider: ^2.0.11
- gallery_saver: ^2.3.2
- fluttertoast: ^8.1.1

## 致谢 | Acknowledgements

**中文**：
此项目完全由Cursor编辑器和Claude AI共同完成，展示了AI辅助开发的强大能力。项目所有者提供了想法和需求，但没有亲自编写任何代码。这是AI辅助编程的一个实际应用案例。

**English**：
This project was entirely completed through the collaboration of Cursor editor and Claude AI, demonstrating the power of AI-assisted development. The project owner provided the idea and requirements without writing a single line of code. This represents a practical case of AI-assisted programming.

## 许可 | License

**中文**：
本项目采用MIT许可证。您可以自由使用、修改和分发此代码。

**English**：
This project is licensed under the MIT License. You are free to use, modify, and distribute this code.

---

*使用AI创建的应用程序，让照片编辑变得简单而优雅。*

*An AI-created application that makes photo editing simple and elegant.*
