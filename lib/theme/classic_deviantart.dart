import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A deliberately compact, skeuomorphic green UI inspired by late-2000s art
/// communities.  It is original LocalBooru code/assets: the goal is to evoke
/// the era without turning the application into a branded DeviantArt client.
/// Removes modern route motion from the classic UI. The original late-2000s
/// web-style interface changes pages immediately instead of zooming between them.
/// Keeping this at ThemeData level lets normal Material/go_router pages retain
/// their existing navigation logic while only changing presentation.
class ClassicNoPageTransitionsBuilder extends PageTransitionsBuilder {
  const ClassicNoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

abstract final class ClassicPalette {
  static const Color headerTop = Color(0xFF536D60);
  static const Color headerBottom = Color(0xFF334A40);
  static const Color headerBorder = Color(0xFF24372F);
  static const Color page = Color(0xFFD4E0D0);
  static const Color pageDeep = Color(0xFFC6D4C2);
  static const Color sidebar = Color(0xFFDDE7DA);
  static const Color panel = Color(0xFFE7EEE4);
  static const Color panelAlt = Color(0xFFD5E0D2);
  static const Color panelHeader = Color(0xFFB9CBB5);
  static const Color panelHeaderDark = Color(0xFFA5BAA0);
  static const Color border = Color(0xFF9BAF99);
  static const Color borderDark = Color(0xFF778D79);
  static const Color ink = Color(0xFF23342F);
  static const Color muted = Color(0xFF65786F);
  static const Color link = Color(0xFF0B6D8D);
  static const Color accent = Color(0xFFBBD424);
  static const Color accentDark = Color(0xFF839A10);
  static const Color buttonTop = Color(0xFFF4F8F1);
  static const Color buttonBottom = Color(0xFFD6E2D2);
  static const Color selection = Color(0xFFCFDFB4);
}

ThemeData buildClassicTheme({bool dark = false}) {
  // The dark variant intentionally remains green rather than becoming a modern
  // charcoal theme. It simply deepens the same classic palette.
  final page = dark ? const Color(0xFF9FB0A0) : ClassicPalette.page;
  final panel = dark ? const Color(0xFFB6C4B4) : ClassicPalette.panel;
  final panelAlt = dark ? const Color(0xFFA8B8A7) : ClassicPalette.panelAlt;
  final ink = dark ? const Color(0xFF17241F) : ClassicPalette.ink;

  final scheme = ColorScheme.fromSeed(
    seedColor: ClassicPalette.link,
    brightness: Brightness.light,
  ).copyWith(
    primary: ClassicPalette.link,
    onPrimary: Colors.white,
    secondary: ClassicPalette.accentDark,
    onSecondary: Colors.white,
    error: const Color(0xFF9A2D20),
    onError: Colors.white,
    surface: panel,
    onSurface: ink,
    surfaceContainer: panelAlt,
    surfaceContainerLow: panel,
    surfaceContainerHigh: panelAlt,
    surfaceContainerHighest: ClassicPalette.panelHeader,
  );

  const radius = BorderRadius.all(Radius.circular(6));
  final borderSide = const BorderSide(color: ClassicPalette.border, width: 1);

  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: scheme,
    primaryColor: ClassicPalette.link,
    scaffoldBackgroundColor: page,
    canvasColor: page,
    dividerColor: ClassicPalette.border,
    disabledColor: ClassicPalette.muted.withOpacity(.45),
    splashColor: ClassicPalette.accent.withOpacity(.18),
    highlightColor: ClassicPalette.accent.withOpacity(.10),
    hoverColor: Colors.white.withOpacity(.18),
    fontFamily: 'Arial',
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ClassicNoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ClassicNoPageTransitionsBuilder(),
        TargetPlatform.iOS: ClassicNoPageTransitionsBuilder(),
        TargetPlatform.linux: ClassicNoPageTransitionsBuilder(),
        TargetPlatform.macOS: ClassicNoPageTransitionsBuilder(),
        TargetPlatform.windows: ClassicNoPageTransitionsBuilder(),
      },
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
      fontFamily: 'Arial',
    ).copyWith(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
      bodyMedium: TextStyle(fontSize: 13, color: ink),
      bodySmall: const TextStyle(fontSize: 11, color: ClassicPalette.muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: panelAlt,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 46,
      titleTextStyle: TextStyle(fontFamily: 'Arial', fontSize: 17, fontWeight: FontWeight.w700, color: ink),
      iconTheme: IconThemeData(color: ink, size: 20),
      actionsIconTheme: IconThemeData(color: ink, size: 20),
      shape: const Border(bottom: BorderSide(color: ClassicPalette.border)),
    ),
    cardTheme: CardThemeData(
      color: panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ClassicPalette.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: panel,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ClassicPalette.borderDark),
      ),
      titleTextStyle: TextStyle(fontFamily: 'Arial', fontSize: 18, fontWeight: FontWeight.w700, color: ink),
      contentTextStyle: TextStyle(fontFamily: 'Arial', fontSize: 13, color: ink),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: panel,
      surfaceTintColor: Colors.transparent,
      elevation: 5,
      menuPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: const BorderSide(color: ClassicPalette.borderDark),
      ),
      textStyle: TextStyle(fontFamily: 'Arial', fontSize: 12.5, color: ink),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: ClassicPalette.sidebar,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF5F8F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      hintStyle: const TextStyle(color: ClassicPalette.muted, fontSize: 12),
      border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(4)), borderSide: borderSide),
      enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(4)), borderSide: borderSide),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: ClassicPalette.link, width: 1.25),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 4,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      iconColor: ClassicPalette.ink,
      textColor: ClassicPalette.ink,
      titleTextStyle: TextStyle(fontFamily: 'Arial', fontSize: 13, color: ClassicPalette.ink),
      subtitleTextStyle: TextStyle(fontFamily: 'Arial', fontSize: 11, color: ClassicPalette.muted),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ClassicPalette.headerBottom,
        border: Border.all(color: ClassicPalette.headerBorder),
        borderRadius: BorderRadius.circular(3),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ClassicPalette.link,
        textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: ClassicPalette.buttonBottom,
        side: borderSide,
        textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: ClassicPalette.buttonBottom,
        elevation: 1,
        shadowColor: ClassicPalette.borderDark,
        textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 12, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: borderSide),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: ClassicPalette.ink,
        backgroundColor: ClassicPalette.accent,
        textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 12, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: const BorderSide(color: ClassicPalette.accentDark)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? ClassicPalette.link : const Color(0xFFF3F7F1)),
      side: borderSide,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(Color(0xFFF5F8F3)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: borderSide,
      )),
      textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'Arial', fontSize: 12, color: ink)),
      hintStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Arial', fontSize: 12, color: ClassicPalette.muted)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ClassicPalette.headerBottom,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 12),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ClassicPalette.accentDark,
      linearTrackColor: ClassicPalette.panelHeader,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: panelAlt,
      selectedColor: ClassicPalette.selection,
      secondarySelectedColor: ClassicPalette.selection,
      disabledColor: panelAlt,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      side: borderSide,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      labelStyle: TextStyle(fontFamily: 'Arial', fontSize: 11, color: ink),
      secondaryLabelStyle: TextStyle(fontFamily: 'Arial', fontSize: 11, color: ink),
      brightness: Brightness.light,
    ),
  );
}


