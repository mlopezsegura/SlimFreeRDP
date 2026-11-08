@echo off
rem SlimFreeRDP: minimal, fully static wfreerdp.exe (headless use) with a minimal OpenSSL.
rem
rem Usage:  build.cmd <freerdp-src> <openssl-src> <work-dir>
rem   freerdp-src  extracted freerdp-3.33.0.tar.gz (patches\*.patch are applied here)
rem   openssl-src  extracted openssl-3.6.5.tar.gz
rem   work-dir     build directory; the result is <work-dir>\out\wfreerdp.exe
rem
rem Needs: Visual Studio 2022/2026 (C++ workload, with CMake and Ninja),
rem        Strawberry Perl and NASM on PATH.
setlocal
set FRDP=%~f1
set OSSL_SRC=%~f2
set WORK=%~f3
if "%WORK%"=="" (echo usage: build.cmd ^<freerdp-src^> ^<openssl-src^> ^<work-dir^> & exit /b 2)
set ROOT=%~dp0
set OSSL=%WORK%\openssl

for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set VS=%%i
call "%VS%\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
rem English compiler output: a localized /showIncludes prefix breaks Ninja's RC step
set VSLANG=1033

rem ---- 1. patches ------------------------------------------------------------
for %%p in ("%ROOT%patches\*.patch") do (
  git -C "%FRDP%" apply --check "%%~fp" 2>nul && git -C "%FRDP%" apply "%%~fp" || echo [patch] %%~nxp already applied or does not apply
)

rem ---- 2. OpenSSL: TLS 1.2/1.3, RSA/EC/X25519/DH, AES/SHA/DES only -------------
rem RC4 and MD4 (NTLM) come from FreeRDP's internal implementations, so no legacy provider.
pushd "%OSSL_SRC%" || exit /b 1
perl Configure VC-WIN64A --prefix="%OSSL%" --openssldir="%OSSL%\ssl" --release ^
 no-shared no-module no-legacy no-engine no-dso no-dynamic-engine no-apps no-tests no-docs no-unit-test ^
 no-capieng no-padlockeng no-loadereng no-winstore no-autoload-config no-ui-console no-async no-multiblock ^
 no-quic no-dtls no-dgram no-sctp no-srtp no-ssl3 no-ssl3-method no-psk no-srp no-nextprotoneg no-comp ^
 no-ct no-ts no-cms no-ocsp no-cmp no-http no-rfc3779 ^
 no-aria no-bf no-blake2 no-camellia no-cast no-idea no-mdc2 no-rc2 no-rc4 no-rc5 no-md4 no-rmd160 no-seed ^
 no-sm2 no-sm3 no-sm4 no-whirlpool no-gost no-ec2m no-siphash no-siv no-ocb no-scrypt no-argon2 no-cmac ^
 no-chacha no-poly1305 no-dsa no-ml-kem no-ml-dsa no-slh-dsa no-lms ^
 "-O1" "-Gw" "-FS" || exit /b 1
nmake build_libs || exit /b 1
nmake install_dev || exit /b 1
popd

rem ---- 3. FreeRDP: Windows client only, static, channels rdpsnd/audin/rdpdr --------
rem rail and encomsp are referenced unconditionally by the Windows client; rdpsnd and
rem /network:lan need rdpdr. Drive/printer/serial/parallel/smartcard stay off.
cmake -S "%FRDP%" -B "%WORK%\freerdp" -G Ninja ^
 -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_C_COMPILER=cl ^
 -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON ^
 -DCMAKE_EXE_LINKER_FLAGS="/OPT:REF /OPT:ICF" ^
 -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF ^
 -DOPENSSL_ROOT_DIR="%OSSL%" -DOPENSSL_USE_STATIC_LIBS=ON -DOPENSSL_MSVC_STATIC_RT=ON ^
 -DWITH_INTERNAL_RC4=ON -DWITH_INTERNAL_MD4=ON ^
 -DWITH_CLIENT=ON -DWITH_CLIENT_SDL=OFF -DWITH_CLIENT_WINDOWS=ON ^
 -DWITH_SERVER=OFF -DWITH_PROXY=OFF -DWITH_SHADOW=OFF -DWITH_PLATFORM_SERVER=OFF ^
 -DWITH_SAMPLE=OFF -DWITH_WINPR_TOOLS=OFF -DWITH_MANPAGES=OFF ^
 -DWITH_CCACHE=OFF -DWITH_CLANG_FORMAT=OFF -DWITH_VERBOSE_WINPR_ASSERT=OFF ^
 -DWITH_FFMPEG=OFF -DWITH_DSP_FFMPEG=OFF -DWITH_VIDEO_FFMPEG=OFF -DWITH_SWSCALE=OFF ^
 -DWITH_OPENH264=OFF -DWITH_MEDIA_FOUNDATION=OFF -DWITH_JPEG=OFF -DWITH_CAIRO=OFF ^
 -DWITH_OPUS=OFF -DWITH_FDK_AAC=OFF -DWITH_FAAD2=OFF -DWITH_FAAC=OFF -DWITH_LAME=OFF -DWITH_GSM=OFF -DWITH_SOXR=OFF ^
 -DWITH_KRB5=OFF -DWITH_AAD=OFF -DWITH_JSON_DISABLED=ON -DWITH_PKCS11=OFF -DWITH_SMARTCARD_EMULATE=OFF ^
 -DWITH_URIPARSER=OFF -DWITH_WEBVIEW=OFF -DWITH_LIBRESSL=OFF ^
 -DWITH_CHANNELS=ON -DWITH_CLIENT_CHANNELS=ON -DWITH_SERVER_CHANNELS=OFF ^
 -DCHANNEL_AUDIN=ON -DCHANNEL_RDPSND=ON -DCHANNEL_DRDYNVC=ON -DCHANNEL_RDPDR=ON -DCHANNEL_RAIL=ON -DCHANNEL_ENCOMSP=ON ^
 -DCHANNEL_AINPUT=OFF -DCHANNEL_CLIPRDR=OFF -DCHANNEL_DISP=OFF -DCHANNEL_DRIVE=OFF -DCHANNEL_ECHO=OFF ^
 -DCHANNEL_GEOMETRY=OFF -DCHANNEL_GFXREDIR=OFF -DCHANNEL_LOCATION=OFF -DCHANNEL_PARALLEL=OFF ^
 -DCHANNEL_PRINTER=OFF -DCHANNEL_RDP2TCP=OFF -DCHANNEL_RDPEAR=OFF -DCHANNEL_RDPECAM=OFF -DCHANNEL_RDPEI=OFF ^
 -DCHANNEL_RDPEMSC=OFF -DCHANNEL_RDPEWA=OFF -DCHANNEL_RDPGFX=OFF -DCHANNEL_REMDESK=OFF -DCHANNEL_SERIAL=OFF ^
 -DCHANNEL_SMARTCARD=OFF -DCHANNEL_SSHAGENT=OFF -DCHANNEL_TELEMETRY=OFF -DCHANNEL_TSMF=OFF ^
 -DCHANNEL_URBDRC=OFF -DCHANNEL_VIDEO=OFF ^
 || exit /b 1
cmake --build "%WORK%\freerdp" --target wfreerdp || exit /b 1

if not exist "%WORK%\out" mkdir "%WORK%\out"
copy /y "%WORK%\freerdp\client\Windows\cli\wfreerdp.exe" "%WORK%\out\" >nul || exit /b 1
echo Built %WORK%\out\wfreerdp.exe
