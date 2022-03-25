use crate::init_root;
use jni::objects::{JClass, JString};
use jni::JNIEnv;
use std::ffi::CStr;

#[no_mangle]
pub unsafe extern "C" fn Java_niuhuan_pansy_Jni_setRoot(env: JNIEnv, _: JClass, path: JString) {
    let path = env.get_string(path).unwrap();
    let path = path.as_ptr();
    init_root(CStr::from_ptr(path).to_str().unwrap());
}
