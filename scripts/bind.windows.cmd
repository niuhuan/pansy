
cbindgen native/src/platforms/non_android.rs -l c > windows/Runner/native.h

touch native/src/bridge_generated.rs
flutter_rust_bridge_codegen --rust-input native/src/api.rs --dart-output lib/bridge_generated.dart
