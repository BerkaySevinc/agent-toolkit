@echo off
setlocal enabledelayedexpansion

rem --- ANSI colors (works on modern Windows 10/11 cmd.exe) ---
for /F "delims=#" %%E in ('"prompt #$E# & echo on & for %%B in (1) do rem"') do set "ESC=%%E"
set "C_BLUE=%ESC%[94m"
set "C_CYAN=%ESC%[96m"
set "C_GREEN=%ESC%[92m"
set "C_YELLOW=%ESC%[93m"
set "C_GRAY=%ESC%[90m"
set "C_RED=%ESC%[91m"
set "C_MAGENTA=%ESC%[95m"
set "C_WHITE=%ESC%[97m"
set "C_RESET=%ESC%[0m"

rem --- Left margin used in front of every printed line ---
set "IND=     "
set "IND2=       "

rem --- Moves the cursor up 2 lines and clears to end of screen (used to
rem     replace the [CONFLICT] question with its final result once answered) ---
set "CLR_CONFLICT=%ESC%[2A%ESC%[0J"

set "WIDTH=60"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_FILE=%~f0"
set "CLAUDE_DIR=%USERPROFILE%\.claude"

rem Result lists are kept in memory as semicolon-separated strings, no files.
set "LIST_NEW="
set "LIST_UPDATED="
set "LIST_SKIPPED="
set "LIST_UNCHANGED="
set "TOTAL_FOUND=0"
set "CANCELLED=0"

