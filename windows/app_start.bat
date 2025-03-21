@echo off
chcp 65001 > nul 2>&1
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
set "__file__=%~f0"

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
echo [1/3] Pythonディレクトリの確認
if exist python (
    echo       既存のディレクトリを使用します
) else (
    echo       新規作成します
    mkdir python >> !LOG_FILE! 2>&1
)
cd python
set "PATH=!CURRENT_DIR!\python;%PATH%"

echo [2/3] Python埋め込みパッケージの取得
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

echo [3/3] パッケージの解凍
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

cd ..

REM ============================================================================
REM Pythonコードの実行
REM ============================================================================

python -c "import sys; f=open(sys.argv[1],'r',encoding='utf-8'); lines=f.readlines(); f.close(); start=False; code=''; [code:=code+line for line in lines if start or (start:=(line.strip()=='___PYTHON_CODE___'))]; exec(code.replace('___PYTHON_CODE___',''))" "%__file__%"

exit /b

___PYTHON_CODE___
# ここからPythonコードとして実行
import os
import sys
import glob
import subprocess
import urllib.request
import time
import shutil

# 環境変数を取得
current_dir = os.environ.get('CURRENT_DIR', os.getcwd())
python_dir = os.path.join(current_dir, 'python')
repo_name = os.environ.get('REPO_NAME', '')
repo_url = os.environ.get('REPO_URL', '')
extra_packages = os.environ.get('EXTRA_PACKAGES', '')
startup_command = os.environ.get('STARTUP_COMMAND', '')
pytorch_option = os.environ.get('PYTORCH_OPTION', '1')
log_file = os.environ.get('LOG_FILE', 'setup_log.txt')

# ログファイルのパス
log_path = os.path.join(current_dir, log_file)

# 実行関数
def run_command(cmd, desc=None, check=True):
    if desc:
        print(f"       {desc}")
    
    cmd_str = ' '.join(cmd) if isinstance(cmd, list) else cmd
    with open(log_path, 'a', encoding='utf-8') as f:
        f.write(f"\n$ {cmd_str}\n")
    
    try:
        if isinstance(cmd, list):
            process = subprocess.run(
                cmd, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8'
            )
        else:
            process = subprocess.run(
                cmd,
                shell=True,
                stdout=subprocess.PIPE, 
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8'
            )
        
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(process.stdout)
        
        if check and process.returncode != 0:
            print(f"エラー: コマンド実行に失敗しました: {cmd_str}")
            print(f"詳細は {log_file} を確認してください")
            input("続行するには何かキーを押してください...")
            return False
    except Exception as e:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"コマンド実行例外: {str(e)}\n")
        print(f"エラー: コマンド実行中に例外が発生しました: {cmd_str}")
        print(f"詳細は {log_file} を確認してください")
        input("続行するには何かキーを押してください...")
        return False
    
    return True

# ステップ4: Python設定ファイルの修正
print("[4/12] Python設定ファイルの修正")
os.chdir(python_dir)
pth_files = glob.glob("python*._pth")

if pth_files:
    pth_file = pth_files[0]
    pth_modified = False
    
    with open(pth_file, 'r') as f:
        content = f.read()
    
    if "#import site" in content:
        print("       設定ファイル修正中...")
        modified_content = content.replace("#import site", "import site")
        
        with open(pth_file, 'w') as f:
            f.write(modified_content)
        
        with open(log_path, 'a', encoding='utf-8') as log:
            log.write("----- pthファイル編集開始 -----\n")
            log.write("編集前:\n")
            log.write(content)
            log.write("\n編集後:\n")
            log.write(modified_content)
            log.write("\n----- pthファイル編集終了 -----\n")
    else:
        print("       設定: 既に修正済みです")

# ステップ5: pip導入スクリプトの取得
print("[5/12] pip導入スクリプトの取得")
if os.path.exists("get-pip.py"):
    print("       スクリプト: 既にダウンロード済み")
else:
    print("       ダウンロード中...")
    try:
        urllib.request.urlretrieve("https://bootstrap.pypa.io/get-pip.py", "get-pip.py")
    except Exception as e:
        with open(log_path, 'a', encoding='utf-8') as log:
            log.write(f"get-pip.pyのダウンロードエラー: {str(e)}\n")
        print(f"エラー: get-pip.pyのダウンロードに失敗しました")
        print(f"詳細は {log_file} を確認してください")
        input("続行するには何かキーを押してください...")
        sys.exit(1)

