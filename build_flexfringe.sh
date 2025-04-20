#!/bin/bash

# ==============================================================================
# FlexFringe 自動編譯腳本 (Ubuntu 22.04 LTS)
# ------------------------------------------------------------------------------
# 此腳本會執行以下操作：
# 1. 檢查作業系統是否為 Ubuntu 22.04 LTS。
# 2. 檢查網路連線。
# 3. 安裝必要的建構工具和依賴項 (git, build-essential, cmake)。
# 4. 從 GitHub 克隆 FlexFringe 原始碼。
# 5. 建立並進入 build 目錄。
# 6. 使用 CMake 配置建構系統。
# 7. 使用 make 進行編譯 (使用所有可用核心)。
# 8. 確認可執行檔是否成功產生。
# ==============================================================================

# 設定在任何指令失敗時立即退出腳本
set -e
# 設定在嘗試使用未設定的變數時退出腳本
set -u

echo "=============================================================================="
echo "啟動 FlexFringe 自動編譯腳本 (適用於 Ubuntu 22.04 LTS)"
echo "=============================================================================="

# --- 步驟 1: 環境檢查 ---
echo ""
echo "--- 執行環境檢查 ---"

# 1.1 檢查作業系統版本
echo "檢查作業系統版本..."
OS_ID=$(lsb_release -is)
OS_RELEASE=$(lsb_release -rs)

if [[ "$OS_ID" == "Ubuntu" && "$OS_RELEASE" == "22.04" ]]; then
    echo "✅ 作業系統確認為 Ubuntu 22.04 LTS。"
else
    echo "❌ 作業系統不是 Ubuntu 22.04 LTS。"
    echo "本腳本主要針對 Ubuntu 22.04 設計，在其他系統上可能無法正常運行。"
    echo "檢測到的系統: $OS_ID $OS_RELEASE"
    exit 1
fi

# 1.2 檢查網路連線 (簡單檢查)
echo "檢查網路連線..."
if ping -c 1 google.com &> /dev/null; then
    echo "✅ 網路連線正常。"
else
    echo "❌ 網路連線異常。請檢查您的網路設定。"
    exit 1
fi

# --- 步驟 2: 安裝必要的依賴項 ---
echo ""
echo "--- 安裝必要的建構工具和依賴項 (需要 sudo 權限) ---"

# 2.1 更新套件列表
echo "更新 apt 套件列表..."
if sudo apt update; then
    echo "✅ 套件列表更新成功。"
else
    echo "❌ 套件列表更新失敗。請檢查您的網路或 apt 設定。"
    exit 1
fi

# 2.2 安裝 git, build-essential, cmake
echo "安裝 git, build-essential, cmake..."
# build-essential 包含 g++, make 等
if sudo apt install -y git build-essential cmake; then
    echo "✅ 必要依賴項安裝成功。"
else
    echo "❌ 必要依賴項安裝失敗。請檢查錯誤訊息。"
    exit 1
fi

# # --- 步驟 3: 取得 FlexFringe 原始碼 ---
# echo ""
# echo "--- 取得 FlexFringe 原始碼 ---"

FLEXFRINGE_DIR="FlexFringe"

# # 檢查 FlexFringe 目錄是否已存在，如果存在則先刪除以確保全新開始
# if [ -d "$FLEXFRINGE_DIR" ]; then
#     echo "FlexFringe 目錄 '$FLEXFRINGE_DIR' 已存在，正在刪除舊目錄..."
#     if rm -rf "$FLEXFRINGE_DIR"; then
#         echo "✅ 舊目錄刪除成功。"
#     else
#         echo "❌ 刪除舊目錄失敗。請手動檢查並刪除 '$FLEXFRINGE_DIR'。"
#         exit 1
#     fi
# fi

# echo "正在從 GitHub 克隆 FlexFringe 原始碼..."
# if git clone https://github.com/tudelft-cda-lab/FlexFringe.git; then
#     echo "✅ 原始碼克隆成功到 '$FLEXFRINGE_DIR' 目錄。"
# else
#     echo "❌ 原始碼克隆失敗。請檢查 git 設定或網路連線。"
#     exit 1
# fi

# # 進入原始碼目錄
# cd "$FLEXFRINGE_DIR"
# echo "進入目錄: $(pwd)"

# --- 步驟 4: 編譯 FlexFringe ---
echo ""
echo "--- 編譯 FlexFringe ---"

BUILD_DIR="build"

# 建立 build 目錄
echo "建立建構目錄 '$BUILD_DIR'..."
if mkdir "$BUILD_DIR"; then
    echo "✅ 建構目錄建立成功。"
