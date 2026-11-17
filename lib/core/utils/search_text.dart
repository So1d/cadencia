/// Normalização de texto para busca.
///
/// A pessoa digita "bistro" e espera achar "Bistrô"; digita "CAFÉ" e espera
/// achar "cafe". Sem normalizar, a comparação falha por detalhe de escrita, e
/// não por conteúdo.
library;

/// Acentos e cedilha que aparecem em português, mapeados para a letra base.
///
/// O mapa é pequeno de propósito: cobre o alfabeto usado no app sem depender
/// de um pacote de unicode.
const Map<String, String> _semAcento = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
};

/// Devolve o texto em minúsculas, sem acentos e sem espaços nas pontas.
///
/// É a forma canônica usada tanto no que a pessoa digita quanto no que é
/// pesquisado (título + observações).
String normalizeForSearch(String text) {
  final lower = text.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_semAcento[char] ?? char);
  }
  return buffer.toString();
}

/// Quebra a busca em palavras, já normalizadas.
///
/// Quem digita "enviar relatório" quer as duas palavras, não a frase exata.
/// Espaços repetidos não viram termos vazios.
List<String> searchTerms(String text) {
  final normalized = normalizeForSearch(text);
  if (normalized.isEmpty) return const [];
  return normalized
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
}
