#!/usr/bin/env bash

# Mac App Store apps have IDs. You can find these
# with `mas search <name>`.

apps=(
  1423210932 # Flow - Focus & Pomodoro Timer
  1440405750 # MusicHarbor
)

for app in "${apps[@]}"; do
    mas install $app
done