chcp 65001
@echo off
:Load
set "VERSION=2603.1"
set "CFG-URL="
set "CFG-FILE=mg.cfg"
set "GLB-URL="
if not exist "%~dp0agreement.txt" (goto Agreement)
if exist "%~dp0%CFG-FILE%" (call :Load-Config %CFG-FILE%) else (goto Need-Config)
if "%LOCAL-VER%"=="" (goto Load-Config-Error)
if "%GLOBAL-VER%"=="" (goto Load-Config-Error)

:Main
title moto.globalizer (для %MODEL-NAME%)
call :HeadLine "moto.globalizer (для %MODEL-NAME%)"
call :Righted "Конфигурация: %GLOBAL-VER%-%LOCAL-VER% "
set "MODE="
echo.    1:Прошивка
echo.    2:Подготовка к работе офлайн
echo.    3:Дополнительно
echo.    0:Выход [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (set "LOCAL-PATH=C:\" & goto Software) else (if "%REPLY%"=="2" (goto Offline) else (if "%REPLY%"=="3" (goto Additional)))
if "%REPLY%"=="U" (goto Device-Unlock) else (if "%REPLY%"=="F" (goto Finish))
:To-Exit
call :CopyRight "moto.globalizer %VERSION%" 2026
exit

:Additional
call :HeadLine "Дополнительно"
echo.
echo.    1:Обновление файла конфигурации
echo.    2:Разблокировка загрузчика
echo.    3:Смена канала обновлений
echo.    4:Удаление лишнего
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (goto Need-Config) else (if "%REPLY%"=="2" (set "MODE=unlock" & goto Software) else (if "%REPLY%"=="3" (goto Channel-Only) else (if "%REPLY%"=="4" (call :HeadLine "Удаление лишнего" & echo. & call :CleanUp & echo.  Готово. & echo. & goto To-Main))))
goto Main

:Software
if "%MODE%"=="offline" (if not exist "%~dp0%MMD-FILE%" (goto Need-MMD)) else (if not exist "%MMD-PATH%" (goto Need-MMD))
if "%MODE%"=="offline" (if not exist "%~dp0%SDK-FILE%" (goto Need-SDK)) else (if not exist "%SDK-PATH%\fastboot.exe" (goto Need-SDK))
if "%MODE%"=="unlock" (set "LOCAL-PATH=" & goto Device-SetUp) else (if "%MODE%"=="channel" (set "LOCAL-PATH=" & goto Loader-Check))
if "%MODE%"=="offline" (if not exist "%~dp0%MFP-FILE%" (goto Need-MFP)) else (if not exist "%MFP-PATH%\MotoFlashPro.exe" (goto Need-MFP))
set "LOCAL-PATH="

:Channel-And-Frameware
call :HeadLine "Канал и файл прошивки"
echo.
echo.  На устройство нельзя установить прошивку версии ниже текущей (используемой в данный момент).
echo.
echo.  Чтобы узнать текущую версию: откройте "Настройки / Об устройстве / Идентификаторы устройства" (англ. "Settings / About phone / Device Identifiers"), найдите там строку "Номер сборки" (англ. "Build number"), это и есть текущая версия прошивки (что-то вроде: %BLD-NUM-EX%)...
echo.
call :Start-Config-Message
set "START-CFG="
echo.    1:Выбрать канал и скачать прошивку [по умолчанию]
echo.    2:У меня уже есть файл прошивки
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="2" (if "%MODE%"=="offline" (set "MODE=" & goto Offline-Finish) else (goto I-Have-File)) else (if "%REPLY%"=="0" (goto Main))
:Channel-Select
set "CUSTOM-CH="
echo.  Выберите канал обновлений/файл прошивки.
echo.
echo.    1:%CH1-NAME% (%CH1-INFO%) [по умолчанию]
setlocal enabledelayedexpansion
for /L %%i in (2, 1, 9) do (if not "!CH%%i-NAME!"=="" (echo.    %%i:!CH%%i-NAME! ^(!CH%%i-INFO!^)))
endlocal
echo.    0:В главное меню
if "%SOURCES%"=="" (echo.) else (call :Righted "Источник(и) ссылок: %SOURCES% ")
set /p REPLY="Ваш выбор: "
echo.
set "CHANNEL="
setlocal enabledelayedexpansion
if not "!CH%REPLY%-NAME!"=="" (set "CHANNEL=%REPLY%") else (set "CHANNEL=1")
endlocal & set "CHANNEL=%CHANNEL%"
if "%REPLY%"=="0" (goto Main) else (if "%CHANNEL%"=="" set "CHANNEL=1")
call :Get-By-Index "CH" "-URL"
echo %REPLY% | findstr /b "Rhttp">nul
if "%ERRORLEVEL%"=="0" (goto Repository)
echo %REPLY% | findstr /b "Dhttp">nul
if "%ERRORLEVEL%"=="0" (goto Direct)
goto Browser

:Clear-URL
setlocal
set "REPLY=%REPLY:~1%"
endlocal & set "REPLY=%REPLY%"
goto :eof

:Repository
call :Clear-URL
start "" "%REPLY%"
echo.  На открывшейся веб-странице, найдите и скопируйте ссылку на нужную вам версию прошивки. А затем - вставьте её в это окно (при помощи правой кнопки мыши или сочетания клавиш Ctrl+V). Чтобы вернуться на предыдущий шаг, оставьте поле пустым и нажмите ввод...
echo.
set /p FRW-URL="Введите URL: "
echo.
if "%FRW-URL%"=="" (goto Channel-Select) else (goto Frameware-Download)

:Direct
call :Clear-URL
set "FRW-URL=%REPLY%"
goto Frameware-Download

:Frameware-Download
set "REPLY="
for %%i in ("%FRW-URL%") do set "REPLY=%%~nxi"
if "%REPLY%"=="" (call :Get-By-Index "CH" "-NAME" .zip)
set "FRW-NAME=%REPLY%
call :Need _ %FRW-NAME% %FRW-URL%
if "%REPLY%"=="download-error" (del /F /Q "%~dp0%FRW-NAME%" & goto Frameware-Download-Error)
if "%MODE%"=="offline" (goto Offline-Finish)
set "LOCAL-PATH=c"
:Frameware-Unpack
call :Get-By-Index "CH" "-NAME"
set "UNP-PATH=%LOCAL-PATH%:\%REPLY%"
call :Unpack %UNP-PATH% %FRW-NAME%
if "%REPLY%"=="unpack-error" (rmdir /S /Q "%UNP-PATH%" & goto Frameware-Unpack-Error)
if exist "%UNP-PATH%\flashfile.xml" (set "FRW-PATH=%LOCAL-PATH%:\%REPLY%" & goto Device-SetUp) else (goto Frameware-Error)

:Frameware-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
echo.  Не удалось найти файл "%UNP-PATH%\flashfile.xml".
echo.
echo.  Возможно: в архиве с прошивкой отсутствуют некоторые файлы или он содержит вложенные папки...
echo.  
echo.    1:Начать сначала
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Channel-And-Frameware) else (goto Main)

:Frameware-Download-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
echo.  Не удалось скачать файл прошивки "%FRW-NAME%".
echo.
echo.  Возможно: отсутствует доступ в интернет, заблокирован доступ к ресурсу (на котором размещён файл), недостаточно свободного места на диске. Проверьте возможные источники проблемы, (если получится) устраните их и повторите попытку...
echo.  
echo.    1:Повторить попытку
echo.    2:Скачать вручную
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Frameware-Download) else (if not "%REPLY%"=="2" (goto Main))
start "" "%FRW-URL%"
goto Browser-Download

