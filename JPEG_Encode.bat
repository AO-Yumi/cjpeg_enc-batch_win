@echo off
REM JPEG encode batch for cjpeg - version 1.5
REM   これはcjpegによるJPEGエンコードを簡単に扱えるようにするためのパッチです。 
REM   複数のフォルダ入力とファイル入力に対応しています。
REM   mozjpeg版cjpegを使用した場合は、JPEGファイルの再エンコードも可能です。

setlocal enabledelayedexpansion

REM ---- USER SETTING -------------------------------------
REM "cjpeg.exe"の場所を指定（引用符付加を推奨）
set BIN_DIST="cjpeg.exe"

REM "cjpeg.exe"に与えるオプションを設定（引用符無）
REM example:
REM   -baseline or -progressive (default)
REM   -quality (0-100), -grayscale (Y only), -sample (2x2, 2x1, 1x1)
set BIN_OPTION=

REM 連続エンコード用の設定
REM エンコード品質の最低値と最大値をセット（0～100の数値）
REM   QUALITY_LO(LOW)…最低値、QUALITY_HI(HIGH)…最大値
REM   両方同じ数字を指定すると無効
set QUALITY_LO=0
set QUALITY_HI=0

REM 出力パスを指定（引用符付加を推奨）
set OUT_DIR="JPEG-OUT"

REM テストモード（1=有効、0=無効）
set TEST_SW=1
REM テストモード有効時の追加文字列（引用符無）
set TEST_NAME=mozjpeg

REM --- INTERNAL SETTING ----------------------------------
set OUT_EXT=.jpg
set IN_EXT=.bmp .jpg .jpeg
set OUTWORK_MODE=1
set MIN_OUTSIZE=10

set IFILE=0
set OPFILE=0
set OLFILE=0
set QA_MODE=0

set IN_DIR=%IN_EXT:.=*.%

if %TEST_SW% == 1 (
  set TEST_NAME=" [%TEST_NAME% %BIN_OPTION%]"
  echo %TEST_NAME%
) else (
  set TEST_NAME=""
)

REM 数値ではないデータが入っていた場合、0が入る
set /a QUALITY_HI=%QUALITY_HI%
set /a QUALITY_LO=%QUALITY_LO%

REM 数値の範囲は0から100　条件を満たしていればQA_MODE(1)に変更
if %QUALITY_HI% LSS 0 goto QA_CHECK_ERROR
if %QUALITY_LO% LSS 0 goto QA_CHECK_ERROR
if %QUALITY_HI% GTR 100 goto QA_CHECK_ERROR
if %QUALITY_LO% GTR 100 goto QA_CHECK_ERROR
if %QUALITY_LO% LSS %QUALITY_HI% (
 echo Encode Quality %QUALITY_LO% - %QUALITY_HI%
 set QA_MODE=1
) else (
 if %QUALITY_HI% NEQ %QUALITY_LO% goto QA_CHECK_ERROR
)

call :SET_QUOTE_FP %OUT_DIR%
set OUT_DIR=%RET@SET_QUOTE_FP%
mkdir %OUT_DIR% 2> nul
if not exist %OUT_DIR% (
 goto OD_CHECK_ERROR
)
echo Output DIR %OUT_DIR%
call :CONNECT_PATH %OUT_DIR% "\"
set OUT_DIR=%RET@CONNECT_PATH%

%~d0
cd "%~p0"
call :SET_QUOTE_FP %BIN_DIST%
set BIN_DIST=%RET@SET_QUOTE_FP%
if not exist %BIN_DIST% goto EX_CHECK_ERROR
echo Available EXE %BIN_DIST%

echo. 
goto MAINSTART

