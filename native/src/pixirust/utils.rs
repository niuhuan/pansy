use sha2::{Digest, Sha256};

///////////////////// SHA256 /////////////////////

pub fn sha256(src: String) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(src.as_bytes());
    hasher.finalize().to_vec()
}

//////////////////////////////////////////////////
