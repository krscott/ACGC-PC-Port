# Run recipes inside `nix develop` (Linux) or `nix develop .#windows` (Windows).

default:
    @just --list

# Build the 32-bit Linux executable.
linux:
    @test "${ACGC_TARGET:-}" = linux || { echo 'Run this recipe with: nix develop -c just linux' >&2; exit 1; }
    cmake -S pc -B build/linux -G Ninja -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX"
    cmake --build build/linux --parallel "${NIX_BUILD_CORES:-4}"

# Cross-compile the 32-bit Windows executable and copy its runtime DLLs.
windows:
    @test "${ACGC_TARGET:-}" = windows || { echo 'Run this recipe with: nix develop .#windows -c just windows' >&2; exit 1; }
    cmake -S pc -B build/windows -G Ninja -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=i686 -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_RC_COMPILER="$RC" -DSDL2_DLL_PATH="$SDL2_DLL_PATH"
    cmake --build build/windows --parallel "${NIX_BUILD_CORES:-4}"
    install -m755 "$WINDOWS_DLL_DIR"/bin/*.dll build/windows/bin/

# Run beside the shaders, using the repository's rom/ directory.
[positional-arguments]
run *args: linux
    test -e build/linux/bin/rom || test -L build/linux/bin/rom || ln -s ../../../rom build/linux/bin/rom
    cd build/linux/bin && ./AnimalCrossing "$@"

# Run on a private display with software graphics (requires framewisp on PATH).
[positional-arguments]
headless *args:
    framewisp acgc run --x11 -- env SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=x11 LIBGL_ALWAYS_SOFTWARE=1 SDL_VIDEO_X11_FORCE_EGL=1 __EGL_VENDOR_LIBRARY_FILENAMES="$ACGC_EGL_VENDOR_FILE" just run "$@"
