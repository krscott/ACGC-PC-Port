{
  description = "32-bit Linux and Windows development shells for Animal Crossing";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      linux = pkgs.pkgsi686Linux;
      windows = pkgs.pkgsCross.mingw32;
      # MinGW uses the system WGL library, not nixpkgs' Unix libGL dependency.
      windowsSDL3 = (windows.sdl3.override { traySupport = false; }).overrideAttrs (old: {
        cmakeFlags = old.cmakeFlags ++ [ "-DSDL_OPENGL=ON" ];
      });
      windowsSDL2 = windows.SDL2.override { sdl3 = windowsSDL3; };
      tools = with pkgs; [ cmake ninja pkg-config just ];
    in
    {
      devShells.${system} = {
        default = linux.mkShell {
          nativeBuildInputs = tools;
          buildInputs = [ linux.SDL2 linux.libGL ];
          ACGC_TARGET = "linux";
          # SDL loads the OpenGL driver at runtime. NixOS exposes 32-bit drivers here.
          LD_LIBRARY_PATH = "/run/opengl-driver-32/lib:${pkgs.lib.makeLibraryPath [ linux.libGL linux.mesa ]}";
        };

        windows = windows.mkShell {
          nativeBuildInputs = tools;
          buildInputs = [ windowsSDL2 ];
          ACGC_TARGET = "windows";
          # sdl2-compat puts its DLL in the dev output alongside sdl2-config.
          SDL2_DLL_PATH = "${windowsSDL2.dev}/bin/SDL2.dll";
          WINDOWS_DLL_DIR = pkgs.symlinkJoin {
            name = "animal-crossing-windows-runtime";
            paths = [
              windowsSDL2.dev
              (pkgs.lib.getBin windowsSDL3)
              (pkgs.lib.getBin windows.windows.mcfgthreads)
            ];
          };
        };
      };
    };
}
