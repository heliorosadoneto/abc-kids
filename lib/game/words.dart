/// Letra, palavra de exemplo e emoji ilustrativo.
class LetterInfo {
  const LetterInfo(this.letter, this.word, this.emoji);
  final String letter;
  final String word;
  final String emoji;
}

const letters = <LetterInfo>[
  LetterInfo('A', 'Abelha', '🐝'), LetterInfo('B', 'Bola', '⚽'),
  LetterInfo('C', 'Casa', '🏠'), LetterInfo('D', 'Dado', '🎲'),
  LetterInfo('E', 'Elefante', '🐘'), LetterInfo('F', 'Flor', '🌸'),
  LetterInfo('G', 'Gato', '🐱'), LetterInfo('H', 'Hipopótamo', '🦛'),
  LetterInfo('I', 'Igreja', '⛪'), LetterInfo('J', 'Jacaré', '🐊'),
  LetterInfo('K', 'Kiwi', '🥝'), LetterInfo('L', 'Leão', '🦁'),
  LetterInfo('M', 'Macaco', '🐵'), LetterInfo('N', 'Navio', '🚢'),
  LetterInfo('O', 'Ovo', '🥚'), LetterInfo('P', 'Pato', '🦆'),
  LetterInfo('Q', 'Queijo', '🧀'), LetterInfo('R', 'Rato', '🐭'),
  LetterInfo('S', 'Sol', '☀️'), LetterInfo('T', 'Tartaruga', '🐢'),
  LetterInfo('U', 'Uva', '🍇'), LetterInfo('V', 'Vaca', '🐮'),
  LetterInfo('W', 'Wafer', '🧇'), LetterInfo('X', 'Xícara', '☕'),
  LetterInfo('Y', 'Iô-iô', '🪀'), LetterInfo('Z', 'Zebra', '🦓'),
];
