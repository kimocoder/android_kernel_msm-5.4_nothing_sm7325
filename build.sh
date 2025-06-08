#!/bin/bash
#
# kimocoder kernel builder and packer
# 2024 - kimocoder
#

# Setup getopt
long_opts="regen,clean,homedir:,tcdir:"
getopt_cmd=$(getopt -o rch:t: --long "$long_opts" -n "$(basename "$0")" -- "$@") || {
    echo -e "\nError: Getopt failed. Check the provided options.\n"
    exit 1
}

eval set -- "$getopt_cmd"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "Usage: $(basename "$0") [options]\n"
    echo "Options:"
    echo "  -r, --regen          Regenerate the defconfig."
    echo "  -c, --clean          Clean the output folder before building."
    echo "  -h, --homedir DIR    Specify the home directory."
    echo "  -t, --tcdir DIR      Specify the toolchain directory."
    echo "  --help               Show this help message."
    exit 0
fi

# Setup HOME directory
if [ -z "$HOME_DIR" ]; then
    HOME_DIR="$HOME"
fi
echo -e "HOME directory is set to: $HOME_DIR\n"

# Setup Toolchain directory
if [ -z "$TC_DIR" ]; then
    TC_DIR="$HOME_DIR/tc"
else
    TC_DIR="/media/kimocoder/0a8f4e77-590d-467f-8f46-21390a5ac67b/tc"
fi
echo -e "Toolchain directory is set to: $TC_DIR\n"

# Check required dependencies
for cmd in make python3 git; do
    command -v $cmd >/dev/null || { echo "Error: '$cmd' is not installed."; exit 1; }
done

# Initialize paths and variables
SECONDS=0
ZIPNAME="nethunter-spacewar-$(date '+%Y%m%d-%H%M').zip"
if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
    ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi
CLANG_DIR="$TC_DIR/linux-x86/clang-r547379"
AK3_DIR="AnyKernel3"
DEFCONFIG="spacewar_defconfig"

MAKE_PARAMS="O=out ARCH=arm64 CC=clang CLANG_TRIPLE=$CLANG_DIR/bin/llvm- LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-"

#BACKPORT_DIR=$(pwd)/backports BACKPORTS_VERSION=$(cd backports; git describe --always) BACKPORTED_KERNEL_VERSION=$(make -s kernelversion) BACKPORTED_KERNEL_NAME=Linux"

#BACKPORT_DIR=$(pwd)/backports     BACKPORTS_VERSION=$(cd backports; git describe --always)     BACKPORTED_KERNEL_VERSION=$(make -s kernelversion) BACKPORTED_KERNEL_NAME=Linux

export PATH="$CLANG_DIR/bin:$PATH"

# Regenerate defconfig, if requested
if [ "$FLAG_REGEN_DEFCONFIG" = 'y' ]; then
    echo "Regenerating defconfig..."
    make $MAKE_PARAMS $DEFCONFIG savedefconfig || { echo "Failed to regenerate defconfig."; exit 1; }
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
    exit
fi

# Clean output directory, if requested
if [ "$FLAG_CLEAN_BUILD" = 'y' ]; then
    echo -e "\nCleaning output folder..."
    rm -rf out
fi

mkdir -p out
make $MAKE_PARAMS $DEFCONFIG || { echo "Failed to configure build."; exit 1; }

# Kernel compilation
echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS 2>&1 | tee build.log || {
    echo "Kernel build failed. Check 'build.log' for details.";
    exit 1;
}

make -j$(nproc --all) $MAKE_PARAMS INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install

# Validate outputs
kernel="out/arch/arm64/boot/Image"
dts_dir="out/arch/arm64/boot/dts/vendor/qcom"

if [ -f "$kernel" ] && [ -d "$dts_dir" ]; then
    echo -e "\nKernel compiled successfully! Preparing to zip...\n"
else
    echo -e "\nError: Kernel or DTB files not found. Compilation may have failed."
    exit 1
fi

# Handle AnyKernel3 repository
if [ -d "$AK3_DIR" ]; then
    echo "Using existing AnyKernel3 repository..."
    cd "$AK3_DIR"
    git reset --hard HEAD && git pull || { echo "Failed to update AnyKernel3 repository. Proceeding with the current version."; }
    cd ..
else
    echo "AnyKernel3 not found locally. Attempting to clone..."
    if ! git clone https://github.com/kimocoder/AnyKernel3 -b spacewar "$AK3_DIR"; then
        echo "Error: Failed to clone AnyKernel3 repo. Aborting..."
        exit 1
    fi
fi

# Prepare for zipping
if [ -d "AnyKernel3" ]; then
    echo "Cleaning up old AnyKernel3 build files..."
    rm -f AnyKernel3/Image AnyKernel3/dtb AnyKernel3/dtbo.img
    rm -rf AnyKernel3/modules/vendor/lib/modules/*
fi

cp $kernel AnyKernel3/Image
cat $dts_dir/*.dtb > AnyKernel3/dtb
python3 scripts/mkdtboimg.py create AnyKernel3/dtbo.img --page_size=4096 $dts_dir/*.dtbo

KERNEL_VERSION=$(make kernelversion)
MODULES_PATH="AnyKernel3/modules/vendor/lib/modules/${KERNEL_VERSION}-qgki+"
mkdir -p "$MODULES_PATH"

# Copy compiled modules
find out -name '*.ko' -exec cp {} "$MODULES_PATH/" \; || echo "No driver modules found."
cp out/lib/modules.* "$MODULES_PATH/" || echo "No module metadata found."

sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "$MODULES_PATH/modules.dep" 2>/dev/null || true
sed -i 's/.*\///g' "$MODULES_PATH/modules.load" 2>/dev/null || true

# Final cleanup and zipping
rm -rf out/arch/arm64/boot out/modules
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x "*.git*" "*README.md*" "*placeholder*"
cd ..
rm -rf AnyKernel3

# Completion message
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!"
echo "Zip created: $ZIPNAME"

