extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::{Encode, Decode};

fn decode_from_raw_parts<T: Decode + PartialEq + std::fmt::Debug>(v_pointer: *const u8, len: usize) -> T {
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    println!("vector is {:?}", v);
    <T>::decode(&mut &v[..]).unwrap()
}

#[no_mangle]
pub extern fn parse_u64(v_pointer: *const u8, len: usize, expectation: u64) {
    assert_eq!(decode_from_raw_parts::<u64>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_u8(v_pointer: *const u8, len: usize, expectation: u8) {
    assert_eq!(decode_from_raw_parts::<u8>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_bool(v_pointer: *const u8, len: usize, expectation: bool) {
    assert_eq!(decode_from_raw_parts::<bool>(v_pointer, len), expectation);
}
