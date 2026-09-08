import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:image_compression/image_compression.dart' as imageCompression;
import 'package:image_compression/image_compression_io.dart';
import 'package:localbooru/api/index.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Map<String, Future<bool>> _imageTransparencyCache = {};

Future<bool> imageHasTransparency(File file) async {
    final mime = lookupMimeType(file.path);

    if(mime == null || !mime.startsWith('image/')) {
        return false;
    }

    // These formats cannot contain an alpha channel.
    if(
        mime == 'image/jpeg' ||
        mime == 'image/bmp' ||
        mime == 'image/wbmp'
    ) {
        return false;
    }

    try {
        final stat = await file.stat();

        // Including modification time and size prevents an edited/replaced file
        // from inheriting an obsolete transparency result.
        final cacheKey =
            '${file.path}|${stat.size}|${stat.modified.microsecondsSinceEpoch}';

        return _imageTransparencyCache.putIfAbsent(
            cacheKey,
            () => _decodeImageHasTransparency(file),
        );
    } catch (_) {
        return false;
    }
}

Future<bool> _decodeImageHasTransparency(File file) async {
    ui.Codec? codec;

    try {
        final decodedCodec = await ui.instantiateImageCodec(
            await file.readAsBytes(),
            targetWidth: 96,
            allowUpscaling: false,
        );

        codec = decodedCodec;

        // Check every frame. This also handles GIF/WebP files where
        // transparency may appear during the animation.
        for(
            int frameIndex = 0;
            frameIndex < decodedCodec.frameCount;
            frameIndex++
        ) {
            final frame = await decodedCodec.getNextFrame();
            final decodedImage = frame.image;

            try {
                final pixelData = await decodedImage.toByteData(
                    format: ui.ImageByteFormat.rawRgba,
                );

                if(pixelData == null) {
                    continue;
                }

                final rgba = pixelData.buffer.asUint8List(
                    pixelData.offsetInBytes,
                    pixelData.lengthInBytes,
                );

                // RGBA = four bytes per pixel. Alpha is the fourth byte.
                for(
                    int alphaIndex = 3;
                    alphaIndex < rgba.length;
                    alphaIndex += 4
                ) {
                    // Anything below fully opaque counts as transparency,
                    // including semi-transparent antialiased pixels.
                    if(rgba[alphaIndex] < 255) {
                        return true;
                    }
                }
            } finally {
                decodedImage.dispose();
            }
        }
    } catch (_) {
        // An unsupported or malformed image should not break Browse.
        return false;
    } finally {
        codec?.dispose();
    }

    return false;
}

Future<File> _createTransparencyPreservingThumbnail({
    required File input,
    required String outputPath,
}) async {
    ui.Codec? codec;

    try {
        final decodedCodec = await ui.instantiateImageCodec(
            await input.readAsBytes(),
            targetWidth: 768,
            allowUpscaling: false,
        );

        codec = decodedCodec;

        // Like the old thumbnail system, animated files get a static gallery
        // thumbnail. Unlike JPEG, this PNG thumbnail retains alpha.
        final frame = await decodedCodec.getNextFrame();

        try {
            final pngData = await frame.image.toByteData(
                format: ui.ImageByteFormat.png,
            );

            if(pngData == null) {
                throw 'Could not encode transparent thumbnail';
            }

            return await File(outputPath).writeAsBytes(
                pngData.buffer.asUint8List(
                    pngData.offsetInBytes,
                    pngData.lengthInBytes,
                ),
                flush: true,
            );
        } finally {
            frame.image.dispose();
        }
    } finally {
        codec?.dispose();
    }
}

Future<Directory> obtainThumbnailDirectory() async {
    final String booruPath = (await getCurrentBooru()).path;

    final directory = Directory(p.join(booruPath, "thumbnails"));
    if(!(await Directory(p.join(booruPath, "thumbnails")).exists()))await directory.create();
    return directory;
}