rem ======================================================================
rem Main banner (inlined - no labels, so CALL/GOTO to an internal label,
rem which is sensitive to the file's line-ending style, is never used).
rem ======================================================================
set "TEXT=agent-toolkit installer"
set "BCOLOR=%C_BLUE%"
set "LEN=0"
for /L %%i in (0,1,199) do if not "!TEXT:~%%i,1!"=="" set /a LEN=%%i+1
set /a "PAD=!WIDTH!-2-!LEN!"
if !PAD! lss 0 set "PAD=0"
set /a "LEFT=!PAD!/2"
set /a "RIGHT=!PAD!-!LEFT!"
set "LEFTSP="
for /L %%i in (1,1,!LEFT!) do set "LEFTSP=!LEFTSP! "
set "RIGHTSP="
for /L %%i in (1,1,!RIGHT!) do set "RIGHTSP=!RIGHTSP! "
set "LINE="
for /L %%i in (1,1,!WIDTH!) do set "LINE=!LINE!="
set /a "FULLPAD=!WIDTH!-2"
set "BLANKSP="
for /L %%i in (1,1,!FULLPAD!) do set "BLANKSP=!BLANKSP! "
echo(
echo(
echo %IND%!BCOLOR!!LINE!%C_RESET%
echo %IND%!BCOLOR!=!BLANKSP!=%C_RESET%
echo %IND%!BCOLOR!=!LEFTSP!!TEXT!!RIGHTSP!=%C_RESET%
echo %IND%!BCOLOR!=!BLANKSP!=%C_RESET%
echo %IND%!BCOLOR!!LINE!%C_RESET%
echo(

if not exist "%CLAUDE_DIR%" (
    echo(
    echo %IND%%C_RED%[WARN]%C_RESET%  %CLAUDE_DIR% does not exist yet.
    choice /c YN /n /m "%C_RESET%%IND%Create it now? (Y = create / N = cancel): "
    if errorlevel 2 (
        echo(
        echo %IND%%C_RED%Cancelled. Nothing was changed.%C_RESET%
        set "CANCELLED=1"
    ) else (
        mkdir "%CLAUDE_DIR%"
        echo %IND%%C_GREEN%Created %CLAUDE_DIR%%C_RESET%
    )
)

if "!CANCELLED!"=="0" (
    echo(
    echo %IND%%C_YELLOW%Installing agent-toolkit into %CLAUDE_DIR%...%C_RESET%
    echo(
    echo(
)

rem ======================================================================
rem Mirror every file ("is_dotted", "is_meta_file" and "resolve_file" all
rem inlined). Destination folders are created lazily, right before the
rem first file that actually needs them, so a folder with no installable
rem files in it is never created and never falsely implies a change.
rem ======================================================================
if "!CANCELLED!"=="0" (
    for /R "%SCRIPT_DIR%" %%F in (*) do (
        set "FULLFILE=%%F"
        if /I not "!FULLFILE!"=="%SCRIPT_FILE%" (
            set "REL=!FULLFILE!"
            set "REL=!REL:%SCRIPT_DIR%=!"
            set "SKIP=0"
            if "!REL:~0,1!"=="." set "SKIP=1"
            echo !REL!| find "\." >nul
            if not errorlevel 1 set "SKIP=1"
            if "!SKIP!"=="0" (
                echo !REL!| find "\" >nul
                if errorlevel 1 (
                    for %%N in (README README.md README.txt README.rst LICENSE LICENSE.md LICENSE.txt CHANGELOG CHANGELOG.md CONTRIBUTING.md CODE_OF_CONDUCT.md NOTICE NOTICE.md) do (
                        if /I "!REL!"=="%%N" set "SKIP=1"
                    )
                )
            )
            if "!SKIP!"=="0" (
                set /a TOTAL_FOUND+=1
                set "DST=%CLAUDE_DIR%\!REL!"
                if not exist "!DST!" (
                    for %%P in ("!DST!") do set "DSTDIR=%%~dpP"
                    if not exist "!DSTDIR!" (
                        mkdir "!DSTDIR!"
                        set "DSTDIRREL=!DSTDIR:%CLAUDE_DIR%\=!"
                        echo %IND%%C_GREEN%[DIR]%C_RESET%        %C_WHITE%!DSTDIRREL!%C_RESET%
                        echo(
                    )
                    copy /Y "!FULLFILE!" "!DST!" >nul
                    echo %IND%%C_GREEN%[NEW]%C_RESET%        %C_WHITE%!REL!%C_RESET%
                    echo(
                    set "LIST_NEW=!LIST_NEW!;!REL!"
                ) else (
                    fc /b "!FULLFILE!" "!DST!" >nul 2>&1
                    if not errorlevel 1 (
                        echo %IND%%C_GRAY%[UNCHANGED]%C_RESET%  %C_WHITE%!REL!%C_RESET%
                        echo(
                        set "LIST_UNCHANGED=!LIST_UNCHANGED!;!REL!"
                    ) else (
                        echo %IND%%C_RED%[CONFLICT]%C_RESET%   %C_WHITE%!REL!%C_RESET% already exists and differs from the repo version.
                        choice /c YN /n /m "%C_RESET%%IND%            Overwrite with the repo version? (Y = overwrite / N = skip): "
                        if errorlevel 2 (
                            <nul set /p ".=%CLR_CONFLICT%"
                            echo %IND%%C_MAGENTA%[SKIPPED]%C_RESET%    %C_WHITE%!REL!%C_RESET%
                            echo(
                            set "LIST_SKIPPED=!LIST_SKIPPED!;!REL!"
                        ) else (
                            copy /Y "!FULLFILE!" "!DST!" >nul
                            <nul set /p ".=%CLR_CONFLICT%"
                            echo %IND%%C_CYAN%[UPDATED]%C_RESET%    %C_WHITE%!REL!%C_RESET%
                            echo(
                            set "LIST_UPDATED=!LIST_UPDATED!;!REL!"
                        )
                    )
                )
            )
        )
    )
)

rem ======================================================================
rem Summary ("banner" and "print_section" both inlined)
rem ======================================================================
if "!CANCELLED!"=="0" (
    if "!TOTAL_FOUND!"=="0" (
        echo(
        echo %IND%%C_RED%Nothing to install - no files found yet.%C_RESET%
        echo(
    ) else if "!LIST_NEW!!LIST_UPDATED!!LIST_SKIPPED!"=="" (
        echo(
        echo %IND%%C_GREEN%Everything is already up to date - nothing needed changing.%C_RESET%
        echo(
    ) else (
        set "TEXT=Summary"
        set "BCOLOR=%C_BLUE%"
        set "LEN=0"
        for /L %%i in (0,1,199) do if not "!TEXT:~%%i,1!"=="" set /a LEN=%%i+1
        set /a "PAD=!WIDTH!-2-!LEN!"
        if !PAD! lss 0 set "PAD=0"
        set /a "LEFT=!PAD!/2"
        set /a "RIGHT=!PAD!-!LEFT!"
        set "LEFTSP="
        for /L %%i in (1,1,!LEFT!) do set "LEFTSP=!LEFTSP! "
        set "RIGHTSP="
        for /L %%i in (1,1,!RIGHT!) do set "RIGHTSP=!RIGHTSP! "
        set "LINE="
        for /L %%i in (1,1,!WIDTH!) do set "LINE=!LINE!="
        echo(
        echo %IND%!BCOLOR!!LINE!%C_RESET%
        echo %IND%!BCOLOR!=!LEFTSP!!TEXT!!RIGHTSP!=%C_RESET%
        echo %IND%!BCOLOR!!LINE!%C_RESET%
        echo(

        if not "!LIST_NEW!"=="" (
            set "ITEMS=!LIST_NEW:~1!"
            set "COUNT=0"
            for %%I in ("!ITEMS:;=" "!") do set /a COUNT+=1
            echo %IND%%C_GREEN%New ^(!COUNT!^)%C_RESET%
            for %%I in ("!ITEMS:;=" "!") do echo %IND2%%C_GREEN%-%C_RESET% %C_WHITE%%%~I%C_RESET%
            echo(
        )

        if not "!LIST_UPDATED!"=="" (
            set "ITEMS=!LIST_UPDATED:~1!"
            set "COUNT=0"
            for %%I in ("!ITEMS:;=" "!") do set /a COUNT+=1
            echo %IND%%C_CYAN%Updated ^(!COUNT!^)%C_RESET%
            for %%I in ("!ITEMS:;=" "!") do echo %IND2%%C_CYAN%-%C_RESET% %C_WHITE%%%~I%C_RESET%
            echo(
        )

        if not "!LIST_SKIPPED!"=="" (
            set "ITEMS=!LIST_SKIPPED:~1!"
            set "COUNT=0"
            for %%I in ("!ITEMS:;=" "!") do set /a COUNT+=1
            echo %IND%%C_MAGENTA%Skipped ^(!COUNT!^)%C_RESET%
            for %%I in ("!ITEMS:;=" "!") do echo %IND2%%C_MAGENTA%-%C_RESET% %C_WHITE%%%~I%C_RESET%
            echo(
        )

        if not "!LIST_UNCHANGED!"=="" (
            set "ITEMS=!LIST_UNCHANGED:~1!"
            set "COUNT=0"
            for %%I in ("!ITEMS:;=" "!") do set /a COUNT+=1
            echo %IND%%C_GRAY%Unchanged ^(!COUNT!^)%C_RESET%
            for %%I in ("!ITEMS:;=" "!") do echo %IND2%%C_GRAY%-%C_RESET% %C_WHITE%%%~I%C_RESET%
            echo(
        )
    )
)

echo(
<nul set /p ".=%C_GRAY%%IND%Press any key to exit...%C_RESET%"
endlocal
pause >nul
