ifeq ($(shell uname),Darwin)
    EXT := dylib
else
    EXT := so
endif

all: target/debug/libvector_ffi.$(EXT)

target/debug/libvector_ffi.$(EXT): src/lib.rs Cargo.toml
	cargo build

clean:
	rm -rf target
