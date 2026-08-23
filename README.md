# b_flutter

旧项目的 clean-room Flutter 重构版本。

## 本机开发配置

API 线路、签名和响应解密参数不写入源码。VS Code 工作区设置和 Android Studio 的 `main.dart` 运行配置均通过以下参数加载本机私有配置：

```text
--dart-define-from-file=C:/Users/Administrator/.b_flutter/dev_defines.json
```

`dart-define` 属于编译期配置，修改后必须停止应用并重新运行；仅执行 Hot Restart 不会更新配置。

VS Code 应选择运行配置 `b_flutter（本机开发配置）`。工作区设置也会为普通的 Flutter Run 自动附加相同参数。

命令行启动时使用：

```powershell
flutter run --dart-define-from-file=C:/Users/Administrator/.b_flutter/dev_defines.json
```