Future<File> getImageThumbnail(BooruImage image) async {
    final filename = image.filename;
    final sourceFile = image.getImage();
    final thumbDir = await obtainThumbnailDirectory();

    final hasTransparency = await imageHasTransparency(sourceFile);

    // JPEG remains appropriate for ordinary opaque artwork.
    // Anything containing alpha receives a PNG thumbnail instead.
    final extension = hasTransparency ? '.png' : '.jpg';

    final thumbnailFile = File(
        '${p.join(
            thumbDir.path,
            p.basenameWithoutExtension(filename),
        )}$extension'
    );

    if(await thumbnailFile.exists()) {
        return thumbnailFile;
    }

    debugPrint("Compressing $filename");

    final thumbnail = hasTransparency
        ? await _createTransparencyPreservingThumbnail(
            input: sourceFile,
            outputPath: thumbnailFile.absolute.path,
        )
        : await createThumbnail(
            input: sourceFile,
            outputPath: thumbnailFile.absolute.path,
        );

    debugPrint("Obtained ${p.basename(thumbnailFile.path)}");

    return thumbnail;
}

Future<File> createThumbnail({required File input, required String outputPath}) async {
    File outputFile;

    final mime = lookupMimeType(input.path);
    if(mime!.startsWith("video/") || mime == "image/gif") {
        final hadGenerated = await generateVideoThumbnail(
            inputPath: input.path,
            outputPath: outputPath
        );
        if(!hadGenerated) throw "Could not generate thumbnail from video";
        outputFile = File(outputPath);
    } else if(mime.startsWith("image/")) {
        final compressedImage = await compressImage(ImageFile(
            filePath: input.path,
            rawBytes: await input.readAsBytes()
        ));
        outputFile = await File(outputPath).writeAsBytes(compressedImage.rawBytes);
    } else {
        throw "Unknown file type";
    }

    return outputFile;
}

//update to not depend on media_kit
Future<bool> generateVideoThumbnail({required String inputPath, required String outputPath}) async {
    debugPrint("getting thumbnail");
    final plugin = FcNativeVideoThumbnail();
    final thumbnailGenerated = await plugin.getVideoThumbnail(
        srcFile: inputPath,
        destFile: outputPath,
        width: 10000,  // i will be impressed if i find a 10.000x10.000 video size
        height: 10000,
        format: 'jpeg',
        quality: 30
    );
    return thumbnailGenerated;
}


Future<File> compress(File file) async {
    final tempDir = await getTemporaryDirectory();
    
    final mime = lookupMimeType(file.path)!;
    /*if(mime.startsWith("video/") || mime == "image/gif") {
        final compressedVideo = await compressVideo(file);
        return compressedVideo;
    } else*/ if(mime.startsWith("image/")) {
        final compressedImage = await compressImage(ImageFile(
            filePath: file.path,
            rawBytes: await file.readAsBytes()
        ), quality: 80);
        final newFile = File("${p.join(tempDir.path, p.basenameWithoutExtension(file.path))}.jpg");
        await newFile.writeAsBytes(compressedImage.rawBytes);
        return newFile;
    } else {
        throw "Unknown file type";
    }
}

Future<ImageFile> compressImage(ImageFile file, {int quality = 30}) {
    return imageCompression.compressInQueue(imageCompression.ImageFileConfiguration(
        input: file,
        config: imageCompression.Configuration(
            jpgQuality: quality,
        )
    ));
}

// Future<File> compressVideo(File file, {int crf = 32}) async {
//     // FFmpeg ffmpeg = createFFmpeg(CreateFFmpegParam(log: true, corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js'));

//     // await ffmpeg.load();

//     // final extension = p.extension(file.path);

//     // final inputFile = "input$extension";
//     // final outputFile = "output$extension";

//     // ffmpeg.writeFile(inputFile, await file.readAsBytes());

//     // await ffmpeg.run(["-i", inputFile, "-crf", crf.toString(), "-o", outputFile]);

//     // final data = ffmpeg.readFile(outputFile);

//     // return data;

//     final tempDir = await getTemporaryDirectory();
//     final outputPath = p.join(tempDir.path, p.basename(file.path));

//     final command = FfmpegCommand.simple(
//         inputs: [
//             FfmpegInput.asset(file.path)
//         ],
//         args: [
//             CliArg(name: "crf", value: "$crf"),
//             const CliArg(name: "y")
//         ],
//         outputFilepath: outputPath
//     );

//     debugPrint("Running ${command.expectedCliInput()}");

//     final process = await Ffmpeg().run(command);

//     // Pipe the process output to the Dart console.
//     process.stderr.transform(utf8.decoder).listen((data) {
//         debugPrint(data);
//     });

//     // // Allow the user to respond to FFMPEG queries, such as file overwrite
//     // // confirmations.
//     // stdin.pipe(process.stdin);

//     debugPrint("processHell");

//     await process.exitCode;

//     return File(outputPath);
// }