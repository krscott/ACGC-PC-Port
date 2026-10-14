{
  description = "32-bit Linux and Windows development shells for Animal Crossing";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      linux = pkgs.pkgsi686Linux;
      windows = pkgs.pkgsCross.mingw32;
      tools = with pkgs; [ cmake ninja pkg-config just ];
    in
    {
      devShells.${system} = {
        default = linux.mkShell {
          nativeBuildInputs = tools;
          buildInputs = [ linux.SDL2 linux.libGL ];
          ACGC_TARGET = "linux";
          # SDL loads the OpenGL driver at runtime. NixOS exposes 32-bit drivers here.
          LD_LIBRARY_PATH = "/run/opengl-driver-32/lib:${pkgs.lib.makeLibraryPath [ linux.mesa ]}";
        };

        windows = windows.mkShell {
          nativeBuildInputs = tools;
          buildInputs = [ windows.SDL2 ];
          ACGC_TARGET = "windows";
          # sdl2-compat puts its DLL in the dev output alongside sdl2-config.
          SDL2_DLL_PATH = "${windows.SDL2.dev}/bin/SDL2.dll";
          WINDOWS_DLL_DIR = pkgs.symlinkJoin {
            name = "animal-crossing-windows-runtime";
            paths = [
              windows.SDL2.dev
              (pkgs.lib.getBin (windows.sdl3.override { traySupport = false; }))
              (pkgs.lib.getBin windows.windows.mcfgthreads)
            ];
          };
        };
      };
    };
}
