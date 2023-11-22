
cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

flutter_rust_bridge_codegen \
    --rust-input native/src/api.rs \
    --dart-output lib/bridge_generated.dart \
    --c-output ios/Runner/bridge_generated.h \
    --rust-crate-dir native \
    --llvm-path $LLVM_HOME \
    --class-name Native

cd native
cargo ndk -o ../android/app/src/main/jniLibs -t arm64-v8a build --release

