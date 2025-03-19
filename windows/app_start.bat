@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM �ݒ�Z�N�V����
REM ============================================================================

REM ���|�W�g�����A���|�W�g��URL
set "REPO_NAME=mc_translate"
set "REPO_URL=https://github.com/sugarkwork/mc_translate"

REM requirements.txt �ȊO�̒ǉ��p�b�P�[�W���X�y�[�X��؂�Ŏw��
set "EXTRA_PACKAGES="

REM �N���R�}���h
set "STARTUP_COMMAND=python translate_mods.py"

REM Python �o�[�W�����i 3.13.2/3.12.9/3.11.9/3.10.11 �j
set "PYTHON_VERSION=3.11.9"

REM PyTorch �o�[�W�����̎w��
REM 1: �C���X�g�[�����Ȃ�
REM 2: CPU�ł��C���X�g�[��
REM 3: CUDA 11.8�p���C���X�g�[��
REM 4: CUDA 12.4�p���C���X�g�[��
REM 5: CUDA 12.6�p���C���X�g�[��
set "PYTORCH_OPTION=1"

REM ���O�t�@�C����
set "LOG_FILE=setup_log.txt"

REM ============================================================================
REM ������
REM ============================================================================
set "CURRENT_DIR=%CD%"
set "ORIGINAL_PATH=%PATH%"
set "PATH=!CURRENT_DIR!\python;%PATH%"

echo ���O�t�@�C��: !LOG_FILE! >> !LOG_FILE!
echo ���s����: !date! !time! >> !LOG_FILE!
echo. >> !LOG_FILE!

echo ===================================================
echo ���Z�b�g�A�b�v
echo ===================================================
echo Python�o�[�W����: !PYTHON_VERSION!
echo.

REM ============================================================================
REM Python�Z�b�g�A�b�v
REM ============================================================================
echo [1/12] Python�f�B���N�g���̊m�F
if exist python (
    echo       �����̃f�B���N�g�����g�p���܂�
) else (
    echo       �V�K�쐬���܂�
    mkdir python >> !LOG_FILE! 2>&1
)
cd python

echo [2/12] Python���ߍ��݃p�b�P�[�W�̎擾
set "PYTHON_ZIP=python-!PYTHON_VERSION!-embed-amd64.zip"
set "PYTHON_URL=https://www.python.org/ftp/python/!PYTHON_VERSION!/!PYTHON_ZIP!"

if exist !PYTHON_ZIP! (
    echo       �p�b�P�[�W: ���Ƀ_�E�����[�h�ς�
) else (
    echo       �_�E�����[�h��...
    echo curl -L -o !PYTHON_ZIP! !PYTHON_URL! >> !LOG_FILE! 2>&1
    curl -L -o !PYTHON_ZIP! !PYTHON_URL! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: �p�b�P�[�W�̃_�E�����[�h�Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
)

echo [3/12] �p�b�P�[�W�̉�
if exist python.exe (
    echo       ��: ���Ɋ������Ă��܂�
) else (
    echo       �𓀒�...
    echo tar -xf !PYTHON_ZIP! >> !LOG_FILE! 2>&1
    tar -xf !PYTHON_ZIP! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: �𓀂Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        cd ..
        exit /b 1
    )
)

echo [4/12] Python�ݒ�t�@�C���̏C��
set pth_already_modified=0
for %%F in (python*._pth) do (
    set "pthfile=%%F"
    
    findstr /c:"import site" "!pthfile!" > nul
    if !errorlevel! equ 0 (
        findstr /c:"#import site" "!pthfile!" > nul
        if !errorlevel! neq 0 (
            echo       �ݒ�: ���ɏC���ς݂ł�
            set pth_already_modified=1
        )
    )
    
    if !pth_already_modified! equ 0 (
        echo       �ݒ�t�@�C���C����...
        echo ----- pth�t�@�C���ҏW�J�n ----- >> !LOG_FILE!
        type "!pthfile!" >> !LOG_FILE!
        echo ----- �ҏW�O���e ----- >> !LOG_FILE!
        
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
        echo ----- �ҏW����e ----- >> !LOG_FILE!
        type "!pthfile!" >> !LOG_FILE!
    )
)

echo [5/12] pip�����X�N���v�g�̎擾
if exist get-pip.py (
    echo       �X�N���v�g: ���Ƀ_�E�����[�h�ς�
) else (
    echo       �_�E�����[�h��...
    echo curl -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py >> !LOG_FILE! 2>&1
    curl -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: get-pip.py�̃_�E�����[�h�Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        cd ..
        exit /b 1
    )
)

echo [6/12] pip�̃C���X�g�[��
if exist Scripts\pip.exe (
    echo       pip: ���ɃC���X�g�[���ς�
) else (
    echo       �C���X�g�[����...
    echo python get-pip.py >> !LOG_FILE! 2>&1
    python get-pip.py >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: pip�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        cd ..
        exit /b 1
    )
)

echo [7/12] uv�p�b�P�[�W�}�l�[�W���̃C���X�g�[��
if exist Scripts\uv.exe (
    echo       uv: ���ɃC���X�g�[���ς�
) else (
    echo       �C���X�g�[����...
    echo python -m pip install uv >> !LOG_FILE! 2>&1
    python -m pip install uv >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: uv�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        cd ..
        exit /b 1
    )
)

if not defined REPO_URL (
    echo [8/12] Git�N���C�A���g�̃C���X�g�[���̓X�L�b�v���܂�
) else (
    echo [8/12] Git�N���C�A���g�̃C���X�g�[��
    if exist Scripts\dulwich.exe (
        echo       dulwich: ���ɃC���X�g�[���ς�
    ) else (
        echo       �C���X�g�[����...
        echo python -m uv pip install dulwich >> !LOG_FILE! 2>&1
        python -m uv pip install dulwich >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo �G���[: dulwich�̃C���X�g�[���Ɏ��s���܂���
            echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
            pause
            cd ..
            exit /b 1
        )
    )
)

cd ..

echo [9/12] PyTorch�̃C���X�g�[��
if "!PYTORCH_OPTION!"=="1" (
    echo       PyTorch: �C���X�g�[�����܂���
) else if "!PYTORCH_OPTION!"=="2" (
    echo       CPU��PyTorch���C���X�g�[����...
    echo python -m uv pip install torch torchvision torchaudio >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: PyTorch�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="3" (
    echo       CUDA 11.8�pPyTorch���C���X�g�[����...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: PyTorch�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="4" (
    echo       CUDA 12.4�pPyTorch���C���X�g�[����...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: PyTorch�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
) else if "!PYTORCH_OPTION!"=="5" (
    echo       CUDA 12.6�pPyTorch���C���X�g�[����...
    echo python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 >> !LOG_FILE! 2>&1
    python -m uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: PyTorch�̃C���X�g�[���Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
)

if "!REPO_URL!" == "" (
    echo [10/12] ���|�W�g���̃N���[���̓X�L�b�v���܂�
    echo [11/12] �ˑ��p�b�P�[�W�̃C���X�g�[���̓X�L�b�v���܂�
) else (
    echo [10/12] ���|�W�g���̃N���[��
    if exist "!REPO_NAME!" (
        echo       !REPO_NAME!: ���ɑ��݂��܂�
    ) else (
        echo       �N���[����...
        echo python -m dulwich clone !REPO_URL! >> !LOG_FILE! 2>&1
        python -m dulwich clone !REPO_URL! >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo �G���[: ���|�W�g���̃N���[���Ɏ��s���܂���
            echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
            pause
            exit /b 1
        )
    )

    echo [11/12] �ˑ��p�b�P�[�W�̃C���X�g�[��
    if exist "!REPO_NAME!\requirements.txt" (
        echo       requirements.txt����C���X�g�[����...
        echo python -m uv pip install -U -r !REPO_NAME!\requirements.txt >> !LOG_FILE! 2>&1
        python -m uv pip install -U -r !REPO_NAME!\requirements.txt >> !LOG_FILE! 2>&1
        if !errorlevel! neq 0 (
            echo �G���[: �p�b�P�[�W�̃C���X�g�[���Ɏ��s���܂���
            echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
            pause
            exit /b 1
        )
    ) else (
        echo       requirements.txt: ������܂���
    )

)

if "!EXTRA_PACKAGES!" == "" (
    echo [12/12] �ǉ��p�b�P�[�W�̓����̓X�L�b�v���܂�
) else (
    echo [12/12] �ǉ��p�b�P�[�W�̓���
    echo python -m uv pip install !EXTRA_PACKAGES! >> !LOG_FILE! 2>&1
    python -m uv pip install !EXTRA_PACKAGES! >> !LOG_FILE! 2>&1
    if !errorlevel! neq 0 (
        echo �G���[: �ǉ��p�b�P�[�W�̓����Ɏ��s���܂���
        echo �ڍׂ� !LOG_FILE! ���m�F���Ă�������
        pause
        exit /b 1
    )
)

echo.
echo ===================================================
echo �Z�b�g�A�b�v�������܂���
echo ===================================================
echo ���O�t�@�C��: !LOG_FILE!
echo.
echo ===================================================
echo �A�v���P�[�V�����N��
echo ===================================================

if "!REPO_URL!" == "" (
    echo �f�B���N�g��: !CD!
) else (
    echo �f�B���N�g��: !REPO_NAME!
    cd !REPO_NAME!
)

echo �R�}���h: !STARTUP_COMMAND!
!STARTUP_COMMAND!

pause
