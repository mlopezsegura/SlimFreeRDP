# Third-party notices

The `wfreerdp.exe` published in Releases is built from unmodified upstream sources plus the
patches in `patches/`:

| Component | Version | License | Source |
|---|---|---|---|
| FreeRDP | 3.33.0 | Apache-2.0 | https://github.com/FreeRDP/FreeRDP/releases/tag/3.33.0 |
| OpenSSL | 3.6.5 | Apache-2.0 | https://github.com/openssl/openssl/releases/tag/openssl-3.6.5 |

`patches/0001-audin-winmm-choose-microphone.patch` modifies FreeRDP's
`channels/audin/client/winmm/audin_winmm.c`.
