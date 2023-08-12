#!/usr/bin/env bash
# import util functions
[ -f ./utils.sh ] && . ./utils.sh

# Copy settings over.
term_message cb "\nSetting up preferences..."

task_start "Copying preferences"
sudo cp configs/com.apple.dock.plist ~/Library/Preferences
sudo cp configs/com.apple.EmojiPreferences.plist ~/Library/Preferences
task_done "Preferences copied"

task_start "Copying ZSH config"
sudo cp configs/.zshrc ~/
task_end "ZSH config copied"

term_message cb "\nInstalling lockscreen."
desktop_pictures_dir='/Library/Caches/Desktop Pictures'

  task_start "Getting User UUID"
  uuidWithFieldName=$(dscl . -read "/Users/$USER" GeneratedUID)
  uuid=${uuidWithFieldName#'GeneratedUID: '}
  task_done "User UUID retrieved"
  # echo $uuid

  task_start "Checking for desktop pictures directories."

  # check if the /Library/Caches/Desktop Pictures directory exists
  if [ -d "$desktop_pictures_dir/" ]; then

      # check if there's a subfolder with the user's UUID
      if [ -d "$desktop_pictures_dir/$uuid/" ]; then
        task_done "Desktop pictures directories confirmed."
        task_start ""

        # check if a lockscreen.png already exists
        if [ -f "$desktop_pictures_dir/$uuid/lockscreen.png" ]; then
            task_fail "Lockscreen image already exists in $desktop_pictures_dir/$uuid. Skipping copy."
          else

            # check if repo has lockscreen to copy
            if [ -f ./configs/lockscreen.png ]; then
              cp "./configs/lockscreen.png" "$desktop_pictures_dir/$uuid/"
              task_done "Lockscreen image copied into $desktop_pictures_dir/$uuid."
            else
              task_fail "./configs/ does not have a lockscreen image to copy."
            fi
        fi
      else
        task_fail "Desktop pictures directory for $uuid does not exist."
      fi
  else
      task_fail "Error: /Library/Caches/Desktop Pictures/ directory does not exist."
  fi

  term_message gb "\nPreferences configuration completed."