class ClassicFieldLabel extends StatelessWidget {
  const ClassicFieldLabel({super.key, required this.label, required this.child, this.enabled = true});

  final String label;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 3),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w700,
                color: ClassicPalette.muted,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ClassicPanel extends StatelessWidget {
  const ClassicPanel({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.headerIcon,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.headerTrailing,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? headerIcon;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: ClassicPalette.panel,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: ClassicPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
          if (title != null)
            Container(
              height: 37,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC9D8C6), ClassicPalette.panelHeader],
                ),
                border: Border(bottom: BorderSide(color: ClassicPalette.border)),
              ),
              child: Row(
                children: [
                  if (headerIcon != null) ...[
                    headerIcon!,
                    const SizedBox(width: 7),
                  ] else if (icon != null) ...[
                    ClassicIconBadge(icon: icon!),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ClassicPalette.ink),
                    ),
                  ),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class ClassicSectionTitle extends StatelessWidget {
  const ClassicSectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ClassicPalette.panelHeader,
        border: Border.all(color: ClassicPalette.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[ClassicIconBadge(icon: icon!), const SizedBox(width: 6)],
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ClassicBevelButton extends StatelessWidget {
  const ClassicBevelButton({super.key, required this.label, required this.onPressed, this.icon, this.leading, this.accent = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(5),
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: accent
                  ? const [Color(0xFFD9EA49), ClassicPalette.accent]
                  : const [ClassicPalette.buttonTop, ClassicPalette.buttonBottom],
            ),
            border: Border.all(color: accent ? ClassicPalette.accentDark : ClassicPalette.borderDark),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [BoxShadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 0)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 5)]
              else if (icon != null) ...[ClassicIconBadge(icon: icon!, size: 16), const SizedBox(width: 5)],
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ClassicPalette.ink)),
            ],
          ),
        ),
      ),
    );
  }
}


