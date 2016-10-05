#!/bin/sh

set -eu
unset TOP TOOLCHAIN WORK

TOOLCHAIN='nightly-2016-09-09'

export WORK="$(cd $(dirname "$0"); pwd)"
cd "${WORK}"

mkdir install-llvm-root
mkdir install-rust-root

# make llvm patch
git clone 'https://github.com/avr-llvm/llvm' avr-llvm
cd avr-llvm
## see also: https://github.com/avr-llvm/llvm/tree/avr-support
git diff 55ea065c2eab83335d33478009d547f4563465e8 06faf0a7730b63ce1ebab9a0b10ae027cf9d34fa > "${WORK}/avr-llvm.patch"
## see also: https://github.com/avr-llvm/llvm/tree/avr-rust-support
git diff 2860030806d0fb22831192835e2e257622d73575 3a536427566bde011ad685fe18fbe7c5dd78aca5 > "${WORK}/rustavr-llvm.patch"
cd "${WORK}"

# make rust patch
git clone 'https://github.com/avr-rust/rust' avr-rust
cd avr-rust
## see also: https://github.com/avr-rust/rust/tree/avr-support
git diff 5b09f2a1a61ba09fa4d027bc58249e29a7fde78d 897f485ea55284549653294854acdff39e7e19d2 > "${WORK}/avr-rust.patch"
cd "${WORK}"

# make compiler-rt patch
git clone 'https://github.com/avr-llvm/compiler-rt' avr-compiler-rt
cd avr-compiler-rt
## see also: https://github.com/avr-llvm/compiler-rt/tree/avr-support
git diff c30637134ec5d2286d80950d727db06049318e47 5c0a82cf456393fd51c2b615a014c6a509425f8d > "${WORK}/avr-compiler-rt.patch"
cd "${WORK}"

# clone rust
git clone 'https://github.com/rust-lang/rust' rust
cd rust
## checkout nightly-2016-09-09
git checkout 378195665cc365720c784752877d5b1242c38ed8
cd "${WORK}"

# edit patch
ed --quiet --verbose < "avr-llvm-patch-patch.ed"
ed --quiet --verbose < "rustavr-llvm-patch-patch.ed"
ed --quiet --verbose < "avr-rust-patch-patch.ed"
ed --quiet --verbose < "avr-compiler-rt-patch-patch.ed"

# build avr-rust

## patching
cd rust
git submodule init
git submodule update
git apply "${WORK}/avr-rust.patch"
cd src/compiler-rt
git apply "${WORK}/avr-compiler-rt.patch"
cd ../llvm
git apply "${WORK}/avr-llvm.patch"
git apply "${WORK}/rustavr-llvm.patch"

## build llvm
mkdir -p debug/build && cd debug/build
cmake ../../ \
    -DLLVM_TARGETS_TO_BUILD="X86;AVR" \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DWITH_POLLY=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INSTALL_UTILS=ON \
    -DCMAKE_C_COMPILER:FILEPATH='/usr/bin/clang' \
    -DCMAKE_CXX_COMPILER:FILEPATH='/usr/bin/clang++' \
    -DCMAKE_C_FLAGS='  -ffunction-sections -fdata-sections -DNDEBUG -m64 -fPIC -stdlib=libc++' \
    -DCMAKE_CXX_FLAGS='-ffunction-sections -fdata-sections -DNDEBUG -m64 -fPIC -stdlib=libc++' \
    -DCMAKE_INSTALL_PREFIX="${WORK}/install-llvm-root/"
cmake --build . -- -j2
cmake --build . --target install
cd ../../../../

## build rust
mkdir -p debug
cd debug
../configure \
    --disable-docs \
    --disable-jemalloc \
    --llvm-root="${WORK}/install-llvm-root/" \
    --prefix="${WORK}/install-rust-root/" \
    --enable-debug-assertions \
    --enable-debug \
    --enable-rustbuild
make -j2 rustc-stage1
cp -r ./build/*/stage1/* "${WORK}/install-rust-root/"

echo; echo; echo
echo 'build done.'
echo 'install directory: '"${WORK}/install-rust-root/"
echo
echo 'optional:'
echo '$ rustup toochain link avr-atmel-none /path/to/install-rust-root'
echo '$ cp /other/path/to/rust-nightly/bin/cargo /path/to/install-rust-root/bin/'