:Frameware-Unpack-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
echo.  Не удалось распаковать прошивку.
echo.
echo.  Возможно: файл повреждён или на диске "%LOCAL-PATH%:" недостаточно свободного места...
echo.  
echo.    1:Повторить попытку
echo.    2:Выбрать другой диск
echo.    3:Распаковать вручную
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Frameware-Unpack) else (if "%REPLY%"=="3" (goto Self-Unpack) else (if not "%REPLY%"=="2" (goto Main)))
echo.  Укажите букву диска, на который нужно распаковать прошивку...
echo.
call :Drives-List
set /p LOCAL-PATH="Введите букву диска: "
echo.
goto Frameware-Unpack

:Drives-List
setlocal enabledelayedexpansion
echo.  Буква:    Свободно байт: Метка тома:
wmic logicaldisk where "DriveType=2 OR DriveType=3" get DeviceID,VolumeName,FreeSpace>%~dp0temp.tmp
for /f "delims=" %%a in ('more +1 "%~dp0temp.tmp" 2^>nul') do (echo.  %%a)
del /F /Q %~dp0temp.tmp
endlocal
echo.
goto :eof

:Self-Unpack
set "LOCAL-PATH="
call :Get-By-Index "CH" "-NAME"
start "" "%FRW-NAME%"
echo.  Создайте в корне одного из локальных дисков папку: "%REPLY%", и распакуйте в неё содержимое архива с прошивкой...
echo.
goto Browser-Select

:I-Have-File
echo.  Укажите канал, к которому относится имеющийся файл прошивки.
echo.
if "%OFFLINE-CH%"=="" (goto Custom-Channel)
echo.    1:Выбрать канал "%OFFLINE-CH%"
echo.    2:Ввести название канала вручную
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="2" (goto Custom-Channel) else (if "%REPLY%"=="0" (goto Main) else (set "CUSTOM-CH=%OFFLINE-CH%" & goto Browser-Unpack))

:Custom-Channel
call :Enter
if not "%CUSTOM-CH%"=="" (goto Browser-Unpack) else (goto Channel-And-Frameware)

:Enter
echo.  Обратите внимание:
echo.   Эта опция, рассчитана на продвинутых пользователей (хорошо понимающих - что они делают). Если неверно указать название канала, устройство не сможет получать обновления...
echo.
if "%MODE%"=="channel" (echo.  Если вы не хотите менять канал, оставьте поле пустым и нажмите ввод.) else (echo.  Чтобы вернуться на предыдущий шаг, оставьте поле пустым и нажмите ввод.)
echo.
set "CUSTOM-CH="
set /p CUSTOM-CH="Название канала: "
echo.
goto :eof

:Browser
start "" "%REPLY%"
:Browser-Download
echo.  Скачайте файл прошивки на открывшейся веб-странице...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
if "%MODE%"=="offline" (goto Offline-Finish)
:Browser-Unpack
set "LOCAL-PATH="
call :Get-By-Index "CH" "-NAME"
echo.  Создайте в корне одного из локальных дисков папку: "%REPLY%", и распакуйте в неё содержимое архива с прошивкой...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
:Browser-Select
call :Get-By-Index "CH" "-NAME"
echo.  Укажите букву диска, на котором вы создали папку: "%REPLY%"...
echo.
call :Drives-List
set /p LOCAL-PATH="Введите букву диска: "
echo.
if exist "%LOCAL-PATH%:\%REPLY%\flashfile.xml" (set "FRW-PATH=%LOCAL-PATH%:\%REPLY%" & goto Device-Setup) else (goto Browser-Error)

:Browser-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
echo.  На указанном диске не обнаружен файл: "%LOCAL-PATH%:\%REPLY%\flashfile.xml".
echo.
echo.  Возможно указана неверная буква диска или при распаковке прошивки - появились дополнительные вложенные папки...
echo.  
echo.    1:Повторить попытку
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Browser-Select) else (goto Main)

:Device-SetUp
call :HeadLine "Подготовка устройства"
echo.
echo.  Должен быть активирован режим "Для разработчиков".
echo.
echo.  Для его активации: откройте "Настройки / Об устройстве / Идентификаторы устройства" (англ. "Settings / About phone / Device Identifiers"), и последовательно (несколько раз) нажмите на строку "Номер сборки" (англ. "Build number"), до появления (в нижней части экрана) сообщения "Вы стали разработчиком!" (англ. "You are now a developer"), обычно хватает 8-ми нажатий...
echo.
if not "%START-CFG%"=="" (call :Start-Config-Message)
set "START-CFG=show"
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  Перейдите в: "Настройки / Система / Для разработчиков" (англ. "Settings / System / Developer options"). Найдите параметр "Заводская разблокировка" (англ. "OEM unlocking"), действуйте в соответствии со своим вариантом:
echo.   - Параметр активен и выключен: его нужно включить.
echo.   - Параметр активен и включен: не трогайте его (оставьте включенным).
echo.   - Параметр не активен: переходите к следующему шагу.
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
:Loader-Check
echo.  Выключите ваше устройство (если кнопка питания не вызывает меню выключения, попробуйте одновременно нажать кнопки: управления питанием и увеличения громкости)...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  На выключенном устройстве, одновременно нажмите и удерживайте кнопки: включения и уменьшения громкости, до появления на экране меню "FastBoot".
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (if "%MODE%"=="offline" (goto Offline-State))
echo.  Подключите устройство к ПК USB-кабелем...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (goto Device-Connect)

