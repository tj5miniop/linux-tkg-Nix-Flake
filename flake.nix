{
  description = "Kernel Flake for ZenPlus - a Linux Kernel for NIXOS (not based on the zen kernel but inspired by it)";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system; 
        config.allowUnfree = true; 
      };

      zenplus = pkgs.linux_latest.override {
        kernelPatches = [
          { name = "BORE"; patch = ./patches/bore.patch; }
          { name = "cgroup-vram"; patch = ./patches/cgroup-vram.patch; }
          { name = "glitched-base"; patch = ./patches/glitched-base.patch; }
        ];
        structuredExtraConfig = with pkgs.lib.kernel; {
          SCHED_BORE = yes;
          PREEMPT_DYNAMIC = yes;
          HZ_1000 = yes;
          HZ = freeform "1000";
          X86_64_VERSION = freeform "3";
        };
        ignoreConfigErrors = true;
      };

    in {
      packages.${system} = {
        # Point to the kernel derivation
        linux-zenplus = zenplus;
        # Make the kernel the default build target
        default = self.packages.${system}.linux-zenplus;
        # Export the full package set for kernel modules
        zenplusPackages = pkgs.linuxPackagesFor zenplus;
      };

      overlays.default = final: prev: {
        linuxPackages_zenplus = pkgs.linuxPackagesFor zenplus;
      };
    };
    };
}