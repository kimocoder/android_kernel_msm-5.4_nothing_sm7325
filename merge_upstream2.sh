#!/usr/bin/env bash
set -e

TAG="$1"

if [[ -z "$TAG" ]]; then
    echo "Usage: $0 <tag-or-branch>"
    exit 1
fi

echo "[*] Syncing techpacks using tag: $TAG"

sync_subtree() {
    local path="$1"
    local remote="$2"
    local url="$3"

    if ! git remote | grep -q "^$remote$"; then
        echo "[+] Adding remote '$remote' -> $url"
        git remote add "$remote" "$url"
    fi

    if [ ! -d "$path" ]; then
        echo "[+] First-time setup: git subtree add for $path"
        git subtree add --prefix="$path" "$remote" "$TAG" --squash
    else
        echo "[+] Updating subtree: $path"
        git subtree pull --prefix="$path" "$remote" "$TAG" --squash
    fi
}

# === Techpack ===
sync_subtree techpack/audio audio https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/audio-kernel.git
sync_subtree techpack/dataipa dataipa https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/dataipa/drivers.git
sync_subtree techpack/datarmnet datarmnet https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/datarmnet.git
sync_subtree techpack/datarmnet-ext datarmnet-ext https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/datarmnet-ext.git
sync_subtree techpack/display display https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/display-drivers.git
sync_subtree techpack/video video https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/video-driver.git

# === WLAN ===
sync_subtree drivers/staging/fw-api fw-api https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/fw-api.git
sync_subtree drivers/staging/qca-wifi-host-cmn qca-wifi-host-cmn https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn.git
sync_subtree drivers/staging/qcacld-3.0 qcacld-3.0 https://git.codelinaro.org/clo/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0.git

echo "[✔] All techpacks and Wi-Fi sources merged successfully."
