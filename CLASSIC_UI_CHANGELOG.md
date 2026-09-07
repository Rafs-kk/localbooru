## v4.9.3 - Classic clear-selection icon
- Replaced the flat text `×` used by the Browse multi-selection toolbar with the user-supplied classic X artwork.
- Kept the existing clear-selection callback and selection-state logic unchanged; this pass only swaps the visual glyph through `ClassicCustomIcon`.
- Added the icon as `assets/classic_deviantart/custom/clear_selection.png`, which is already covered by the project's existing custom-asset directory declaration.

## v4.9.2 - Related deviations vertical editor layout

- Reworked the **Related Deviations** editor from a fixed-height horizontal `ListView` into a content-sized vertical list. Related thumbnails now stack downward instead of disappearing beyond the right edge of the narrow Submit/Edit side panel.
- Removed the hard-coded 80px container height from the editor. The enclosing classic panel now grows naturally as additional related deviations are selected, so every entry remains visible without requiring horizontal mouse-drag scrolling.
- Kept the existing 80x80 thumbnail renderer, remove-on-click behavior, relation IDs, selection dialog, persistence callbacks and dedicated **Add deviation** button unchanged.
- Left the Deviation page's **More from LocalBooru** strip horizontal and scrollable by design; that area has enough viewing context for a gallery-style carousel and already supports horizontal interaction.
- This is a layout-only pass: no related-deviation persistence, relation symmetry, image loading, route handling, deletion behavior or booru metadata logic was modified.

## v4.9.1 - Text clipboard shortcut compatibility

- Fixed the global image-paste shortcut intercepting **Ctrl+V** while a LocalBooru text editor has focus. Focused `TextField`/`TextFormField`/`SearchBar`/autocomplete editors now keep Flutter's normal desktop text-editing shortcuts, so keyboard copy/paste works in submission notes, typed tag fields, source URL fields, the masthead search and Browse/search controls.
- Kept LocalBooru's convenient image-paste behavior outside text editors: pressing **Ctrl+V** with an image on the clipboard can still open/add it through the existing submission flow.
- Text-only clipboard contents no longer trigger the image submission route when Ctrl+V is pressed outside a text field. This also prevents the empty-image-list path that could previously reach image-manager callbacks.
- Hardened clipboard probing against formats disappearing/changing between detection and read; failed/non-image clipboard reads now quietly fall through instead of surfacing an asynchronous exception.
- No tag parsing, source persistence, search semantics, image storage, routing destinations or visual styling were changed in this pass.

## v4.9.0 - Classic add buttons and booru-settings identity

- Restyled the **Sources → Add source** action as the same beveled, bordered push-button language used throughout the classic interface, while preserving the source-list callback and scrolling behavior.
- Replaced the flat **Related Deviations** plus control with a compact classic **Add deviation** bevel button using the existing dedicated related/source plus glyph.
- Added the supplied old-DeviantArt user/settings icon as `booru_settings.png` and scoped it to **Current booru settings** / **Current booru**, keeping the general Settings icon reserved for application-wide settings.
- Added a `hasClients` guard before auto-scrolling a newly added source field, avoiding a possible controller access race without changing source persistence.
- No booru data model, source persistence, related-deviation selection logic, routing, or destructive actions were changed in this pass.

## v4.8.6 - Submit/collection icon polish

- Restored the classic DA green upload-arrow sprite for **Select a file** and **Add Deviations**.
- Added the supplied dedicated green plus glyph exclusively to **Related Deviations** and **Sources** add actions.
- Replaced the **Sources** panel header glyph with the supplied classic DeviantART book icon.
- Replaced the source-row minus control with the existing classic trash/delete action icon.
- Kept the changes asset-only/presentation-only so submission, collection, and source-list behavior remains unchanged.

## v4.8.5 — Routing classic-icon compile fix

- Fixed the Windows/Dart build regression introduced by the classic icon audit.
- `lib/routing.dart` now directly imports `theme/classic_deviantart.dart`, which defines `ClassicCustomIcon` and `ClassicActionIcon`.
- This resolves the analyzer/compiler errors at the search and collection routes without changing their navigation behavior.
- Audited every Dart file that references the shared `Classic*` widgets to verify the defining theme library is imported.

