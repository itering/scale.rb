extern crate parity_scale_codec;
use std::slice;
use parity_scale_codec::Decode;
use frame_support::Twox128;
use frame_support::Twox64Concat;
use frame_support::Identity;
use frame_support::Blake2_128Concat;
use frame_support::StorageHasher;

use libc::c_char;
use std::ffi::{CStr, CString};

fn to_u8_vec(v_pointer: *const u8, len: usize) -> Vec<u8> {
	let data_slice = unsafe {
		assert!(!v_pointer.is_null());
		slice::from_raw_parts(v_pointer, len)
	};
	data_slice.to_vec()
}

fn to_string(str_p: *const c_char) -> String {
	let s = unsafe {
		assert!(!str_p.is_null());
		CStr::from_ptr(str_p)
	};

	s.to_str().unwrap().to_string()
}

fn v8_vec_to_pointer(key: Vec<u8>) -> *const c_char {
	let key = CString::new(hex::encode(key)).unwrap();
	let result = key.as_ptr();
	std::mem::forget(key);
	result
}

fn gen_param_hash(param_pointer: *const u8, param_len: usize, param_hasher: *const c_char) -> Vec<u8> {
	let param_hasher = to_string(param_hasher);
	let param_hasher = param_hasher.as_str();
	let param = to_u8_vec(param_pointer, param_len);

	if param_hasher == "blake2_128_concat" {
		Blake2_128Concat::hash(&param).to_vec()
	} else if param_hasher == "twox64_concat" {
		Twox64Concat::hash(&param).to_vec()
	} else if param_hasher == "identity" {
		Identity::hash(&param).to_vec()
	} else {
		panic!("Not supported hasher type")
	} 
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
pub extern fn get_storage_key_for_value(
	module_name: *const c_char, 
	storage_name: *const c_char, 
) -> *const c_char {
	let module_name = to_string(module_name);
	let storage_name = to_string(storage_name);

	let storage_key = [Twox128::hash(module_name.as_bytes()), Twox128::hash(storage_name.as_bytes())].concat();
	v8_vec_to_pointer(storage_key)
}

#[no_mangle]
pub extern fn get_storage_key_for_map(
	module_name: *const c_char, 
	storage_name: *const c_char, 
	param_pointer: *const u8, param_len: usize, param_hasher: *const c_char,
) -> *const c_char {
	let module_name = to_string(module_name);
	let storage_name = to_string(storage_name);
	let mut storage_key = [Twox128::hash(module_name.as_bytes()), Twox128::hash(storage_name.as_bytes())].concat();

	let param_hash = gen_param_hash(param_pointer, param_len, param_hasher);
	storage_key.extend(param_hash);

	v8_vec_to_pointer(storage_key)
}

#[no_mangle]
pub extern fn get_storage_key_for_double_map(
	module_name: *const c_char, 
	storage_name: *const c_char, 
	param1_pointer: *const u8, param1_len: usize, param1_hasher: *const c_char,
	param2_pointer: *const u8, param2_len: usize, param2_hasher: *const c_char,
) -> *const c_char {
	let module_name = to_string(module_name);
	let storage_name = to_string(storage_name);
	let mut storage_key = [Twox128::hash(module_name.as_bytes()), Twox128::hash(storage_name.as_bytes())].concat();

	let param1_hash = gen_param_hash(param1_pointer, param1_len, param1_hasher);
	storage_key.extend(param1_hash);

	let param2_hash = gen_param_hash(param2_pointer, param2_len, param2_hasher);
	storage_key.extend(param2_hash);

	v8_vec_to_pointer(storage_key)
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
