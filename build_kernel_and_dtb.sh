#!/usr/bin/env bash

make -j$(nproc) O=out \
  ARCH=arm64 \
  CROSS_COMPILE=$CROSS_COMPILE \
  CLANG_TRIPLE=$CLANG_TRIPLE \
  CC=$CC \
  LD=ld.lld \
  Image.gz-dtb
