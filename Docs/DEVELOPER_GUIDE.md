# PasSDL3-GUI developer and control guide

This is the detailed behavior, integration, ownership, styling, and control
reference. Start with the [repository overview](../README.md) for screenshots,
requirements, and the shortest build path.

A native Pascal retained-mode GUI toolkit for SDL3 games, tools, menus, and HUDs.
Controls are persistent objects owned by their parent. The API is not Dear ImGui's
per-frame immediate-mode API.

The complete public facade exposes 60 visual control classes. See the
[architecture and migration guide](ARCHITECTURE.md) for implementation owners,
dependency rules, subclass/ownership contracts, and the public-field migration.

## List row sizing

List-based controls (`TGuiListBox`, `TGuiRadioGroup`, `TGuiCheckListBox`, and
`TGuiSwitchListBox`) reject nonfinite `ItemHeight` values and clamp finite values
below one to one GUI unit. Changing row height immediately reconciles scrolling
and reveals the selection without emitting a selection-change notification.

## Indicators

`TGuiPageIndicator` displays a bounded window of page dots. Set `Count` and
`SelectedIndex`, and handle `OnSelect` to synchronize it with your pages.
`Interactive=True` enables clicking, arrows, Home/End and wheel navigation;
the default is passive. Override `PaintIndicator` for custom dot rendering.
XML supports `count`, `selectedIndex`, `interactive`, `dotSize`, `spacing`, and
`maxVisibleDots`, with malformed numeric attributes rejected.

`TGuiActivityIndicator` is the passive busy indicator: `Animate=False` hides its
dots, while disabling it leaves a static muted frame. `FrameInterval` is in
milliseconds and accepts the full Cardinal range (zero clamps to one). XML names
`activityindicator` and `busyindicator` accept `animate` and `frameInterval`;
malformed, negative, or overflowing intervals are rejected.

Progress bars support determinate and marquee modes. XML accepts `minValue`,
`maxValue`, `value`, `orientation` (horizontal/vertical), `reverse`, `showText`,
`segmentCount`, `segmentGap`, `showTicks`, `tickCount`, `showThreshold`,
`thresholdValue`, `marquee`, and `marqueeInterval`. Range/value properties reject
NaN and infinity; finite values clamp to the configured range. Marquee mode retains
the determinate value for switching back.
Each segment represents an equal share of the range; gaps do not consume that
share. At render time, gaps are limited to half the available per-segment slot,
keeping segments visible inside narrow tracks without changing `SegmentGap`.
`SegmentGap` rejects negative or nonfinite values, and `ThresholdValue` rejects
nonfinite values. Fill and threshold normalization use widened arithmetic for
extreme finite ranges. Decorations are clipped to the control bounds, including
when padding leaves no usable track.
Segment and tick counts must be nonnegative. Counts denser than one mark per GUI
unit render as a continuous progress fill or tick band, keeping drawing work
proportional to the track length without changing the requested counts.
Disabled determinate fills use `Style.DisabledTextColor`, matching marquee mode;
explicit tick and threshold colors remain caller-controlled.

## Build and run

The examples use SDL3 and SDL3_ttf. Delphi Win64 and FPC 3.2.2 Linux64 are tested.
The XML loader is an optional Delphi-only unit; it is not imported by the FPC
umbrella unit. The Linux SDL libraries must be installed in the linker/runtime
search path. Native DLLs/shared libraries are not committed; obtain them from the
SDL and SDL_ttf releases and place them beside the executable.

`uses PasSDL3.GUI;` exposes the control classes, context, public control enums,
and geometry/color/style factories. Specialized subsystem functions can still
be imported from their individual units. `Tests/PublicApiTests.dpr` intentionally
imports no other framework unit and constructs all 23 standard-list controls.

From WSL, using the supplied Delphi compiler setup:

```sh
bash build-wsl-generic.sh Examples/00_basic_window/BasicWindow.dpr Win64
./Bin/Win64/BasicWindow.exe
```

On Linux:

```sh
bash build-wsl-generic.sh Examples/00_basic_window/BasicWindow.dpr Linux64
./Bin/Linux64/BasicWindow
```

`SOURCE_PATHS` defaults to `Source;Lib/SDL3/units`. Compiler and output overrides
are documented at the top of `build-wsl-generic.sh`. Font lookup supports common
Windows, Linux, and macOS locations; set `PASSDL3_GUI_FONT` to a font file to
override it. An executable-local `font.ttf` is another fallback.

For a comprehensive interactive gallery, build
[`Examples/01_test_lab/TestLab.dpr`](../Examples/01_test_lab/TestLab.dpr).
The [Test Lab guide](../Examples/01_test_lab/README.md) describes its 60-control
coverage, manual checklists, automated scenarios, screenshots, and reports.

```sh
bash build-wsl-generic.sh Examples/01_test_lab/TestLab.dpr Win64
./Bin/Win64/TestLab.exe
```

The other examples are `Examples/02_shop_menu/ShopMenu.dpr` and
`Examples/03_reactor_hud/ReactorHud.dpr`. Pass `-smoke-test` to render one frame
and shut down. This exercises initialization, layout, rendering, and cleanup.

## Integration and ownership

