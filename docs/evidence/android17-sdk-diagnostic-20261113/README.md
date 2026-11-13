# Android 17 SDK package diagnosis

Base Host: `e3d161cb2f79b732ac2dbafc2764b151247f018b`.
Dedicated push branch: `chatgpt/lumo-android17-sdk-diagnostic-20261113`.

The original Studio API37 job `132049288677` in run `43461547945` stopped at
`sdkmanager --install 'build-tools;37.0.0' platform-tools 'platforms;android-37'`
with `Failed to find package 'platforms;android-37'`. It did not start an emulator
or install the candidate APK. Its SDK-manager version and available package list
were not recorded.

This independent workflow inventories the current Ubuntu runner. It records the
effective SDK-manager path, actual version output, original `source.properties`,
Java version, source commit/tree/parents and runner environment identifiers. It
preserves complete, unfiltered SDK catalogs for channels 0 and 3, including each
command's stdout, stderr, actual exit code, elapsed time and timeout state.

It then compares the existing tools with Google's command-line-tools archive
`commandlinetools-linux-15859902_latest.zip`, executing that archive only after
SHA256 equals `4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583`.
The fresh toolset and its Android user directory are isolated in runner temporary
storage. The ZIP's identity and contents listing are archived; the downloaded
tool binaries are not included in the evidence artifact.

Official source references supplied for this diagnosis:

- <https://developer.android.com/studio/>
- <https://developer.android.com/about/versions/17/setup-sdk>
- <https://github.com/ReactiveCircus/android-emulator-runner/blob/a421e43855164a8197daf9d8d40fe71c6996bb0d/src/sdk-installer.ts>

The observed emulator action passes its channel argument to emulator and system
image installation, but not to the preceding platform/build-tools installation.
Its separate `system-image-api-level` input may become relevant after real package
names are established. This inventory does not select or install such an image.

No SDK platform, emulator, system image or APK is installed. No release is created.
`INVENTORY_COMPLETE` means only that the diagnostic commands succeeded. It does
not assert API37 availability or Android17 runtime compatibility. The Studio
SDK37/release17 checks and frozen APK/native source remain unchanged.

Failures and timeouts remain visible in `summary.json` and fail the job while
the artifact upload still runs. Package-name matches are only a navigation aid;
the complete catalogs and their installed/available headings remain authoritative.