void classicSafeBack(BuildContext context, {Uri? routeUri, String fallback = '/home'}) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final uri = routeUri ?? GoRouterState.of(context).uri;
  final path = uri.path;
  String target = fallback;

  if (path.startsWith('/settings/booru/tag_types') || path.startsWith('/settings/booru/collections')) {
    target = '/settings/booru';
  } else if (path == '/settings/booru' || path == '/settings/change_booru' || path.startsWith('/settings/overall_settings')) {
    target = '/settings';
  } else if (path == '/settings' || path == '/about') {
    target = '/home';
  } else if (path.endsWith('/note') && path.startsWith('/view/')) {
    target = path.substring(0, path.length - '/note'.length);
  } else if (path.startsWith('/collections/')) {
    target = '/collections';
  } else if (path.startsWith('/view/')) {
    target = '/search';
  } else if (path.startsWith('/manage_image')) {
    target = '/home';
  }

  context.go(target);
}

class ClassicSafeBackButton extends StatelessWidget {
  const ClassicSafeBackButton({super.key, this.routeUri, this.fallback = '/home'});

  final Uri? routeUri;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => classicSafeBack(context, routeUri: routeUri, fallback: fallback),
      icon: const ClassicNavArrow.left(size: 13),
    );
  }
}

class ClassicDialogFrame extends StatelessWidget {
  const ClassicDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions = const [],
    this.width,
    this.maxWidth = 680,
    this.contentPadding = const EdgeInsets.fromLTRB(14, 14, 14, 12),
  });

  final String title;
  final Widget child;
  final Widget? icon;
  final List<Widget> actions;
  final double? width;
  final double maxWidth;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width - 36;
    final resolvedWidth = (width ?? maxWidth).clamp(280.0, available.clamp(280.0, maxWidth)).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: resolvedWidth,
        child: Material(
          color: ClassicPalette.panel,
          elevation: 12,
          shadowColor: const Color(0x99000000),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: ClassicPalette.borderDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD4E0D1), ClassicPalette.panelHeader],
                  ),
                  border: Border(bottom: BorderSide(color: ClassicPalette.borderDark)),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 7),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ClassicPalette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(padding: contentPadding, child: child),
              if (actions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7E2D4),
                    border: Border(top: BorderSide(color: ClassicPalette.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 7),
                        actions[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassicLink extends StatelessWidget {
  const ClassicLink(this.text, {super.key, this.onTap, this.bold = false, this.fontSize = 12});
  final String text;
  final VoidCallback? onTap;
  final bool bold;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: ClassicPalette.link,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            decoration: onTap == null ? TextDecoration.none : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class ClassicTopBar extends StatefulWidget {
  const ClassicTopBar({super.key, required this.routeUri});
  final Uri routeUri;

  @override
  State<ClassicTopBar> createState() => _ClassicTopBarState();
}

class _ClassicTopBarState extends State<ClassicTopBar> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _search.text.trim();
    context.go('/search?tag=${Uri.encodeComponent(text)}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF536D60), Color(0xFF344C41)],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF688073), width: 1),
          bottom: BorderSide(color: ClassicPalette.headerBorder, width: 1.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1040;
          final veryCompact = constraints.maxWidth < 820;
          final searchWidth = veryCompact ? 218.0 : (compact ? 270.0 : 330.0);

          return Row(
            children: [
              InkWell(
                onTap: () => context.go('/home'),
                child: SizedBox(
                  height: 42,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: veryCompact
                        ? Image.asset(
                            'assets/classic_deviantart/custom/localbooru_logo_2010.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.fitHeight,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                          )
                        : Image.asset(
                            'assets/classic_deviantart/custom/localbooru_logo_2010.png',
                            width: 108,
                            height: 32,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                          ),
                  ),
                ),
              ),
              SizedBox(width: veryCompact ? 8 : 16),
              SizedBox(
                width: searchWidth,
                child: _ClassicHeaderSearch(
                  controller: _search,
                  compact: veryCompact,
                  onSubmit: _submit,
                ),
              ),
              if (!veryCompact) ...[
                const SizedBox(width: 13),
                _TopLink(label: 'Browse', active: widget.routeUri.path.startsWith('/search'), onTap: () => context.go('/search')),
                _TopLink(label: 'Collections', active: widget.routeUri.path.startsWith('/collections'), onTap: () => context.go('/collections')),
                if (!compact) _TopLink(label: 'Submit', active: widget.routeUri.path.startsWith('/manage_image'), onTap: () => context.push('/manage_image')),
              ],
              const Spacer(),
              if (!compact) ...[
                _TopLink(label: 'Settings', active: widget.routeUri.path.startsWith('/settings'), onTap: () => context.go('/settings')),
                _TopLink(label: 'About', active: widget.routeUri.path.startsWith('/about'), onTap: () => context.go('/about')),
              ] else
                PopupMenuButton<String>(
                  tooltip: 'Navigation',
                  color: ClassicPalette.panel,
                  icon: const ClassicCustomIcon('menu', size: 18),
                  onSelected: (value) {
                    if (value == '/manage_image') {
                      context.push(value);
                    } else {
                      context.go(value);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: '/home', child: Text('Browse')),
                    PopupMenuItem(value: '/collections', child: Text('Collections')),
                    PopupMenuItem(value: '/manage_image', child: Text('Submit image')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: '/settings', child: Text('Settings')),
                    PopupMenuItem(value: '/about', child: Text('About')),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassicHeaderSearch extends StatelessWidget {
  const _ClassicHeaderSearch({required this.controller, required this.onSubmit, this.compact = false});

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF25372F)),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1),
          BoxShadow(color: Color(0x55FFFFFF), offset: Offset(0, -1), blurRadius: 0),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDCE4DB), Color(0xFFC7D1C8)],
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F4F0)),
                  bottom: BorderSide(color: Color(0xFF8D9E91)),
                ),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF22322D),
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search your collection...',
                  hintStyle: TextStyle(
                    color: Color(0xFF66766E),
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.fromLTRB(7, 0, 7, 1),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onSubmit,
            child: Container(
              width: compact ? 42 : 55,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4B6157), Color(0xFF2D4138)],
                ),
                border: Border(
                  left: BorderSide(color: Color(0xFF1F3029)),
                  top: BorderSide(color: Color(0xFF6E8178)),
                ),
              ),
              child: Text(
                compact ? 'Go' : 'Search',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCBE32D),
                  height: 1,
                  shadows: [Shadow(color: Color(0x99000000), offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassicSidebar extends StatelessWidget {
  const ClassicSidebar({super.key, required this.routeUri});
  final Uri routeUri;

  bool _active(String path) => routeUri.path.startsWith(path);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      decoration: const BoxDecoration(
        color: ClassicPalette.sidebar,
        border: Border(right: BorderSide(color: ClassicPalette.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(11, 8, 10, 18),
        children: [
          const Text('Browse', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 5),
          _SidebarLink(icon: Icons.image_outlined, text: 'Deviations', selected: _active('/home') || _active('/search'), onTap: () => context.go('/search')),
          _SidebarLink(icon: Icons.photo_library_outlined, text: 'Collections', selected: _active('/collections'), onTap: () => context.go('/collections')),
          _SidebarLink(icon: Icons.upload_file_outlined, text: 'Submit an image', selected: _active('/manage_image'), onTap: () => context.push('/manage_image')),
          const SizedBox(height: 13),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 5),
          _TextSidebarLink(text: 'Artist tags', onTap: () => context.go('/settings/booru/tag_types')),
          _TextSidebarLink(text: 'Character tags', onTap: () => context.go('/settings/booru/tag_types')),
          _TextSidebarLink(text: 'Copyright tags', onTap: () => context.go('/settings/booru/tag_types')),
          _TextSidebarLink(text: 'Species tags', onTap: () => context.go('/settings/booru/tag_types')),
          _TextSidebarLink(text: 'Generic tags', onTap: () => context.go('/settings/booru/tag_types')),
          const SizedBox(height: 13),
          const Text('Library', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 5),
          _TextSidebarLink(text: 'Booru settings', onTap: () => context.go('/settings/booru')),
          _TextSidebarLink(text: 'Application settings', onTap: () => context.go('/settings/overall_settings')),
          _TextSidebarLink(text: 'About LocalBooru', onTap: () => context.go('/about')),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: ClassicPalette.panelHeader,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('Classic collection mode', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: ClassicPalette.ink)),
          ),
        ],
      ),
    );
  }
}