:EX_CHECK_ERROR
echo Detect error.
echo   Illegal executable file path.
goto FINAL

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
  call :VARI_LENGTH "%~dp1"
  set NUM_OPLACE2= !ERRORLEVEL!
  for /r "%~1" %%A in (%IN_DIR%) do (
    echo In^|"%%~fA"
    set /a IFILE+=1
    call :CUTCHAR_F "%%~dpnA" !NUM_OPLACE2!
    call :CONNECT_PATH %OUT_DIR% !RET@CUTCHAR_F!
    call :SET_PATH !RET@CONNECT_PATH!
    mkdir !RET@SET_PATH! 2> nul
    set OUT_FILE=!RET@CONNECT_PATH!
    if %QA_MODE% == 1 (
      for /l %%B in (%QUALITY_LO%, 1, %QUALITY_HI%) do (
        set /a OPFILE+=1
        call :CONNECT_PATH !OUT_FILE! "_[q%%B]"
        call :CONNECT_PATH !RET@CONNECT_PATH! %TEST_NAME%
        call :CONNECT_PATH !RET@CONNECT_PATH! "%OUT_EXT%"
        call :DECIDENAME !RET@CONNECT_PATH!
        set DUP_FLAG=!ERRORLEVEL!
        call :EXE_RUN "%BIN_OPTION% -quality %%B" "%%~fA" !RET@DECIDENAME!
        call :OUTWORK !ERRORLEVEL! !RET@DECIDENAME! !DUP_FLAG!
      )
    ) else (
      set /a OPFILE+=1
      call :CONNECT_PATH !OUT_FILE! %TEST_NAME%
      call :CONNECT_PATH !RET@CONNECT_PATH! "%OUT_EXT%"
      call :DECIDENAME !RET@CONNECT_PATH!
      set DUP_FLAG=!ERRORLEVEL!
      call :EXE_RUN "%BIN_OPTION%" "%%~fA" !RET@DECIDENAME!
      call :OUTWORK !ERRORLEVEL! !RET@DECIDENAME! !DUP_FLAG!
    )
  )
  goto NEXT
)

set CHECKEXT=FALSE
for %%A in (%IN_EXT%) do (
  if /i "%~x1" == "%%A" set CHECKEXT=TRUE
)
if %CHECKEXT%==FALSE goto NEXT

echo In^|"%~f1"
set /a IFILE+=1
if %QA_MODE% == 1 (
  for /l %%B in (%QUALITY_LO%, 1, %QUALITY_HI%) do (
    set /a OPFILE+=1
    call :CONNECT_PATH %OUT_DIR% "%~n1_[q%%B]"
    call :CONNECT_PATH !RET@CONNECT_PATH! %TEST_NAME%
    call :CONNECT_PATH !RET@CONNECT_PATH! "%OUT_EXT%"
    call :DECIDENAME !RET@CONNECT_PATH!
    set DUP_FLAG=!ERRORLEVEL!
    call :EXE_RUN "%BIN_OPTION% -quality %%B" "%~f1" !RET@DECIDENAME!
    call :OUTWORK !ERRORLEVEL! !RET@DECIDENAME! !DUP_FLAG!
  )
) else (
  set /a OPFILE+=1
  call :CONNECT_PATH %OUT_DIR% "%~n1"
  call :CONNECT_PATH !RET@CONNECT_PATH! %TEST_NAME%
  call :CONNECT_PATH !RET@CONNECT_PATH! "%OUT_EXT%"
  call :DECIDENAME !RET@CONNECT_PATH!
  set DUP_FLAG=!ERRORLEVEL!
  call :EXE_RUN "%BIN_OPTION%" "%~f1" !RET@DECIDENAME!
  call :OUTWORK !ERRORLEVEL! !RET@DECIDENAME! !DUP_FLAG!
)

:NEXT
shift
goto MAINSTART

:EXE_RUN
REM 1=OPTION, 2=INPUT FILE, 3=OUTPUT FILE
REM OPTIONについては引用句で括って渡すこと。
REM 戻り値は実行ファイルの戻り値をそのまま渡す。
%BIN_DIST% %~1 -outfile %3 %2

exit /b %ERRORLEVEL%

