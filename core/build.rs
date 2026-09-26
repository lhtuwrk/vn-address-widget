use std::env;
use std::path::PathBuf;

/// Generates `include/vnaddr.h` from the crate's `#[no_mangle] extern "C"` surface
/// (ADR 0002 §9). Consumed by Dart FFI, the Android JNI shim, and Swift/Xcode.
fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let out_path = PathBuf::from(&crate_dir).join("include").join("vnaddr.h");

    let config = cbindgen::Config {
        language: cbindgen::Language::C,
        ..Default::default()
    };

    match cbindgen::Builder::new()
        .with_crate(&crate_dir)
        .with_config(config)
        .generate()
    {
        Ok(bindings) => {
            bindings.write_to_file(&out_path);
        }
        Err(e) => {
            // Don't fail the build over header generation (e.g. during early scaffolding
            // before the FFI surface is stable) — but make it loud.
            println!("cargo:warning=cbindgen failed to generate {out_path:?}: {e}");
        }
    }

    println!("cargo:rerun-if-changed=src/lib.rs");
}