## v4.8.4 - Collection arrows and classic icon audit
- Replaced the flat Material left/right collection-cycling arrows on Deviation pages with the newly supplied 13px classic arrow artwork. Disabled Prev/Next behavior is unchanged because the same `IconButton` callbacks and null-state rules are preserved.
- Added a small reusable `ClassicNavArrow` wrapper and reused the supplied right arrow for Settings-row navigation chevrons and the supplied left arrow for the shared safe-back control, eliminating two more conspicuously modern navigation glyphs without changing routing behavior.
- Replaced the remaining obvious flat action glyphs in selection mode, the image zoom view, compact masthead navigation, Syncthing's external-link affordance, the permissions folder action, and drag/drop upload overlay with existing classic LocalBooru/DA-era assets or framed classic badges.
- Replaced modern missing-image and selected-state gallery glyphs with classic artwork/text marks, and updated mobile/fallback drawers/search controls to use the same period-style asset set as the desktop shell.
- The new arrow assets live at `assets/classic_deviantart/custom/nav_left.png` and `nav_right.png`; they are rendered with medium filtering/antialiasing to match the rest of the softened classic raster artwork.
- No collection paging, search, image-management, persistence, routing callbacks, or destructive actions were changed in this pass.

## v4.8.3 - Classic gallery action menus and supplied navigation icons
- Replaced the flat **Add image** glyph used by Browse/search and collection galleries with the supplied `add_image.png` artwork, without changing the existing routes or image-manager handlers.
- Replaced the generic three-dot gallery/collection menu trigger with the supplied `menu.png`, and the Deviation-page actions trigger with the supplied `image_actions.png`.
- Tightened the classic popup-menu surface (smaller radius, denser type and lower elevation) and added period-style icons to Refresh, booru location, image open/copy/share, edit and delete entries so action menus visually follow the existing Search Tags suggestion panel instead of Material's default menu treatment.
- Replaced the generic Settings identity artwork with the supplied `settings.png` on Settings-shell/application settings headers and the Overall settings entry, while preserving task-specific icons such as Tag Types, Collections and Save Changes.
- No booru persistence, search semantics, collection membership, image deletion, sharing, clipboard, file opening or navigation callbacks were changed in this pass.

## v4.7.4 — submission tag autocomplete fix
- Fixed image-submission tag suggestions replacing the entire tag field when a suggestion was chosen. RawAutocomplete normally writes `displayStringForOption` into the whole controller before calling `onSelected`; TagField now restores the complete tag list and replaces only the active partial token.
- Suggestion selection now preserves existing tags for mouse and keyboard selection and explicitly notifies the image form so the completed tag is persisted immediately.
- Suggestions now use the token at the caret rather than assuming the final space-delimited token, and already-present tags are excluded from completion candidates.
- Normalized tag serialization/validation to ignore repeated whitespace and duplicate tags, preventing empty-token overlap false positives.
- Automatic tag generation now merges results without duplicating tags that were already entered manually.
- TagField now disposes its FocusNode and any internally-owned TextEditingController.

## v4.7.3
- Restored the classic DA-era sprite for the **Automatic tags** label.
- Kept the custom `generate_tags.png` artwork scoped to **Generate tags** actions only.
## v4.7.1 – build hotfix

- Fixed the `const_with_non_const` compile error in `lib/components/search_tag.dart` introduced by the v4.7 classic search-results header.
- The header contained a `const Row` with `Image.asset(...)`; `Image.asset` is not a const constructor, so the enclosing Row can't be a const expression. The Row is now non-const while the static child widgets remain otherwise unchanged.
- No search behavior or v4.7 visual changes were altered by this hotfix.

## v4.5 – final navigation/search polish

- Removed the redundant Back arrow from the primary Deviation page; `All` remains the gallery-return action.
- Fixed masthead searches performed while already on Browse by refreshing `GalleryViewer` when its route/query configuration changes.
- Kept the Browse search text synchronized when the route query changes.
- Added a classic custom icon for New Collection/Create a collection.
- Replaced About-page GitHub, Discord and Liberapay glyphs with the supplied classic-style PNGs.
- Pointed the GitHub project link to `Rafs-kk/localbooru`.

# Classic UI change summary

The classic UI conversion is intentionally concentrated in presentation-layer code so LocalBooru's booru data model and storage routines remain unchanged.

## Added
- `lib/theme/classic_deviantart.dart`
- `CLASSIC_UI.md`
- `CLASSIC_UI_CHANGELOG.md`

