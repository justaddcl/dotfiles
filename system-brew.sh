#!/usr/bin/env bash

function brewSystem() {
  ./brew.sh;
  ./mas.sh;
  ./install-configs.sh
}

read -p "This will install Homebrew and associated formulae, cask and some apps, plus some MAS apps. Ready? (y/n) " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
	brewSystem;
fi;
unset brewSystem;