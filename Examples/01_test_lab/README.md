# GUI Test Lab

An interactive test application built with the GUI framework itself. It includes
all **60 visual control classes** exported by the aggregate API and implemented
across `PasSDL3.GUI.Core`, `Context`, and the category units,
including the base container/control classes and context rendering layers.
Tree nodes, scope markers, resources, fonts, and context behavior are also exercised.

The menus/pages gallery includes an interactive `TGuiPageIndicator` synchronized
with the page control above it. Click the dots, use arrow keys or Home/End while
focused, or turn the mouse wheel. Tab selection updates the dots too. Indicators
are passive by default in application code; set `Interactive := True` to opt in.

Ranges & HUD includes an indeterminate progress bar beside the zero-range slider.
Set `TGuiProgressBar.Marquee := True` to enable this mode and `MarqueeInterval`
to adjust the full animation cycle in milliseconds. Switching it off restores
the existing determinate value; disabled controls show a static muted pulse.

Tabs & menus also demonstrates `TGuiSpeedButton`: Grid/List share a positive
`GroupIndex`, and the icon-only button uses `Checkable`. `Down` holds selection;
`AllowAllUp` permits deselecting a grouped button. Try Space/Enter after tabbing
to a tool, and the search edit beside the toolbar separator.

The same gallery has standalone `TGuiTabButton` examples beside the integrated
tab control. These show icon/caption and disabled states; arrow keys wrap through
enabled peers. Use `Down`/`OnChange` to connect these tabs to application content.

Radio buttons on Buttons & states support arrow-key selection within their
`GroupName`, skipping hidden/disabled peers. Programmatic `Checked := True`
now enforces the same exclusivity as clicking, and `OnChange` logs transitions.

Scroll to the bottom of Lists & selection for `TGuiRadioGroup`, a full-row,
scrollable option group. Click the caption or indicator, navigate with arrows or
Home/End/PageUp/PageDown, and verify wheel scrolling does not select another row.
Its `Items`, `ItemIndex`, and `OnChange` API also retains the list-box aliases
`SelectedIndex` and `OnSelect`.

Ranges & HUD has a release-only slider beneath the zero-range and marquee row.
Drag to preview, release to snap in steps of 10, or press Escape to cancel.
Use `Live`, `StepSize`, and `SnapMode` to configure this behavior; `PreviewValue`
exposes the thumb's pending value while `OnChange` reports committed changes.

Buttons & states includes `TGuiRoundButton` circles, pills, an icon-only example
and a disabled example. `Radius=-1` (default) follows the control size; set a
nonnegative radius for explicit rounding. This choice survives theme changes.

Scroll down on Ranges & HUD for `TGuiKnob`: circular/stepped/wrapping examples,
a horizontal relative knob with a custom semicircle, and a vertical deferred knob.
`InputMode` selects the gesture; `DragDistance` controls relative sensitivity.
`SetAngles` configures the clockwise arc in degrees from the rightward axis.
The wrapping example logs `OnWrapped` directions. Non-wrapping examples stop at
their endpoints when dragged through the arc gap; deferred wrapping reports the
preview crossing without committing the value until release.

The lab is extensive, not an exhaustive proof of every public method or possible
state combination. A control's presence, an automated behavior assertion, a
successful frame submission, and a human visual check are different results.

## Start it

From the project root:

```sh
bash build-wsl-generic.sh Examples/01_test_lab/TestLab.dpr Win64
./Bin/Win64/TestLab.exe
```

Or on Linux with FPC and SDL3/SDL3_ttf installed:

```sh
bash build-wsl-generic.sh Examples/01_test_lab/TestLab.dpr Linux64
./Bin/Linux64/TestLab
```

No image assets are needed: SDL generates the test atlas. Font discovery and
`PASSDL3_GUI_FONT` work as in the other examples. The initial window is 1280x900;
its minimum is 1000x760. Each gallery section scrolls to expose its lower samples,
and scrolls horizontally when the window is narrow.

## Coverage

The default Dark theme now uses rounded surfaces and quieter borders. Buttons
demonstrates a filled **Primary action**, neutral buttons, a **Quiet action**,
checked checkbox, and circular radio indicators. Tab selection uses an accent
underline; combos, dropdowns, spin fields, and tree branches use directional
glyphs. Switch to Reactor to compare the square HUD treatment. Use Tab to check
the inset focus outline, and hover/click the toggle to check selected-state
feedback. The theme INI roundtrip also checks corner-radius metrics.

Scroll down in Buttons & states for 28–31 px alignment samples and captions
with/without descenders. Compare body/mono/large fonts and both themes. Buttons
and selected rows now use subtle gradients; list/tree/table hover is separate
from the selected-row accent marker. Tab/gamepad navigation shows the focus
outline and halo by default; mouse clicks remove that keyboard treatment.

