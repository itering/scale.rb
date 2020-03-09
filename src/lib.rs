extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::{Decode};

fn decode_from_raw_parts<T: Decode + PartialEq + std::fmt::Debug>(v_pointer: *const u8, len: usize) -> T {
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    <T>::decode(&mut &v[..]).unwrap()
}

#[no_mangle]
pub extern fn parse_u64(v_pointer: *const u8, len: usize, expectation: u64) {
    assert_eq!(decode_from_raw_parts::<u64>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_u32(v_pointer: *const u8, len: usize, expectation: u32) {
    assert_eq!(decode_from_raw_parts::<u32>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_u8(v_pointer: *const u8, len: usize, expectation: u8) {
    assert_eq!(decode_from_raw_parts::<u8>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_bool(v_pointer: *const u8, len: usize, expectation: bool) {
    assert_eq!(decode_from_raw_parts::<bool>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn parse_opt_u32(v_pointer: *const u8, len: usize, inner_value: u32, option: bool) {
    let expectation = match option {
        true => Some(inner_value),
        false => None,
    };
    assert_eq!(decode_from_raw_parts::<Option<u32>>(v_pointer, len), expectation);
}

#[test]
fn opt_bool_is_broken()
{
    // does not conform to boolean specification in https://substrate.dev/docs/en/conceptual/core/codec#options
    let v = vec![1, 1];
    assert_eq!(<Option<bool>>::decode(&mut &v[..]).unwrap(), Some(true));

    //this does
    let v = vec![0];
    assert_eq!(<Option<bool>>::decode(&mut &v[..]).unwrap(), None);

    //this does not
    let v = vec![0, 0, 0, 0];
    assert_eq!(<Option<bool>>::decode(&mut &v[..]).unwrap(), None);

    //this does not
    let v = vec![1];
    assert!(<Option<bool>>::decode(&mut &v[..]).is_err());

    //this does not
    let v = vec![2];
    assert!(<Option<bool>>::decode(&mut &v[..]).is_err())
}
