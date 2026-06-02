class ModerationKeywordMatch {
  const ModerationKeywordMatch({
    required this.category,
    required this.keyword,
  });

  final String category;
  final String keyword;
}

const Map<String, List<String>> moderationKeywordGroups = {
  'drugs': ['drogas', 'drug', 'weed', 'cocaine', 'mdma'],
  'sex': ['sexo', 'sex', 'hookup'],
  'self_harm': ['suicidio', 'suicide', 'self harm'],
  'violence': ['pelea', 'fight', 'kill', 'matar'],
  'vandalism': ['graffiti', 'vandalizar', 'vandalism'],
  'spam': ['crypto', 'casino', 'betting'],
};

String normalizeModerationText(String value) {
  final lower = value.toLowerCase();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

List<ModerationKeywordMatch> findModerationKeywordMatches(String value) {
  final normalized = normalizeModerationText(value);
  final matches = <ModerationKeywordMatch>[];

  for (final entry in moderationKeywordGroups.entries) {
    for (final keyword in entry.value) {
      final normalizedKeyword = normalizeModerationText(keyword);
      if (normalized.contains(normalizedKeyword)) {
        matches.add(
          ModerationKeywordMatch(category: entry.key, keyword: keyword),
        );
      }
    }
  }

  return matches;
}
