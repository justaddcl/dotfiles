# dotfiles

A collection of scripts to run that aim to automate setting up a new Mac

## Usage

To run the script direct you can use curl with the following command

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/justaddcl/dotfiles/main/system-brew.sh)"
```

### Marta

To use the config and themes for [Marta](https://marta.sh/) file manager, once you have this repo cloned to your local machine, you'll want to symlink from the Marta install location into Marta configs directory in this repository. This will allow Marta to use the configs, while syncing any changes to git.

- The install location may look something like: `/Users/{user}/Library/Application Support/org.yanex.marta`

1. Once in the Marta install directory, symlink the config file:
   ```bash
   ln -s {location/of/this/repo/dotfiles}/configs/marta/conf.marco conf.marco
   ```
2. Symlink the Dracula theme:
   ```bash
   ln -s {location/of/this/repo/dotfiles}/configs/marta/Themes/Dracula.theme Themes/Dracula.theme
   ```