:OUTWORK
if %OUTWORK_MODE% == 1 (
  if %1 == 0 (
    set OUTWORK_FLAG=SUCCESS
  ) else set OUTWORK_FLAG=FAILURE
) else (
  call :CHECKFILE %2
  if !ERRORLEVEL! GEQ %MIN_OUTSIZE% (
    set OUTWORK_FLAG=SUCCESS
  ) else set OUTWORK_FLAG=FAILURE
)
if %OUTWORK_FLAG% == SUCCESS (
  set /a OLFILE+=1
  echo   ^|Out %2
  if %3 neq 0 echo     [Warning] Renamed filename.
) else if %OUTWORK_FLAG% == FAILURE (
  echo   ^|Err %2
) else echo   ^|?   %2
exit /b

REM --- COMMON SUB ROUTINE ---------------------------------------

REM ---------------
REM 重複するファイルがあった場合は自動的にファイル名に番号を追加する。
REM 引数はフルパスのファイル名。
REM これはファイルの上書きを防止する。
:DECIDENAME
set TEMP_DECIDENAME=0
:DECIDENAME_LOOP
if %TEMP_DECIDENAME% == 0 (
  set RET@DECIDENAME="%~f1"
) else (
  set RET@DECIDENAME="%~dpn1 (%TEMP_DECIDENAME%)%~x1"
)
call :CHECKFILE %RET@DECIDENAME%
if %ERRORLEVEL% GEQ 0 (
  set /a TEMP_DECIDENAME+=1
  goto DECIDENAME_LOOP
)
exit /b %TEMP_DECIDENAME%

REM ---------------
REM ファイルの存在とファイルサイズをチェックする。
REM 戻り値 -1      ファイルが存在しない
REM         0以上　ファイルが存在（ファイルサイズをExitコードで返す）
:CHECKFILE
if exist "%~f1\" exit /b -1
if not exist "%~f1" exit /b -1
exit /b %~z1

REM ---------------
REM 前方から"%2"分の文字を削る。
REM 出力文字列は必ず引用符(")で括られる。
:CUTCHAR_F
set RET@CUTCHAR_F="%~f1"
set /a TEMP_CUTCHAR_F=%2+1
set RET@CUTCHAR_F="!RET@CUTCHAR_F:~%TEMP_CUTCHAR_F%!
exit /b

REM ---------------
REM 入力された文字列に対して引用符(")を設定する。
:SET_QUOTE
set RET@SET_QUOTE="%~1"
exit /b

REM ---------------
REM 入力された文字列をファイルパスと見なし、
REM 完全修飾パス名に展開して引用符(")を設定する。
:SET_QUOTE_FP
set RET@SET_QUOTE_FP="%~f1"
exit /b

REM ---------------
REM 入力された文字列に対して引用符(")を削除する。
:SET_QUOTE
set RET@SET_QUOTE=%~1
exit /b

REM ---------------
REM 入力された文字列を絶対パスとみなして拡張子以外を取り出す。
REM 全体は引用符(")で括られる。
:SET_FILEWEXT
set RET@SET_FILEWEXT="%~dpn1"
exit /b

REM ---------------
REM 入力された文字列を絶対パスとみなしてドライブ名とパス情報を取り出す。
REM 全体は引用符(")で括られる。
:SET_PATH
set RET@SET_PATH="%~dp1"
exit /b

REM ---------------
REM %1と%2を連結する。
REM 全体は引用符(")で括られる。
:CONNECT_PATH
set RET@CONNECT_PATH="%~1%~2"
exit /b

REM ---------------
REM 渡された文字列の長さをExitコードで返す。
REM 全体を括る引用符(")は常に存在するものとして文字数を計算する。
:VARI_LENGTH
set TEMP_VARI_LENGTH="%~1"
set TEMP_VARI_LENGTH_RET=0
:VARI_LENGTH_LOOP
if %TEMP_VARI_LENGTH% == "" exit /b %TEMP_VARI_LENGTH_RET%
REM 下の行は意図的にこうしているので注意
set TEMP_VARI_LENGTH="%TEMP_VARI_LENGTH:~2%
set /a TEMP_VARI_LENGTH_RET=TEMP_VARI_LENGTH_RET+1
goto VARI_LENGTH_LOOP

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
