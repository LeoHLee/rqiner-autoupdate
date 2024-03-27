@echo off

REM rqiner parameters
set "threadNum=30"
set "wallet=XZKDOOXKOBINTEAFTFKUHBQENBMBXCNOXGHXKJFNEALYQJUNSTSCGOGGDNBJ"
set "alias=default"

REM Define the directory where rqiner-x86.exe is located
set "rqiner_dir=."

set "executable=rqiner-x86.exe"
set "version_prefix=v0.3."
set "retryDelay=15"

if exist "%rqiner_dir%\%executable%" (
    for /f "tokens=3 delims=." %%a in ('"%rqiner_dir%\%executable%" -V 2^>^&1') do (
        set "version=%%a"
    )
    setlocal enabledelayedexpansion
    echo Current version %version_prefix%!version!
    endlocal
    set /a "version+=1"
) else (
    set "version=15"
    :installLoop
    setlocal enabledelayedexpansion
    echo Checking version %version_prefix%!version!
    curl -s -o "%rqiner_dir%\%executable%.new" -L https://github.com/Qubic-Solutions/rqiner-builds/releases/download/%version_prefix%!version!/rqiner-x86-znver2.exe

    if %errorlevel% neq 0 (
        timeout /t !retryDelay! > nul
        set /a "retryDelay*=2"
        goto :installLoop
    )
    endlocal
    
    set "retryDelay=15"

    for %%F in ("%rqiner_dir%\%executable%.new") do (
        if %%~zF leq 1000 (
            del "%rqiner_dir%\%executable%.new"
        ) else (
	        del "%rqiner_dir%\%executable%"
            ren "%rqiner_dir%\%executable%.new" %executable%
            set /a "version+=1"
            goto :installLoop
        )
    )
)

start "rqiner" %rqiner_dir%\%executable% -t %threadNum% -i %wallet% -l %alias%

:mainLoop

curl -s -o "%rqiner_dir%\%executable%.new" -L https://github.com/Qubic-Solutions/rqiner-builds/releases/download/%version_prefix%%version%/rqiner-x86-znver2.exe

if %errorlevel% neq 0 (
    timeout /t %retryDelay% >nul
    set /a "retryDelay*=2"
    goto :installLoop
)
set "retryDelay=15"

for %%F in ("%rqiner_dir%\%executable%.new") do (
    if %%~zF leq 1000 (
        del "%rqiner_dir%\%executable%.new"
        timeout /t 600 >nul
        goto :mainLoop
    ) else (
        echo Found new version %version_prefix%%version%
        taskkill /f /im "%executable%"
        timeout /t 3 >nul
	    del "%rqiner_dir%\%executable%"
        ren "%rqiner_dir%\%executable%.new" %executable%
        start "rqiner" %rqiner_dir%\%executable% -t %threadNum% -i %wallet% -l %alias%
        set /a "version+=1"
        goto :mainLoop
    )
)

