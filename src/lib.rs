use std::slice;

#[no_mangle]
pub extern fn vector_input(v_pointer: *const i32, len: usize) -> i32 {
    println!("{:?}", v_pointer);
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    println!("{:?}", v);
    1
}
