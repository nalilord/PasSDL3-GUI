#!/usr/bin/env bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${1:-Linux64}"
case "$platform" in Linux64|Win64) ;; *) printf 'Use Linux64 or Win64\n' >&2; exit 1 ;; esac
test_output="${OUTPUT_ROOT:-$task_root/Bin/Tests}"
if [[ "$test_output" != /* ]]; then test_output="$task_root/$test_output"; fi
export SDL_VIDEODRIVER=dummy
if [[ "$platform" == Win64 ]]; then
  export WSLENV="${WSLENV:+$WSLENV:}SDL_VIDEODRIVER"
fi

build_and_run() {
  local project="$1" name="$2" extra_arg="${3:-}"
  OUTPUT_ROOT="$test_output" bash "$task_root/build-wsl-generic.sh" "$project" "$platform"
  local executable="$test_output/$platform/$name"
  if [[ "$platform" == Win64 ]]; then
    cp "$task_root/Bin/Win64/SDL3.dll" "$task_root/Bin/Win64/SDL3_ttf.dll" "$test_output/Win64/"
    executable="$executable.exe"
  fi
  if [[ -n "$extra_arg" ]]; then "$executable" "$extra_arg"; else "$executable"; fi
}

bash "$task_root/Tests/test-style-check.sh"
bash "$task_root/Tests/test-unit-dependencies.sh"
build_and_run Tests/GraphemeTests.dpr GraphemeTests
build_and_run Tests/PublicApiTests.dpr PublicApiTests
build_and_run Tests/AllPublicApiTests.dpr AllPublicApiTests
build_and_run Tests/FoundationBoundaryTests.dpr FoundationBoundaryTests
build_and_run Tests/ImagesTests.dpr ImagesTests
build_and_run Tests/ImageCompatibilityTests.dpr ImageCompatibilityTests
build_and_run Tests/ProgressCompatibilityTests.dpr ProgressCompatibilityTests
build_and_run Tests/ChartsTests.dpr ChartsTests
build_and_run Tests/ChartsCompatibilityTests.dpr ChartsCompatibilityTests
build_and_run Tests/ContainersTests.dpr ContainersTests
build_and_run Tests/ContainersCompatibilityTests.dpr ContainersCompatibilityTests
build_and_run Tests/ButtonsCompatibilityTests.dpr ButtonsCompatibilityTests
build_and_run Tests/RangeCompatibilityTests.dpr RangeCompatibilityTests
build_and_run Tests/TextCompatibilityTests.dpr TextCompatibilityTests
build_and_run Tests/ListsCompatibilityTests.dpr ListsCompatibilityTests
build_and_run Tests/PagesCompatibilityTests.dpr PagesCompatibilityTests
build_and_run Tests/MenusCompatibilityTests.dpr MenusCompatibilityTests
build_and_run Tests/BarsCompatibilityTests.dpr BarsCompatibilityTests
build_and_run Tests/DialogsCompatibilityTests.dpr DialogsCompatibilityTests
bash "$task_root/Tests/run-category-import-tests.sh" "$platform"
build_and_run Tests/CoreTests.dpr CoreTests
build_and_run Tests/SDLTests.dpr SDLTests
build_and_run Examples/01_test_lab/TestLab.dpr TestLab -self-test
build_and_run Examples/00_basic_window/BasicWindow.dpr BasicWindow -smoke-test
build_and_run Examples/02_shop_menu/ShopMenu.dpr ShopMenu -smoke-test
build_and_run Examples/03_reactor_hud/ReactorHud.dpr ReactorHud -smoke-test
printf 'All tests and example smoke checks passed for %s.\n' "$platform"