For customization and compatibility details, see [Styling](../../README.md#styling).

For scrollbar checks, use Ranges & HUD and scroll down in Layout & scrolling.
Grab each thumb near either end: it should stay under the grab point. Check idle,
hover, drag, both-axis gutters/corner, and content near the far scroll limits.
List boxes, memos, trees, and list views should use the same neutral thumb treatment.
On Lists & selection, use End/Home and PageDown/PageUp in the list box, then drag
its thumb. Selection must stay visible during keyboard navigation. Row highlights
in the list box, tree, and table extend beneath dimmed scrollbar lanes; text stays
clear of the thumbs. Clicking or dragging a scrollbar must not select another row.
Resize the window to verify the same geometry with shorter and taller viewports.
Open the 20-item combo and dropdown popups. Drag the thumb outside the popup,
release, click the track, and then select a scrolled item. Scrolling must leave
the popup open and selection unchanged. Empty/single-item popups have no bar.

Drag table header dividers and the standalone
header dividers on Lists & selection: check minimum widths, drag beyond the
header, release, and confirm row text stays aligned. The last table column fills
the remaining space automatically.

At the bottom of Layout & scrolling, compare equal-height scroll box, memo, tree,
and list-view samples side by side. Their scrollbar widths and outer-edge insets
should match; only the table's header shifts its track start. Thumb lengths can
differ because line heights, padding, and headers change the visible fraction.

| Section | Controls and cases |
| --- | --- |
| Buttons & states | Buttons; toggle; checkbox; radio exclusivity; four icon positions; link; enabled/disabled/hidden parent; mouse and keyboard activation; tooltip; hold-to-confirm delay buttons with checked/reset and disabled states |
| Text & editing | Labels and alignment; value label; editable/read-only/password/length-limited edits; multiline memo; clipboard; undo/redo; Unicode sample; native IME |
| Lists & selection | 20-item list/combo/dropdown; empty and single-item combo; tree branches; 100-row list view; standalone header; item template; radio group; scrollable checklist with checked/mixed/disabled rows; switch list with caption toggling and draggable indicators; wrapping hours/minutes wheels, nonwrapping quality wheel, empty and disabled wheels |
| Ranges & HUD | Both slider orientations; live/deferred/vertical/disabled/coincident two-thumb range sliders; both scrollbar orientations; live/deferred numeric spin editing, single-click/custom-repeat/wrapping variants and separate user-modification logs; zero range; segmented/ticked/threshold progress; reverse vertical progress; dial; animated scope |
| Layout & scrolling | Nested docking; padding/margins; anchors; frame header/footer; stack/grid; horizontal and vertical scrolling; splitter; group box; transparent containers; base classes |
| Tabs & menus | Standalone tabs; page control/pages and hidden-page focus; command menus with nested submenus, separators, checked/disabled items; toolbar; command bar; separator; status bar |
| Dialogs & layers | Embedded dialog and overlay; live modal/non-modal/nested dialogs; default/cancel results; debug layer; focus loss; gamepad navigation/hotplug checklist |
| Rendering & themes | Image; stretch/contain/cover icons; resource atlas; nine-slice skin; line widths; nested clipping; alpha; three font roles; theme INI roundtrip; cache clear; logical presentation |
| Lifetime & stress | Create 1–1000 controls; clear/recreate; focus then remove; resized windows; frame-submission timing |
| Checks & reports | Automated results; XML sample (Delphi); manual notes; exported reports |

Select a section on the left and follow its checklist. The lower pane logs
activation, changes, and focus transitions. The status bar shows render submission
time, event count, focused/hovered/captured control names, and font-cache hits.
Text event logs report length, not the entered text.

**Mark page PASS/FAIL** records your human assessment of the current section.
Manual sections initially read **NOT RUN** and automated checks never change that
status. Add reproduction details in the editable notes field near the bottom of
Checks & reports. **Export report** writes a timestamped text file beside the
executable and records its path in the event log. The theme roundtrip button
similarly writes a timestamped INI file there; files are retained for inspection.

The embedded dialog only logs results. The live-dialog buttons exercise modal
context behavior. Closed live dialogs are freed after event dispatch completes.
Dynamic control creation/removal is also deferred to avoid freeing the current
event sender from its callback.

## Unattended runs

```sh
SDL_VIDEODRIVER=dummy ./Bin/Linux64/TestLab -self-test -report=/tmp/TestLab-report.txt
SDL_VIDEODRIVER=dummy ./Bin/Linux64/TestLab -self-test -capture-dir=/tmp/TestLab-images
```

On Windows, run `TestLab.exe -self-test -report=I:\path\report.txt` with Windows
paths. For a dummy-driver run launched from WSL, export `SDL_VIDEODRIVER` through
`WSLENV`, or use `bash Tests/run-tests.sh Win64`, which handles that setup.

`-self-test` (also accepted as `-smoke-test`) runs:

1. Gallery coverage checks against an explicit catalog of 60 visual classes.
2. Isolated input/ownership/layout/editing/selection/range/data/modal scenarios.
3. Host-routed mouse navigation through all ten sections under both themes.
4. Frame submission for each section; optional BMP captures for inspection.
5. Creation/rendering/removal of 1,000 controls and nested modal operations.
6. XML tree loading on Delphi, or an explicit SKIP on FPC.

It prints individual results and exits with status 1 for assertion failures or
unhandled errors. `-report=path` writes a report; `-capture-dir=path` creates the
directory and writes `page-NN-theme-N.bmp` files. Existing captures at that explicit
destination are replaced. These options can be combined. Reports include separate
manual status, manual notes, compiler family, and observational stress timings.

Capture runs also write `focus-theme-N.bmp` and `alignment-theme-N.bmp` for both
themes, exercising actual keyboard navigation and the scrolled alignment samples.
`scroll-area-theme-N.bmp` additionally captures the lower nested-scroll-area samples.
`scrollbar-comparison-theme-N.bmp` captures the equal-height comparison row.
`menus-theme-N.bmp` captures an open menu and submenu. On Tabs & menus, open
File > Recent files > More examples, invoke commands and check the event log.
Toggle View > Show guides. Check keyboard arrows, Enter, Escape, disabled entries,
and outside-click dismissal; menu popups must render above the tabs and toolbar.
Also test Alt+F, F10, S in the File menu, and Ctrl+S from another control on the
page. Right-click the page for context commands, long captions, and submenus.
Hover text, links, splitters, header dividers, and window edges/title bars to
check native mouse cursors; keep dragging outside the control and cancel input.
`dialog-windows-theme-N.bmp` compares active/inactive overlapping windows.
On Dialogs & layers, open two non-modal windows, move one, resize all edges and
corners, click each window to raise it, and close the active one to check focus
restoration. Test Escape during dragging and app focus loss. Fixed/movable-only
examples are below the previews; embedded previews remain stationary. Moving a
modal must survive layout updates, and background windows must not activate.
The titleless and resize-only examples demonstrate independent title visibility,
movement, and resizing. Titleless content starts near the top without an empty
header gap, and dragging content must not move the window.
Live windows now enable close, minimize, and maximize/restore title buttons.
Minimize leaves a compact title strip; click its minimize button again to restore.
Check maximize → minimize → restore, parent resizing while maximized, focus after
restoration, and cancelling a close-button press by releasing outside it.

The standard `Tests/run-tests.sh` runner includes this application as well as the
existing core and SDL integration suites. The latter cover virtual gamepad
attachment, coordinate conversion, font failure recovery, caching, and synthetic
IME composition/commit events independently of this gallery.

## Checkboxes, activity indicators, and switches

The Buttons page also includes a three-state `TGuiCheckBox`. `AllowGrayed`
enables cycling through unchecked, mixed, and checked; `State` can represent
an aggregate mixed value independently of user cycling. Boolean `Checked`
assignments continue to work. `OnChange` reports state transitions and
`OnGetNextState` can customize the cycle.

The Buttons page includes `TGuiToggleSwitch` examples (on, off, disabled).
Click the caption or drag the thumb; Space/Enter toggles, Left/Right chooses a
state, and Escape cancels an active drag. The "Background activity" switch
controls `TGuiActivityIndicator` on the Ranges page. A disabled indicator stays
static; setting `Animate := False` hides its dots without changing its layout.
Keep rendering frames to animate it; `FrameInterval` is milliseconds per frame.
Both controls use the selected theme. XML supports `toggleswitch` with `checked`
and `activityindicator` with `animate` and `frameInterval`.

The current unit owner map and extension contracts are in the
[architecture guide](../../Docs/ARCHITECTURE.md).

## Interpreting failures and limitations

Native IME candidate windows, real controller behavior, clipboard interaction,
display scaling on different monitors, and visual output still need interactive
testing on the target machine. Headless rendering success is not a visual PASS.

The gallery deliberately exposes the framework's current behavior, including
incomplete features. In particular, inspect cover-fit
image clipping, and caret alignment after changing the default font. Unicode grapheme segmentation is tested automatically. Bidirectional layout
and advanced script/font fallback support are intentionally out of scope. Do not mark a manual section passed merely
because its corresponding automated checks passed.

On Text & editing, resize the wrapped memo and toggle wrapping. Test Home/End,
Ctrl+Home/End, Up/Down, PageUp/PageDown, Shift selection, mouse selection across
soft breaks, copy, and undo. Hover the memo for a long wrapped tooltip. Source
line breaks must not change when wrapping toggles or the control resizes.
Capture mode includes `wrapped-selection-theme-N.bmp` and
`wrapped-tooltip-theme-N.bmp` for these cases.

To extend the lab, add samples in `TestLab.App.pas`, behavioral assertions in
`TestLab.Checks.pas`, and update the class catalog and this coverage table when
new framework controls appear. Platform-specific tests should report SKIP when
unavailable rather than silently count as success.
