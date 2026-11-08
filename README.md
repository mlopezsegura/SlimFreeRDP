# SlimFreeRDP

A minimal, fully static build of FreeRDP's `wfreerdp.exe` for headless use: a client that runs
hidden (for example in session 0 of a Windows service) only to keep an RDP session alive, with
sound and microphone redirection. Built for [OpenStreamMS](https://github.com/mlopezsegura/OpenStreamMS).

| | Size |
|---|---|
| Upstream-style static `wfreerdp.exe` 3.32.0 | 9.2 MB |
| **SlimFreeRDP 3.33.0** | **5.8 MB** |

One file, no DLLs besides the ones that ship with Windows.

## What is kept
- Windows client (`wfreerdp`), TLS 1.2/1.3 and NLA (NTLM), certificate handling.
- Channels: `rdpsnd` (sound), `audin` (microphone), `drdynvc`, `rdpdr` (required by `rdpsnd` and
  `/network:lan`, with no drive/printer/serial/parallel/smartcard devices), `rail` and `encomsp`
  (referenced unconditionally by the Windows client).
- Options in use: `/v /u /d /p /cert:ignore /w /h /bpp /scale-desktop /network:lan
  /audio-mode:redirect /sound:sys:winmm /microphone:sys:winmm,dev:<id> +disable-output /log-level`.

## What is removed
- SDL clients, server, proxy, shadow, WinPR tools, samples, tests.
- FFmpeg, H.264 (OpenH264, Media Foundation), JPEG, scaling, Opus/AAC/MP3/GSM audio codecs.
- Kerberos, Azure AD, PKCS#11, smartcard.
- Channels: clipboard, drives, printers, serial/parallel, USB, `disp`, `rdpgfx`, video, camera,
  input (`rdpei`, `ainput`) and the rest. **`/gfx` and `/rfx` are not available.**
- OpenSSL reduced to TLS 1.2/1.3 with RSA, EC, X25519, DH, AES, SHA and DES. No legacy provider:
  RC4 and MD4 for NTLM come from FreeRDP's internal implementations. No QUIC/DTLS, CMS, OCSP,
  ChaCha20, post-quantum (ML-KEM/ML-DSA/SLH-DSA) or national ciphers.

## Patch
`patches/0001-audin-winmm-choose-microphone.patch`: upstream's winmm microphone backend ignores
`dev:` and always opens the default communications microphone. With the patch,
`/microphone:sys:winmm,dev:<value>` opens the waveIn device whose Windows endpoint id
(`{0.0.1.00000000}.{guid}`) or name matches `<value>`; `default` or no match keeps the old behaviour.

## Build
Requirements: Visual Studio 2022/2026 with the C++ workload (CMake and Ninja included),
Strawberry Perl and NASM on `PATH`.

```bat
:: download and verify freerdp-3.33.0.tar.gz and openssl-3.6.5.tar.gz, then extract both
build.cmd C:\src\freerdp-3.33.0 C:\src\openssl-3.6.5 C:\build\slim
:: -> C:\build\slim\out\wfreerdp.exe
```

## License
Apache-2.0, same as FreeRDP and OpenSSL. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
