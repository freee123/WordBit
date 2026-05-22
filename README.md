# 背单词 (WordBits)

跨平台背单词应用，支持 Android / Windows，云端同步词库。

## 功能

- 录入英文单词，自动补全翻译（百度翻译）和发音（有道词典）
- 音标、词性、例句自动填充（Free Dictionary API）
- 拼写校验
- SM-2 间隔重复算法背诵
- 批量导入单词
- 云端同步（自建 Go 后端），多设备共享词库

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Flutter + Provider + sqflite |
| 后端 | Go + net/http + SQLite |
| 翻译 | 百度翻译 API + Free Dictionary API |
| 发音 | 有道词典 TTS（在线） + 系统 TTS（离线） |
| 同步 | REST API + JWT 认证 |

## 快速开始

### 前提

- Flutter SDK 3.x
- Go 1.22+
- 百度翻译 API Key（免费注册 [fanyi-api.baidu.com](https://fanyi-api.baidu.com)）

### 1. 配置百度翻译

复制 `lib/secrets.example.dart` 为 `lib/secrets.dart`，填入你的 APPID 和 KEY：

```dart
const String secrets_appId = '你的APPID';
const String secrets_key = '你的KEY';
```

`lib/secrets.dart` 已加入 `.gitignore`，不会提交到仓库。其他人克隆后按同样方式创建即可。

### 2. 运行 Flutter 前端

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android
```

### 3. 运行 Go 后端（可选，云端同步需要）

```bash
cd server
go run .
```

默认监听 `:8080`，App 设置页可配置服务器地址。

## 项目结构

```
├── lib/                    # Flutter 前端
│   ├── pages/              # 页面
│   │   ├── home_page.dart
│   │   ├── add_word_page.dart
│   │   ├── review_page.dart
│   │   ├── login_page.dart
│   │   └── ...
│   ├── widgets/            # 组件
│   ├── db_helper.dart      # 数据库
│   ├── api_client.dart     # 后端 API
│   ├── sync_service.dart   # 同步
│   ├── translation_service.dart
│   ├── tts_service.dart
│   └── models.dart
├── server/                 # Go 后端
│   ├── main.go
│   ├── auth.go
│   ├── word.go
│   └── ...
└── ARCHITECTURE.md         # 架构设计文档
```

## 构建发布

```bash
# Android APK
flutter build apk --release

# Windows EXE
flutter build windows --release
```

## 同步协议

客户端发起同步时先推后拉，所有时间戳由服务端统一覆盖，避免多端时钟偏差。

