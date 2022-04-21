
cd "$( cd "$( dirname "$0"  )" && pwd  )/.."


touch native/src/bridge_generated.rs
flutter_rust_bridge_codegen --rust-input native/src/api.rs --dart-output lib/bridge_generated.dart

cd native

cargo ndk -o ../android/app/src/main/jniLibs -t arm64-v8a build
