{
  description = "Latest Linux Kernel built with patches from TKG, Nobara, OGC & CachyOS";

# NOTE - the basis of this code has been AI Generated using Gemini - I am a beginner in Nix so I needed a base that I could work from
# NOTE - This is a rewrite I have made of the original, keeping syntax and everything the same


  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      patchDir = ./patches;
      
      customPatches = let
      # Filter so then only *.patch files show up
        files = builtins.attrNames (pkgs.lib.filterAttrs 
          (name: type: type == "regular" && pkgs.lib.hasSuffix ".patch" name) 
          (builtins.readDir patchDir));
      in map (file: {
        name = file;
        patch = "${patchDir}/${file}";
      }) files;

      # use latest kernel
      tkgKernel = pkgs.linux_latest.override {
        # allow the kernel to be called "linux-tkg" - this allows for easier setting in 
        argsOverride = {
          name = "linux-tkg";
        };

        kernelPatches = pkgs.linux_latest.kernelPatches ++ customPatches;
        
        structuredExtraConfig = with pkgs.lib.kernel; {
          O3 = yes;
          SCHED_ALT = yes;
        };
      };

    in {
      # The package exported by the flake
      packages.${system}.default = tkgKernel;

      # Add the Nix Overlay
      overlays.default = final: prev: {
        # wrap the kernel derivation into NixOS-compatible kernel packages
        linuxPackages_tkg = prev.linuxPackagesFor tkgKernel;
      };
    };
}