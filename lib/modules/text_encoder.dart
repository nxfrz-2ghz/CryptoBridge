// modules/text_encoder.dart
import 'dart:typed_data';
import 'dart:convert';

ByteCoder byteCoder = ByteCoder();
class ByteCoder {

  Future<Uint8List> encodeText(String text) async {
    Uint8List bytes = Uint8List.fromList(utf8.encode(text));
    return bytes;
  }

  Future<String> decodeText(Uint8List bytes) async {
    String text = utf8.decode(bytes);
    return text;
  }

}

const EnglishSyllableDictionary = [
  "ing", "er", "a", "ly", "ed", "i", "es", "re", "tion", "in",
  "e", "con", "y", "ter", "ex", "al", "de", "com", "o", "di",
  "en", "an", "ty", "ry", "u", "ti", "ri", "be", "per", "to",
  "pro", "ac", "ad", "ar", "ers", "ment", "or", "tions", "ble", "der",
  "ma", "na", "si", "un", "at", "dis", "ca", "cal", "man", "ap",
  "po", "sion", "vi", "el", "est", "la", "lar", "pa", "ture", "for",
  "is", "mer", "pe", "ra", "so", "ta", "as", "col", "fi", "ful",
  "ger", "low", "ni", "par", "son", "tle", "day", "ny", "pen", "pre",
  "tive", "car", "ci", "mo", "on", "ous", "pi", "se", "ten", "tor",
  "ver", "ber", "can", "dy", "et", "it", "mu", "no", "ple", "cu",
  "fac", "fer", "gen", "ic", "land", "light", "ob", "of", "pos", "tain",
  "den", "ings", "mag", "ments", "set", "some", "sub", "sur", "ters", "tu",
  "af", "au", "cy", "fa", "im", "li", "lo", "men", "min", "mon",
  "op", "out", "rec", "ro", "sen", "side", "tal", "tic", "ties", "ward",
  "age", "ba", "but", "cit", "cle", "co", "cov", "da", "dif", "ence",
  "ern", "eve", "hap", "ies", "ket", "lec", "main", "mar", "mis", "my",
  "nal", "ness", "ning", "n't", "nu", "oc", "pres", "sup", "te", "ted",
  "tem", "tin", "tri", "tro", "up", "va", "ven", "vis", "am", "bor",
  "by", "cat", "cent", "ev", "gan", "gle", "head", "high", "il", "lu",
  "me", "nore", "part", "por", "read", "rep", "su", "tend", "ther", "ton",
  "try", "um", "uer", "way", "ate", "bet", "bles", "bod", "cap", "cial",
  "cir", "cor", "coun", "cus", "dan", "dle", "ef", "end", "ent", "ered",
  "fin", "form", "go", "har", "ish", "lands", "let", "long", "mat", "meas",
  "mem", "mul", "ner", "play", "ples", "ply", "port", "press", "sat", "sec",
  "ser", "south", "sun", "the", "ting", "tra", "tures", "val", "var", "vid",
  "wil", "win", "won", "work", "act", "ag"
];


WordCoder wordCoder = WordCoder(EnglishSyllableDictionary);
class WordCoder {
  final List<String> dictionary;

  late final Map<String, int> _reverse =
  Map.fromEntries(dictionary.asMap().entries.map((e) => MapEntry(e.value, e.key)));

  WordCoder(this.dictionary);

  Future<Uint8List> toBytes(String syllablesText) async {
    final syllables = syllablesText.trim().isEmpty
        ? <String>[]
        : syllablesText.trim().split(RegExp(r'\s+'));

    return Uint8List.fromList(
      syllables.map((s) => _reverse[s] ?? 255).toList(),
    );
  }

  Future<String> toWords(Uint8List bytes) async {
    final wordsList = bytes.map((b) => dictionary[b]).toList();
    return wordsList.join(' ');
  }
}