Create a `TGuiContext`, add controls to `Context.Root`, and create a
`TGuiSDL3Host` with your SDL renderer and that context. Forward SDL events to
`Host.ProcessEvent`, then call `Host.Render` between your scene rendering and
`SDL_RenderPresent`. `ProcessEvent` returns whether the translated GUI event was
handled. The host does not clear or present your renderer.

The host converts window input into rendering coordinates, processes resize and
focus-loss events, and opens/closes connected gamepads. Give it original SDL
events, not coordinates already converted by your application. Call `Host.Resize`
with GUI-coordinate dimensions if you change render scale, viewport, or logical
presentation independently of window resize events.

The host manages SDL text-input activation for focused writable edits/memos.
Set `Host.ManageTextInput := False` if your application manages text input itself.
Include `PasSDL3.GUI.Clipboard.SDL3` to register the OS clipboard provider.

- `Parent.Add(Child)` transfers ownership to that parent. `Remove` detaches
  without freeing; `Clear` frees children. Freeing an attached child detaches it.
- Detaching a subtree clears its context's focus, hover, capture, and modal
  references. Detachment does not invoke application focus callbacks.
- A host owns the context only when it created that context itself.
- Font renderers, font collections, image textures, and the SDL renderer remain
  caller-owned. Release cached fonts/collections before destroying the SDL
  renderer. Call `Font.ClearCache` before destroying a renderer while retaining
  the font object, or after modifying its native `Font` handle.
