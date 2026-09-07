# LocalBooru Classic DA

<p align="center">
  <img src="assets/promotional/classic%20DA%20layout.png" alt="LocalBooru Classic DA interface" />
</p>

<p align="center">
  <strong>Your personal booru collection... now with a nostalgic look!</strong>
</p>

<p align="center">
  <a href="https://github.com/Rafs-kk/localbooru/releases/latest">
    <img src="https://img.shields.io/github/v/release/Rafs-kk/localbooru?display_name=tag&style=for-the-badge&color=9dbb18" alt="Latest release" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/Rafs-kk/localbooru?style=for-the-badge" alt="GPL-3.0 license" />
  </a>
</p>

**LocalBooru Classic DA** is a visual and usability-focused fork of [LocalBooru](https://github.com/resucutie/localbooru), redesigned around the compact interface style associated with late-2000s and early-2010s art-community websites.

It keeps LocalBooru's core purpose intact: organize, tag, search and browse a personal art collection directly from local storage, without needing to host a server.

> **Classic DA v1.0** is based on **LocalBooru 1.6.1 "Kuroodod"**.

## What this fork changes

The LocalBooru workflow is still here, but most of the desktop interface has been reworked to feel more cohesive, compact and accurate.

- Classic green masthead, navigation and beveled controls
- Framed gallery thumbnails with titles and tag summaries
- DeviantArt-inspired deviation pages with artwork, metadata and side panels
- Redesigned Browse, Collections, Submit and Settings screens
- Classic-styled dialogs, search suggestions, context menus and action buttons
- Typed tags for General, Artist, Character, Copyright and Species
- Tag autocomplete, automatic tag suggestions and tag search
- Collections, related deviations, source links and content ratings
- Bulk submission and clipboard image import
- Normal `Ctrl+C` / `Ctrl+V` behavior inside editable text fields
- Snappier navigation with modern zoom-style page transitions removed
- Numerous navigation, tagging, source, related-image and stability fixes made during the redesign

For a more technical overview of the interface work, see [CLASSIC_UI.md](CLASSIC_UI.md).

## Download

### Windows x64

Download the latest build from:

**[LocalBooru Classic DA Releases](https://github.com/Rafs-kk/localbooru/releases/latest)**

The current Classic DA release is distributed as a portable Windows x64 ZIP. Extract it somewhere convenient and run `localbooru.exe`.

If Windows reports missing Microsoft C/C++ runtime libraries, install the latest supported **Microsoft Visual C++ Redistributable x64**:

**[Download VC++ Redistributable x64](https://aka.ms/vc14/vc_redist.x64.exe)**

### Other platforms

Upstream LocalBooru supports Windows, Android and Linux. This fork retains the cross-platform Flutter project structure, but **Classic DA prebuilt releases are currently provided for Windows x64 only**.

If you build the fork on another platform, reports and fixes are welcome.

## Getting started

1. Launch LocalBooru Classic DA.
2. Select an existing booru folder or create a new one.
3. Use **Submit** to add artwork from disk or the clipboard.
4. Add or generate tags, choose a content rating, and optionally add sources or related deviations.
5. Use **Browse** to search your collection by tags.
6. Use **Collections** to group related artwork together.

Your collection and its metadata remain in the local booru directory you choose.

## Building from source

You will need a recent stable [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with the project lockfile.

```bash
git clone https://github.com/Rafs-kk/localbooru.git
cd localbooru

flutter pub get
flutter analyze
flutter run -d windows
```

To create a Windows release build:

```bash
flutter build windows --release
```

The resulting files are normally placed under:

```text
build/windows/x64/runner/Release/
```

## Credits

- **[LocalBooru](https://github.com/resucutie/localbooru)** — original application by resucutie and contributors
- **[Rafs-kk/localbooru](https://github.com/Rafs-kk/localbooru)** — Classic DA interface fork and additional fixes
- Classic interface inspiration comes from the visual language of DeviantArt during the late 2000s and early 2010s

## License

This project remains licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for the full license text.
