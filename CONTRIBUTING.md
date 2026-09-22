# Contributing

Issues and pull requests are welcome. Keep changes focused, preserve Delphi and
Free Pascal compatibility, and include regression coverage for behavior changes.

Initialize the binding submodule after cloning:

```sh
git submodule update --init --recursive
```

Binding changes belong in `nalilord/SDL3-for-Pascal`; update the `Lib/SDL3`
submodule pointer here only after that binding revision is available upstream.

## Before opening a pull request

Run the source-policy checks:

```sh
node Tools/check-pascal-style.js
bash Tests/test-unit-dependencies.sh
```

When the required compiler and SDL runtime are available, run both complete
suites:

```sh
bash Tests/run-tests.sh Win64
bash Tests/run-tests.sh Linux64
```

Use an unused `OUTPUT_ROOT` when retaining fresh build evidence. The XML loader
is Delphi-only; that exclusion is intentional on FPC.

## Code and architecture

- Follow the [code style guide](Docs/CODE_STYLE.md); the automated checker covers
  the mechanical rules.
- Put concrete controls in their responsibility-based `Controls.*` owner.
- Foundation units must not depend on concrete control categories or aggregate
  facades. Categories must not import aggregate facades.
- Preserve ownership, callback ordering, and callback-lifetime guards.
- Add visual evidence in both themes for rendering changes.

See the [architecture guide](Docs/ARCHITECTURE.md) for the owner map, dependency
rules, subclass hooks, and public migration guidance.
