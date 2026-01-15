cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
