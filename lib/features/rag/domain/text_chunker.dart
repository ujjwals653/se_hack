/// Splits text into overlapping chunks of approximately [size] words.
/// [overlap] words from the end of each chunk are repeated at the start of the next,
/// so context isn't lost at chunk boundaries.
class TextChunker {
  final int size;
  final int overlap;

  const TextChunker({this.size = 400, this.overlap = 80});

  List<String> chunk(String text) {
    // Normalise whitespace
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    final chunks = <String>[];
    int start = 0;

    while (start < words.length) {
      final end = (start + size).clamp(0, words.length);
      final chunk = words.sublist(start, end).join(' ');

      // Skip very tiny fragments (likely just metadata)
      if (chunk.split(' ').length > 20) {
        chunks.add(chunk.trim());
      }

      if (end >= words.length) break;
      start += size - overlap;
    }

    return chunks;
  }
}
