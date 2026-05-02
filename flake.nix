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

      mkZenplus = pkgs_: pkgs_.linux_latest.override {
        kernelPatches = [
          { name = "BORE"; patch = ./patches/bore.patch; }
          { name = "cgroup-vram"; patch = ./patches/cgroup-vram.patch; }
          { name = "glitched-base"; patch = ./patches/glitched-base.patch; }
        ];
        structuredExtraConfig = with pkgs_.lib.kernel; {
          SCHED_BORE = yes;
          PREEMPT_DYNAMIC = yes;
          HZ_1000 = yes;
          HZ = freeform "1000";
          CACHY = yes;
          #GENERIC_CPU = no;
          #MZEN4 = yes;
          #X86_NATIVE_CPU = no;
        };
        ignoreConfigErrors = true;
      };

      zenplus = mkZenplus pkgs;

    in {
      packages.${system} = {
        linux-zenplus = zenplus;
        default = self.packages.${system}.linux-zenplus;
        zenplusPackages = pkgs.linuxPackagesFor zenplus;
      };

      overlays.default = final: prev: {
        linux_zenplus = mkZenplus final;
        linuxPackages_zenplus = final.linuxPackagesFor final.linux_zenplus;
      };
    };
}