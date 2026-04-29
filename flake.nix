{
  description = "Custom Build of the NixOS zen kernel made to be more like the TKG kernel with appropriate patches";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # while the kernel is named zenplus, only use the linux_latest - zenplus just sounds better 
      zenplus = pkgs.linux_latest.override {
        kernelPatches = [
          {
            name = "BORE";
            patch = .patches/bore.patch;
          }
          {
            name = "cgroup-vram";
            patch = ./patches/cgroup-vram.patch;
          }
          {
            name = "glitched-base"; # From TKG
            patch = ./patches/glitched-base.patch;
          }
        ];

        structuredExtraConfig = with pkgs.lib.kernel; {
          # BORE Scheduler
          SCHED_BORE = yes;
          SCHED_AUTOGROUP = pkgs.lib.mkForce no;

          # Cachy/Gaming Optimizations - patch not in yet
          #CACHY = yes;
          #MQ_IOSCHED_ADIOS = yes;

          # Timing & Preemption
          PREEMPT_DYNAMIC = yes;
          HZ_1000 = yes;
          HZ = freeform "1000";
          NO_HZ_IDLE = yes;

          # CPU Architecture Optimization (x86_64-v3)
          GENERIC_CPU = no; # Disable generic to ensure version-specific optimization
          X86_64_VERSION = freeform "3";

          # Memory Management
          TRANSPARENT_HUGEPAGE_ALWAYS = pkgs.lib.mkForce yes;
        };

        ignoreConfigErrors = true;
      };

    in {
      # Output the raw kernel
      packages.${system}.default = zenplus;

      # The allows the use of 'pkgs.linuxPackages_zenplus' in your NixOS configuration
      overlays.default = final: prev: {
        linuxPackages_zenplus = prev.linuxPackagesFor zenplus;
      };
    };
}