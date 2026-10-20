import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Mobile/desktop: abre a folha de compartilhamento com o arquivo gerado.
Future<void> saveFile(Uint8List bytes, String name, String mime) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mime, name: name)],
      fileNameOverrides: [name],
    ),
  );
}