# ステップ6: pipのインストール
print("[6/12] pipのインストール")
if os.path.exists(os.path.join("Scripts", "pip.exe")):
    print("       pip: 既にインストール済み")
else:
    print("       インストール中...")
    # 埋め込み版Pythonの場合は直接実行する必要がある
    if not run_command(["python", "get-pip.py", "--no-warn-script-location"]):
        os.chdir(current_dir)
        sys.exit(1)

# ステップ7: uvパッケージマネージャのインストール
print("[7/12] uvパッケージマネージャのインストール")
if os.path.exists(os.path.join("Scripts", "uv.exe")):
    print("       uv: 既にインストール済み")
else:
    # pipコマンドを直接実行する（モジュールとしてではなく）
    if not run_command(["python", "-m", "pip", "install", "uv", "--no-warn-script-location"], "インストール中..."):
        os.chdir(current_dir)
        sys.exit(1)

# ステップ8: Gitクライアントのインストール
if not repo_url:
    print("[8/12] Gitクライアントのインストールはスキップします")
else:
    print("[8/12] Gitクライアントのインストール")
    dulwich_path = os.path.join("Lib", "site-packages", "dulwich")
    if os.path.exists(dulwich_path):
        print("       dulwich: 既にインストール済み")
    else:
        if not run_command(["python", "-m", "uv", "pip", "install", "dulwich"], "インストール中..."):
            os.chdir(current_dir)
            sys.exit(1)

os.chdir(current_dir)

# ステップ9: PyTorchのインストール
print("[9/12] PyTorchのインストール")
if pytorch_option == "1":
    print("       PyTorch: インストールしません")
elif pytorch_option == "2":
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio"], 
                     "CPU版PyTorchをインストール中..."):
        sys.exit(1)
elif pytorch_option == "3":
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio", 
                      "--index-url", "https://download.pytorch.org/whl/cu118"], 
                     "CUDA 11.8用PyTorchをインストール中..."):
        sys.exit(1)
elif pytorch_option == "4":
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio", 
                      "--index-url", "https://download.pytorch.org/whl/cu124"], 
                     "CUDA 12.4用PyTorchをインストール中..."):
        sys.exit(1)
elif pytorch_option == "5":
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio", 
                      "--index-url", "https://download.pytorch.org/whl/cu126"], 
                     "CUDA 12.6用PyTorchをインストール中..."):
        sys.exit(1)

# ステップ10と11: リポジトリのクローンと依存パッケージのインストール
if not repo_url:
    print("[10/12] リポジトリのクローンはスキップします")
    print("[11/12] 依存パッケージのインストールはスキップします")
else:
    print("[10/12] リポジトリのクローン")
    if os.path.exists(os.path.join(current_dir, repo_name)):
        print(f"       {repo_name}: 既に存在します")
    else:
        if not run_command(["python", "-m", "dulwich", "clone", repo_url], "クローン中..."):
            sys.exit(1)

    print("[11/12] 依存パッケージのインストール")
    req_file = os.path.join(current_dir, repo_name, "requirements.txt")
    if os.path.exists(req_file):
        if not run_command(["python", "-m", "uv", "pip", "install", "-r", req_file], 
                         "requirements.txtからインストール中..."):
            sys.exit(1)
    else:
        print("       requirements.txt: 見つかりません")

# ステップ12: 追加パッケージの導入
if not extra_packages:
    print("[12/12] 追加パッケージの導入はスキップします")
else:
    print("[12/12] 追加パッケージの導入")
    packages = extra_packages.split()
    cmd = ["python", "-m", "uv", "pip", "install"] + packages
    if not run_command(cmd, "追加パッケージをインストール中..."):
        sys.exit(1)

print()
print("===================================================")
print("セットアップ完了しました")
print("===================================================")
print(f"ログファイル: {log_file}")
print()
print("===================================================")
print("アプリケーション起動")
print("===================================================")

if not repo_url:
    print(f"ディレクトリ: {os.getcwd()}")
else:
    print(f"ディレクトリ: {repo_name}")
    os.chdir(os.path.join(current_dir, repo_name))

print(f"コマンド: {startup_command}")
subprocess.run(startup_command, shell=True)

input("続行するには何かキーを押してください...")