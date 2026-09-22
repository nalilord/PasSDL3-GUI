# Architecture and migration guide

The control extraction completed on 2026-09-22. Each concrete control now has
one implementation owner; `PasSDL3.GUI` and `PasSDL3.GUI.Controls` are convenient
aggregate entry points, not implementation containers.

## Unit ownership

| Unit | Primary public ownership |
| --- | --- |
| `PasSDL3.GUI.Types` | Geometry, color, brush, drawable, style, and input-event value types |
| `PasSDL3.GUI.Core` | `TGuiControl`, `TGuiContainer`, `TGuiPopupControl`, base events/layout state, the context-services contract, and shared scroll/focus helpers |
| `PasSDL3.GUI.Context` | `TGuiContext`, layer controls/kinds, focus, capture, modal state, routing, tooltips, and scheduled interaction updates |
| `PasSDL3.GUI.Controls.Containers` | Panels, frames, stack/grid/scroll containers, group boxes, transparent containers, and splitter |
| `PasSDL3.GUI.Controls.Text` | Labels, value labels, edit, memo, spin edit, and editor state |
| `PasSDL3.GUI.Controls.Images` | Image/icon controls and image-fit behavior |
| `PasSDL3.GUI.Controls.Buttons` | Button, delay/round/speed/toggle buttons, checkbox, radio button, and toggle switch |
| `PasSDL3.GUI.Controls.Range` | Slider, range slider, knob, scrollbar, and their interaction types |
| `PasSDL3.GUI.Controls.Progress` | Progress bar and activity indicator |
| `PasSDL3.GUI.Controls.Lists` | List/check/switch/radio lists, wheel picker, tree, header, list view, item template, and combo box |
| `PasSDL3.GUI.Controls.Pages` | Tab button, page indicator, tab/page controls, pages, and tab item state |
| `PasSDL3.GUI.Controls.Menus` | Menu items, menu/popup bars, dropdown button, and menu helpers |
| `PasSDL3.GUI.Controls.Bars` | Toolbar, command bar, status bar, and separator |
| `PasSDL3.GUI.Controls.Charts` | Dial gauge, scope, and scope marker |
| `PasSDL3.GUI.Controls.Dialogs` | Dialog, modal overlay, window modes/states, results, and title buttons |
| `PasSDL3.GUI.Theme` / `.Theme.Files` | Theme data/application and optional INI persistence |
| `PasSDL3.GUI.Host.SDL3` / adapters | SDL event, rendering, clipboard, font, and host integration |

Use `PasSDL3.GUI` in applications that want the complete public facade. Use the
smallest owning unit in libraries, custom controls, and compile-boundary tests.
`PasSDL3.GUI.Controls.Base` remains the base-control entry point and
`PasSDL3.GUI.Layout` remains the layout-container entry point.

Code that previously imported a concrete widget from `PasSDL3.GUI.Core` must now
import its category, `PasSDL3.GUI.Controls`, or `PasSDL3.GUI`. `Core` deliberately
does not re-export concrete widgets because doing so would reverse the dependency
direction and recreate a cycle.

## Dependency direction

Dependencies flow from applications and aggregate facades through integration and
control categories to `Core`, then to low-level value/text/canvas services.
Foundation units do not import control categories. Categories do not import the
aggregate units. Categories may depend on another category for real inheritance or
composition, but the graph must stay acyclic. The dependency checker records the
approved edges, including `Context -> Controls.Containers` for `TGuiLayerControl`.

Concrete context access is intentionally hidden behind `TGuiContextServices` in
`Core`. Controls use that non-owning contract for focus, modal, popup, and detach
operations. Theme, XML, and SDL host units are integration consumers and may import
the concrete categories they inspect.

## Subclass contracts

Custom controls normally derive from `TGuiControl` or a category class and override
only the narrowest relevant hook:

- `PaintSelf` draws the control; `Paint` and `PaintOverlay` retain traversal and
  clipping responsibilities.
- `Measure`, `Arrange`, `InvalidateLayout`, and `CompleteArrange` participate in
  layout. Child bounds are local to the parent.
- `HandleEvent`, `HitTest`, `HitTestOverlay`, `MouseCursorAt`, and
  `DispatchShortcut` customize input without bypassing context routing.
- `UpdateInteraction` handles timed repeat, hold, motion, or secondary-repeat work.
- `DetachedFromContext` releases non-owning interaction state; it must not free the
  context.
- `BeforePointerRelease`, `BeforeFocusedActivation`, `SuppressReleaseClick`, and
  the focus-scope/navigation hooks exist for specialized interaction semantics.
- Prefer the category-specific paint/format/search/animation hooks where present
  instead of reimplementing a complete control event path.

Callbacks may remove controls. Existing lifetime guards and post-callback exits are
part of the behavioral contract and must be preserved by overrides.

## Ownership and lifetime

`Parent.Add(Child)` transfers child ownership. `Remove` detaches without freeing;
`Clear` frees all children. Destruction of an attached control detaches it and clears
context references. A context owns its root and layers. An SDL host owns a context
only when the host created it.

Fonts, font collections, textures, and the SDL renderer remain caller-owned. Free
font caches/collections before their renderer. Resource regions refer to textures;
they do not own native SDL textures. Event handlers and `Data` are non-owning
references unless a more specific API explicitly says otherwise.

## Public field migration

Public class and record storage now follows the style guide: storage is private and
`F`-prefixed, while the established public names remain read/write properties. This
preserves ordinary assignments such as:

```pascal
Control.Bounds:=GuiRect(10, 10, 100, 30);
Style.BorderWidth:=1;
```

Delphi does not permit writing through a record-valued property. Migrate an old
nested field write by copying, changing, and assigning the complete value:

```pascal
Bounds:=Control.Bounds;
Bounds.Width:=200;
Control.Bounds:=Bounds;

Style:=Control.Style;
Style.Background:=GuiColorDrawable(GuiColor(20, 30, 40));
Control.Style:=Style;
```

The same rule applies to `Theme.Metrics`, event `Position`/`Delta`, padding/margins,
and any property passed to a `var`/`out` parameter. This is an intentional source
migration; direct field addresses and binary record-layout compatibility are not
promised.

## Supported checks

Run from the repository root:

```sh
node Tools/check-pascal-style.js
bash Tests/test-unit-dependencies.sh
bash Tests/run-category-import-tests.sh Win64
bash Tests/run-category-import-tests.sh Linux64
bash Tests/run-tests.sh Win64
bash Tests/run-tests.sh Linux64
```

Use an unused `OUTPUT_ROOT` for fresh evidence. Build the normal interactive lab
with:

```sh
bash build-wsl-generic.sh Examples/01_test_lab/TestLab.dpr Win64
bash build-wsl-generic.sh Examples/01_test_lab/TestLab.dpr Linux64
```

The XML loader is Delphi-only. Automated SDL runs use the dummy video driver and
do not certify physical gamepads, native IME candidate UI, native cursor appearance,
clipboard integration, or mixed-DPI displays. The available manual platform scope
is Windows with mouse and keyboard.