enum ClassicGlyphKind {
  deviation,
  collection,
  submit,
  folder,
  switchFolder,
  settings,
  refresh,
  info,
  tag,
  counter,
  notes,
  link,
  rating,
  generic,
}

ClassicGlyphKind? _classicGlyphForMaterialIcon(IconData icon) {
  if (icon == Icons.image_outlined || icon == Icons.image || icon == Icons.photo_outlined) return ClassicGlyphKind.deviation;
  if (icon == Icons.photo_library_outlined || icon == Icons.photo_library || icon == Icons.collections_outlined || icon == Icons.collections) return ClassicGlyphKind.collection;
  if (icon == Icons.upload_file_outlined || icon == Icons.add_photo_alternate_outlined || icon == Icons.add_photo_alternate || icon == Icons.upload) return ClassicGlyphKind.submit;
  if (icon == Icons.folder_outlined || icon == Icons.folder || icon == Icons.folder_open) return ClassicGlyphKind.folder;
  if (icon == Icons.drive_file_move_outline || icon == Icons.drive_file_move || icon == Icons.swap_horiz) return ClassicGlyphKind.switchFolder;
  if (icon == Icons.settings || icon == Icons.settings_outlined || icon == Icons.tune) return ClassicGlyphKind.settings;
  if (icon == Icons.refresh || icon == Icons.sync || icon == Icons.update) return ClassicGlyphKind.refresh;
  if (icon == Icons.info_outline || icon == Icons.info) return ClassicGlyphKind.info;
  if (icon == Icons.sell_outlined || icon == Icons.sell || icon == Icons.local_offer_outlined) return ClassicGlyphKind.tag;
  if (icon == Icons.bar_chart || icon == Icons.analytics_outlined) return ClassicGlyphKind.counter;
  if (icon == Icons.notes || icon == Icons.description_outlined) return ClassicGlyphKind.notes;
  if (icon == Icons.link || icon == Icons.public) return ClassicGlyphKind.link;
  if (icon == Icons.shield || icon == Icons.question_mark_rounded || icon == Icons.explicit || icon == Icons.gavel) return ClassicGlyphKind.rating;
  return null;
}

