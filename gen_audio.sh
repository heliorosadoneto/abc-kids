#!/bin/bash
# Gera vozes pt-BR offline com Piper (voz pt_BR-cadu-medium) + efeitos sintetizados com ffmpeg.
# Letra: devagar (length_scale 1.7), +2 semitons, 150 ms de silêncio inicial, volume normalizado.
# Palavra: alegre (length_scale 1.25), +3 semitons.
set -e
cd "$(dirname "$0")"
V=~/piper/voices/pt_BR-cadu-medium.onnx
rm -f assets/audio/*.mp3
say() { # texto, saída, length_scale, fator de tom
  echo "$1" | ~/piper/bin/piper -m $V --length_scale $3 --sentence_silence 0 -f /tmp/say.wav >/dev/null 2>&1
  SR=$(ffprobe -v error -show_entries stream=sample_rate -of csv=p=0 /tmp/say.wav)
  ffmpeg -nostdin -loglevel error -y -i /tmp/say.wav -af "asetrate=$SR*$4,aresample=44100,atempo=1/$4,silenceremove=start_periods=1:start_threshold=-45dB,adelay=150,apad=pad_dur=0.15,loudnorm=I=-14:TP=-1.5" -ac 1 -b:a 64k "$2"
}
while IFS='|' read l name word; do
  say "$name." assets/audio/letra_$l.mp3 1.7 1.12
  say "$word!" assets/audio/palavra_$l.mp3 1.25 1.19
done < words.txt
# efeitos
ffmpeg -nostdin -loglevel error -y -f lavfi -i "sine=f=520:d=0.2" -af "vibrato=f=18:d=0.6,afade=t=out:st=0.03:d=0.17,volume=0.7" -b:a 64k assets/audio/pop.mp3
ffmpeg -nostdin -loglevel error -y -f lavfi -i "aevalsrc='0.4*sgn(sin(2*PI*(220+25*sin(2*PI*6*t))*t))*(0.5+0.5*sin(2*PI*3*t))':d=1.2:s=44100" -af "lowpass=f=1800,afade=t=in:d=0.1,afade=t=out:st=0.9:d=0.3,volume=0.5" -b:a 64k assets/audio/efeito_A.mp3
