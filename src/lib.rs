extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::{Encode, Decode};
use frame_support::Twox128;
use frame_support::Blake2_128Concat;
use frame_support::StorageHasher;

fn to_u8_vec(v_pointer: *const u8, len: usize) -> Vec<u8> {
	let data_slice = unsafe {
		assert!(!v_pointer.is_null());
		slice::from_raw_parts(v_pointer, len)
	};
	data_slice.to_vec()
}

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

#[no_mangle]
pub extern fn parse_opt_bool(v_pointer: *const u8, len: usize, inner_value: bool, option: bool) {
    let expectation = match option {
        true => Some(inner_value),
        false => None,
    };
    assert_eq!(decode_from_raw_parts::<Option<bool>>(v_pointer, len), expectation);
}

#[no_mangle]
pub extern fn assert_storage_key_for_value(
	mv_pointer: *const u8, mv_len: usize, 
	sv_pointer: *const u8, sv_len: usize, 
	ev_pointer: *const u8, ev_len: usize
) {
	let m = to_u8_vec(mv_pointer, mv_len);
	let s = to_u8_vec(sv_pointer, sv_len);
	let e = to_u8_vec(ev_pointer, ev_len);

	let k = [Twox128::hash(&m), Twox128::hash(&s)].concat();
	assert_eq!(k, e);
}

#[no_mangle]
pub extern fn assert_storage_key_for_map_black2128concat(
	mv_pointer: *const u8, mv_len: usize, 
	sv_pointer: *const u8, sv_len: usize, 
	pv_pointer: *const u8, pv_len: usize, 
	ev_pointer: *const u8, ev_len: usize,
) {
	let m = to_u8_vec(mv_pointer, mv_len);
	let s = to_u8_vec(sv_pointer, sv_len);
	let p = to_u8_vec(pv_pointer, pv_len);
	let e = to_u8_vec(ev_pointer, ev_len);
	let mut k = [Twox128::hash(&m), Twox128::hash(&s)].concat();
	k.extend(p.using_encoded(Blake2_128Concat::hash));
	assert_eq!(k, e);
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