int? _classicSpriteIndexForMaterialIcon(IconData icon) {
  if (icon == Icons.image_outlined || icon == Icons.image || icon == Icons.photo_outlined) return 0;
  if (icon == Icons.photo_library_outlined || icon == Icons.photo_library || icon == Icons.collections_outlined || icon == Icons.collections) return 28;
  if (icon == Icons.upload_file_outlined || icon == Icons.add_photo_alternate_outlined || icon == Icons.add_photo_alternate || icon == Icons.upload || icon == Icons.file_upload_outlined) return 32;
  if (icon == Icons.folder_outlined || icon == Icons.folder || icon == Icons.folder_open) return 29;
  if (icon == Icons.drive_file_move_outline || icon == Icons.drive_file_move || icon == Icons.swap_horiz) return 16;
  if (icon == Icons.settings || icon == Icons.settings_outlined || icon == Icons.tune) return 11;
  if (icon == Icons.refresh || icon == Icons.sync || icon == Icons.update || icon == Icons.cached || icon == Icons.restart_alt) return 38;
  if (icon == Icons.info_outline || icon == Icons.info) return 14;
  if (icon == Icons.sell_outlined || icon == Icons.sell || icon == Icons.local_offer_outlined || icon == Icons.local_offer) return 45;
  if (icon == Icons.bar_chart || icon == Icons.analytics_outlined) return 5;
  if (icon == Icons.notes || icon == Icons.description_outlined || icon == Icons.description) return 9;
  if (icon == Icons.link || icon == Icons.public) return 38;
  if (icon == Icons.star || icon == Icons.star_outline || icon == Icons.favorite || icon == Icons.favorite_border) return 21;
  if (icon == Icons.grid_3x3 || icon == Icons.grid_view || icon == Icons.apps) return 5;
  if (icon == Icons.visibility || icon == Icons.remove_red_eye_outlined) return 2;
  if (icon == Icons.image_aspect_ratio || icon == Icons.aspect_ratio) return 29;
  if (icon == Icons.dark_mode || icon == Icons.light_mode || icon == Icons.palette || icon == Icons.palette_outlined) return 39;
  if (icon == Icons.web_asset || icon == Icons.web_asset_outlined || icon == Icons.open_in_browser) return 16;
  if (icon == Icons.gif || icon == Icons.gif_box_outlined) return 3;
  if (icon == Icons.fingerprint || icon == Icons.lock || icon == Icons.lock_outline) return 23;
  if (icon == Icons.home || icon == Icons.home_outlined) return 41;
  if (icon == Icons.chat || icon == Icons.chat_bubble_outline || icon == Icons.comment_outlined) return 12;
  if (icon == Icons.mail || icon == Icons.mail_outline) return 9;
  if (icon == Icons.help || icon == Icons.help_outline) return 20;
  return null;
}

