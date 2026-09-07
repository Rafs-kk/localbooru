# LocalBooru Classic UI

This fork keeps LocalBooru's local storage, tagging, collections, import, media viewing and settings behavior, but replaces its visual shell with a compact green interface inspired by art-community websites from roughly 2005–2013.

## Design goals

- Dense, information-first layout rather than modern oversized cards.
- Dark green global masthead with an integrated collection search.
- Persistent desktop browse/category rail.
- Pale sage content surfaces, bordered modules and lightly beveled controls.
- Gallery thumbnails displayed as framed artwork with captions instead of edge-to-edge square crops.
- Deviation view with a large artwork stage and a right-hand details/tag/source rail.
- Collections and settings presented as classic module panels.
- Mobile behavior remains responsive and all data stays local.

The interface is an original LocalBooru skin and does not connect to DeviantArt. This revision does include a small user-supplied sprite sheet of interface pictograms extracted from the 2010-era site; those sprites are stored locally under `assets/classic_deviantart/icons/` and are used only for the personal classic-interface recreation.

## Main implementation files

- `lib/theme/classic_deviantart.dart` – palette, theme, masthead, sidebar, panels and bevel controls.
- `lib/components/housings.dart` – desktop application chrome.
- `lib/components/image_grid_display.dart` – classic framed gallery cards.
- `lib/views/navigation/home.dart` – browse-style landing page.
- `lib/views/navigation/tag_browse.dart` – search/gallery presentation.
- `lib/views/navigation/image_view.dart` – deviation viewer and information rail.
- `lib/views/navigation/collection_list.dart` – collection gallery.
- `lib/views/settings/index.dart` – settings landing page.
- `lib/views/about.dart` – classic About page.

## Build

Use a current stable Flutter SDK that satisfies the project lockfile (Flutter 3.27+ / Dart 3.6+ recommended for this snapshot), then run:

```bash
flutter pub get
flutter analyze
flutter run -d windows
```

For a Windows release build:

```bash
flutter build windows --release
```

The executable is produced under `build/windows/x64/runner/Release/` on standard current Flutter Windows projects.

### Classic pictogram pass

The classic shell now has its own small pictogram renderer for the navigation rail, panel headers and Settings landing page. These icons use the beveled gold/olive framing and colorful, dense symbols associated with the late-2000s DeviantArt era instead of stock modern Material glyphs.

The `squares` image-counter theme was also redrawn as the default period-style counter. Existing users who previously chose another counter can preview/select `squares` again in **Settings → Overall settings → Counter**.


### 2010 masthead and Submit-page pass

The masthead now uses the tighter proportions of the late-2000s/2010 DeviantArt header, including a 24px integrated search field/button instead of two controls with mismatched vertical sizing.

The full Settings detail screen was also converted from large Material list rows/switches into bordered classic modules with the supplied period icons, compact checkboxes and smaller controls.

The image manager now presents a DeviantArt-like **Submit** page on desktop: a Create Your Deviation upload well, editable description/note, typed keyword fields, source metadata, a right-side Features module, related deviations, and a classic beveled submit action. Existing LocalBooru import, tagging, rating, related-image and save logic remains underneath the new presentation.


### Final polish notes

The classic shell now also includes:
- the user-provided pixel Syncthing and magnifying-glass icons;
- a corrected masthead search field with a full-height period-style gradient;
- an old-DeviantArt-style browse search control;
- non-overlapping external labels for tag and submission fields;
- dedicated pixel-art content-rating badges; and
- a persistent rating chooser that does not close on each selection.

### Deviation page (v4.3)

The desktop deviation page now follows the classic DeviantArt artwork-view layout rather than LocalBooru's original split inspector. Artwork occupies the main column; title, local byline, description and searchable keywords sit underneath it. A narrower right rail contains LocalBooru-specific equivalents of the old site sidebar: edit/image actions, related deviations, collections the image is featured in, content rating, sources and file details.

Classic raster icons are intentionally rendered with smooth interpolation now. The archived DeviantArt UI generally displayed its tiny raster artwork with browser-style smoothing rather than hard nearest-neighbour scaling.

### v4.4 polish

The classic masthead now uses the user-designed LocalBooru logo. Home no longer marks Browse as the active top-level section, and the artwork chooser treats barrier dismissal as cancellation instead of falling through to the native file picker.

Frequently used actions now share a dedicated late-2000s-style pixel badge family (Prev/Next, Edit, image actions, Submit, Delete and Compress), with Flutter's medium filtering preserving the softened classic-web appearance at display size.

