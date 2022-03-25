#[cfg(target_os = "android")]
mod android;
#[cfg(not(target_os = "android"))]
mod non_android;
