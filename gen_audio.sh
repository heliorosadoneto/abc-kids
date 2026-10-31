#!/bin/bash
# Efeitos sonoros 100% sintetizados com ffmpeg (sem samples de terceiros).
set -e
cd "$(dirname "$0")"
A=assets/audio
rm -f $A/*.mp3
# pop: estalo curto
ffmpeg -nostdin -loglevel error -y -f lavfi -i "sine=f=520:d=0.2" -af "vibrato=f=18:d=0.6,afade=t=out:st=0.03:d=0.17,volume=0.7" -b:a 64k $A/pop.mp3
# boing: mola (tom que sobe e oscila)
ffmpeg -nostdin -loglevel error -y -f lavfi -i "aevalsrc='0.6*sin(2*PI*(180*t+900*t*t-60*sin(2*PI*9*t)/(2*PI*9)))*exp(-3*t)':d=0.5:s=44100" -af "afade=t=in:d=0.01,afade=t=out:st=0.35:d=0.15,loudnorm=I=-16" -b:a 64k $A/boing.mp3
# whoosh: sopro rápido (ruído filtrado)
ffmpeg -nostdin -loglevel error -y -f lavfi -i "anoisesrc=d=0.35:c=pink:a=0.6" -af "bandpass=f=1200:w=900,afade=t=in:d=0.08,afade=t=out:st=0.12:d=0.23,volume=0.6" -b:a 64k $A/whoosh.mp3
