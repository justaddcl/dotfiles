#!/usr/bin/env bash

# Mac App Store apps have IDs. You can find these
# with `mas search <name>`.

apps=(
  1168254295 # AmorphousDiskMark https://apps.apple.com/us/app/amorphousdiskmark/id1168254295?mt=12
  937984704 # Amphetamine: https://apps.apple.com/us/app/amphetamine/id937984704?mt=12
  1643751440 # Energiza https://apps.apple.com/us/app/energiza-battery-monitor/id1643751440?mt=12
  1423210932 # Flow - Focus & Pomodoro Timer: https://flowapp.info/
  1452452150 # Hidden Bar https://apps.apple.com/us/developer/dwarves-foundation/id1452452150
  1440405750 # MusicHarbor: https://apps.apple.com/us/app/musicharbor-track-new-music/id1440405750
)

for app in "${apps[@]}"; do
    mas install $app
done