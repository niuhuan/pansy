use crate::init_root;

#[no_mangle]
pub unsafe extern "C" fn set_root(path: *const std::os::raw::c_char) {
    init_root(std::ffi::CStr::from_ptr(path).to_str().unwrap());
}