## Reworked
- `lib/main.dart` — installs the classic green light/dark themes.
- `lib/components/housings.dart` — adds a classic masthead and browse sidebar on desktop.
- `lib/components/image_grid_display.dart` — framed, captioned deviation thumbnails.
- `lib/views/navigation/home.dart` — browse-style landing page with gallery, search, tags and library summary.
- `lib/views/navigation/tag_browse.dart` — compact classic search/gallery chrome.
- `lib/views/navigation/image_view.dart` — large deviation stage and right-hand metadata/source/tag modules.
- `lib/views/navigation/collection_list.dart` — classic collection gallery.
- `lib/views/settings/index.dart` — module-based settings landing page.
- `lib/views/about.dart` — classic About/project links page.
- `README.md` — classic UI notice.

## Deliberately unchanged
- Booru storage format and `repoinfo.json` model.
- Importers and source parsing.
- Tag search semantics.
- Collection data model.
- File management, sharing, drag-and-drop, video playback and image-management logic.
- Platform projects (Windows/Linux/macOS/Android/iOS/web).

## Classic icon + counter refinement pass

- Replaced the modern monochrome Material glyphs used by the classic navigation and panel headers with an original set of tiny, colorful, beveled pictograms drawn in Flutter. The set covers deviations, collections, submission, folders, settings, refresh/update, info, tags, counters, notes and links.
- Updated the Settings landing page to use the same period-style icon badges instead of flat teal Material icons.
- Replaced the built-in `squares` counter artwork with a LocalBooru Classic counter inspired by late-2000s web badges: cream/gold bevels, sage-green faces and segmented teal digits. The preference key remains `squares`, so no settings migration is needed.
- The new pictograms are original LocalBooru assets/code rather than copied DeviantArt binaries. They intentionally mirror the visual vocabulary of the 2008–2010 interface while keeping the project self-contained.

## 2010 icon / masthead / submit refinement pass

- Rebuilt the desktop masthead proportions around the compact 2008–2010 DeviantArt header: 42px bar, tighter logo spacing, and a single 24px-high integrated search control whose text field and Search button share the same baseline and outer frame.
- Replaced the previous generated classic pictograms with the user's supplied 2010-era DeviantArt icon strip wherever there is a sensible semantic match. The strip is split into 46 transparent local PNG assets under `assets/classic_deviantart/icons/` and rendered with nearest-neighbour filtering to preserve the pixel-art look.
- Kept the existing locally drawn badge fallback for actions that do not have a useful historical counterpart, so no modern monochrome Material icon has to be exposed merely because a matching archived icon was unavailable.
- Reworked the Settings detail screen into compact bordered modules with period-style pictograms, checkbox-style toggles, smaller value controls, and restrained classic sliders. Booru/tag/collection settings also use the archived pictograms for their primary actions.
- Rebuilt the image submission flow around the classic DeviantArt Submit page composition: pale page header, "Create Your Deviation" area, large drag/drop file well, description/note field, keyword/tag module, source module, right-hand Features panel, related deviations panel, and classic Submit action.
- The submit form now exposes LocalBooru's existing `note` metadata as an editable Description / note field. No storage format changes were required.


## Final polish pass: search, fields, ratings, and Syncthing

- Replaced the Current Booru Settings Syncthing glyph with the user's new 24px pixel-art Syncthing mark, rendered with nearest-neighbour filtering.
- Rebuilt the masthead search field background so it is painted by the classic shell rather than Material's filled input decoration. This removes the flat lower-half band and vertically centers the text against the Search button.
- Added a dedicated classic browse/search control modeled after the 2008–2010 DeviantArt browse bar. The user's green pixel search glyph is used only where a magnifying-glass affordance is shown.
- Eliminated floating-label collisions in LocalBooru's tag and submission fields. TagField now renders its label outside the input border, and the remaining named form fields were migrated to the same classic label treatment.
- Added five dedicated pixel-art rating badges (`none`, `safe`, `questionable`, `explicit`, `borderline`) so ratings are visually distinct rather than sharing one generic star badge.
- Changed the rating chooser to keep itself open while ratings are selected. Changes are applied immediately; the dialog closes only through the Close button or by dismissing the modal barrier.