- Controls keep local bounds relative to their parent. Assigning layout properties
  is detected before layout/input/painting. For a nested update such as changing
  only `Bounds.Width`, copy the record, modify it, and assign `Bounds` back; see
  the [public-field migration](ARCHITECTURE.md#public-field-migration).

## Editing, tooltips, scrolling, and fonts

`TGuiEdit` supports selection, clipboard operations, password masking, read-only
mode, Unicode character boundaries, and a bounded 128-state undo history.
Ctrl+Z undoes; Ctrl+Y or Ctrl+Shift+Z redoes. Single-line edits strip line breaks.

`TGuiMemo` extends the editor with line breaks, multiline selection/editing,
up/down and home/end navigation, and scrolling. `Text` and `Lines: TStringList`
stay synchronized. Set `ReadOnly := True` for log viewers. Internally memo line
breaks are LF. Caret and selection offsets use Pascal string offsets: UTF-16
code units in Delphi and UTF-8 bytes in FPC. Indices are snapped to Unicode 17
extended-grapheme boundaries, keeping combining marks, joined emoji, flags, and
Indic conjuncts intact. Arrow movement, selection, deletion, password masking,
and wrapping use those boundaries. Each editor caches its segmentation map;
changing text (including undo/redo) refreshes it on the next lookup. `MaxLength`
still counts string units, but truncation never keeps a partial grapheme.

Set `Memo.WordWrap := True` for word wrapping (default is False). Soft rows do
not alter `Text`, `Lines`, clipboard text, or undo records. Home/End and vertical
arrows operate on visual rows; Ctrl+Home/End address the whole document.
PageUp/PageDown move by the visible row count. Shift extends selection, including
Shift-click. `VisualLineCount` exposes the current layout; final font-accurate
layout is updated during painting, with an eight-unit character estimate before
a canvas has supplied metrics. Layout accounts for the scrollbar gutter and
reflows on size/font-metrics changes. Extremely wide words break at character
boundaries; source spaces and explicit line breaks are preserved.

SDL IME composition is previewed separately from committed text. Native candidate
windows and complex input methods still need interactive platform testing.
Bidirectional layout/editing, advanced script shaping, and additional script-specific
font sets/fallback are intentionally out of scope, not pending features. Editors
retain ordinary Unicode text with source-order, left-to-right layout; available
glyphs depend on the selected font. Full Unicode word breaking and rich text are
not implemented. Ctrl-word operations retain ASCII word classification but
step over complete graphemes, never splitting combining sequences.

Set an interactive control's `Hint` to show a tooltip. `Context.TooltipDelay`
defaults to 500 ms; `TooltipsEnabled` disables them. Long hints wrap at words and
explicit line breaks within `Context.TooltipMaxWidth` (default 320 logical units).
Tooltips are constrained to the GUI viewport; text taller than the available
viewport is clipped.

`TGuiScrollBox.ScrollX` and `ScrollY` support both axes. Horizontal wheels and
Shift+wheel scroll horizontally; horizontal scrollbars support dragging. Combo
boxes and dropdown buttons scroll their six-row popups with the wheel, and
keyboard selection keeps the selected item visible.
Popups with more than six items also show a draggable scrollbar. Clicking its
track or dragging its thumb scrolls without selecting an item or closing the
popup. Highlights extend beneath the dimmed lane; text stays clear of the thumb.

`TGuiListBox` supports wheel scrolling, thumb dragging, and Up/Down, Home/End,
and PageUp/PageDown navigation. `ScrollY` and read-only `MaxScrollY` expose its
offset and range; changing the selection keeps that row visible.

XML stack panels and toolbars accept `orientation` (`horizontal`/`vertical`),
`spacing` and `autoSizeToContent`, preserving constructor defaults when omitted.
Separators accept `orientation` and `thickness`. Thickness is finite/nonnegative;
zero hides the line and oversized values are clipped to the control's cross-axis
size. Stack spacing must be finite; negative spacing retains its existing zero clamp.

`TGuiButton.AutoRepeat` is opt-in (default False). `RepeatDelay` defaults to 300 ms
and `RepeatInterval` to 100 ms; the interval must be positive. Primary-pointer holds
repeat after the delay and retain the normal final release click. Space, Enter and
gamepad-confirm activation click immediately, then repeat on the same timer; their
release stops repeating without another activation. OS key-repeat events do not
drive button activation. Keyboard holds also show the pressed visual state.
Leaving the button during a pointer hold, cancellation, focus loss, disabled/hidden
ancestry, clock rollback or changing repeat settings stops the timer. Long frames
emit one repeat, without catch-up bursts. Context.Paint runs timed callbacks before
control traversal, so an OnClick handler may remove the button. Custom hosts can
call UpdateRepeat; the protected AnimationTime hook supports deterministic clocks.
XML accepts `autoRepeat`, `repeatDelay` and `repeatInterval`. DelayButton rejects
AutoRepeat=True because its hold-to-confirm semantics are independent.

Ordinary buttons expose `OnPressAndHold` for an alternate primary-pointer action.
`PressAndHoldInterval` defaults to 800 ms and must be positive (also supported by
XML). The handler fires once while held and consumes the subsequent release click,
including for checkable buttons. Short presses remain ordinary clicks. AutoRepeat
suppresses this hold event; keyboard/gamepad presses do not synthesize pointer holds.
Changing the handler/interval cancels a pending hold. Context checks timing during
frames and before an inside pointer release, so a missed frame does not lose a hold
at its deadline. A hold callback may remove its button. DelayButton uses OnActivated
instead and rejects assigning the ordinary hold handler.

Checkbox, radio and speed-button activation stops if a state-change handler frees
or disables the activating control, rather than continuing into OnClick. Checkbox
next-state handlers may also remove the control. Radio/speed exclusive-group updates
tolerate a peer removing itself or the activating button during its change callback.
These guarantees apply to the guarded activation/state paths, not arbitrary event
handlers throughout the framework.

`TGuiDelayButton` provides hold-to-confirm activation. Set `Delay` in milliseconds
(default 3000); hold the primary mouse button, Space, Enter or gamepad accept.
`Progress` exposes 0..1 and `Holding` reports a pending confirmation. Completion
sets `Checked` and invokes `OnActivated` once. `OnActivated` and `OnClick` are aliases
for the same handler: ordinary click dispatch cannot skip the delay. Early release,
leaving the button, Escape or lost focus cancels. The next press on a checked button
resets it; `Reset` and assigning `Checked` also set state without activation.
Zero delay activates immediately. Changing `Delay` resets the button.

Context painting advances pending holds before rendering; keep rendering frames
while awaiting confirmation. Custom hosts painting controls directly must call
`UpdateHold` themselves, outside paint traversal. Reading `Progress` does not fire
events. Custom input hosts should preserve `TGuiEvent.KeyRepeat`; repeated key-down
events are ignored so they cannot restart a cancelled hold. XML supports
`<delaybutton caption="Hold to confirm" delay="1500" checked="false"/>`.

`TGuiSlider` supports horizontal/vertical orientation, finite `MinValue`,
`MaxValue` and clamped `Value`, optional `StepSize`, and `SnapMode` (none,
always, or release). `Live=False` previews a drag without committing until
release; Escape cancels it. XML exposes these settings, for example:
`<slider minValue="-20" maxValue="80" value="35" orientation="vertical"
stepSize="5" live="false" snapMode="release"/>`. Malformed numeric settings,
negative steps, and unknown orientation/snap names are rejected.

`TGuiRangeSlider` selects an interval using `LowerValue` and `UpperValue` within
`MinValue`..`MaxValue`. Use `SetValues(Lower, Upper)` to update both atomically;
endpoints cannot cross. `ActiveThumb` is `grtLower` or `grtUpper`. Tab/Shift+Tab
visit both handles; Space/Enter switches handles; arrows, Home/End, Page keys and
wheel adjust the active value. Track clicks choose the nearest handle, and grabbing
a handle preserves the pointer offset. Vertical values increase upward.

`StepSize`, `SnapMode` and `Live` match the ordinary slider. With `Live=False`,
`PreviewValue[Thumb]` moves while committed endpoints remain unchanged until release;
Escape cancels. `OnChange` reports committed changes, while
`OnMoved(Sender, Thumb)` identifies user-driven movement. `Position(Thumb)` returns
the displayed fraction and `ValueAt(Fraction)` maps to a clamped, stepped value.
XML supports `<rangeslider minValue="0" maxValue="100" lowerValue="20"
upperValue="80" stepSize="5" snapMode="release" live="false"
orientation="horizontal" activeThumb="lower"/>`.

`TGuiCheckListBox` adds independent `Checked[Index]`, three-state `State[Index]`,
and `ItemEnabled[Index]` properties. `AllowGrayed` enables mixed-state cycling.
Click a row or use Space/Enter to toggle; navigation only changes selection.
`OnCheck(Sender, Index)` reports changed states, including programmatic assignments.
Disabled rows remain selectable but cannot be toggled by input. Check/enabled flags
follow items through insertion, deletion, moving and sorting without using `Items.Objects`.
XML uses `<checklistbox items="One|Two" states="checked|grayed"
itemEnabled="true|false" allowGrayed="true" selectedIndex="0"/>`.
Optional `states` and `itemEnabled` lists must match the item count; `itemHeight`
sets row height. The Lists & selection Test Lab page includes a scrollable example.

`TGuiSwitchListBox` uses the same row/state API with switch indicators. Click a row
or press Space/Enter to toggle; Left/Right sets the selected switch off/on. Dragging
an indicator previews `ThumbPosition[Index]` (0..1) and commits at the halfway point
on release, including captured releases outside the row. Escape, focus loss or item
mutation cancels the preview. Interactive cycling is always two-state, regardless
of inherited `AllowGrayed`; an explicitly assigned `gcbGrayed` is displayed at the
midpoint and resolves to checked on activation. XML uses `switchlistbox` with the
same item/state attributes. The gallery places both list variants side by side.

`TGuiWheelPicker` presents a centered, vertically scrolling item wheel. Populate
`Items`, select `ItemIndex`, and handle `OnChange`. Empty wheels have index -1;
nonempty wheels always have a selected item. `VisibleItemCount` is odd (default 5,
allowed 1..101). Automatic wrapping applies when items exceed visible rows; set
`Wrap` explicitly or restore `WrapMode := gwwAuto`.

Drag/release to flick, click a neighboring row to center it, or use wheel/arrows,
PageUp/PageDown and Home/End. `FlickEnabled`, `Deceleration` (rows/second², default
20), and `SettleDuration` (milliseconds, default 150) control motion. `Moving` covers
dragging and animation; `ScrollPosition` exposes the fractional row position.
Escape, focus loss, item mutation or programmatic selection cancels motion. The
context advances it before painting; custom hosts can call `UpdateMotion` directly.
Override `PaintWheelItem` to customize row rendering using its fractional displacement.
XML example: `<wheelpicker items="Low|Medium|High" itemIndex="1"
visibleItemCount="3" wrap="false" flickEnabled="true" deceleration="20"
settleDuration="150"/>`; `wrap="auto"` is the default.

`TGuiSpinEdit` supports direct text editing by default. `Text` is the editable buffer;
`Value` is the committed integer. With `Live=False` (default), Enter or focus loss
commits; Escape restores the committed text. Parsed numbers clamp to MinValue/MaxValue,
while malformed or overflowing input is rejected. `InputValid` reports whether the
buffer parses within range; `CommitEdit` returns parsing success and `CancelEdit`
restores formatted text. Live mode updates only valid in-range entries.

Set `Editable=False` for stepping-only operation. `Increment` must be positive;
wheel, arrows and `StepBy(Count)` use overflow-safe arithmetic. `Wrap=True` sends an
overshooting step to the opposite endpoint. `OnChange` reports numeric changes,
including programmatic Value assignments. Override `FormatValue`/`TryParseValue`
for custom representations. Caret, selection, clipboard and undo/redo reuse TGuiEdit.
`OnValueModified` reports user numeric changes after `OnChange`: stepping (including
repeat), typed commits, and valid live typing, paste, cut or undo/redo. Explicit
`StepBy`, `CommitEdit`, clipboard and history commands count as editing actions.
Property assignments (`Value`, `Text`, limits or enabling live mode) emit no user
event. Incomplete/invalid text, unchanged values and cancelled edits do not emit it.
If an `OnChange` handler replaces the value or changes spin configuration, the stale
user notification is suppressed. Either numeric handler may remove the spin; nested
notifications and exceptions leave no dangling notification state.
Arrow buttons distinguish idle, hover and held states. `AutoRepeat=True` defaults
to a 400 ms `RepeatDelay` and 75 ms `RepeatInterval` (must be positive). A press
steps immediately; context rendering calls `UpdateRepeat` before drawing. Standalone
hosts may call it explicitly. Delayed frames emit at most one step per update,
not a catch-up burst. Leaving the pressed arrow cancels until a fresh press;
release, Escape, focus loss, hidden/disabled ancestry and configuration/value/text
changes also cancel. Set `AutoRepeat=False` for one step per click.
XML example: `<spinedit minValue="-20" maxValue="120" value="35" increment="5"
wrap="true" editable="true" live="false" autoRepeat="true" repeatDelay="400"
repeatInterval="75"/>`. Caption does not replace numeric text.

`TGuiComboBox.Items` supports direct and batched string-list changes. Selection
follows its row through inserts, deletes, moves, exchanges and sorting, including
duplicate captions; application `Items.Objects` are untouched. Deleting the selected
row selects the next row at that position (or the last remaining row). Clearing
items resets selection to -1 and closes the popup. First population selects row 0;
an explicit -1 remains deselected when adding to a nonempty list. `Items.Assign`
replaces rows and clamps the old index, without importing another list's selection.
`OnSelect` reports changes to the selected index, row identity or selected caption;
unchanged selection does not notify. Item changes cancel pending scrollbar gestures.
Only primary clicks operate the popup; Escape, cancellation and focus loss close
it. Up/Down and Home/End stay within the item range. `ItemHeight` must be positive
and finite. `DropDownCount` sets the maximum visible rows (default 6);
`VisibleItemCount` and `PopupBounds` expose the current layout. Attached popups
stay inside the context viewport, prefer complete rows, and open above the control
when that side offers more room. A viewport too small for a full row gets a clipped
row; an anchor filling the viewport uses an overlapping popup. Scrollbar range,
selection visibility and hit testing use the actual visible count, including after
resize. Popup geometry changes cancel an active thumb drag. XML supports `items`
(pipe-separated), `selectedIndex`, `itemHeight` and `dropDownCount`.
While the popup is open, arrows, Home/End and PageUp/PageDown move
`HighlightedIndex` without changing `SelectedIndex`. Enter/Space accepts the
preview; Escape, F4-close or focus loss cancel it. F4 opens a closed popup.
Closed-combo navigation still changes selection directly. `OnAccept` reports
explicit mouse/keyboard acceptance (or an `AcceptSelection` command), including
accepting an unchanged item; property assignments do not emit it. `OnSelect`
comes first when selection changes, with the popup already closed. Replacement
of selection/items in that handler suppresses stale acceptance, and either handler
may remove the combo. Popup scrolling clears stale hover/preview; Enter with no
highlight closes without accepting.

`TGuiComboBox.Editable=True` enables the shared Unicode editor; the default remains
noneditable. `Text` is a draft and `Editing` reports pending input. Enter or
`AcceptText` matches an exact item label (`FindText`) or accepts a custom value
with `SelectedIndex=-1`, without inserting items. `CancelEdit`/Escape restores the
last accepted value; focus loss preserves the unaccepted draft without committing.
`OnChange` reports buffer edits and direct Text assignments; selection-driven text
synchronization uses OnSelect instead. OnAccept reports explicit acceptance.
Caret/selection, clipboard, undo/redo and composition reuse TGuiEdit. Closed
editable Home/End move the caret; the arrow lane opens the popup. Active composition
blocks premature acceptance. Model updates preserve unrelated drafts/custom values;
replacing the selected row or explicitly assigning SelectedIndex restores its label.
XML additionally supports `editable`, `text`, `readOnly` and `placeholder`.
`AutoComplete=True` optionally completes typed/pasted prefixes and selects the
suggested suffix. Completion remains a draft; Enter accepts it. Typing plus its
completion is one undo step and one OnChange notification. Deletion, undo/redo,
and direct Text assignments do not trigger completion. `CompleteText` explicitly
completes an unselected draft when the caret is at its end. Completion respects
MaxLength, single-line text and grapheme boundaries.
`FindPrefix(Text, StartIndex)` searches forward without wrapping and returns -1
for an empty prefix or no match. Matching uses the platform's `SameText` by default;
`SearchCaseSensitive=True` uses exact matching. This is not Unicode normalization
or full Unicode case folding. `FindText` retains its exact-match semantics.
XML supports `autoComplete` and `searchCaseSensitive`.

Noneditable combos have `TypeAhead=True` by default. SDL text input searches labels
without editing them: closed combos change selection, while open popups move only
the preview highlight. Repeated letters cycle/wrap matches; successive characters
extend the prefix; Space extends an active multiword search instead of opening
the popup. Failed extensions retry the latest input as a fresh prefix.
`TypeAheadTimeout` defaults to 1000 ms and must be positive; the next input after
that interval starts fresh. `Search(Text)` feeds the same search mechanism and
`ClearSearch` resets it; `SearchPrefix` exposes the current buffer. Model/selection
changes, focus loss, popup toggles and navigation clear the buffer. Composition
preview does not search or accept; committed Unicode text does. The SDL host enables
text input for this read-only search mode, without making the combo editable.
Set TypeAhead=False to opt out; XML supports `typeAhead` and `typeAheadTimeout`.

`TGuiTabControl.Items` preserves selected row identity across insertion, deletion
before it, moves, exchanges and sorting, without using application Objects.
Deleting the selected tab chooses its nearest remaining replacement; Clear resets
selection to -1. Batch updates report final selection, and OnSelect also reports
selected-caption changes. Explicit deselection survives appending to a nonempty
list. Primary clicks and arrow/Home/End navigation respect disabled state and
control bounds. TabHeight must be positive and finite; short controls clip their
header/body safely. `TabEnabled[Index]` defaults to True and follows row mutations
without using Objects. Disabled tabs are muted, reject mouse/programmatic selection,
and are skipped by arrow/Home/End navigation. Disabling the active tab selects the
next enabled tab, then the previous if necessary, or -1 if none remain. Re-enabling
a tab preserves deselection until navigation or explicit selection. Assigning new
Items resets disabled flags; self-assignment preserves them.

`TabWidth=0` keeps equal-width tabs; set a positive width for fixed-width tabs.
`MinTabWidth` optionally prevents tabs shrinking below a usable width (default 0
preserves existing layouts). Overflow adds left/right scroll buttons and supports
mouse-wheel scrolling over the header. Scrolling does not change selection;
keyboard/programmatic selection and resizing reveal the active tab. Tab captions
are clipped to their own cells and the header viewport. `ScrollOffset`,
`MaxScrollOffset`, `HeaderViewport`, `TabRect(Index)` and `ScrollTabIntoView(Index)`
provide geometry and explicit scroll access. Oversized tabs reveal their leading
edge when selected. Widths must be nonnegative and finite; scroll offsets are
finite and clamped. `TabPosition` supports `gtpTop` (default) and `gtpBottom`;
the bottom header, overflow buttons and selection marker face the content above.
`AutoSizeTabs=True` sizes tabs to measured captions plus 24 units of horizontal
padding. `ItemWidths[Index]` sets an explicit per-tab width; zero inherits the
control's sizing mode. Precedence is per-tab width, positive TabWidth, content size,
then equal shares of the space left after fixed tabs. MinTabWidth applies to every
mode. If fixed tabs exhaust that space, flexible tabs fall back to equal-width
overflow cells (at least 24 units) rather than disappearing. Widths follow items
through moves/sorting without touching Objects; assigning
replacement rows resets them, while self-assignment preserves them. Font-metric or
caption changes remeasure on painting; before the first measurement, content sizing
uses an eight-unit-per-string-unit estimate. ContentWidth exposes total tab width.
Overflowing strips support primary-pointer dragging (`DragScroll=True`) and
inertial scrolling (`FlickEnabled=True`). Movement beyond four units starts a drag;
a simple click selects on release, whereas dragging does not change selection or
emit OnClick. Disabled tabs can be used as drag surfaces without being selected.
Nonoverflowing tabs retain immediate selection. Set DragScroll=False to retain
immediate selection everywhere, or FlickEnabled=False for drag-only scrolling.
Deceleration defaults to 2500 GUI units/second squared and must be finite/positive.
Moving reports drag/coast activity. Rendering frames advances coast motion;
ScrollOffset/Moving reads also update it. Focus loss/cancellation, changes to
items/layout, explicit selection/scrolling and new keyboard/wheel input stop motion.
The protected AnimationTime hook allows deterministic testing without sleeps.

XML `tabcontrol` supports pipe-separated `items` and `tabEnabled` flags,
`selectedIndex`, `tabHeight`, `tabWidth`, `minTabWidth`, `tabPosition` (`top` or
`bottom`) and optional `scrollOffset`.
It also accepts `autoSizeTabs` and pipe-separated `itemWidths` (one nonnegative
number per item; zero inherits sizing).
`dragScroll`, `flickEnabled` and `deceleration` configure pointer scrolling.
Enabled flags must be `true`/`false` and match the item count when supplied.
Omitted selection chooses the first enabled tab; -1 explicitly deselects. Disabled
selection requests follow the same rejection policy as the Pascal API. Selection
is applied before an explicit scroll offset, allowing an independently scrolled
initial view. Invalid tab configuration raises an exception; failed XML loads
clean up their partially created control tree.

Scroll boxes reserve gutters instead of painting controls beneath their bars.
Both axes share a clear corner, and scroll limits use the reduced viewport.
`ViewportWidth`/`ViewportHeight` expose the most recently calculated visible area
(updated during arrangement, painting, input, and child addition). Fixed-width
content can therefore need horizontal scrolling when a vertical gutter appears.
Thumbs use a consistent minimum length, and standalone scrollbar drags retain
the pointer's grab offset instead of snapping the thumb to its center.

Scroll boxes, list boxes, memos, trees, list views, and standalone scrollbars share neutral
idle thumbs, wider hover thumbs, and an active drag accent. Configure gutter
width through `Theme.Metrics.ScrollBarSize` (minimum 8 logical units). Individual
styles expose `ScrollBarSize`, `ScrollTrackColor`, `ScrollThumbColor`,
`ScrollHoverColor`, and `ScrollPressedColor`. Existing custom `Track` and `Thumb`
image drawables retain their own appearance; slider/progress accents are unchanged.

Embedded vertical tracks are anchored to the control's outer right edge, with
four-pixel top/bottom insets, independently of content padding. Text and icons
end at least four pixels before the gutter; larger explicit right padding is
still respected. List-box, tree, and list-view row highlights span the interior
width beneath a translucent, dimmed scrollbar lane. Scrollbar input takes
priority over row selection. A list-view track begins below its header.
The list-view header spans the interior width, and its last column fills the
remaining space, including the area above the scrollbar. Earlier column widths
and text alignment are preserved; row text still stays clear of the thumb.
The header attaches to the top frame with a bottom separator rather than an
inset, separately rounded item background.

Header and list-view columns support dragging their dividers (four logical units
of hit tolerance), with a 32-unit minimum width. A highlighted divider indicates
the resize target. `ColumnWidth[index]` is writable; `ColumnsResizable := False`
disables interactive resizing. The list view's final column remains automatic
fill, so resize its left divider to change its available width. Pointer capture
keeps resizing active outside the header; releasing or cancelling ends the drag.

List-view headers sort on a completed click, toggling ascending/descending with
a direction indicator. Set `SortOnHeaderClick := False` for command-only headers;
`OnColumnClick(Sender, Column)` fires after optional sorting. `SortByColumn`
also works programmatically. Sorting is stable; `ColumnSortKind[column]` supports
text or numeric ordering (`gcskNumber`, dot-decimal/exponent notation). Ascending
numeric sorting places valid numbers before nonnumeric text. `OnCompareRows`
can override comparison: return negative/zero/positive through `AResult`. The
callback must not mutate the table or retain its borrowed row objects.

`MultiSelect` defaults to false. When enabled, Ctrl-click/Space toggles membership,
Shift-click/arrows extends an anchored range, Ctrl+Shift adds a range, and Ctrl+A
selects all. Home/End and PageUp/PageDown support the same modifiers; Ctrl+navigation
moves focus without replacing selection. Alt+Left/Right chooses a header;
Alt+Up/Down sorts it ascending/descending; Alt+Enter invokes its header command.
`SelectedIndex` is the focused row; assigning it replaces selection. Use
`RowSelected[index]`, `SelectedCount`, `SelectedIndices`, `SelectAll`, and
`ClearSelection` for membership. Selection and its anchor follow row identity
through sorting; a reorder alone does not fire `OnSelect`. Navigation reveals
the focused row. `CellText[row,column]` reads/writes cells; changing an active sort
key repositions the row. `AddRow` maintains active ordering and returns the new
row's current index. Row indices are therefore not permanent identifiers.

`TGuiMenuBar.AddMenu` creates an owned `TGuiMenuItem` tree. Use `Add(caption,
handler)` for commands/submenus and `AddSeparator` for separators. Items expose
`Enabled`, `Checked`, and `AutoCheck`; handlers have the `TNotifyEvent` signature
(`Sender: TObject`, the menu item). Menus own their descendants: do not free
items separately. Existing `AddItem`/`Items` flat-selector usage remains valid.

Click a caption to open; hover switches open menus and opens submenus. Tab can
focus the bar; arrows navigate, Enter/Space activate, Home/End select first/last,
and Escape backs out or dismisses. Disabled items and separators are skipped.
Outside clicks, focus loss, and cancellation dismiss the menu. Popups stay within
the GUI viewport; long menus support wheel scrolling and keyboard reveal.
Popup widths adapt to captions and shortcut labels, within `MinPopupWidth` and
`MaxPopupWidth` (defaults 180 and 420 logical units) and the window bounds.
Captions exceeding the maximum are clipped without overlapping shortcut labels.
Use `&File` / `&Save` to mark ASCII keyboard mnemonics (`&&` displays a literal
ampersand). Alt+F or F10 opens the menu; S invokes Save while that menu is open.
Set an item's `ShortcutKey` and `ShortcutModifiers` for application accelerators;
`ShortcutText` optionally overrides the generated display label. Focused controls
get first refusal on shortcuts, except Alt menu navigation/F10. Hidden/disabled
menus, disabled items, and background menus behind a modal cannot activate.

`TGuiPopupMenu` reuses the command/submenu model through its `Menu` root. Attach
the popup to the same context as its target (inside the modal for modal use),
then set `Target.PopupMenu := Popup` for right-click activation. Descendants
inherit their nearest ancestor's assignment. Alternatively call `PopupAt` with
GUI coordinates. The assignment is non-owning; detaching/freeing an attached
popup clears references from controls in that context. Command activation and
Escape restore previous eligible focus. XML can construct `popupmenu`; command
trees and target assignments are configured in Pascal.

Controls expose `MouseCursorAt` and an optional `Cursor` override. Automatic
cursors cover text editing, links, splitters, column dividers, window movement,
and edge/corner resizing; captured drags retain their cursor outside the control.
The SDL host lazily caches native cursors and falls back to the default when a
platform cannot create one. Set `Host.ManageMouseCursor := False` to manage SDL
cursors yourself. Real OS cursor appearance still requires interactive checking.

`TGuiDialog.WindowMode` defaults to `gdwmEmbedded`, preserving existing embedded
layout and callback-only close behavior. Opt into `gdwmFixed` for window styling
and activation, `gdwmMovable` for title dragging, or `gdwmResizable` for title,
edge, and corner dragging. Interactive geometry requires `Align = gaNone`.
Modes are presets for `Movable` and `Resizable`; set these Boolean options after
`WindowMode` to override them independently. `ShowTitleBar` is independent of
the preset, so a titleless window can still resize and receive focus. Without a
title bar there is no implicit move handle over the content. Embedded mode never
enables window dragging, regardless of the flags.

`TitleBarHeight` defaults to 32 logical units (minimum 20). Caption text is
vertically centered within the painted bar. Hiding/showing the bar or changing
its height adjusts `Padding.Top` by that height difference, preserving the
content gap (default 8). Set custom padding after these options when you need
an explicit final inset. Title options can also be used on embedded dialogs.

`MinWidth`/`MinHeight` and optional `MaxWidth`/`MaxHeight` constrain resizing.
Escape during a drag restores its starting bounds; input cancellation ends it.
Modal overlays preserve user-moved positions across layout updates.

Call `Dialog.Activate` after attaching/showing it to raise it within its parent
and restore its last focused child (or focus its default button/the dialog).
Clicks on dialog contents activate the window; `Active` reflects descendant
focus. Tab navigation remains within the active dialog. Windowed `Close` hides
the dialog, closes its modal entry if present, and restores eligible prior focus
before invoking `OnClose`; it does not free the dialog. Removed controls are
pruned from focus history.

`TitleButtons` independently enables `gdbClose`, `gdbMinimize`, and
`gdbMaximize` (default `[]`). Buttons activate on release inside their original
hit area, never start a title drag, and disappear with `ShowTitleBar := False`.
Close reports `gmrClose`; Alt+F4 closes when the close option is enabled.
`WindowState` exposes `gdsNormal`, `gdsMinimized`, or `gdsMaximized`; the public
`Minimize`, `Maximize`, and `Restore` methods work without visible buttons.
Minimize requires a title bar and collapses the window to it, hiding the client
and bottom buttons while retaining an accessible restore action. Restore keeps
the previous normal/maximized state and restores eligible child focus. Maximize
fills the parent and follows its size; restoring returns to the saved normal
bounds. These states require window mode and `Align = gaNone`, but maximize does
not require interactive resizing. OS-native windows/taskbar integration remains
outside this SDL-drawn dialog implementation.
Thumb proportions use the actual visible content height, excluding padding and
headers, rather than the track length. Resizing these controls clamps obsolete
scroll offsets during painting. The shared `GuiScrollTrackRect` and
`GuiVerticalScrollThumbRect` helpers keep painting and interaction geometry aligned.

Register named fonts with `TGuiSDLTTFFontCollection.AddFont`, assign the collection
to `Host.Canvas.Fonts`, and set `Control.FontName` to the registered name. Unknown
names fall back to the collection's default font, then the canvas font renderer.
Text rendering caches up to 128 text/color/renderer entries per font. Each cached
surface is limited to 65,536 pixels; larger strings are rendered transiently.
`CacheHits` exposes reuse for diagnostics.

## Styling

`GuiDarkTheme` provides a restrained dark tool theme with rounded controls,
muted panel borders, accent selection, and an inset keyboard-focus outline.
`GuiReactorTheme` keeps square HUD geometry and its own palette. Apply a theme
after building the control tree; reapply it when switching themes.

```pascal
Theme := GuiDarkTheme;
Theme.Metrics.ControlCornerRadius := 6;
Theme.Metrics.PanelCornerRadius := 8;
Theme.Metrics.FocusWidth := 2;
Theme.SurfaceGradientStrength := 0.06; // 0 keeps surfaces flat
Context.Root.StyleClass := 'Window';
SaveButton.StyleClass := 'Primary'; // filled accent action
CancelButton.StyleClass := 'Quiet'; // transparent until hovered/pressed
GuiApplyTheme(Context.Root, Theme);
```

Ordinary buttons use the neutral style. Existing `Surface`, `Card`, `Muted`,
`Price`, and `Success` classes remain available. The two new button roles can
also be requested directly using `GuiThemeStyle(Theme, gtrPrimaryButton)` or
`gtrQuietButton`. Use named control fonts for heading/body/caption hierarchy.
Applying a theme copies values; apply local style overrides and image skins
afterwards. Newly added controls also need their theme applied.

`Style.CornerRadius` controls procedural surface/border geometry; zero restores
square edges. Unthemed `GuiButtonStyle` remains square for compatibility.
Disabled colour surfaces use `Style.DisabledBackgroundColor`; checked controls
retain their selected tint and gain hover/pressed feedback. Theme INI files
save geometry, focus width, and gradient strength; older files inherit missing values from
the supplied base theme.

Buttons and selected list rows use subtle vertical gradients; editable surfaces
remain flat. `GuiGradientDrawable(TopColor, BottomColor)` and the canvas method
`FillRoundedGradient` also support custom gradients with alpha. Hovered controls
use `Style.HoverBorderColor`; selected rows have an accent marker distinct from
the hover background. Gradients use the existing drawables API without changing
image/nine-slice rendering.

Keyboard/gamepad input reveals a focus outline and soft halo; mouse clicks hide
that keyboard treatment while retaining input focus. Controls now opt in by
default. Set `Control.ShowFocus := False` or `Context.ShowFocus := False` to
suppress it for custom interfaces. `Style.FocusWidth` controls outline thickness.

Centered text uses a shared font cap-height reference (not each caption's ink
bounds), so descenders do not shift adjacent baselines. Half-pixel positions use
consistent rounding to avoid odd/even pixel jumps. Explicit top/bottom alignment
is unchanged. `CenterYOffset` remains available for font-specific optical tuning;
the stock themes no longer add a vertical text offset. Changing the default font
or clearing a font cache also invalidates edit caret measurements.

The canvas has non-abstract `FillRoundedRect`, `DrawRoundedBorder`, `DrawSurface`,
`DrawCheckMark`, and `DrawChevron` methods, so existing canvas implementations
continue to compile. Rounded spans use fractional horizontal edge coverage and
batch straight sections. Image, texture-brush, and nine-slice drawables retain
their existing rendering path. Rectangular child clipping and hit testing are
unchanged: corner radius is decoration, not a rounded content mask. This pass
does not add animation, shadows, automatic typography sizing, or text wrapping.

The Test Lab's Buttons, Lists, Ranges, Tabs, and Rendering sections exercise the
new appearance. Check both themes and keyboard focus as well as mouse states.

## Verification

```sh
bash Tests/run-tests.sh Linux64
bash Tests/run-tests.sh Win64
```

The runner builds and executes core regression tests, SDL integration tests,
and the Test Lab self-test, then builds and smoke-tests the other three examples. SDL uses its dummy video driver
and software rendering for these checks. Output goes under `Bin/Tests` unless
`OUTPUT_ROOT` overrides it. Win64 tests require WSL's Windows executable support.

The tests cover ownership, focus, docking, Unicode deletion, editing history,
multiline synchronization, popup/horizontal scrolling, tooltips, SDL coordinate
conversion, virtual gamepad attachment, font failure recovery, cache reuse, and
IME event routing. These checks do not replace interactive visual testing.

Concrete controls are implemented in responsibility-based `Controls.*` units.
`PasSDL3.GUI.Core` contains only base controls/contracts/helpers; `Context` owns
runtime routing and layers. Aggregate units retain convenient exports. See
[ARCHITECTURE.md](ARCHITECTURE.md) for the complete owner map. Project-owned
code is MIT-licensed; third-party material retains the licenses listed in
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