class ClassicActionIcon extends StatelessWidget {
  const ClassicActionIcon(this.name, {super.key, this.size = 20});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/classic_deviantart/actions/$name.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
      ),
    );
  }
}

class ClassicCustomIcon extends StatelessWidget {
  const ClassicCustomIcon(this.name, {super.key, this.size = 20});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/classic_deviantart/custom/$name.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
      ),
    );
  }
}


/// Tiny previous/next arrows supplied for the classic collection navigator.
/// They are also reused for lightweight classic navigation affordances so a
/// flat Material chevron does not leak into the retro shell.
class ClassicNavArrow extends StatelessWidget {
  const ClassicNavArrow.left({super.key, this.size = 13}) : isLeft = true;
  const ClassicNavArrow.right({super.key, this.size = 13}) : isLeft = false;

  final bool isLeft;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/classic_deviantart/custom/${isLeft ? 'nav_left' : 'nav_right'}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
      ),
    );
  }
}

class ClassicSpriteIcon extends StatelessWidget {
  const ClassicSpriteIcon({super.key, required this.index, this.size = 20});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = index.toString().padLeft(2, '0');
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/classic_deviantart/icons/$file.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
      ),
    );
  }
}

/// Small period-style pictograms. Known actions use the user-supplied
/// 2010-era sprite strip; unmatched actions fall back to locally drawn badges
/// so the classic shell never has to expose a large flat Material glyph.
class ClassicIconBadge extends StatelessWidget {
  const ClassicIconBadge({super.key, required this.icon, this.size = 20});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spriteIndex = _classicSpriteIndexForMaterialIcon(icon);
    if (spriteIndex != null) {
      return ClassicSpriteIcon(index: spriteIndex, size: size);
    }

    final kind = _classicGlyphForMaterialIcon(icon);
    if (kind != null) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ClassicGlyphPainter(kind)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7F1C6), Color(0xFFC89A3A)]),
        border: Border.all(color: const Color(0xFF756329)),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(color: Color(0x55819079), offset: Offset(1, 1), blurRadius: 0)],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * .64, color: ClassicPalette.ink),
    );
  }
}

class _ClassicGlyphPainter extends CustomPainter {
  const _ClassicGlyphPainter(this.kind);
  final ClassicGlyphKind kind;

  static const _outline = Color(0xFF4A4B35);
  static const _goldDark = Color(0xFF806328);
  static const _gold = Color(0xFFD5A540);
  static const _goldLight = Color(0xFFF4E7A8);
  static const _paper = Color(0xFFF3F1D5);
  static const _teal = Color(0xFF246E7B);
  static const _tealDark = Color(0xFF174A51);
  static const _green = Color(0xFF9AAF22);
  static const _orange = Color(0xFFD66E28);
  static const _blue = Color(0xFF26749A);