## v4.1 stability fixes
- Fixed the desktop deviation details rail creating invalid `BoxConstraints` (`370 <= width <= 369`) after its border consumed one pixel.
- Fixed Submit/Edit remaining stuck on `Saving...` when opened from masthead navigation: successful saves now navigate explicitly to the saved deviation (or Browse for multi-submit) instead of blindly popping a route that may not exist.
- Added save error recovery so a failed write re-enables the submit button and surfaces the error in a snackbar.
- Reworked the `/home` data load to read `repoinfo.json` once and derive recent images, tag counts, collection count and totals from one snapshot, avoiding redundant Windows file I/O and duplicate refresh notifications.
- Added a recoverable Home load error panel with Retry instead of escalating repository read errors into the app-wide red error screen.

## v4.2 runtime stability fix
- Fixed the Home/Browse landing-page crash that only occurred once the collection contained at least one deviation.
- Root cause: `SliverPadding.sliver` contained `SharedPreferencesBuilder`; its loading state is a normal box (`Center`) rather than a sliver. Flutter therefore received a `RenderPositionedBox`/`RenderPhysicalModel` where `RenderSliverPadding` requires `RenderSliver`.
- Home now resolves grid preferences before constructing the scroll view, so `SliverPadding` always receives `SliverRepoGrid` directly.
- Converted `ClassicPanel` from an opaque decorated `Container` to a real `Material` surface. This fixes Flutter 3.44+ debug assertions that `ListTile` ink/background effects are hidden by an intermediate `DecoratedBox`.
- Kept Submit as push-style navigation in the mobile fallback drawer for consistency with the save flow.

## v4.3 — Classic deviation page pass

- Rebuilt the desktop deviation viewer around the late-2000s/2010-era DeviantArt composition:
  - compact `Prev / All / Next` navigation strip;
  - artwork-first main column;
  - title/LocalBooru byline and metadata directly below the artwork;
  - description presented as the main page content instead of a sidebar card;
  - open, narrow right rail for actions, related deviations, collections, rating, sources, and file details.
- Replaced the colored tag-pill presentation on deviation pages with understated inline blue keyword links, grouped by LocalBooru tag type.
- Added a `Featured in:` area backed by the image's real LocalBooru collections.
- Preserved Edit, share/copy/open, source, related-image, rating, detail, context-menu, drag/drop, zoom and collection functionality.
- Switched classic raster UI assets from nearest-neighbour sampling to Flutter's medium filtering with antialiasing for the softer look used by classic DeviantArt.
  - Applies to the supplied 2010-era sprite icons, custom search icon, custom Syncthing icon and classic rating badges.
- Kept the v4.2 home-page sliver crash and ListTile/Material fixes intact.

## v4.4 — Navigation, picker and action-icon polish

- The masthead `Browse` tab is now highlighted only on `/search`; the Home landing page no longer makes Browse look pressed.
- Fixed the Choose artwork dialog so dismissing it by clicking the modal barrier (or otherwise returning `null`) simply closes the chooser. The file picker opens only after explicitly selecting **Select a file**.
- Replaced the generated LB/text masthead mark with the user-provided classic LocalBooru logo asset.
- Added a cohesive set of small gold-framed pixel action badges under `assets/classic_deviantart/actions/` for Prev, All, Next, Edit, Open/Copy/Share, Submit, Delete and Compress.
- Updated deviation navigation/actions, Submit/Save Changes, upload buttons, collection deletion, image-management deletion, related-image removal and compression controls to use the new badges.
- The main deviation page now exposes only one Edit control: the right-rail **Edit Deviation** button. The top app-bar Edit button and overflow edit entry are suppressed on that page while remaining available on other image-view/edit contexts.

## v4.6 — Classic search suggestion view

- Restyled the Browse tag-search suggestion route without changing LocalBooru's `SearchAnchor`, `SearchController`, tag filtering, metatag insertion, or search semantics.
- Replaced the large Material-style rounded search surface with a compact sage/green bordered view, short classic header, restrained shadow, and late-2000s-style list treatment.
- Added classic beveled Close/Clear/Search controls to the search view header; the magnifying-glass action continues to use the supplied classic search artwork.
- Replaced Material `ListTile` suggestion rows in the desktop classic search with compact old-web rows using classic DeviantArt-era sprites, blue link-style tag names, type labels, counts, separators, and a subdued hover highlight.
- Kept the non-classic/mobile SearchTagBox presentation untouched.

## v4.7 — Classic forms, collections and navigation reliability

