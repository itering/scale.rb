use std::slice;

#[no_mangle]
pub extern fn vector_input(v_pointer: *const u8, len: usize) -> u32 {
    println!("pointer is {:?}", v_pointer);
    let data_slice = unsafe {
        assert!(!v_pointer.is_null());
        slice::from_raw_parts(v_pointer, len)
    };
    let v = data_slice.to_vec();
    println!("vector is {:?}", v);
    1
}
