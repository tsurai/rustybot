RUSTC ?= rustc
RUSTFLAGS ?= -g -O -Z verbose
RUSTLIBFLAGS ?= --dylib --rlib

sources=\
	src/cmd.rs \
	src/bot.rs \
  src/main.rs

($build): $(sources)
	$(RUSTC) $(RUSTFLAGS) src/main.rs -o rustybot -L deps/rust-lua 

all: ($build)

clean:
	rm rustybot
	rm -rf bin/ .rust/