### v4.7 classic forms, search, collections and dialogs

The Browse autocomplete now uses the dedicated user-supplied tag-category icons while retaining LocalBooru's existing `SearchAnchor`, controller, filtering, metatag and search behavior.

Settings back navigation now preserves actual route history where possible and falls back to logical parent pages for direct/deep navigation. Tag Types uses a compact early-web forum/table treatment, collection management uses a Favourites-style folder editor, and collection creation plus the application's other modal dialogs share one sage bordered classic dialog frame.

The application now intentionally exposes one fixed Classic DeviantArt theme instead of a theme selector that barely changed the heavily customized interface. The masthead search has also been brought closer to the old DeviantArt treatment: pale inset field, dark green Search segment and lime label.

### v4.8 unified settings pages

The regular Settings routes now reuse the visual organization established by the classic Change booru screen. A narrow settings navigation column sits beside compact bordered content modules, with Current booru settings and All settings highlighted according to the active route. Nested Tag Types, Collections and Overall Settings remain functionally unchanged but inherit the same surrounding settings context.

The design is intentionally modeled on the structure of late-2000s/early-2010s DeviantArt settings pages: persistent category navigation, pale sage panels, dense rows, restrained borders and minimal decorative whitespace. LocalBooru's existing routes, persistence, collection maintenance and update-check behavior remain intact.

### v4.8.2 settings and bulk-submit alignment

When a collection is already open, **Change booru** is now hosted by the regular Settings shell instead of the standalone first-run shell. This gives Current booru settings, Change booru and All settings one shared masthead, page-header, 205px navigation rail and 1180px centered content frame. The standalone `/setbooru` screen remains available for first-run setup before LocalBooru has a usable collection.

Bulk submission now follows the same visual logic as the classic single-image Submit page: a compact yellow status strip, a pale-green artwork review well, and a narrow Features column for batch relations, compression and collection creation. The Bulk Adding drawer uses the same sage panels, bordered rows, small raster icons and dense typography as the rest of the classic UI. The underlying LocalBooru save/import/edit operations are reused rather than replaced.
### v4.8.3 classic action-menu polish

Browse/search galleries and collection galleries now use the supplied classic **Add image** and menu artwork instead of flat Material `+`/overflow glyphs. Deviation pages use a separate supplied **Deviation actions** icon, while generic Settings pages use the new supplied Settings icon. Popup action menus were deliberately kept on Flutter's existing `PopupMenuButton`/`showMenu` behavior and only restyled/illustrated, minimizing risk to navigation and destructive-action handling. Their denser sage panel, bordered shell, compact rows and small action pictograms now align more closely with the already-stable classic Search Tags suggestion panel.

### v4.8.4 collection-arrow and icon-audit polish

The small collection navigator on Deviation pages now uses the user-supplied left/right arrow artwork rather than Material `arrow_back`/`arrow_forward` glyphs. The same tiny arrows are also used for classic settings/back-navigation affordances where a flat Material chevron was still visible. A follow-up audit replaced the remaining conspicuous modern action glyphs that could appear in the classic shell (selection edit/close, zoom actions/menu, Syncthing external-link affordance, folder permissions, drag/drop upload overlay, missing-art placeholders and fallback drawer/search actions) with existing classic assets or framed classic badges. This pass intentionally leaves the underlying callbacks and route/data logic untouched.
### Routing import regression fix (v4.8.5)
The classic route action icons are defined in `lib/theme/classic_deviantart.dart`; route code that instantiates them must import that library directly. The icon audit now includes an import-coverage check for shared `Classic*` widgets.
### v4.9.1 keyboard clipboard behavior

The global image-paste shortcut now yields to Flutter's built-in text-editing shortcuts whenever an editable text control has focus. On Windows, **Ctrl+C** and **Ctrl+V** therefore work normally in submission metadata, tag fields, source URLs, masthead search, Browse search and Search Tags fields. When no text editor is focused, **Ctrl+V** still retains LocalBooru's image-from-clipboard convenience, but only when the clipboard actually contains a supported image.
### v4.9.2 related-deviation editor layout

The Related Deviations editor in Submit/Edit mode now uses a content-sized vertical stack instead of a fixed-height horizontal strip. Each selected deviation remains an 80×80 removable preview, but every additional relation increases the panel height rather than extending beyond the right edge. The surrounding Submit/Edit page is already vertically scrollable, so this avoids adding a second nested scroll interaction. The Deviation page's separate **More from LocalBooru** gallery remains horizontal and scrollable.

