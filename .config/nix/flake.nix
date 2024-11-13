{
  description = "JustAddCL Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
	  pkgs.appcleaner
	  pkgs.arc-browser
	  pkgs.bat
	  pkgs.bat-extras.batman
	  pkgs.bat-extras.batgrep
	  pkgs.bat-extras.batdiff
	  pkgs.bat-extras.prettybat
	  pkgs.docker
	  pkgs.drawio
	  pkgs.fira-code
	  pkgs.fzf
	  pkgs.gifski
	  pkgs.gh
	  pkgs.git
	  pkgs.hidden-bar
	  pkgs.iina
	  pkgs.jq
	  pkgs.mkalias
	  pkgs.neovim
	  pkgs.oh-my-posh
	  pkgs.postman
	  pkgs.raycast
	  pkgs.rectangle
	  pkgs.ripgrep
	  pkgs.spotify
	  pkgs.stow
	  pkgs.tableplus
	  pkgs.tree
	  pkgs.typescript
	  pkgs.unzip
	  pkgs.vscode
	  pkgs.wget
	  pkgs.zsh-autosuggestions
	  pkgs.zsh-syntax-highlighting
	  pkgs.zoxide
        ];


      homebrew = {
        enable = true;
	brews = [
	  "git-delta"
	  "mas"
	  "node"
	];
	casks = [
          "1password"
	  "adobe-creative-cloud"
	  "clipy"
	  "discord"
	  "disk-inventory-x"
	  "docker"
	  "figma"
	  "font-fira-code"
	  "font-fira-mono-for-powerline"
	  "fliqlo"
	  "flux"
	  "font-inconsolata-for-powerline"
	  "itsycal"
	  "linear-linear"
	  "marta"
	  "nordvpn"
	  "notion"
	  "numi"
	  "paragon-ntfs"
	  "rocket"
	  "shottr"
	  "signal"
	  "steam"
	  "webull"
	  "warp"
	  "whatsapp"
	];
	masApps = {
	  "AmorphousDiskMark" = 1168254295;
	  "Amphetamine" = 937984704;
	  "Engergiza" = 1643751440; 
	  "MusicHarbor" = 1440405750;
	  "1PasswordForSafari" = 1569813296;
	};
	onActivation.cleanup = "zap";
	# onActivation.autoUpdate = true;
	# onActivation.upgrade = true;
      };

      fonts.packages = [
	(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];

      system.activationScripts.applications.text = let
	  env = pkgs.buildEnv {
	    name = "system-applications";
	    paths = config.environment.systemPackages;
	    pathsToLink = "/Applications";
	  };
	in
	  pkgs.lib.mkForce ''
	  # Set up applications.
	  echo "setting up /Applications..." >&2
	  rm -rf /Applications/Nix\ Apps
	  mkdir -p /Applications/Nix\ Apps
	  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
	  while read src; do
	    app_name=$(basename "$src")
	    echo "copying $src" >&2
	    ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
	  done
	      '';

      system.defaults = {
	## Dock settings
        dock.autohide = true;
	# magnificiation
	dock.magnification = false;
	dock.tilesize = 32;

	dock.persistent-apps = [
	  "/Applications/Notion.app"
	  "/System/Applications/Calendar.app"
	  "/System/Applications/Music.app"
	  "${pkgs.spotify}/Applications/Spotify.app"
	  "${pkgs.arc-browser}/Applications/Arc.app"
	  "/Applications/Steam.app"
	  "${pkgs.vscode}/Applications/Visual Studio Code.app"
	  "/Applications/Linear.app"
	  "/Applications/Warp.app"
	  "/Applications/Docker.app"
	  "/Applications/Figma.app"
	  "/System/Applications/Messages.app"
	  "/Applications/WhatsApp.app"
	  "/Applications/Discord.app"
	  "/Applications/NordVPN.app"
	  "/System/Applications/System Settings.app"
	];
	dock.persistent-others = [
	  "~/Applications"
	  "~/Users/yuji/Downloads"
	];

	## Mouse and trackpad settings
	# disable "natural" scrolling direction
        NSGlobalDomain."com.apple.swipescrolldirection" = false;

	## Finder settings
	# Set preferred view style as list
	finder.FXPreferredViewStyle = "Nlsv";
	
	finder.ShowPathbar = true;

	finder.ShowStatusBar = true;
	
	# Always show hidden files
	NSGlobalDomain.AppleShowAllFiles = true;

	## Clock settings
	# User 24-hour time
	NSGlobalDomain.AppleICUForce24HourTime = true;
	menuExtraClock.Show24Hour = true;
	menuExtraClock.ShowSeconds = true;
	menuExtraClock.ShowDate = 2;
	menuExtraClock.ShowDayOfWeek = false;

	loginwindow.GuestEnabled = false;

	NSGlobalDomain.AppleInterfaceStyle = "Dark";
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."studio" = nix-darwin.lib.darwinSystem {
      modules = [ 
      configuration 
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
	  enable = true;
	  
	  enableRosetta = true;
	  
	  user = "yuji";
	};
      }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."studio".pkgs;
  };
}