else
    echo "❌ 建構目錄建立失敗。請檢查權限或磁碟空間。"
    exit 1
fi

# 進入 build 目錄
cd "$BUILD_DIR"
echo "進入目錄: $(pwd)"

# 配置建構系統 (使用 CMake)
echo "使用 CMake 配置建構系統..."
if cmake ..; then
    echo "✅ CMake 配置成功。"
else
    echo "❌ CMake 配置失敗。請檢查錯誤訊息。"
    exit 1
fi

# 執行編譯 (使用所有可用核心)
# $(nproc) 會回傳系統的處理器核心數量
echo "使用 make 進行編譯 (使用 $(nproc) 個核心)..."
if make -j $(nproc); then
    echo "✅ 編譯成功。"
else
    echo "❌ 編譯失敗。請檢查錯誤訊息。"
    exit 1
fi

# --- 步驟 5: 確認產出並建立軟連結 ---
echo ""
echo "--- 確認產出檔案並建立軟連結 ---"

# 尋找編譯產生的 flexfringe 可執行檔 (從 build 目錄下尋找)
FLEXFRINGE_EXEC_PATH=$(command find . -maxdepth 2 -name flexfringe -type f -executable)

if [ -n "$FLEXFRINGE_EXEC_PATH" ]; then
    echo "✅ FlexFringe 可執行檔已成功產生在 build 目錄下。"

    # 獲取可執行檔的完整絕對路徑 (從 build 目錄執行 readlink -f)
    FLEXFRINGE_FULL_PATH=$(command readlink -f "$FLEXFRINGE_EXEC_PATH")

    # 計算從 FlexFringe 根目錄到執行檔的相對路徑，用於建立軟連結
    # 我們目前在 build 目錄，所以 FlexFringe 根目錄是 ..
    # realpath --relative-to=<base> <target> 計算從 <base> 到 <target> 的相對路徑
    LINK_TARGET_REL_PATH=$(command realpath --relative-to="$(command realpath ..)" "$FLEXFRINGE_FULL_PATH")

    echo "可執行檔的完整路徑: $FLEXFRINGE_FULL_PATH"
    echo "用於軟連結的目標相對路徑 (從 FlexFringe 根目錄看): $LINK_TARGET_REL_PATH"


    # --- 步驟 6: 建立到 FlexFringe 根目錄的軟連結 ---
    echo "--- 建立 FlexFringe 根目錄的軟連結 ---"

    # 切換回 FlexFringe 根目錄來建立連結
    cd ..
    echo "切換到目錄: $(pwd)"

    LINK_NAME="flexfringe"

    # 檢查 FlexFringe 根目錄是否已經存在同名檔案或連結，存在則刪除
    if [ -L "$LINK_NAME" ] || [ -f "$LINK_NAME" ]; then
        echo "在 $(pwd) 存在舊的連結或檔案 '$LINK_NAME'，正在刪除..."
        if command rm "$LINK_NAME"; then
             echo "✅ 舊的連結/檔案刪除成功。"
        else
             echo "❌ 刪除舊的連結/檔案失敗。請手動檢查權限。"
             # 這裡不 exit 1，嘗試繼續建立新的連結，但印出警告
        fi
    fi

    echo "正在建立 '$LINK_NAME' -> '$LINK_TARGET_REL_PATH' 的軟連結..."
    # 建立軟連結
    if command ln -s "$LINK_TARGET_REL_PATH" "$LINK_NAME"; then
        echo "✅ 軟連結建立成功。"
        # 驗證建立的連結
        echo "軟連結資訊: $(command ls -l "$LINK_NAME")"

        # 測試透過軟連結執行
        echo "正在測試執行建立的軟連結 ($LINK_NAME)..."
        if ./flexfringe --help &> /dev/null; then
           echo "✅ 軟連結執行測試成功。"
        else
           echo "⚠️ 軟連結執行測試失敗。請手動檢查連結和權限。"
        fi

    else
        echo "❌ 軟連結建立失敗。請手動檢查原因。"
        exit 1 # 軟連結失敗是個問題，退出腳本
    fi

else
    echo "❌ 未找到 FlexFringe 可執行檔。"
    echo "編譯過程可能沒有成功完成，請檢查上面的錯誤訊息。"
    exit 1 # 編譯失敗，退出腳本
fi

echo ""
echo "=============================================================================="
echo "FlexFringe 編譯及軟連結流程完成。"
echo "FlexFringe 執行檔完整路徑: $FLEXFRINGE_FULL_PATH"
echo "在 $(pwd) 目錄下已建立軟連結: ./flexfringe"
echo "您現在可以直接在此目錄下執行 ./flexfringe"
echo "=============================================================================="

exit 0