- Replaced the Browse search-suggestion category icons with the user's dedicated `search_option`, `artist`, `character`, `copyright`, `species` and `general` artwork while preserving the existing search controller and suggestion semantics.
- Added a safe back-navigation helper for classic routes. Settings, nested settings, image-note views and gallery back buttons now pop when a real history entry exists and otherwise navigate to a sensible parent instead of silently doing nothing.
- Reworked Tag Types into an old forum/table-style management screen inspired by early DeviantArt: compact section header, bordered rows, category artwork, descriptions and dedicated tag-entry cells.
- Reworked collection management into a classic Favourites-style folder manager with compact folder headers, inline naming, old-web image rows, reordering, Add Deviations and Delete Collection actions.
- Restyled the Create Collection, Counter, Rating, confirmation, import and selection dialogs around one shared classic dialog frame with sage headers, thin borders and beveled action buttons.
- Removed the non-functional theme chooser from the user-facing settings flow. The Classic DeviantArt interface is now the authoritative fixed theme and `MaterialApp` is kept in light/classic mode for visual consistency.
- Updated the masthead search control to more closely match classic DeviantArt: pale inset field plus a dark green Search segment with lime text rather than a bright modern action button.
- Replaced Generate Tags and Submit-header glyphs with the new user-supplied artwork.
- Added a small Favourites cue to the Collections browser while retaining LocalBooru's existing collection model and behavior.

## v4.7.2 - Tag Types page stability hotfix
- Fixed the redesigned Tag Types page rendering blank on Windows.
- Removed an unbounded-height `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` layout from inside the vertical `ListView`; the forum-style rows are now content-sized and use borders for the column divider.
- Hardened loading of `specificTags` so absent/malformed tag metadata no longer leaves the page unusable.
- Added an explicit loading state, visible error panel, and Retry action for tag metadata loading failures.

## v4.7.5 - Repository/navigation stability pass
- Fixed Home's repository-refresh callback returning a `Future` from inside `setState`; the callback is now strictly synchronous and only assigns the new future inside a block.
- Repository metadata writes are now serialized and staged through a fully-written temporary JSON file before replacing `repoinfo.json`. The latest valid metadata snapshot is also kept as `repoinfo.json.bak` for read-side recovery.
- Hardened `Booru.getRawInfo()` with short retries for transient file replacement and a last-known-good backup fallback, preventing empty/partial JSON reads from surfacing as `FormatException: Unexpected end of input`.
- Image submission now merges specific-tag classifications and image metadata into one repository write instead of issuing a write/notification for every tag category.
- Booru update notifications are coalesced and dispatched after the current Flutter frame, preventing listeners from calling `setState`/`markNeedsBuild` during the build/layout phase.
- Search-tag caches now unregister their listener on dispose, discard stale async refreshes, rebuild from scratch instead of appending duplicates after every repository update, and avoid recursively refreshing the SearchAnchor while its initial suggestion list is being built.
- Global top-level Settings/About navigation now uses declarative `go()` transitions rather than stacking sibling ShellRoutes with repeated `push()` calls; active top-bar destinations cannot be pushed repeatedly.
- The custom Flutter error screen is scrollable, so a long diagnostic stack trace no longer creates a second multi-thousand-pixel `RenderFlex` overflow on top of the original exception.
- Tag Type parsing now normalizes whitespace and duplicate entries before overlap validation and persistence.
- Booru switching now awaits the SharedPreferences path update before notifying the interface.

## v4.7.6 - Change-booru classic setup pass
- Restored an explicit Back control on the Change booru screen whenever an active collection already exists. It safely returns to Settings even when `/setbooru` was reached with declarative `go()` navigation and therefore has no route to pop.
- Rebuilt the Change booru screen as a compact classic settings page: dark LocalBooru masthead, pale section header, narrow settings navigation, bordered collection panel, current-path notice, beveled action rows and an old-web informational strip.
- Kept first-run setup safe: the Back/Settings navigation is hidden when no current booru exists, so a fresh installation cannot escape into collection-dependent settings before choosing a folder.
- Replaced the two Change-booru action glyphs with the user-provided house and folder artwork. The house is used for **Create a new one** and the folder for **Select an already existing booru**.
- Replaced the shared classic Delete action asset with the user's new trash-can-with-X artwork, so all existing delete controls that use `ClassicActionIcon('delete')` inherit the new icon automatically.
- Hardened booru creation slightly by awaiting `setBooru()` before navigating home and refusing to initialize a new collection over a folder that already contains LocalBooru metadata.
- Replaced generic snackbars on this screen with classic framed error dialogs so invalid/corrupt folder selections remain consistent with the rest of the classic interface.

