import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class EPaper {
  static const int maxPages = 60;

  final _tilePathDateFormat = DateFormat('yyyyMMdd');
  final _tileDateFormat = DateFormat('yy-MM-dd');
  final DateTime dateTime;
  final Dio dio = Dio();
  late final Directory directory;
  late int aValue;

  int pages = 0;

  EPaper({
    required this.dateTime,
  });

  ///
  /// Delete image folder
  ///
  Future<void> deleteImages() async {
    await directory.delete(recursive: true);
  }

  ///
  /// Combine all image tiles into a pdf
  ///
  Future<File> generatePdf() async {
    final pdf = Document();

    for (int page = 1; page <= pages; page++) {
      final List<MemoryImage> images = [];

      for (int y = 0; y <= 5; y++) {
        for (int x = 0; x <= 3; x++) {
          images.add(
            MemoryImage(
              File('${directory.path}${'/$page/2-$x-$y.jpg'}')
                  .readAsBytesSync(),
            ),
          );
        }
      }

      pdf.addPage(
        Page(
          pageFormat: PdfPageFormat.a4,
          margin: const EdgeInsets.all(0),
          build: (Context context) {
            return Column(
              children: List.generate(
                6,
                (y) {
                  return Row(
                    children: List.generate(
                      4,
                      (x) {
                        if (y == 5) {
                          return Container(
                            height:
                                (29.7 / 5.20833) * 0.20833 * PdfPageFormat.cm,
                            child: Image(images[y * 4 + x]),
                          );
                        } else {
                          return Container(
                            height: (29.7 / 5.20833) * 1 * PdfPageFormat.cm,
                            child: Image(images[y * 4 + x]),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final file = File("${_tilePathDateFormat.format(dateTime)}-ov.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  ///
  /// Download all page-tile-images and save it into a temporary directory
  ///
  Future<void> downloadPaperTiles() async {
    directory = await Directory.current.createTemp('images-');
    for (int page = 1; page <= maxPages; page++) {
      // Get tile URL's for current page
      final tileUrls = _getTileUrls(page);

      // Collect download futures
      final futures = tileUrls.map(
        (url) => dio.download(
          url,
          '${directory.path}${'/$page/${url.split('/').last}'}',
        ),
      );

      // Execute all futures in parallel.
      // Use eagerError to instantly interrupt, if one Future fails
      try {
        await Future.wait(futures, eagerError: true);
      } catch (e) {
        // If there is an error we should be at the end of the paper
        return;
      }

      pages++;
    }
  }

  ///
  /// Tries to find the download url to [dateTime]. Sets [aValue] and return true
  /// if successfull.
  ///
  /// [getImageUrl] can be used without [value] after this method completed successfully.
  ///
  Future<bool> findDownloadURL() async {
    for (int v = 15; v <= 17; v++) {
      try {
        // Try to get Ressource with value v
        final response = await dio.get(_getImageUrl(1, 0, 0, value: v));

        // If the request is successfull und not redirected, set aValue to current v
        // and complete future with true
        if (response.statusCode == 200 && !(response.isRedirect ?? false)) {
          aValue = v;
          return true;
        }
      } catch (e) {
        // We dont want to handle the exception because we are expecting some errors
      }
    }

    // No url could be found, complete future with false
    return false;
  }

  String _getImageUrl(int pageNum, int x, int y, {int? value}) {
    // Left pad page number with zeros (1 -> 01)
    final page = pageNum.toString().padLeft(2, '0');

    // Return image url with date, aValue and tile x/y
    return 'https://oldenburgische-volkszeitung.de/lib/epaper/img/${dateTime.year}/${_tilePathDateFormat.format(dateTime)}-ov/tiles/a${value ?? aValue}-${_tileDateFormat.format(dateTime)}-ov-$page-_$page-4c-hp/2-$x-$y.jpg';
  }

  ///
  /// Generates all image tile url in the highest resolution
  /// One page has 4*6 = 24 tiles / images
  ///
  List<String> _getTileUrls(int pageNum) {
    final List<String> out = [];
    for (int x = 0; x <= 3; x++) {
      for (int y = 0; y <= 5; y++) {
        out.add(_getImageUrl(pageNum, x, y));
      }
    }
    return out;
  }
}
