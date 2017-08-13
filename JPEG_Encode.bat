@echo off
REM これはJPEGファイルをエンコードするパッチです。 
REM フォルダ入力とファイル入力に対応しています。
REM Version 1.31
REM JPEGファイルの入力に対応（JPEGファイルを入力する場合はmozjpeg版cjpegが必須）

setlocal enabledelayedexpansion

REM ---- USER SETTING -------------------------------------
REM cjpegの位置を絶対パスで指定
set BIN_DIST=""
REM cjpegに与えるオプションを設定
REM example:
REM   -baseline or -progressive (default)
REM   -quality (0-100), -grayscale (Y only), -sample (2x2, 2x1, 1x1)
set BIN_OPTION=
REM エンコード品質をセット（1～100） 両方共0で無効
set QUALITY_LO=0
set QUALITY_UP=0
REM 出力場所を指定
set OUT_DIR=""
REM テストモード（1=有効、0=無効）
set TEST_SW=0
REM テストモード有効時の追加文字列
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

REM 数値じゃないデータが入っていた場合、0が入る処理
set /a QUALITY_UP=%QUALITY_UP%
set /a QUALITY_LO=%QUALITY_LO%

REM 数値の範囲は1から100　条件を満たしていればモード(1)に変更
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
REM 重複するファイルがあった場合は自動的にファイル名に番号を追加する。
REM 引数はフルパスのファイル名。
REM これはファイルの上書きを防止する。
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
REM ファイルが存在しているかをチェックする。
REM 引数はファイル名（フルパス）。
REM 戻り値 0=存在していない 1=存在している
:CHECKFILE
if exist "%~f1" if not exist "%~f1\" exit /b 1
exit /b 0

REM ---------------
REM ファイルの存在をとファイルサイズをチェックする。
REM 戻り値 -1 ファイルが存在しない
REM         0以上　ファイルが存在（ファイルサイズを返す）
:CHECKFILE2
if exist "%~f1\" exit /b -1
if "%~z1" == "" exit /b -1
exit /b %~z1

REM ---------------
REM 前方から"%2"分の文字を削る。
REM 出力文字列は必ず引用句で括られる。
:RUNCUT
set WORKCUT="%~f1"
set /a CUTNUM=%2+1
set WORKCUT="!WORKCUT:~%CUTNUM%!
exit /b

REM ---------------
REM 入力された文字列を絶対パスとみなして拡張子以外を取り出す。
REM 全体は引用句で括られる。
:FIND_FILEPATH
set WORKFINDF="%~dpn1"
exit /b

REM ---------------
REM 入力された文字列を絶対パスとみなしてドライブ名とパス情報を取り出す。
REM 全体は引用句で括られる。
:FIND_PATH
set WORKFINDP="%~dp1"
exit /b

REM ---------------
REM %1と%2を連結する。
REM 全体は引用句で括られる。
:CONNECT_PATH
set WORKCONNECT="%~1%~2"
exit /b

REM ---------------
REM 渡された文字列の長さをGETCNUM_RETに入れる。
REM 呼び出し元の引数は引用句""で必ず囲むこと。
REM 環境変数GETCNUM_RETは他で使用しないこと。
:GETCNUM
set GETCNUM_TEMP="%~1"
set GETCNUM_RET=0
:GETCNUM_LOOP
if %GETCNUM_TEMP% == "" exit /b
REM 下の行は意図的にこうしているので注意
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
