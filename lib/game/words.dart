/// Letras do jogo, em ordem.
class LetterInfo {
  const LetterInfo(this.letter);
  final String letter;
}

final letters = <LetterInfo>[
  for (var c = 65; c <= 90; c++) LetterInfo(String.fromCharCode(c)),
];