:Device-Connect
%SDK-PATH%\fastboot devices>"%~dp0temp.tmp" 2>&1
set "REPLY="
set /p REPLY=<"%~dp0temp.tmp"
del /F /Q "%~dp0temp.tmp"
if "%REPLY%"=="" (goto Device-Connect-Error) else (if "%MODE%"=="channel" (goto Channel-Enter))
%SDK-PATH%\fastboot getvar all>"%~dp0getvar_all.txt" 2>&1
call :Get-Line "getvar_all.txt" "securestate: "
if "%REPLY%"=="oem_lock" (goto Device-Unlock) else (if "%REPLY%"=="flashing_unlocked" (if "%MODE%"=="unlock" (goto Device-Unlocked) else (goto Device-Flashing)) else (if "%REPLY%"=="flashing_locked" (goto Device-Warning) else (goto Device-Unlock-Error)))

:Device-Connect-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
echo.  Не обнаружено подключенных устройств.
echo.
echo.  Убедитесь, что устройство находится в режиме FastBoot (на его экране отображается меню FastBoot), возможно вам следует попробовать другой порт/USB-кабель. Если это не поможет - попробуйте переустановить драйверы и перезагрузить ПК...
echo.  
echo.    1:Повторить попытку
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Device-Connect) else (goto Main)

:Device-Unlock-Error
color 4F
call :HeadLine "ОШИБКА" error
echo.
call :Get-Line "getvar_all.txt" "securestate: "
echo.  Загрузчик устройства находится в состоянии: "%REPLY%".
echo.
if "REPLY"=="flashing_locked" (echo.  Похоже, он уже был разблокирован, а затем - его повторно заблокировали... & echo.)
echo.    1:Нужна помощь
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (call :Troubleshooting & "%~dp0getvar_all.txt" & goto To-Main) else (goto Main)

