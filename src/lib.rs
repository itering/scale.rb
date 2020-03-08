extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::{Encode, Decode};

#[no_mangle]
pub extern fn byte_string_literal_parse(v_pointer: *const u8, len: usize) -> bool {
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    println!("vector is {:?}", v);
    v.using_encoded(|ref slice| {
        println!("encoded slice: {:?}", slice);
    });
    println!("{:?}", <u64>::decode(&mut &v[..]).unwrap());
    true
}

