extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::{Encode, Decode};

fn byte_string_literal_internal<T: Decode + PartialEq + std::fmt::Debug>(v_pointer: *const u8, len: usize) -> T {
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    println!("vector is {:?}", v);
    v.using_encoded(|ref slice| {
        println!("encoded slice: {:?}", slice);
    });
    <T>::decode(&mut &v[..]).unwrap()
}

#[no_mangle]
pub extern fn byte_string_literal_parse_u64(v_pointer: *const u8, len: usize, expectation: u64) -> bool {
    assert_eq!(byte_string_literal_internal::<u64>(v_pointer, len), expectation);
    true
}

#[no_mangle]
pub extern fn byte_string_literal_parse_u8(v_pointer: *const u8, len: usize, expectation: u8) -> bool {
    assert_eq!(byte_string_literal_internal::<u8>(v_pointer, len), expectation);
    true
}
