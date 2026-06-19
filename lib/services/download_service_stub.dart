import 'dart:typed_data';

class DownloadService {
  static void downloadBytes(
    Uint8List bytes, {
    required String filename,
    required String contentType,
  }) {
    throw UnsupportedError('Exportação de ficheiros disponível apenas na versão Web.');
  }
}
