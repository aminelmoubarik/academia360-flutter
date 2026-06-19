import 'dart:html' as html;
import 'dart:typed_data';

class DownloadService {
  static void downloadBytes(
    Uint8List bytes, {
    required String filename,
    required String contentType,
  }) {
    final blob = html.Blob([bytes], contentType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
