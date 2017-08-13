@echo off
REM �����JPEG�t�@�C�����G���R�[�h����p�b�`�ł��B 
REM �t�H���_���͂ƃt�@�C�����͂ɑΉ����Ă��܂��B
REM Version 1.31
REM JPEG�t�@�C���̓��͂ɑΉ��iJPEG�t�@�C������͂���ꍇ��mozjpeg��cjpeg���K�{�j

setlocal enabledelayedexpansion

REM ---- USER SETTING -------------------------------------
REM cjpeg�̈ʒu���΃p�X�Ŏw��
set BIN_DIST=""
REM cjpeg�ɗ^����I�v�V������ݒ�
REM example:
REM   -baseline or -progressive (default)
REM   -quality (0-100), -grayscale (Y only), -sample (2x2, 2x1, 1x1)
set BIN_OPTION=
REM �G���R�[�h�i�����Z�b�g�i1�`100�j ������0�Ŗ���
set QUALITY_LO=0
set QUALITY_UP=0
REM �o�͏ꏊ���w��
set OUT_DIR=""
REM �e�X�g���[�h�i1=�L���A0=�����j
set TEST_SW=0
REM �e�X�g���[�h�L�����̒ǉ�������
set TEST_NAME=mozjpeg

REM --- BATCH SETTING -------------------------------------
set FLAG=FALSE
set IFILE=0
set OPFILE=0
set OLFILE=0
set QA_MODE=0

if %TEST_SW% == 1 (
  set TEST_NAME=" [%TEST_NAME% %BIN_OPTION%]"
) else (
  set TEST_NAME=""
)

echo %TEST_NAME%

REM ���l����Ȃ��f�[�^�������Ă����ꍇ�A0�����鏈��
set /a QUALITY_UP=%QUALITY_UP%
set /a QUALITY_LO=%QUALITY_LO%

REM ���l�͈̔͂�1����100�@�����𖞂����Ă���΃��[�h(1)�ɕύX
if %QUALITY_UP% LSS 0 goto QA_CHECK_ERROR
if %QUALITY_LO% LSS 0 goto QA_CHECK_ERROR
if %QUALITY_UP% GTR 100 goto QA_CHECK_ERROR
if %QUALITY_LO% GTR 100 goto QA_CHECK_ERROR
if %QUALITY_LO% == 0 (
  if %QUALITY_UP% == 0 (
    set QA_MODE=0
  )
) else (
  if %QUALITY_LO% LSS %QUALITY_UP% (
   echo Encode Quality %QUALITY_LO% - %QUALITY_UP%
   set QA_MODE=1
  ) else goto QA_CHECK_ERROR
)
echo. 
mkdir %OUT_DIR% 2> nul
for %%B in (%OUT_DIR%) do (
  echo OUTPUT-DIR "%%~fB"
  set OUT_DIR="%%~fB\"
)
if not exist %OUT_DIR% (
 goto OD_CHECK_ERROR
)

goto MAINSTART

:OD_CHECK_ERROR
echo Detect error.
echo   Illegal output directory.
goto FINAL

:QA_CHECK_ERROR
echo Detect error.
echo    Illegal quality setting.
goto FINAL

REM --- Main ----------------------------------------------
:MAINSTART
if not exist "%~1" goto AFTERWORKING

if exist "%~1\" (
  call :GETCNUM "%~dp1"
  set NUM_OPLACE2= !GETCNUM_RET!
  for /R "%~1" %%A in (*.bmp *.jpg) do (
    echo ^ "%%~fA"
    set /a IFILE+=1
    call :RUNCUT "%%~dpnA" !NUM_OPLACE2!
    call :CONNECT_PATH %OUT_DIR% !WORKCUT!
    call :FIND_PATH !WORKCONNECT!
    mkdir !WORKFINDP! 2> nul
    set OUT_FILE=!WORKCONNECT!
    if %QA_MODE% == 1 (
      for /L %%B in (%QUALITY_LO%, 1, %QUALITY_UP%) do (
        set /a OPFILE+=1
        call :CONNECT_PATH !OUT_FILE! "_[q%%B]"
        call :CONNECT_PATH !WORKCONNECT! %TEST_NAME%
        call :CONNECT_PATH !WORKCONNECT! ".jpg"
        call :DECIDENAME !WORKCONNECT!
        %BIN_DIST% %BIN_OPTION% -quality %%B -outfile !DN_FILENAME! "%%~fA"
        call :CHECKFILE2 !DN_FILENAME!
        if !ERRORLEVEL! GEQ 0 set /a OLFILE+=1
      )
    ) else (
      set /a OPFILE+=1
      call :CONNECT_PATH !OUT_FILE! %TEST_NAME%
      call :CONNECT_PATH !WORKCONNECT! ".jpg"
      call :DECIDENAME !WORKCONNECT!
      %BIN_DIST% %BIN_OPTION% -outfile !DN_FILENAME! "%%~fA"
      call :CHECKFILE2 !DN_FILENAME!
      if !ERRORLEVEL! GEQ 0 set /a OLFILE+=1
    )
  )
  goto NEXT
)

set FLAG=FALSE
if "%~x1" == ".bmp" set FLAG=TRUE
if "%~x1" == ".BMP" set FLAG=TRUE
if "%~x1" == ".jpg" set FLAG=TRUE
if "%~x1" == ".JPG" set FLAG=TRUE
if %FLAG%==FALSE goto NEXT

echo ^ "%~f1"
set /a IFILE+=1
if %QA_MODE% == 1 (
  for /L %%B in (%QUALITY_LO%, 1, %QUALITY_UP%) do (
    set /a OPFILE+=1
    call :CONNECT_PATH %OUT_DIR% "%~n1_[q%%B]"
    call :CONNECT_PATH !WORKCONNECT! %TEST_NAME%
    call :CONNECT_PATH !WORKCONNECT! ".jpg"
    call :DECIDENAME !WORKCONNECT!
    %BIN_DIST% %BIN_OPTION% -quality %%B -outfile !DN_FILENAME! "%~f1"
    call :CHECKFILE2 !DN_FILENAME!
    if !ERRORLEVEL! GEQ 0 set /a OLFILE+=1
  )
) else (
  set /a OPFILE+=1
  call :CONNECT_PATH %OUT_DIR% "%~n1"
  call :CONNECT_PATH !WORKCONNECT! %TEST_NAME%
  call :CONNECT_PATH !WORKCONNECT! ".jpg"
  call :DECIDENAME !WORKCONNECT!
  %BIN_DIST% %BIN_OPTION% -outfile !DN_FILENAME! "%~f1"
  call :CHECKFILE2 !DN_FILENAME!
  if !ERRORLEVEL! GEQ 0 set /a OLFILE+=1
)

:NEXT
SHIFT
GOTO MAINSTART

REM --- SUB ROUTINE ---------------------------------------

REM ---------------
REM �d������t�@�C�����������ꍇ�͎����I�Ƀt�@�C�����ɔԍ���ǉ�����B
REM �����̓t���p�X�̃t�@�C�����B
REM ����̓t�@�C���̏㏑����h�~����B
:DECIDENAME
set DN_NUM=0
:DECIDENAME_LOOP
if %DN_NUM% == 0 (
  set DN_FILENAME="%~f1"
) else (
  set DN_FILENAME="%~dpn1 (%DN_NUM%)%~x1"
)
call :CHECKFILE %DN_FILENAME%
if %ERRORLEVEL% == 1 (
  set /a DN_NUM+=1
  goto :DECIDENAME_LOOP
)
exit /b
:DECIDENAME_SET

REM ---------------
REM �t�@�C�������݂��Ă��邩���`�F�b�N����B
REM �����̓t�@�C�����i�t���p�X�j�B
REM �߂�l 0=���݂��Ă��Ȃ� 1=���݂��Ă���
:CHECKFILE
if exist "%~f1" if not exist "%~f1\" exit /b 1
exit /b 0

REM ---------------
REM �t�@�C���̑��݂��ƃt�@�C���T�C�Y���`�F�b�N����B
REM �߂�l -1 �t�@�C�������݂��Ȃ�
REM         0�ȏ�@�t�@�C�������݁i�t�@�C���T�C�Y��Ԃ��j
:CHECKFILE2
if exist "%~f1\" exit /b -1
if "%~z1" == "" exit /b -1
exit /b %~z1

REM ---------------
REM �O������"%2"���̕��������B
REM �o�͕�����͕K�����p��Ŋ�����B
:RUNCUT
set WORKCUT="%~f1"
set /a CUTNUM=%2+1
set WORKCUT="!WORKCUT:~%CUTNUM%!
exit /b

REM ---------------
REM ���͂��ꂽ��������΃p�X�Ƃ݂Ȃ��Ċg���q�ȊO�����o���B
REM �S�͈̂��p��Ŋ�����B
:FIND_FILEPATH
set WORKFINDF="%~dpn1"
exit /b

REM ---------------
REM ���͂��ꂽ��������΃p�X�Ƃ݂Ȃ��ăh���C�u���ƃp�X�������o���B
REM �S�͈̂��p��Ŋ�����B
:FIND_PATH
set WORKFINDP="%~dp1"
exit /b

REM ---------------
REM %1��%2��A������B
REM �S�͈̂��p��Ŋ�����B
:CONNECT_PATH
set WORKCONNECT="%~1%~2"
exit /b

REM ---------------
REM �n���ꂽ������̒�����GETCNUM_RET�ɓ����B
REM �Ăяo�����̈����͈��p��""�ŕK���͂ނ��ƁB
REM ���ϐ�GETCNUM_RET�͑��Ŏg�p���Ȃ����ƁB
:GETCNUM
set GETCNUM_TEMP="%~1"
set GETCNUM_RET=0
:GETCNUM_LOOP
if %GETCNUM_TEMP% == "" exit /b
REM ���̍s�͈Ӑ}�I�ɂ������Ă���̂Œ���
set GETCNUM_TEMP="%GETCNUM_TEMP:~2%
set /a GETCNUM_RET=GETCNUM_RET+1
goto GETCNUM_LOOP

REM --- FINISHED WORKING -------------------------------------
:AFTERWORKING
  echo.
if not %OPFILE% == %OLFILE% (
  echo Detect error.
  echo  "Output file(s): %OLFILE%(%OPFILE%)"
) else (
  if %IFILE% == 0 (
    echo Input file not found.
  ) else (
    echo "Converted number of file(s): in[%IFILE%] out[%OLFILE%]" 
    echo Complete.
  )
)
:FINAL
echo -- Hit any key --
pause > nul
