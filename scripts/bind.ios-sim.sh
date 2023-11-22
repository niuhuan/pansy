
cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

flutter_rust_bridge_codegen \
    --rust-input native/src/api.rs \
    --dart-output lib/bridge_generated.dart \
    --c-output ios/Runner/bridge_generated.h \
    --rust-crate-dir native \
    --llvm-path $LLVM_HOME \
    --class-name Native


cargo build --manifest-path=native/Cargo.toml --features= --lib --release --target=aarch64-apple-ios-sim
cargo build --manifest-path=native/Cargo.toml --features= --lib --release --target=x86_64-apple-ios
lipo -create -output ios/Runner/libnative.a native/target/aarch64-apple-ios-sim/release/libnative.a native/target/x86_64-apple-ios/release/libnative.a
