import 'dart:io';

import 'package:console/console.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ov_epaper/epaper.dart';

Future<void> main(List<String> arguments) async {
  try {
    Console.init();
    initializeDateFormatting('de_DE');
  } catch (e) {
    Console.write('Dieses Tool wird in deinem Terminal nicht unterstützt.');
    exit(1);
  }

  final dateFormat = DateFormat.yMMMd('de');

  // Ask for paper date
  final date = Chooser<DateTime>(
    getLastWeekdays(10),
    message: 'Wähle ein Datum aus: ',
    formatter: (dateTime, index) {
      return '$index) ${dateFormat.format(dateTime)}';
    },
  ).chooseSync();

  // Initialize ePaper object
  final ePaper = EPaper(dateTime: date);

  // Initialize loading bar for image url search
  final urlSearchLoadingBar = LoadingBar();

  Console.write('Suche Download URL ');
  urlSearchLoadingBar.start();

  // Search for downloadUrl
  final foundDownloadUrl = await ePaper.findDownloadURL();

  // Cancel program if download url could not be found
  if (!foundDownloadUrl) {
    urlSearchLoadingBar.stop(Icon.BALLOT_X);
    exit(1);
  } else {
    urlSearchLoadingBar.stop(Icon.CHECKMARK);
  }

  final tileDownloadLoadingBar = LoadingBar();

  Console.write('Downloade Bilder ');
  tileDownloadLoadingBar.start();

  // Download paper image tiles
  await ePaper.downloadPaperTiles();

  tileDownloadLoadingBar.stop(Icon.CHECKMARK);

  Console.write('${ePaper.pages} Seiten heruntergeladen\n');

  final generatePdfLoadingBar = LoadingBar();

  Console.write('Generiere PDF ');
  generatePdfLoadingBar.start();

  // Generate PDF
  final file = await ePaper.generatePdf();

  generatePdfLoadingBar.stop(Icon.CHECKMARK);

  Console.write('Datei ${file.path} generiert\n');

  final deleteDirLoadingBar = LoadingBar();

  Console.write('Lösche Bilder ');
  deleteDirLoadingBar.start();

  // Delete images
  await ePaper.deleteImages();

  deleteDirLoadingBar.stop(Icon.CHECKMARK);

  exit(0);
}

List<DateTime> getLastWeekdays(int amount) {
  final now = DateTime.now();
  var remaining = amount;
  var currentSubtract = 0;
  final List<DateTime> out = [];

  while (remaining > 0) {
    final dt = now.subtract(Duration(days: currentSubtract));
    currentSubtract++;

    switch (dt.weekday) {
      case DateTime.sunday:
        continue;
      default:
        out.add(dt);
        remaining--;
        break;
    }
  }

  return out;
}
