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
    cp -L "$WINDOWS_DLL_DIR"/bin/*.dll build/windows/bin/

# Run from the repository root to use rom/, save/, and settings beside the source.
[positional-arguments]
run *args: linux
    ./build/linux/bin/AnimalCrossing "$@"
