#!/usr/bin/env bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${1:-Linux64}"

case "$platform" in
  Linux64|Win64) ;;
  *)
    printf 'Use Linux64 or Win64\n' >&2
    exit 1
    ;;
esac

test_output="${OUTPUT_ROOT:-$task_root/Bin/Tests}"
if [[ "$test_output" != /* ]]; then
  test_output="$task_root/$test_output"
fi

projects=(
  BaseImportTests
  ContainersImportTests
  ImagesImportTests
  TextImportTests
  ButtonsImportTests
  ListsImportTests
  RangeImportTests
  ProgressImportTests
  ChartsImportTests
  PagesImportTests
  MenusImportTests
  BarsImportTests
  DialogsImportTests
  ContextImportTests
  LayoutImportTests
)

for project in "${projects[@]}"; do
  OUTPUT_ROOT="$test_output" bash "$task_root/build-wsl-generic.sh" \
    "Tests/CategoryImports/$project.dpr" "$platform"
  executable="$test_output/$platform/$project"
  if [[ "$platform" == Win64 ]]; then
    executable="$executable.exe"
  fi
  "$executable"
done

printf 'All standalone category import tests passed for %s.\n' "$platform"
