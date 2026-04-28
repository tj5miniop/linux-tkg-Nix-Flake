{
  description = "Automatically patched Linux kernel using TKG patches";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Your Linux-tkg fork
    patch-source = {
      url = "tj5miniop/linux-tkg";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, patch-source }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Use the linux 7.0 patchest from the tkg kernel 
      patchFolder = "${patch-source}/linux-tkg-patches/7.0";

      # Use all patches from Folder
      customPatches = let
        patchFiles = builtins.attrNames (pkgs.lib.filterAttrs 
          (name: type: type == "regular" && pkgs.lib.hasSuffix ".patch" name) 
          (builtins.readDir patchFolder));
      in map (file: {
        name = file;
        patch = "${patchFolder}/${file}";
      }) patchFiles;

    in {
      packages.${system}.customKernel = pkgs.linux_latest.override {
        argsOverride = {
          # Combine Patches
          kernelPatches = pkgs.linux_latest.kernelPatches ++ customPatches;

          # Extra Patches/Configuration - will attempt to align with tkg later
          extraConfig = ''
            O3 y
            SCHED_ALT y
          '';
        };
      };

      overlays.default = final: prev: {
        linuxPackages_custom = prev.recurseIntoAttrs (prev.linuxPackagesFor self.packages.${system}.customKernel);
      };
    };
}