:Device-Warning
call :HeadLine "Повторная разблокировка"
echo.
echo.  Похоже, на этом устройстве уже выполнялась разблокировка загрузчика, а затем он был снова заблокирован.
echo.
echo.  В таком состоянии, повторная разблокировка возможна только если канал обновлений - соответствует версии установленной прошивки...
echo.
call :Get-Line "getvar_all.txt" "ro.carrier: "
echo.  Текущий канал на устройстве: %REPLY%
echo.
echo.  В: "Настройки / Об устройстве / Сведения об устройстве", должен отображаться параметр "Регион программного обеспечения" и И его значение - должно совпадать с текущим каналом на устройстве...
echo.  
echo.    1:Проверить [по умолчанию]
echo.    2:Значения совпадают
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="2" (goto Device-Unlock) else (if "%REPLY%"=="0" (goto Main))
call :Device-Reboot
echo.  Проверьте соответствие значений параметров.
echo.
echo.    1:Значения совпадают
echo.    0:Значения различаются или одно из них отсутствует [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (goto Loader-Check)
call :Troubleshooting
echo.  Вы можете попробовать изменить канал обновлений, чтобы привести его в соответствие с установленной на устройстве версией прошивки.
echo.
goto To-Main

:Device-Unlock
call :HeadLine "Разблокировка загрузчика"
echo.
echo.  Загрузчик устройства заблокирован.
echo.
echo.  Пока он находится в таком состоянии - невозможно установить прошивку для другого региона..
echo.  Обратите внимание:
echo.   - Разблокировка загрузчика - лишает устройство заводской гарантии
echo.   - В процессе разблокировки, произойдёт сброс устройства (все пользовательские данные на нём будут удалены)
echo.   - После разблокировки, при каждой загрузке устройства - в течении 5-ти секунд будет отображаться предупреждение: "The boot loader is unlocked ..."
echo.
echo.    1:Разблокировать загрузчик [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
start "" "%MOTO-LGN-URL%"
echo.  Для разблокировки загрузчика, нужно войти/зарегистрироваться и войти (в учётную запись) на странице поддержки Motorola...
echo.  Чтобы зарегистрироваться:
echo.   1. Нажмите "Sign in with Motorola Account"
echo.   2. Затем "Create an Account" (Don't have an account?)
echo.   3. Введите: фамилию, имя, адрес эл.почты и пароль (используйте только английскую раскладку при вводе данных (при использовании других символов - могут возникнуть проблемы с получением кода разблокировки), у некоторых пользователей наблюдались проблемы при использовании почтовых сервисов Google (лучше воспользоваться другими))
echo.   4. Нажмите "Create Account"
echo.   5. На вашу эл.почту - придёт письмо (для подтверждения), нажмите в нём на "Click here to verify"
echo.   6. Войдите в учётную запись (используя введённые ранее данные), если это не произошло автоматически
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
%SDK-PATH%\fastboot oem get_unlock_data>"%~dp0oem_get_unlock_data.txt" 2>&1
set "REPLY="
setlocal enabledelayedexpansion
for /f "delims=" %%l in (%~dp0oem_get_unlock_data.txt) do (if not defined REPLY (set "REPLY=%%l") else (set "REPLY=!REPLY!%%l"))
for /f "delims=[" %%a in ("%REPLY%") do set "REPLY=%%a"
set "REPLY=!REPLY:(bootloader) =!"
set "REPLY=!REPLY:OKAY =!"
set "REPLY=!REPLY:Unlock data:=!"
endlocal & set "REPLY=%REPLY%"
echo.  Идентификатор вашего устройства:
echo.  %REPLY%
echo.
call :Listing "oem_get_unlock_data.txt" " fastboot oem get_unlock_data " "Хотите просмотреть вывод команды?"
echo.  Он (идентификатор) уже скопирован в буфер обмена...
echo.
start "" "%MOTO-UNL-URL%"
echo.  Вставьте его в поле "MAKE SURE YOUR DEVICE IS UNLOCKABLE", на открывшейся веб-странице (воспользуйтесь контекстным меню или сочетанием клавиш Ctrl+V), и нажмите кнопку "Can my device be unlocked?"...
echo.
echo|set /p=%REPLY%|clip
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  В нижней части страницы, "I agree to be bound by the terms of the legal agreement" Выберите "Yes" и нажмите кнопку "REQUEST UNLOCK KEY"...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  На эл.почту (использованную для регистрации учётной записи) придёт письмо, с кодом разблокировки. Код нужно скопировать, и вставить в это окно (при помощи правой кнопки мыши или сочетания клавиш Ctrl+V).
echo.
:Unlock
set /p REPLY="Код разблокировки: "
echo.
setlocal enabledelayedexpansion
set "REPLY=!REPLY: =!"
endlocal & set "REPLY=%REPLY%"
%SDK-PATH%\fastboot oem unlock %REPLY%>"%~dp0oem_unlock.txt" 2>&1
set "REPLY="
set /p REPLY=<oem_unlock.txt
call :Listing "oem_unlock.txt" " fastboot oem unlock %REPLY% " "Хотите просмотреть вывод команды?"
echo.  На экране устройства, должен появиться запрос на разблокировку загрузчика. Для выбора доступны следующие варианты:
echo.   - "DO NOT UNLOCK THE BOOTLOADER" (не разблокировать загрузчик)
echo.   - "UNLOCK THE BOOTLOADER" (разблокировать загрузчик)
echo.  Выбор осуществляется кнопками управления громкостью, подтверждение выбора - кнопкой управления питанием...
echo.
echo.  Выберите "UNLOCK THE BOOTLOADER" и подтвердите свой выбор...
echo.
echo.    1:Готово [по умолчанию]
echo.    2.Запрос не появился
echo.    3:Повторить попытку
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (if "%REPLY%"=="2" (call :Troubleshooting & goto To-Main) else (if "%REPLY%"=="3" (goto Unlock)))
call :Device-Reboot
if "%MODE%"=="unlock" (echo.  Готово. & goto To-Main) else (goto Device-SetUp)

:Device-Reboot
echo.  Устройство нужно перезагрузить...
echo.
echo.    1:Перезагрузить устройство [по умолчанию]
echo.    0:Я сделаю это самостоятельно
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="0" (%SDK-PATH%\fastboot reboot>nul 2>&1)
goto :eof

:Device-Unlocked
echo.  Загрузчик уже разблокирован.
echo.
call :Device-Reboot
goto Main

:Device-Flashing
call :HeadLine "Прошивка"
echo.
echo.  Следующие действия выполняются в приложении: MotoFlash Pro.
echo.   1. Нажать кнопку "OpenXML"
echo.   2. Выберите файл "flashfile.xml" в папке (куда была распакована прошивка)
echo.   3. Снимите флажок "reboot after flash"
echo.   4. Нажмите кнопку "Start flash" и следите за логом...
echo.
echo.  Если всё сделано правильно - в логе не должно быть ошибок. По завершению процесса (когда кнопка "Start flash" снова станет активна), рекомендуется скопировать содержимое лога и сохранить его в текстовый файл, после чего приложение MotoFlash Pro можно закрыть.
echo.
echo.    1:Открыть MotoFlash Pro [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (call :Righted "Когда будет закрыто приложение MotoFlash Pro, работа скрипта продолжится... " & %MFP-PATH%\MotoFlashPro.exe & echo.)
echo.  Прошивка прошла без проблем?
echo.
echo.    1:Да [по умолчанию]
echo.    0:Нет, возникли проблемы
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="0" (goto Device-Channel)
call :Troubleshooting
echo.  Хотите продолжить процесс?
echo.
echo.    1:Да, перейти к следующему шагу
echo.    0:Нет, в главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (goto Device-Channel) else (goto Main)

:Device-Channel
call :HeadLine "Канал обновлений"
call :Get-By-Index "CH" "-NAME"
echo.
echo.  Чтобы устройство получало обновления, необходимо установить канал - соответствующий прошивке...
echo.
call :Get-Line "getvar_all.txt" "ro.carrier: "
echo.  Текущий канал на устройстве: %REPLY%
echo.
call :Get-By-Index "CH" "-NAME"
echo.    1:Установить канал %REPLY% [по умолчанию]
echo.    2:Ввести название канала вручную
echo.    3:Пропустить этот шаг
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="2" (goto Channel-Enter) else (if "%REPLY%"=="3" (call :Device-Reboot) else (if "%REPLY%"=="0" (goto Main) else (goto Channel-Set)))
goto Finish

:Channel-Enter
if "%MODE%"=="channel" (call :Get-Line "getvar_all.txt" "ro.carrier: ")
if "%MODE%"=="channel" (echo.  Текущий канал на устройстве: %REPLY% & echo.)
echo.  Введите новое название канала.
echo.
call :Enter
if "%CUSTOM-CH%"=="" (if "%MODE%"=="channel" (goto Channel-Only) else (goto Device-Channel))
:Channel-Set
call :Get-By-Index "CH" "-NAME"
:Channel-Check
%SDK-PATH%\fastboot oem config carrier %REPLY%>"%~dp0oem_config_carrier.txt" 2>&1
echo.  Установлен канал: %REPLY%
echo.
call :Listing "oem_config_carrier.txt" " fastboot oem config carrier %REPLY% " "Хотите просмотреть вывод команды?"
if "%MODE%"=="channel" (goto Channel-Only-Finish) else (call :Device-Reboot)
:Channel-Only-Check
call :Get-By-Index "CH" "-NAME"
echo.  После перезагрузки устройства и выполнения начальной настройки, откройте: "Настройки / Об устройстве / Сведения об устройстве" и найдите там "Регион программного обеспечения"...
echo.    Должно отображаться значение: %REPLY%
echo.
echo.    1:Канал обновлений отображается правильно [по умолчанию]
echo.    0:Возникли проблемы
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (call :Troubleshooting) else (if "%MODE%"=="channel" (echo.  Готово. & goto To-Main) else (goto Finish))
goto To-Main

:Finish
echo.  Прошивка выполнена.
echo.
call :CleanUp
goto To-Main

:To-Main
set /p REPLY="Для возврата в главное меню - нажмите ввод..."
echo.
goto Main

:Troubleshooting
start "" "%COM-URL%"
echo.  Сожалеем что вы столкнулись с проблемами, возможно их помогут решить в сообществе владельцев %MODEL-NAME%...
echo.
if not exist "%~dp0getvar_all.txt" (if not exist "%~dp0oem_get_unlock_data.txt" (if not exist "%~dp0oem_unlock.txt" (if not exist "%~dp0oem_config_carrier.txt" (goto :eof))))
echo.  В папке с этим скриптом есть файл(ы):
if exist "%~dp0getvar_all.txt" (echo.   - getvar_all.txt)
if exist "%~dp0oem_get_unlock_data.txt" (echo.   - oem_get_unlock_data.txt)
if exist "%~dp0oem_unlock.txt" (echo.   - oem_unlock.txt)
if exist "%~dp0oem_config_carrier.txt" (echo.   - oem_config_carrier.txt)
echo.  Данные из которого(ых), может помочь в решении проблем (учитывайте, что: в файле(ах) может содержаться конфиденциальная информация о вашем устройстве)...
echo.
goto :eof

:Agreement
call :HeadLine "ВНИМАНИЕ"
echo.
echo.  Хотя данный скрипт был протестирован, полностью исключить вероятность возникновения проблем при его использовании - невозможно.
echo.
echo.  Продолжая, вы соглашаетесь с тем что: понимаете и принимаете на себя все возможные риски, связанные с его работой (вплоть до: потери данных и/или работоспособности устройств). Все дальнейшие действия вы выполняете на свой страх и риск...
echo.
echo.    1:Продолжить
echo.    0:Выход [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (echo.Я ^(пользователь^) %USERNAME%, соглашаюсь с тем что: понимаю и принимаю на себя все возможные риски, связанные с работой BAT-скрипта moto.globalizer ^(вплоть до: потери данных и/или работоспособности моих устройств^)...>"%~dp0agreement.txt" & goto Load) else (goto To-Exit)

:Start-Config-Message
echo.  Чтобы попасть в "Настройки" (на новом устройстве/после сброса), нужно пройти начальный диалог (регион, язык, доступ в интернет, лицензионное соглашение и т.д.). Для ускорения процесса - можно воспользоваться кнопкой "Пропустить" (англ. "Skip"), везде где это возможно (т.к. при прошивке - все настройки будут сброшены)... Сразу после начальной настройки, рекомендуется ограничить доступ в интернет (отключить WiFi и мобильный интернет). Если устройство обнаружит обновления и начнёт их установку - это может замедлить процесс/создать проблемы при подготовке к прошивке...
echo.
goto :eof

:Offline
set "MODE=offline"
call :HeadLine "Подготовка"
echo.
echo.  Офлайн прошивка возможна только если у устройства разблокирован загрузчик. Для разблокировки загрузчика требуется (индивидуальный, для каждого устройства) код, который может быть получен только на странице поддержки Motorola.
echo.
echo.  Данный инструмент поможет скачать файл прошивки и всё необходимое ПО, а также проверить состояние загрузчика устройства...
echo.
echo.    1:Начать [по умолчанию]
echo.    2.Проверить состояние загрузчика
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="2" (goto Offline-Check) else (if "%REPLY%"=="0" (goto Main))
set "LOCAL-PATH=_"
goto Software

:Offline-Check
echo.  Для проверки состояния загрузчика:
echo.
goto Loader-Check

:Offline-State
echo.  В меню "FastBoot" должна отображаться информация об устройстве. Если загрузчик разблокирован - одна из строк будет содержать текст: "flashing_unlocked". Если такой строки нет, для выполнения прошивки - устройству потребуется разблокировка загрузчика...
echo.
echo.  Чтобы вернуть устройство в обычный режим работы: выберите "START" (с помощью кнопок управления громкостью), а затем подтвердите выбор кнопкой управления питанием...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (goto Offline)

:Offline-Finish
call :Get-By-Index "CH" "-NAME"
if "%MODE%"=="offline" (set "OFFLINE-CH=%REPLY%" & call :Save-Config)
echo.  Подготовка завершена.
echo.
echo.  Для прошивки офлайн, вам понадобятся следующие файлы:
echo.   - %~nx0
echo.   - %CFG-FILE%
echo.   - %MMD-FILE%
echo.   - %MFP-FILE%
echo.   - %SDK-FILE%
echo.   - файл прошивки...
echo.
goto To-Main

:Channel-Only
call :HeadLine "Смена канала обновлений"
echo.
echo.  Когда, при установке прошивки, на устройстве не выставляется (соответствующий ей) канал - оно теряет возможность получать обновления.
echo.
echo.  Если вы знаете/догадываетесь, к какому каналу относится прошивка на устройстве - можно попробовать сменить канал без выполнения процедуры прошивки. Но, чтобы изменения вступили в силу, придётся выполнить сброс (все пользовательские данные на устройстве будут удалены).
echo.
echo.    1:Начать [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (set "MODE=channel" & goto Software)

:Channel-Only-Finish
echo.  Теперь нужно выполнить сброс устройства.
echo.
echo.  С помощью кнопок управления громкостью, выберите в меню "FastBoot": "RECOVERY MODE", и подтвердите выбор кнопкой управления питанием. Устройство перезагрузится в режим восстановления...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  На экране устройства, должен отображаться логотип и надпись "No command" (на чёрном фоне).
echo.
echo.  Чтобы попасть в меню, одновременно нажмите кнопки: управления питанием и увеличения громкости.
echo.
echo.  С помощью кнопок управления громкостью - выберите пункт: "Wipe data/factory reset", подтвердите выбор кнопкой управления питанием.
echo.
echo.  Выберите вариант: "Factory data reset", и подтвердите выбор - чтобы начать процесс...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main)
echo.  В нижней части экрана - появятся сообщения о выполненных действиях.
echo.
echo.  После появления сообщения: "Data wipe complete" - выберите в меню: "Reboot system now", устройство будет перезагружено...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (goto Main) else (goto Channel-Only-Check)

:CleanUp
if not exist "%~dp0getvar_all.txt" (if not exist "%~dp0oem_get_unlock_data.txt" (if not exist "%~dp0oem_unlock.txt" (if not exist "%~dp0oem_config_carrier.txt" (goto CleanUp-Channel))))
echo.  В процессе работы, полученная от устройства информация - сохранялась во вспомогательные файлы.
if exist "%~dp0getvar_all.txt" (echo.   - getvar_all.txt)
if exist "%~dp0oem_get_unlock_data.txt" (echo.   - oem_get_unlock_data.txt)
if exist "%~dp0oem_unlock.txt" (echo.   - oem_unlock.txt)
if exist "%~dp0oem_config_carrier.txt" (echo.   - oem_config_carrier.txt)
echo.
echo.  Хотите удалить их?
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (goto CleanUp-Channel)
if exist "%~dp0getvar_all.txt" (del /F /Q "%~dp0getvar_all.txt")
if exist "%~dp0oem_get_unlock_data.txt" (del /F /Q "%~dp0oem_get_unlock_data.txt")
if exist "%~dp0oem_unlock.txt" (del /F /Q "%~dp0oem_unlock.txt")
if exist "%~dp0oem_config_carrier.txt" (del /F /Q "%~dp0oem_config_carrier.txt")
:CleanUp-Channel
if "%OFFLINE-CH%"=="" (goto CleanUp-Unpack)
echo.  При подготовке к работе офлайн, название канала "%OFFLINE-CH%" (скачанной прошивки) - было внесено в конфигурацию.
echo.
echo.  Хотите удалить его?
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (goto CleanUp-Unpack)
set "OFFLINE-CH="
call :Save-Config
:CleanUp-Unpack
if not exist "%MFP-PATH%" (if not exist "%SDK-PATH%" (if not exist "%FRW-PATH%\flashfile.xml" (goto CleanUp-Download)))
if not exist "%FRW-PATH%\flashfile.xml" (set "TEXT=с ПО") else (set "TEXT=с ПО и прошивкой")
echo.  В процессе работы - были распакованы архивы %TEXT%.
if exist "%MFP-PATH%" (echo.   - %MFP-PATH%\)
if exist "%SDK-PATH%" (echo.   - %SDK-PATH%\)
if exist "%FRW-PATH%\flashfile.xml" (echo.   - %FRW-PATH%\)
echo.
echo.  Хотите удалить распакованное?
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (goto CleanUp-Download)
if exist "%MFP-PATH%" (rmdir /S /Q "%MFP-PATH%")
if exist "%SDK-PATH%" (rmdir /S /Q "%SDK-PATH%")
if exist "%FRW-PATH%\flashfile.xml" (rmdir /S /Q "%FRW-PATH%")
:CleanUp-Download
if not exist "%~dp0%MFP-FILE%" (if not exist "%~dp0%SDK-FILE%" (if "%FRW-FILE%"=="" (goto CleanUp-MMD) else (if not exist "%~dp0%FRW-FILE%" (goto CleanUp-MMD))))
set "TEXT=с ПО"
if not "%FRW-FILE%"=="" (if exist "%~dp0%FRW-FILE%" (set "TEXT=с ПО и прошивкой"))
echo.  Для работы - были скачаны архивы %TEXT%.
if exist "%~dp0%MFP-FILE%" (echo.   - %MFP-FILE%)
if exist "%~dp0%SDK-FILE%" (echo.   - %SDK-FILE%)
if not "%FRW-FILE%"=="" (if exist "%~dp0%FRW-FILE%" (echo.   - %FRW-FILE%))
echo.
echo.  Хотите удалить скачанное?
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (goto CleanUp-MMD)
if exist "%~dp0%MFP-FILE%" (del /F /Q "%~dp0%MFP-FILE%")
if exist "%SDK-FILE%" (del /F /Q "%~dp0%SDK-FILE%")
if not "%FRW-FILE%"=="" (if exist "%FRW-FILE%" (del /F /Q "%~dp0%FRW-FILE%"))
:CleanUp-MMD
if not exist "%~dp0%MMD-FILE%" (goto :eof)
if exist "%MMD-PATH%" (set "TEXT=скачаны и установлены") else (set "TEXT=скачаны")
echo.  Для работы - были %TEXT% драйверы.
echo.
echo.  Хотите удалить их?
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (goto :eof)
call :Righted "Когда будет закрыт мастер установки, работа скрипта продолжится... "
echo.
"%~dp0%MMD-FILE%"
del /F /Q "%~dp0%MMD-FILE%"
goto :eof

:Save-Config
if exist "%CFG-FILE%" del /F /Q %CFG-FILE%
set "VARS-LIST=LOCAL-VER MODEL-NAME BLD-NUM-EX COM-URL SOURCES CH1-NAME CH1-URL CH1-INFO CH2-NAME CH2-URL CH2-INFO CH3-NAME CH3-URL CH3-INFO CH4-NAME CH4-URL CH4-INFO CH5-NAME CH5-URL CH5-INFO CH6-NAME CH6-URL CH6-INFO CH7-NAME CH7-URL CH7-INFO CH8-NAME CH8-URL CH8-INFO CH9-NAME CH9-URL CH9-INFO OFFLINE-CH GLOBAL-VER MMD-FILE32 MMD-FILE64 MMD-URL32 MMD-URL64 MMD-ALT MMD-PATH MFP-FILE MFP-URL MFP-ALT MFP-PATH SDK-FILE SDK-URL SDK-ALT SDK-PATH FRW-NAME MOTO-LGN-URL MOTO-UNL-URL"
setlocal enabledelayedexpansion
for %%v in (%VARS-LIST%) do (echo %%v=!%%v!>>"%~dp0%CFG-FILE%")
endlocal
goto :eof

:Load-Config
for /f "usebackq delims=" %%c in ("%~1") do set "%%c"
if "%PROCESSOR_ARCHITECTURE%"=="x86" (set "MMD-URL=%MMD-URL32%" & set "MMD-FILE=%MMD-FILE32%") else (set "MMD-URL=%MMD-URL64%" & set "MMD-FILE=%MMD-FILE64%")
goto :eof

:Load-Config-Error
title moto.globalizer (ОШИБКА)
call :HeadLine "ОШИБКА"
color 4F
echo.
echo.  Не удалось загрузить конфигурацию.
echo.
echo.  Возможно файл конфигурации повреждён или имеет неверный формат...
echo.
echo.    1:Повторить попытку
echo.    0:Выход [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Need-Config) else (goto To-Exit)

:Need-Config
echo.  Формирование файла конфигурации...
echo.
call :Need _ temp.tmp %CFG-URL%
if "%REPLY%"=="download-error" (goto Need-Config-Error)
call :Load-Config temp.tmp
del /F /Q "%~dp0temp.tmp"
call :Need _ temp.tmp %GLB-URL%
if "%REPLY%"=="download-error" (goto Need-Config-Error)
call :Load-Config temp.tmp
del /F /Q "%~dp0temp.tmp"
if not "%LOCAL-VER%"=="" (if not "%GLOBAL-VER%"=="" (call :Save-Config) else (goto Save-Config-Error)) else (goto Save-Config-Error)
goto Load

:Need-Config-Error
call :HeadLine "ОШИБКА" error
color 4F
echo.
echo.  Не удалось получить данные для файла конфигурации.
echo.
echo.  Возможно: отсутствует доступ в интернет или заблокирован доступ к ресурсу (на котором они размещёны)...
echo.  
echo.    1:Повторить попытку
echo.    0:Выход [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Need-Config) else (goto To-Exit)

:Save-Config-Error
call :HeadLine "ОШИБКА" error
color 4F
echo.
echo.  Не удалось сформировать новый файл конфигурации.
echo.
echo.  Возможно: Отсутствует часть необходимых данных...
echo.  
echo.    1:Повторить попытку
echo.    0:Выход [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Need-Config) else (goto To-Exit)

:Need-MMD
echo.  Для работы понадобится Motorola Mobile Drivers...
echo.
call :Need %LOCAL-PATH% %MMD-FILE% %MMD-URL%
:MMD-Errors
if "%REPLY%"=="download-error" (del /F /Q "%~dp0%MMD-FILE%" & call :HeadLine "ОШИБКА" error & call :Download-Error %LOCAL-PATH% %MMD-FILE% %MMD-URL% %MMD-ALT% & goto MMD-Errors)
if "%REPLY%"=="unpack-error" (call :HeadLine "ОШИБКА" error & call :Unpack-Error %LOCAL-PATH% %MMD-FILE% %MMD-URL% & goto MMD-Errors)
if "%REPLY%"=="main.menu" (goto Main)
if "%REPLY%"=="run.msi" (call :Righted "Когда будет закрыт мастер установки, работа скрипта продолжится... " & echo. & "%~dp0%MMD-FILE%")
goto Software

:Need-MFP
echo.  Для работы понадобится MotoFlash Pro...
echo.
call :Need %LOCAL-PATH% %MFP-FILE% %MFP-URL%
:MFP-Errors
if "%REPLY%"=="download-error" (del /F /Q "%~dp0%MFP-FILE%" & call :HeadLine "ОШИБКА" error & call :Download-Error %LOCAL-PATH% %MFP-FILE% %MFP-URL% %MFP-ALT% & goto MFP-Errors)
if "%REPLY%"=="unpack-error" (call :HeadLine "ОШИБКА" error & call :Unpack-Error %LOCAL-PATH% %MFP-FILE% %MFP-URL% & goto MFP-Errors)
if "%REPLY%"=="main.menu" (goto Main)
goto Software

:Need-SDK
echo.  Для работы понадобится Android SDK...
echo.
call :Need %LOCAL-PATH% %SDK-FILE% %SDK-URL%
:SDK-Errors
if "%REPLY%"=="download-error" (del /F /Q "%~dp0%SDK-FILE%" & call :HeadLine "ОШИБКА" error & call :Download-Error %LOCAL-PATH% %SDK-FILE% %SDK-URL% %SDK-ALT% & goto SDK-Errors)
if "%REPLY%"=="unpack-error" (call :HeadLine "ОШИБКА" error & call :Unpack-Error %LOCAL-PATH% %SDK-FILE% %SDK-URL% & goto SDK-Errors)
if "%REPLY%"=="main.menu" (goto Main)
goto Software

:Need
if not exist "%~dp0%2" (goto Download) else (goto Download-Action)
:Need-Unpack
echo %2 | findstr /i ".zip ">nul
if "%ERRORLEVEL%"=="0" (if not "%1"=="_" (goto Unpack))
echo %2 | findstr /i ".msi ">nul
if "%ERRORLEVEL%"=="0" (if not "%1"=="_" (set "REPLY=run.msi"))
goto :eof

:Download
set "REPLY="
echo.  Скачивание: "%2"...
echo.
if not "%1"=="_" (curl -s -L -o "%~dp0%2" "%3">nul 2>&1) else (curl -L -o "%~dp0%2" "%3" & echo.)
if "%ERRORLEVEL%"=="0" (goto Need-Unpack) else (set "REPLY=download-error" & goto :eof)

:Download-Action
echo.  Файл "%2" уже существует. Как следует поступить?
echo.
echo.    1:Удалить и скачать заново
echo.    0:Продолжить без нового скачивания [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="1" (del /F /Q %2 & goto Download) else (goto Need-Unpack)
goto Unpack

:Download-Error
color 4F
echo.
echo.  Не удалось скачать файл "%2".
echo.
echo.  Возможно: отсутствует доступ в интернет, заблокирован доступ к ресурсу (на котором размещён файл), недостаточно свободного места на диске. Проверьте возможные источники проблемы, (если получится) устраните их и повторите попытку...
echo.  
echo.    1:Повторить попытку
echo.    2:Скачать вручную
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Download) else (if not "%REPLY%"=="2" (set "REPLY=main.menu" & goto :eof))
start "" "%4"
echo.  На открывшейся странице, скачайте файл "%2" и поместите его в папку с этим скриптом...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (set "REPLY=main.menu")
goto :eof

:Unpack
setlocal enabledelayedexpansion
set "TEMP=D:\0"
if "!TEMP:~0,3!"=="!TEMP!" (if "!TEMP:~1,2!"==":\" (set "TEMP=root") else (set "TEMP=")) else (set "TEMP=")
endlocal & set "REPLY=%TEMP%"
if "%REPLY%"=="root" (if exist "%1" (goto Unpack-Action))
set "REPLY="
echo.  Распаковка...
echo.
if not exist "%1" (mkdir "%1")
tar -xf "%2" -C %1>nul 2>&1
if not "%ERRORLEVEL%"=="0" (set "REPLY=unpack-error" & goto :eof)
goto :eof

:Unpack-Action
echo.  Папка "%1" уже существует. Что с ней следует сделать?
echo.
echo.    1:Переместить [по умолчанию]
echo.    0:Удалить
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (rmdir /S /Q %1) else (goto Rename)
goto Unpack

:Rename
setlocal enabledelayedexpansion
for %%i in ("%1") do set "FOLDER-NAME=%%~nxi"
for /f %%i in ('wmic OS Get LocalDateTime ^| find "."') do set DATE-TIME=%%i
set "DATE-TIME=!DATE-TIME:~0,4!.!DATE-TIME:~4,2!.!DATE-TIME:~6,2! - !DATE-TIME:~8,2! !DATE-TIME:~10,2! !DATE-TIME:~12,2!"
endlocal & set "REPLY=%FOLDER-NAME% (%DATE-TIME%)"
ren "%1" "%REPLY%"
goto Unpack

:Unpack-Error
color 4F
echo.
echo.  Не удалось распаковать "%2".
echo.
echo.  Возможно: файл повреждён или на диске недостаточно свободного места...
echo.  
echo.    1:Повторить попытку
echo.    2:Распаковать вручную
echo.    0:В главное меню [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
color 0F
if "%REPLY%"=="1" (goto Unpack) else (if not "%REPLY%"=="2" (set "REPLY=main.menu" & goto :eof))
start "" "%~dp0%2"
echo.  Распакуйте содержимое архива "%2" в "%1"...
echo.
echo.    1:Готово [по умолчанию]
echo.    0:В главное меню
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if "%REPLY%"=="0" (set "REPLY=main.menu")
goto :eof

:Get-By-Index
if not "%CUSTOM-CH%"=="" (set "REPLY=%CUSTOM-CH%" & goto :eof)
setlocal enabledelayedexpansion
set "REPLY=!%~1%CHANNEL%%~2!"
endlocal & set "REPLY=%REPLY%"
goto :eof

:HeadLine
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%a in ('mode con: ^| find "Columns"') do set COLS=%%a
set "TEXT=%~1"
set LEN=0
set TEMP=%TEXT%
:Loop-HL
if defined TEMP (set TEMP=!TEMP:~1!
	set /a LEN+=1
	goto Loop-HL)
set /a PAD=(%COLS% - %LEN%) / 2
set "SPACES="
for /l %%i in (1,1,%PAD%) do set "SPACES=!SPACES! "
if "%2"=="" (cls)
echo.%SPACES%%TEXT%
endlocal
goto :eof

:Righted
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%a in ('mode con: ^| find "Columns"') do set COLS=%%a
set "VER=%~1"
set LEN=0
set TEMP=%VER%
:Loop-RT
if defined TEMP (set TEMP=!TEMP:~1!
	set /a LEN+=1
	goto Loop-RT)
set /a PAD=%COLS% - %LEN%
set "SPACES="
for /l %%i in (1,1,%PAD%) do set "SPACES=!SPACES! "
echo.%SPACES%%VER%
endlocal
goto :eof

:Listing
setlocal enabledelayedexpansion
echo.  %~3
echo.
echo.    1:Да
echo.    0:Нет [по умолчанию]
echo.
set "REPLY="
set /p REPLY="Ваш выбор: "
echo.
if not "%REPLY%"=="1" (endlocal & goto :eof)

for /f "tokens=2 delims=:" %%a in ('mode con: ^| find "Columns"') do set COLS=%%a
set "TEXT=%~2"
set LEN=0
set TEMP=%TEXT%
:Loop-LS
if defined TEMP (set TEMP=!TEMP:~1!
	set /a LEN+=1
	goto Loop-LS)
set /a PAD1=(%COLS% - %LEN%) / 2
set "SPACES1="
for /l %%i in (1,1,%PAD1%) do set "SPACES1=!SPACES1!="
set /a PAD2=(%COLS% - %LEN% - %PAD1%)
set "SPACES2="
for /l %%i in (1,1,%PAD2%) do set "SPACES2=!SPACES2!="
set "SPACES3="
for /l %%i in (1,1,%COLS%) do set "SPACES3=!SPACES3!="
echo.%SPACES1%%TEXT%%SPACES2%
more "%~dp0%~1"
echo.%SPACES3%
echo.
set /p REPLY="Для продолжения нажмите ввод..."
echo.
endlocal
goto :eof

:Get-Line
setlocal enabledelayedexpansion
set "REPLY="
for /f "delims=" %%l in ('findstr /i "%~2" "%~dp0%~1" 2^>nul') do (set "REPLY=%%l" & goto Done-GL)
endlocal & set "REPLY=" & goto :eof
:Done-GL
set "REPLY=!REPLY:(bootloader) %~2=!"
endlocal & set "REPLY=%REPLY%"
goto :eof

:CopyRight
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%a in ('mode con: ^| find "Columns"') do set COLS=%%a
set "NAME=%~1"
for /f %%i in ('wmic OS Get LocalDateTime ^| find "."') do set TEMP=%%i
set TEMP=!TEMP:~0,4!
if "%TEMP%" GTR "%~2" (set "YEAR=%~2-%TEMP%") else (set "YEAR=%~2")
set LEN=0
set TEMP=%NAME%%YEAR%
:Loop-CR
if defined TEMP (set TEMP=!TEMP:~1!
	set /a LEN+=1
	goto Loop-CR)
set /a PAD=%COLS% - %LEN% - 24
set "SPACES="
for /l %%i in (1,1,%PAD%) do set "SPACES=!SPACES! "
echo. %NAME%%SPACES%© %YEAR% rino Software Lab.
timeout /t 2 >nul
endlocal
goto :eof
