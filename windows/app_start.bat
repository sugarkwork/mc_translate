@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM 設定セクション
REM ============================================================================

REM リポジトリ名、リポジトリURL
set "REPO_NAME=mc_translate"
set "REPO_URL=https://github.com/sugarkwork/mc_translate"

REM requirements.txt 以外の追加パッケージをスペース区切りで指定
set "EXTRA_PACKAGES="

REM 起動コマンド
set "STARTUP_COMMAND=python translate_mods.py"

REM Python バージョン（ 3.13.2/3.12.9/3.11.9/3.10.11 ）
set "PYTHON_VERSION=3.11.9"

REM PyTorch バージョンの指定
REM 1: インストールしない
REM 2: CPU版をインストール
REM 3: CUDA 11.8用をインストール
REM 4: CUDA 12.4用をインストール
REM 5: CUDA 12.6用をインストール
set "PYTORCH_OPTION=1"

REM ログファイル名
set "LOG_FILE=setup_log.txt"

REM ============================================================================
REM 初期化
REM ============================================================================
set "CURRENT_DIR=%CD%"
set "ORIGINAL_PATH=%PATH%"
set "PATH=!CURRENT_DIR!\python;%PATH%"

echo ログファイル: !LOG_FILE! >> !LOG_FILE!
echo 実行日時: !date! !time! >> !LOG_FILE!
echo. >> !LOG_FILE!

echo ===================================================
echo 環境セットアップ
echo ===================================================
echo Pythonバージョン: !PYTHON_VERSION!
echo.

REM ============================================================================
REM Pythonセットアップ
REM ============================================================================
echo [1/12] Pythonディレクトリの確認
if exist python (
    echo       既存のディレクトリを使用します
) else (
    echo       新規作成します
    mkdir python >> !LOG_FILE! 2>&1
)
cd python

echo [2/12] Python埋め込みパッケージの取得
set "PYTHON_ZIP=python-!PYTHON_VERSION!-embed-amd64.zip"
set "PYTHON_URL=https://www.python.org/ftp/python/!PYTHON_VERSION!/!PYTHON_ZIP!"

if exist !PYTHON_ZIP! (
    echo       パッケージ: 既にダウンロード済み
) else (
    echo       ダウンロード中...
    echo curl -L -o !PYTHON_ZIP! !PYTHON_URL! >> !LOG_FILE! 2>&1
    curl -L -o !PYTHON_ZIP! !PYTHON_URL! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: パッケージのダウンロードに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
)

echo [3/12] パッケージの解凍
if exist python.exe (
    echo       解凍: 既に完了しています
) else (
    echo       解凍中...
    echo tar -xf !PYTHON_ZIP! >> !LOG_FILE! 2>&1
    tar -xf !PYTHON_ZIP! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: 解凍に失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        cd ..
        exit /b 1
    )
)

echo [4/12] Python設定ファイルの修正
set pth_already_modified=0
for %%F in (python*._pth) do (
    set "pthfile=%%F"
    
    findstr /c:"import site" "!pthfile!" > nul
    if !errorlevel! equ 0 (
        findstr /c:"#import site" "!pthfile!" > nul
        if !errorlevel! neq 0 (
            echo       設定: 既に修正済みです
            set pth_already_modified=1
        )
    )
    
    if !pth_already_modified! equ 0 (
        echo       設定ファイル修正中...
        echo ----- pthファイル編集開始 ----- >> !LOG_FILE!
        type "!pthfile!" >> !LOG_FILE!
        echo ----- 編集前内容 ----- >> !LOG_FILE!
        
        type nul > temp_pth.txt
        for /f "tokens=*" %%L in ('type "!pthfile!"') do (
            set "line=%%L"
            if "!line!"=="#import site" (
                echo import site >> temp_pth.txt
            ) else (
                echo !line! >> temp_pth.txt
            )
        )
        
        move /y temp_pth.txt "!pthfile!" >> !LOG_FILE! 2>&1
        echo ----- 編集後内容 ----- >> !LOG_FILE!
        type "!pthfile!" >> !LOG_FILE!
    )
)

