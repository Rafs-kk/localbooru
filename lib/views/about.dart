import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaml/yaml.dart';

class AboutScreen extends StatefulWidget{
    const AboutScreen({super.key});

    @override
    State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>{
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('About LocalBooru')),
            body: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                    Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                                children: [
                                    ClassicPanel(
                                        title: 'LocalBooru',
                                        icon: Icons.info_outline,
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                                Container(
                                                    width: 104,
                                                    height: 104,
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                        color: ClassicPalette.pageDeep,
                                                        border: Border.all(color: ClassicPalette.borderDark),
                                                    ),
                                                    child: SvgPicture.asset('assets/brand/rounded-icon.svg'),
                                                ),
                                                const SizedBox(width: 18),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            const Text('LocalBooru', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                                                            const SizedBox(height: 3),
                                                            FutureBuilder<String>(
                                                                future: rootBundle.loadString('pubspec.yaml'),
                                                                builder: (context, snapshot) {
                                                                    String version = 'Unknown version';
                                                                    if (snapshot.hasData) {
                                                                        final yaml = loadYaml(snapshot.data!);
                                                                        version = '${yaml['version']} "${yaml['localbooru_codename']}"';
                                                                    }
                                                                    return Text(version, style: const TextStyle(fontSize: 11, color: ClassicPalette.muted));
                                                                },
                                                            ),
                                                            const SizedBox(height: 11),
                                                            const Text(
                                                                'A local-only booru for organizing art, now wearing a classic late-2000s art-community skin.',
                                                                style: TextStyle(fontSize: 12, height: 1.3),
                                                            ),
                                                            const SizedBox(height: 5),
                                                            const Text('Original application by resucutie and contributors.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                                                        ],
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(height: 12),
                                    ClassicPanel(
                                        title: 'Project Links',
                                        icon: Icons.public,
                                        padding: EdgeInsets.zero,
                                        child: Column(
                                            children: [
                                                ListTile(
                                                    leading: Image.asset('assets/classic_deviantart/custom/github.png', width: 22, height: 22, filterQuality: FilterQuality.medium, isAntiAlias: true),
                                                    title: const Text('GitHub', style: TextStyle(fontWeight: FontWeight.w700, color: ClassicPalette.link)),
                                                    subtitle: const Text('Source code and issue tracker'),
                                                    onTap: () => launchUrlString('https://github.com/Rafs-kk/localbooru'),
                                                ),
                                                const Divider(height: 1),
                                                ListTile(
                                                    leading: Image.asset('assets/classic_deviantart/custom/discord.png', width: 22, height: 22, filterQuality: FilterQuality.medium, isAntiAlias: true),
                                                    title: const Text('Discord', style: TextStyle(fontWeight: FontWeight.w700, color: ClassicPalette.link)),
                                                    onTap: () => launchUrlString('https://discord.gg/mYuUKunj'),
                                                ),
                                                const Divider(height: 1),
                                                ListTile(
                                                    leading: Image.asset('assets/classic_deviantart/custom/liberapay.png', width: 22, height: 22, filterQuality: FilterQuality.medium, isAntiAlias: true),
                                                    title: const Text('Liberapay', style: TextStyle(fontWeight: FontWeight.w700, color: ClassicPalette.link)),
                                                    onTap: () => launchUrlString('https://liberapay.com/resucutie'),
                                                ),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(height: 12),
                                    const ClassicPanel(
                                        title: 'Classic Interface Note',
                                        icon: Icons.palette_outlined,
                                        child: Text(
                                            'This interface is an original LocalBooru adaptation inspired by the green, compact, panel-based web design language common to DeviantArt between the mid-2000s and early 2010s. It does not connect to DeviantArt and remains fully local.',
                                            style: TextStyle(fontSize: 11, height: 1.35),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}
