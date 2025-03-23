@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================================
REM 設定セクション
REM ============================================================================

REM リポジトリ名、リポジトリURL
set "REPO_NAME=mc_translate"
set "REPO_URL=https://github.com/sugarkwork/mc_translate"

REM 自動アップデート（ 0: 無効 / 1: 有効 ）
set "AUTO_UPDATE=0"

REM requirements.txt 以外の追加パッケージをスペース区切りで指定
set "EXTRA_PACKAGES="

REM 起動コマンド
set "STARTUP_COMMAND=python main.py"

REM Python バージョン（3.10.11/3.11.9/3.12.9/3.13.2）
set "PYTHON_VERSION=3.11.9"

REM PyTorch バージョン（none/cpu/cu118/cu124/cu126）
set "PYTORCH_OPTION=none"

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
auto_update = os.environ.get('AUTO_UPDATE', '0')

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

# git class
import os
import shutil
from io import RawIOBase, BytesIO

try:
    import dulwich
except ImportError:
    import importlib
    importlib.invalidate_caches()
try:
    import dulwich
except ImportError:
    import sys
    sys.path.append(os.path.join(python_dir, 'Lib', 'site-packages'))
try:
    import dulwich
except ImportError:
    print("dulwichパッケージが見つかりません")
    sys.exit(1)


from dulwich import porcelain
from dulwich.repo import Repo
from dulwich.client import HttpGitClient
from dulwich import index


class DummyStream(RawIOBase):
    def __init__(self):
        super().__init__()
        self.stream = BytesIO()

    def close(self) -> None:
        self.stream.close()
        return None

    def read(self, size=-1) -> None:
        return None

    def readall(self) -> bytes:
        return self.stream.getvalue()

    def readinto(self, b) -> None:
        return None

    def write(self, b) -> int:
        return self.stream.write(b)


class GitManager:
    def __init__(self, repo_path:str, remote_url:str, branch:str="main"):
        self.repo_path = repo_path
        self.remote_url = remote_url if remote_url.endswith('.git') else remote_url + '.git'
        self.branch = branch
        self.repo = None
        if os.path.exists(repo_path):
            self.repo = Repo(repo_path)
    
    def _to_binary(self, text):
        if isinstance(text, str):
            return text.encode('utf-8')
        return text

    def clone(self):
        if os.path.exists(self.repo_path):
            print("Repo already exists")
            return False
        dummy = DummyStream()
        porcelain.clone(self.remote_url, target=self.repo_path, errstream=dummy)
        self.repo = Repo(self.repo_path)
        return True

    def pull(self):
        # git pull
        if not os.path.exists(self.repo_path):
            return False
        binary_branch = self._to_binary(self.branch)
        
        client = HttpGitClient(self.remote_url)
        fetch_result = client.fetch(self.remote_url, self.repo)
        self.repo.refs[b'refs/remotes/origin/' + binary_branch] = fetch_result.refs[b'refs/heads/' + binary_branch]

        head_commit = self.repo[self.repo.head()]
        index_file = self.repo.index_path()
        index.build_index_from_tree(
            self.repo.path,
            index_file,
            self.repo.object_store,
            head_commit.tree
        )
        return True
    
    def clean(self):
        # git clean -f
        if not os.path.exists(self.repo_path):
            return False
        
        status = porcelain.status(self.repo)
        for untracked in status.untracked:
            full_path = os.path.join(self.repo_path, untracked)
            if os.path.isfile(full_path):
                os.remove(full_path)
            elif os.path.isdir(full_path):
                shutil.rmtree(full_path)
        
        return True

# ステップ9: PyTorchのインストール
print("[9/12] PyTorchのインストール")
if pytorch_option == "none":
    print("       PyTorch: インストールしません")
elif pytorch_option == "cpu":
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio"], 
                     "CPU版PyTorchをインストール中..."):
        sys.exit(1)
elif pytorch_option.startswith("cu"):
    cuda_version = pytorch_option  # cu118, cu124, cu126 など
    if not run_command(["python", "-m", "uv", "pip", "install", "torch", "torchvision", "torchaudio", 
                      "--index-url", f"https://download.pytorch.org/whl/{cuda_version}"], 
                     f"CUDA {cuda_version[2:]}用PyTorchをインストール中..."):
        sys.exit(1)
else:
    print(f"       エラー: 不明なPyTorchオプション '{pytorch_option}'")
    sys.exit(1)


# ステップ10と11: リポジトリのクローンと依存パッケージのインストール
if not repo_url:
    print("[10/12] リポジトリのクローンはスキップします")
    print("[11/12] 依存パッケージのインストールはスキップします")
else:
    print("[10/12] リポジトリのクローン")
    
    git = GitManager(repo_name, repo_url)
    if os.path.exists(os.path.join(current_dir, repo_name)):
        print(f"       {repo_name}: 既に存在します")
        if auto_update == "1":
            print("       更新: 自動更新を実行します")
            if git.pull() is False:
                sys.exit(1)
        else:
            print("       更新: 自動更新は無効です")
    else:
        if git.clone() is False:
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

cwd = current_dir
if repo_url:
    cwd = os.path.join(current_dir, repo_name)

print(f"ディレクトリ: {cwd}")
os.chdir(cwd)

new_env = os.environ.copy()
ppath = new_env.get('PYTHONPATH', '')
new_env['PYTHONPATH'] = f"{cwd}:{python_dir}:{ppath}:{cwd}:."

print(f"コマンド: {startup_command}")
subprocess.run(startup_command.split(), shell=True, cwd=cwd, env=new_env)

input("続行するには何かキーを押してください...")