echo [5/12] pip導入スクリプトの取得
if exist get-pip.py (
    echo       スクリプト: 既にダウンロード済み
) else (
    echo       ダウンロード中...
    echo curl -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py >> !LOG_FILE! 2>&1
    curl -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: get-pip.pyのダウンロードに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        cd ..
        exit /b 1
    )
)

echo [6/12] pipのインストール
if exist Scripts\pip.exe (
    echo       pip: 既にインストール済み
) else (
    echo       インストール中...
    echo python get-pip.py >> !LOG_FILE! 2>&1
    python get-pip.py >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: pipのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        cd ..
        exit /b 1
    )
)

echo [7/12] uvパッケージマネージャのインストール
if exist Scripts\uv.exe (
    echo       uv: 既にインストール済み
) else (
    echo       インストール中...
    echo python -m pip install uv >> !LOG_FILE! 2>&1
    python -m pip install uv >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: uvのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        cd ..
        exit /b 1
    )
)

if not defined REPO_URL (
    echo [8/12] Gitクライアントのインストールはスキップします
) else (
    echo [8/12] Gitクライアントのインストール
    if exist Scripts\dulwich.exe (
        echo       dulwich: 既にインストール済み
    ) else (
        echo       インストール中...
        echo python -m uv pip install dulwich >> !LOG_FILE! 2>&1
        python -m uv pip install dulwich >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo エラー: dulwichのインストールに失敗しました
            echo 詳細は !LOG_FILE! を確認してください
            pause
            cd ..
            exit /b 1
        )
    )
)

cd ..

echo [9/12] PyTorchのインストール
if "!PYTORCH_OPTION!"=="1" (
    echo       PyTorch: インストールしません
) else if "!PYTORCH_OPTION!"=="2" (
    echo       CPU版PyTorchをインストール中...
    echo python -m uv pip install torch torchvision torchaudio >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: PyTorchのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="3" (
    echo       CUDA 11.8用PyTorchをインストール中...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: PyTorchのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="4" (
    echo       CUDA 12.4用PyTorchをインストール中...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: PyTorchのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="5" (
    echo       CUDA 12.6用PyTorchをインストール中...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: PyTorchのインストールに失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
)

if "!REPO_URL!" == "" (
    echo [10/12] リポジトリのクローンはスキップします
    echo [11/12] 依存パッケージのインストールはスキップします
) else (
    echo [10/12] リポジトリのクローン
    if exist "!REPO_NAME!" (
        echo       !REPO_NAME!: 既に存在します
    ) else (
        echo       クローン中...
        echo python -m dulwich clone !REPO_URL! >> !LOG_FILE! 2>&1
        python -m dulwich clone !REPO_URL! >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo エラー: リポジトリのクローンに失敗しました
            echo 詳細は !LOG_FILE! を確認してください
            pause
            exit /b 1
        )
    )

    echo [11/12] 依存パッケージのインストール
    if exist "!REPO_NAME!\requirements.txt" (
        echo       requirements.txtからインストール中...
        echo python -m uv pip install -U -r !REPO_NAME!\requirements.txt >> !LOG_FILE! 2>&1
        python -m uv pip install -U -r !REPO_NAME!\requirements.txt >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo エラー: パッケージのインストールに失敗しました
            echo 詳細は !LOG_FILE! を確認してください
            pause
            exit /b 1
        )
    ) else (
        echo       requirements.txt: 見つかりません
    )

)

if "!EXTRA_PACKAGES!" == "" (
    echo [12/12] 追加パッケージの導入はスキップします
) else (
    echo [12/12] 追加パッケージの導入
    echo python -m uv pip install !EXTRA_PACKAGES! >> !LOG_FILE! 2>&1
    python -m uv pip install !EXTRA_PACKAGES! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo エラー: 追加パッケージの導入に失敗しました
        echo 詳細は !LOG_FILE! を確認してください
        pause
        exit /b 1
    )
)

echo.
echo ===================================================
echo セットアップ完了しました
echo ===================================================
echo ログファイル: !LOG_FILE!
echo.
echo ===================================================
echo アプリケーション起動
echo ===================================================

if "!REPO_URL!" == "" (
    echo ディレクトリ: !CD!
) else (
    echo ディレクトリ: !REPO_NAME!
    cd !REPO_NAME!
)

echo コマンド: !STARTUP_COMMAND!
!STARTUP_COMMAND!

pause
