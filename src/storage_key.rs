use frame_support::Twox128;
use parity_scale_codec::Encode;
use frame_support::{Identity, Blake2_128Concat, Twox64Concat};
use frame_support::StorageHasher;

pub fn to_hex_string(bytes: Vec<u8>) -> String {
	let strs: Vec<String> = bytes.iter()
		.map(|b| format!("{:02x}", b))
		.collect();
	strs.join("")
}

fn main() {
	// value
	let k = [Twox128::hash(b"Sudo"), Twox128::hash(b"Key")].concat();
	println!("{}", to_hex_string(k));

	// map
	let mut k = [Twox128::hash(b"ModuleAbc"), Twox128::hash(b"Map1")].concat();
	k.extend(vec![1u8, 0, 0, 0].using_encoded(Blake2_128Concat::hash));
	println!("{}", to_hex_string(k));

	let mut k = [Twox128::hash(b"ModuleAbc"), Twox128::hash(b"Map2")].concat();
	k.extend(1u32.using_encoded(Twox64Concat::hash));
	println!("{}", to_hex_string(k));

	let mut k = [Twox128::hash(b"ModuleAbc"), Twox128::hash(b"Map3")].concat();
	k.extend(1u32.using_encoded(Identity::hash));
	println!("{}", to_hex_string(k));

	// double map
	let mut k = [Twox128::hash(b"ModuleAbc"), Twox128::hash(b"DoubleMap1")].concat();
	k.extend(1u32.using_encoded(Blake2_128Concat::hash));
	k.extend(2u32.using_encoded(Blake2_128Concat::hash));
	println!("{}", to_hex_string(k));

	let mut k = [Twox128::hash(b"ModuleAbc"), Twox128::hash(b"DoubleMap2")].concat();
	k.extend(1u32.using_encoded(Blake2_128Concat::hash));
	k.extend(2u32.using_encoded(Twox64Concat::hash));
	println!("{}", to_hex_string(k));
}
