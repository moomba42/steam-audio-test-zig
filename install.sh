#!/bin/sh

cd "$(dirname "$0")" || exit

if [ ! -e "libs" ]; then
  mkdir libs
fi

cd libs || exit

if [ ! -e "steamaudio.zip" ]; then
  curl -sL -o steamaudio.zip https://github.com/ValveSoftware/steam-audio/releases/download/v4.6.0/steamaudio_4.6.0.zip
fi

if [ ! -e "steamaudio" ]; then
  rm -rf steamaudio
  unzip steamaudio.zip
fi

cd ..

