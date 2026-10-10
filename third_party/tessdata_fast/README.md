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

Lizenz: Apache License 2.0, siehe `LICENSE`.
