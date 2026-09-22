# Third-party notices

The repository's MIT license covers project-owned PasSDL3-GUI code. Third-party
materials keep their own licenses.

## SDL3-for-Pascal

The `Lib/SDL3` Git submodule points directly to
[nalilord/SDL3-for-Pascal](https://github.com/nalilord/SDL3-for-Pascal), a
Delphi-capable fork of
[PascalGameDevelopment/SDL3-for-Pascal](https://github.com/PascalGameDevelopment/SDL3-for-Pascal).
Its units are distributed under the zlib license included in the submodule as
`LICENSE.md`. Individual source files may retain additional embedded notices,
including the dual MPL 1.1/LGPL notice in `jedi.inc` and the HIDAPI notice in
`SDL_hidapi.inc`.

## Unicode data

Unicode conformance/reference data under `Tests/Unicode` is distributed under the
Unicode License v3 included at `Tests/Unicode/LICENSE.txt`.

## Native SDL libraries

SDL3 and SDL3_ttf runtime libraries are not committed to this repository. Their
upstream projects use the zlib license; obtain binaries or sources from the
[SDL releases](https://github.com/libsdl-org/SDL/releases) and
[SDL_ttf releases](https://github.com/libsdl-org/SDL_ttf/releases).