  Paint _p(Color color, {PaintingStyle style = PaintingStyle.fill, double width = 1}) => Paint()
    ..color = color
    ..style = style
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _frame(Canvas c, Size s) {
    final r = Rect.fromLTWH(1, 1, s.width - 3, s.height - 3);
    c.drawRect(r.shift(const Offset(1, 1)), _p(const Color(0x55607156)));
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s.width * .09)), _p(_goldDark));
    final inner = r.deflate(max(1.0, s.width * .055));
    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldLight, _gold, Color(0xFFB87E2F)],
    ).createShader(inner);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(s.width * .06)), Paint()..shader = shader);
    c.drawLine(inner.topLeft + const Offset(1, 1), inner.topRight + const Offset(-1, 1), _p(const Color(0xAAFFF8C9), width: 1));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _frame(canvas, size);
    final w = size.width;
    final h = size.height;
    final sx = w / 20.0;
    final sy = h / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    switch (kind) {
      case ClassicGlyphKind.deviation:
        canvas.drawRect(const Rect.fromLTWH(4, 4, 12, 12), _p(_outline));
        canvas.drawRect(const Rect.fromLTWH(5, 5, 10, 10), _p(_paper));
        canvas.drawCircle(const Offset(12.3, 7.2), 1.25, _p(_orange));
        final mountains = Path()..moveTo(6, 13)..lineTo(9, 9.5)..lineTo(11, 12)..lineTo(13.2, 10.2)..lineTo(15, 13)..close();
        canvas.drawPath(mountains, _p(_teal));
        canvas.drawRect(const Rect.fromLTWH(6, 14, 8, 1), _p(_tealDark));
        break;
      case ClassicGlyphKind.collection:
        canvas.drawRect(const Rect.fromLTWH(6, 4.8, 9, 10.5), _p(_outline));
        canvas.drawRect(const Rect.fromLTWH(7, 5.8, 7, 8.5), _p(_paper));
        canvas.drawRect(const Rect.fromLTWH(4.5, 7, 8, 9), _p(_outline));
        canvas.drawRect(const Rect.fromLTWH(5.5, 8, 6, 7), _p(const Color(0xFFDDE7D3)));
        final star = _star(const Offset(13.8, 6.7), 3.1, 1.35, 5);
        canvas.drawPath(star, _p(_green));
        canvas.drawPath(star, _p(_outline, style: PaintingStyle.stroke, width: .8));
        break;
      case ClassicGlyphKind.submit:
        canvas.drawRect(const Rect.fromLTWH(5, 4, 10, 12), _p(_outline));
        canvas.drawRect(const Rect.fromLTWH(6, 5, 8, 10), _p(_paper));
        canvas.drawRect(const Rect.fromLTWH(7, 11, 6, 3), _p(const Color(0xFFCCD9C7)));
        final arrow = Path()..moveTo(10, 4.2)..lineTo(6.8, 8.3)..lineTo(8.9, 8.3)..lineTo(8.9, 12)..lineTo(11.1, 12)..lineTo(11.1, 8.3)..lineTo(13.2, 8.3)..close();
        canvas.drawPath(arrow, _p(_green));
        canvas.drawPath(arrow, _p(_outline, style: PaintingStyle.stroke, width: .7));
        break;
      case ClassicGlyphKind.folder:
        final folder = Path()..moveTo(4, 7)..lineTo(8, 7)..lineTo(9.3, 5.4)..lineTo(15.5, 5.4)..lineTo(16, 14.5)..lineTo(4, 14.5)..close();
        canvas.drawPath(folder, _p(_outline));
        final inner = Path()..moveTo(5, 7.8)..lineTo(8.6, 7.8)..lineTo(9.7, 6.4)..lineTo(14.7, 6.4)..lineTo(15, 13.5)..lineTo(5, 13.5)..close();
        canvas.drawPath(inner, _p(const Color(0xFFE7B94F)));
        canvas.drawRect(const Rect.fromLTWH(5, 8.2, 10, 1.2), _p(_goldLight));
        break;
      case ClassicGlyphKind.switchFolder:
        final folder = Path()..moveTo(3.7, 7.4)..lineTo(7.6, 7.4)..lineTo(8.8, 5.8)..lineTo(15.6, 5.8)..lineTo(16, 14.2)..lineTo(3.7, 14.2)..close();
        canvas.drawPath(folder, _p(_outline));
        canvas.drawPath(Path()..moveTo(4.8, 8.2)..lineTo(8.2, 8.2)..lineTo(9.2, 6.8)..lineTo(14.7, 6.8)..lineTo(15, 13.2)..lineTo(4.8, 13.2)..close(), _p(const Color(0xFFE7B94F)));
        final arrow = Path()..moveTo(6, 10.5)..lineTo(11.2, 10.5)..lineTo(9.4, 8.7)..lineTo(10.7, 8.7)..lineTo(13.3, 11.2)..lineTo(10.7, 13.7)..lineTo(9.4, 13.7)..lineTo(11.2, 11.8)..lineTo(6, 11.8)..close();
        canvas.drawPath(arrow, _p(_blue));
        canvas.drawPath(arrow, _p(_outline, style: PaintingStyle.stroke, width: .6));
        break;
      case ClassicGlyphKind.settings:
        canvas.drawCircle(const Offset(10, 10), 4.7, _p(_tealDark));
        for (var i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final center = Offset(10 + cos(a) * 5.1, 10 + sin(a) * 5.1);
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(a);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 2.2, height: 2.4), _p(_tealDark));
          canvas.restore();
        }
        canvas.drawCircle(const Offset(10, 10), 2.2, _p(_paper));
        canvas.drawCircle(const Offset(10, 10), 1.1, _p(_gold));
        break;
      case ClassicGlyphKind.refresh:
        canvas.drawArc(const Rect.fromLTWH(4.2, 4.2, 11.6, 11.6), -.35, 4.2, false, _p(_blue, style: PaintingStyle.stroke, width: 2.2));
        final a = Path()..moveTo(14.5, 4.5)..lineTo(15.8, 8.3)..lineTo(12.1, 7.1)..close();
        canvas.drawPath(a, _p(_blue));
        break;
      case ClassicGlyphKind.info:
        canvas.drawCircle(const Offset(10, 10), 5.2, _p(_blue));
        canvas.drawCircle(const Offset(10, 10), 5.2, _p(_outline, style: PaintingStyle.stroke, width: .8));
        canvas.drawCircle(const Offset(10, 6.6), 1, _p(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9.15, 8.3, 1.7, 5.6), const Radius.circular(.7)), _p(Colors.white));
        break;
      case ClassicGlyphKind.tag:
        final tag = Path()..moveTo(5, 5.7)..lineTo(12.4, 5.7)..lineTo(15.3, 9.8)..lineTo(10.2, 15)..lineTo(5, 9.9)..close();
        canvas.drawPath(tag, _p(const Color(0xFFE4B44D)));
        canvas.drawPath(tag, _p(_outline, style: PaintingStyle.stroke, width: .8));
        canvas.drawCircle(const Offset(8, 8.1), 1.25, _p(_paper));
        canvas.drawCircle(const Offset(8, 8.1), 1.25, _p(_outline, style: PaintingStyle.stroke, width: .6));
        break;
      case ClassicGlyphKind.counter:
        canvas.drawRect(const Rect.fromLTWH(4.5, 12, 2.5, 3), _p(_teal));
        canvas.drawRect(const Rect.fromLTWH(8.8, 8, 2.5, 7), _p(_green));
        canvas.drawRect(const Rect.fromLTWH(13.1, 5.5, 2.5, 9.5), _p(_orange));
        canvas.drawLine(const Offset(4, 15.3), const Offset(16.2, 15.3), _p(_outline, width: .8));
        break;
      case ClassicGlyphKind.notes:
        canvas.drawRect(const Rect.fromLTWH(5, 4.6, 10, 11), _p(_outline));
        canvas.drawRect(const Rect.fromLTWH(6, 5.6, 8, 9), _p(_paper));
        for (var y in [8.0, 10.3, 12.6]) canvas.drawRect(Rect.fromLTWH(7.2, y, 5.6, .8), _p(_teal));
        break;
      case ClassicGlyphKind.link:
        canvas.drawArc(const Rect.fromLTWH(3.8, 7.2, 7.3, 5.4), 2.4, 2.7, false, _p(_blue, style: PaintingStyle.stroke, width: 2.0));
        canvas.drawArc(const Rect.fromLTWH(8.9, 7.2, 7.3, 5.4), -.75, 2.7, false, _p(_blue, style: PaintingStyle.stroke, width: 2.0));
        canvas.drawLine(const Offset(8.1, 10), const Offset(11.9, 10), _p(_outline, width: 1));
        break;
      case ClassicGlyphKind.rating:
        final star = _star(const Offset(10, 10), 5.1, 2.2, 5);
        canvas.drawPath(star, _p(_green));
        canvas.drawPath(star, _p(_outline, style: PaintingStyle.stroke, width: .8));
        break;
      case ClassicGlyphKind.generic:
        canvas.drawCircle(const Offset(10, 10), 5, _p(_teal));
        break;
    }
    canvas.restore();
  }

  Path _star(Offset center, double outerRadius, double innerRadius, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -pi / 2 + i * pi / points;
      final point = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      if (i == 0) path.moveTo(point.dx, point.dy); else path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ClassicGlyphPainter oldDelegate) => oldDelegate.kind != kind;
}

class _TopLink extends StatelessWidget {
  const _TopLink({required this.label, required this.onTap, this.active = false});
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: active ? null : onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: active ? const BoxDecoration(
          color: Color(0x18000000),
          border: Border(bottom: BorderSide(color: ClassicPalette.accent, width: 2)),
        ) : null,
        child: Text(
          label,
          style: TextStyle(
            color: active ? ClassicPalette.accent : const Color(0xFFF4F6F3),
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  const _SidebarLink({required this.icon, required this.text, required this.onTap, this.selected = false});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: selected ? BoxDecoration(color: ClassicPalette.selection, borderRadius: BorderRadius.circular(3)) : null,
        child: Row(
          children: [
            ClassicIconBadge(icon: icon),
            const SizedBox(width: 7),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, color: selected ? const Color(0xFF8B421B) : ClassicPalette.link))),
          ],
        ),
      ),
    );
  }
}

class _TextSidebarLink extends StatelessWidget {
  const _TextSidebarLink({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Text(text, style: const TextStyle(fontSize: 12, color: ClassicPalette.link)),
      ),
    );
  }
}
