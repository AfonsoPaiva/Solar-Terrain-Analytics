@echo off

:MENU
cls
echo ==============================================
echo   Solar Terrain Analytics - Menu Principal
echo ==============================================
echo   [1] Iniciar Backend (Spring Boot)
echo   [2] Iniciar Frontend Web (Flutter - Chrome)
echo   [3] Build APK (release)
echo   [4] Deploy APK no Telemovel
echo   [5] Limpar builds (backend + flutter)
echo   [6] Sair
echo ==============================================
set /p OPCAO=Escolha uma opcao: 

if "%OPCAO%"=="1" goto START_BACKEND
if "%OPCAO%"=="2" goto START_WEB
if "%OPCAO%"=="3" goto BUILD_APK
if "%OPCAO%"=="4" goto DEPLOY_APK
if "%OPCAO%"=="5" goto CLEAN_ALL
if "%OPCAO%"=="6" goto FIM
echo Opcao invalida.
pause
goto MENU

:START_BACKEND
echo Iniciando backend...
start "Backend" cmd /k "cd backend\analytics-backend && .\mvnw.cmd spring-boot:run"
echo Backend iniciado em nova janela.
pause
goto MENU

:START_WEB
echo Iniciando frontend web...
start "Frontend Web" cmd /k "cd frontend\flutter_solar_terrain_analytics && flutter run -d chrome"
echo Frontend web iniciado em nova janela.
pause
goto MENU

:BUILD_APK
echo Iniciando build APK...
pushd frontend\flutter_solar_terrain_analytics
if errorlevel 1 (
  echo ERRO: Nao conseguiu entrar na pasta do Flutter
  pause
  goto MENU
)
echo Fazendo build do APK (sem limpar dependencias)...
flutter build apk --release
echo Build Flutter concluido!
echo APK gerado em: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Para instalar no telemovel, use a opcao 4 do menu.
popd
pause
goto MENU

:DEPLOY_APK

:DEPLOY_APK
echo ========== DEPLOY APK NO TELEMOVEL ==========
pushd frontend\flutter_solar_terrain_analytics
setlocal EnableDelayedExpansion
echo Verificando se APK existe...
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
  echo ERRO: APK nao encontrado!
  echo Execute primeiro a opcao 3 para gerar o APK.
  echo.
  echo Tentando localizar qualquer APK...
  dir /b /s "build\*.apk" 2>nul
  pause
  popd
  goto MENU
)
echo APK encontrado: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Verificando dispositivo conectado...
adb devices
echo.
:RETRY_INSTALL
adb devices | find "device" >nul
if errorlevel 1 (
  echo AVISO: Nenhum dispositivo Android detectado via adb
  echo.
  echo Para conectar o dispositivo:
  echo 1. Conecte via cabo USB
  echo 2. Ative Opcoes de desenvolvedor no Android
  echo 3. Ative Depuracao USB
  echo 4. Aceite o popup de autorizacao no telemovel
  echo.
  set /p RETRY=Pressione Enter apos conectar dispositivo ou S para tentar novamente: 
  if /i "!RETRY!"=="S" goto RETRY_INSTALL
  echo Tentando instalar mesmo assim...
)

echo Removendo versao anterior da app (se existir)...
adb uninstall com.example.flutter_solar_terrain_analytics >nul 2>&1

echo APK encontrado! Instalando nova versao no telemovel...
echo Comando: adb install "build\app\outputs\flutter-apk\app-release.apk"
adb install "build\app\outputs\flutter-apk\app-release.apk"
if errorlevel 1 (
  echo.
  echo ERRO: Instalacao via adb falhou!
  echo.
  echo Opcoes alternativas:
  echo 1. Copiar APK manualmente para o telemovel
  echo 2. Enviar por email/WhatsApp e instalar
  echo 3. Usar cabo USB diferente
  echo.
  echo Localizacao do APK: %cd%\build\app\outputs\flutter-apk\app-release.apk
  echo.
  set /p RETRY_AGAIN=Tentar instalar novamente? (S/N): 
  if /i "!RETRY_AGAIN!"=="S" goto RETRY_INSTALL
) else (
  echo.
  echo ========== SUCESSO! ==========
  echo APK instalado com sucesso no telemovel!
  echo A app 'Solar Terrain Analytics' deve aparecer no menu do dispositivo.
  echo.
)
popd
pause
goto MENU

:CLEAN_ALL
echo Limpando builds (mantendo dependencias)...
pushd backend\analytics-backend
echo Limpando backend Maven...
.\mvnw.cmd clean >nul 2>&1
popd
pushd frontend\flutter_solar_terrain_analytics
echo Limpando apenas build Flutter (mantendo .dart_tool e dependencias)...
if exist build rmdir /s /q build
popd
echo Limpeza concluida.
pause
goto MENU

:FIM
echo Saindo...
exit /b 0
