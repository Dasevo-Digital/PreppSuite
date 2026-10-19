# tessdata_fast (Deutsch, Englisch)

Sprachdaten für Tesseract, mit denen die Android-Fassung gescannte PDFs
liest (#66). Sie liegen unter
`preppsuite_flutter/android/app/src/main/assets/tessdata/` und gehen nur in
die Android-Pakete; die anderen Plattformen nutzen die Texterkennung ihres
Systems.

| Datei | Quelle | SHA-256 |
|---|---|---|
| `deu.traineddata` | `tesseract-ocr/tessdata_fast`, Tag `4.1.0` | `19d219bbb6672c869d20a9636c6816a81eb9a71796cb93ebe0cb1530e2cdb22d` |
| `eng.traineddata` | `tesseract-ocr/tessdata_fast`, Tag `4.1.0` | `7d4322bd2a7749724879683fc3912cb542f19906c83bcc1a52132556427170b2` |

Die „fast“-Modelle statt der „best“: 5,6 MB statt 24 MB für beide
Sprachen, bei gedruckten Scans kaum schlechter.

## Auf Wunsch geladen (#205)

Für „Text aus Foto“ im Übersetzer lädt die Android-App die Daten weiterer
Sprachen erst, wenn sie gebraucht werden, von
`raw.githubusercontent.com/tesseract-ocr/tessdata_fast/4.1.0/<code>.traineddata`.
Sie sind nicht im Paket. Größen und Prüfsummen stehen auch in
`preppsuite_flutter/lib/features/knowledge/application/tesseract_data.dart`; eine Datei, die
nicht passt, wird gelöscht.

| Datei | Größe | SHA-256 |
|---|---|---|
| `spa.traineddata` | 2 294 433 | `6f2e04d02774a18f01bed44b1111f2cd7f3ba7ac9dc4373cd3f898a40ea6b464` |
| `fra.traineddata` | 1 130 365 | `ced037562e8c80c13122dece28dd477d399af80911a28791a66a63ac1e3445ca` |
| `pol.traineddata` | 4 765 518 | `c4476cdbc0e33d898d32345122b7be1cbf85ace15f920f06c7714756e1ef79b2` |
| `tur.traineddata` | 4 550 554 | `7393381111e1152420fc4092cb44eef4237580d21b92bf30d7d221aad192c6b7` |
| `rus.traineddata` | 3 861 738 | `e16e5e036cce1d9ec2b00063cf8b54472625b9e14d893a169e2b0dedeb4df225` |
| `ukr.traineddata` | 3 825 102 | `d59e53e2bded32f4445f124b4b00240fcac7e8044c003ab822ccb94f0b3db59b` |
| `ara.traineddata` | 1 432 056 | `e3206d3dc87fd50c24a0fb9f01838615911d25168f4e64415244b67d2bb3e729` |
| `fas.traineddata` | 431 500 | `db1c0a91208aff00d3cf1ed2c1d23f76419afd5f024688b4f71adc3f2ce4a505` |

Gemessen am 19.10.2026 aus demselben Download, in dem `deu` und `eng` ihre
oben genannten Prüfsummen hatten.

Lizenz: Apache License 2.0, siehe `LICENSE`.
