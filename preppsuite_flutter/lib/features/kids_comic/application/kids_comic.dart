/// The shape of the children's comic, "Mila und Nuss".
///
/// Content, like the first aid guides, and kept the same way for the same
/// reason: a story has to be readable end to end, in one file per
/// language, and not scattered through the interface wording of the ARB
/// files. `kids_comic_de.dart`, `kids_comic_en.dart` and
/// `kids_comic_es.dart` hold the text; `kids_comic_test.dart` holds the
/// translations to the same chapters, the same pictures and the same
/// speakers in the same order, which is the part a compiler cannot check.
///
/// The pictures are cut from the comic's PDF edition into `assets/comic/`
/// by `tool/comic/cut_panels.py`. They carry no words of their own, only
/// each panel's number, so every language shares them; the words are set
/// by Flutter and follow the text size.
///
/// What the comic says follows the BBK's advice on emergency preparedness.
/// Mila, Nuss and the story are this app's own: the BBK declined the use
/// of its "Max und Flocke" comics, and nothing here is taken from them.
library;

import 'kids_comic_de.dart';
import 'kids_comic_en.dart';
import 'kids_comic_es.dart';

/// Who is talking in a speech bubble.
enum ComicSpeaker { mila, nuss, papa }

/// One speech bubble.
class ComicLine {
  const ComicLine(this.speaker, this.text);

  final ComicSpeaker speaker;
  final String text;
}

class ComicPanel {
  const ComicPanel({
    required this.image,
    required this.description,
    required this.lines,
  });

  /// The picture's id, which is also its file name under `assets/comic/`.
  final String image;

  /// What the picture shows, for a screen reader.
  final String description;

  final List<ComicLine> lines;

  String get asset => kidsComicAsset(image);
}

class ComicChapter {
  const ComicChapter({
    required this.id,
    required this.title,
    required this.lede,
    required this.panels,
    required this.note,
    required this.rulesTitle,
    required this.rules,
  });

  final String id;
  final String title;

  /// One or two sentences under the title.
  final String lede;

  final List<ComicPanel> panels;

  /// The box under the last panel: the one fact a grown-up reading along
  /// should not leave out.
  final String note;

  /// The chapter's line on the summary sheet, and its rules.
  final String rulesTitle;
  final List<String> rules;
}

class KidsComic {
  const KidsComic({
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.coverDescription,
    required this.speakers,
    required this.chapters,
    required this.numbers,
    required this.numbersNote,
    required this.parentsIntro,
    required this.parentsTips,
    required this.source,
  });

  final String title;
  final String subtitle;
  final String intro;
  final String coverDescription;

  /// The names on the bubbles.
  final Map<ComicSpeaker, String> speakers;

  final List<ComicChapter> chapters;

  /// The emergency numbers and what each is for, in the order shown.
  final List<({String number, String label})> numbers;

  /// What a child does before any of it.
  final String numbersNote;

  final String parentsIntro;
  final List<String> parentsTips;

  /// Where the advice comes from, and whose the story is.
  final String source;
}

/// The picture on the cover, which belongs to no chapter.
const kidsComicCover = 'titel';

/// The shapes of the pictures as they are cut, so the space is taken
/// before a picture has loaded and nothing of it is cropped.
const kidsComicCoverAspectRatio = 1400 / 713;
const kidsComicPanelAspectRatio = 976 / 553;

String kidsComicAsset(String image) => 'assets/comic/$image.webp';

/// The comic in the language being read, German being the fallback — the
/// same rule as the first aid guides, for the same reason. Spanish has
/// its own since #108: the comic gives no medical advice, so it needs no
/// professional review before it ships, unlike the first aid guides.
KidsComic kidsComic(String localeName) {
  final language = localeName.toLowerCase();
  if (language.startsWith('en')) return kidsComicEn;
  if (language.startsWith('es')) return kidsComicEs;
  return kidsComicDe;
}
