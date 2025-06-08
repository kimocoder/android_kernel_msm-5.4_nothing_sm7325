#!/usr/bin/env bash

export ARCH=arm64
export SUBARCH=arm64
export KBUILD_OUTPUT=out
export CLANG_PATH=/media/kimocoder/0a8f4e77-590d-467f-8f46-21390a5ac67b/tc/linux-x86/clang-r547379/
export CROSS_COMPILE=$CLANG_PATH/bin/aarch64-linux-android-
export CLANG_TRIPLE=aarch64-linux-gnu-
export CC=$CLANG_PATH/bin/clang
