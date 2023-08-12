#!/usr/bin/env bash

# import util functions
[ -f ./utils.sh ] && . ./utils.sh

function brewSystem() {
  term_message cb "\nBrewing a new system."
  ./brew.sh;
  ./mas.sh;
  ./install-configs.sh
  term_message gb "\nSystem brew has completed."
}

read -p "This will install Homebrew and associated formulae, cask and some apps, plus some MAS apps. Ready? (y/n) " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
	brewSystem;
fi;
unset brewSystem;