## v4.8 - Unified classic settings layout
- Reworked the main **All settings** page and **Current booru settings** page around the same compact settings pattern introduced by the Change booru screen: pale page header, narrow settings navigation, centered content column, bordered sage modules and dense old-web rows.
- Added a shared Settings-side navigation inside the normal settings shell. **Current booru settings**, **Change booru**, and **All settings** now stay visually and structurally consistent while preserving their existing routes and data behavior.
- The settings shell now gives nested Tag Types, Collections and Overall Settings pages the same navigation context without changing their underlying editors or persistence logic.
- Reorganized Current booru settings into clear **Current booru**, **Elements**, and **Maintenance** modules. Tag types, Collections, Rebase, gallery hiding and Syncthing retain their existing functions.
- Replaced the gallery-hiding row's large modern switch treatment on this page with a compact checkbox-style setting while keeping the same `.nomedia` behavior. Removal now safely checks that the marker files exist before deleting them.
- Rebuilt the All settings landing page as classic module rows for Collection and Application options, preserving update checks, About navigation, Overall Settings and booru switching.
- Kept the regular LocalBooru masthead intact for settings routes to avoid routing/shell regressions; the internal page structure now mirrors the Change booru screen instead of introducing another top-level shell.

## v4.8.1 - Deviation actions and static navigation polish
- Replaced the shared classic Edit action artwork with the newly supplied icon. The Deviation-page **Edit Deviation** control and any other classic action using `ClassicActionIcon('edit')` now inherit it automatically.
- Restyled the **Open / Copy / Share Image** popup trigger to use the same 30px beveled push-button treatment as **Edit Deviation**, while preserving the existing popup menu and its open/copy/share handlers.
- Removed the modern zoom-style route motion from normal app navigation with a zero-duration `PageTransitionsTheme` for every Flutter target platform. This changes only route presentation; existing `go_router` locations, ShellRoutes, back behavior and page logic are untouched.
- Kept the dedicated image-zoom route's explicit fade intact because it is an image-viewing effect rather than a menu/section navigation transition.

## v4.8.2 - Settings alignment and classic bulk-submit pass
- Moved the in-app **Change booru** destination into the normal Settings shell as `/settings/change_booru`, so it now uses the exact same 205px Settings navigation rail, 1180px content frame, page header and standard LocalBooru masthead as **Current booru settings** and **All settings**.
- Kept the standalone `/setbooru` route intact for first-run setup, where there is no active collection and the normal application/settings shell is intentionally unavailable.
- Updated classic safe-back handling for the new Change-booru settings route so both the header arrow and **Back to Settings** return to the Settings landing page even after declarative navigation.
- Reworked the **Bulk Adding** drawer into a compact classic management panel with a sage header, section labels, bordered rows, selected-row treatment, descriptive subtext and the existing period-style image/action icons.
- Rebuilt the **Bulk Submit** manager around the early-2010s DeviantArt submission composition: yellow submit notice, a large pale-green **Create Your Deviations** review well on the left, and compact **Features / Batch options / Collection** panels on the right at desktop widths.
- Replaced modern bulk switches with classic checkbox rows and retained the existing relate-images, compress-all, create-collection, collection-name and Submit behavior.
- Added a classic **Manage images** button to the batch review well that opens the existing Bulk Adding drawer instead of introducing a second image-selection implementation.
- Hardened the bulk-image bookkeeping while touching the drawer: removing an image now removes the matching per-image error slot, imported multi-image presets receive matching validation slots, and adding files from the drawer fills the original empty placeholder before appending new pages.

## v4.8.8 - Related deviations editor refresh fix
- Fixed the Related Deviations editor strip failing to display selected deviations immediately after the selection dialog closes.
- Each related-deviation thumbnail is now given an explicit 80x80 layout box before entering the horizontal ListView. This avoids the unbounded-width interaction between the horizontal scroll view and `ImageGrid`'s fill-size thumbnail layout.
- Related/source lists are now defensively copied when loading and emitting an image preset, preventing accidental list aliasing between the form state, selector state and parent preset.
- The selected relation list is also copied on return from the picker so Cancel/Select and later edits cannot unexpectedly share mutable list state.
- Persistence and the Deviation page's existing "More from LocalBooru" related-image display are unchanged; this pass only fixes the edit-form preview/state handoff.
