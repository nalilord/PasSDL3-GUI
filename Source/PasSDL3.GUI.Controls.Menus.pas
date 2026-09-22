unit PasSDL3.GUI.Controls.Menus;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Buttons;

type
  TGuiMenuItem = class
  private
    FChildren: TList;
    FCaption: String;
    FEnabled: Boolean;
    FChecked: Boolean;
    FAutoCheck: Boolean;
    FSeparator: Boolean;
    FShortcutKey: Integer;
    FShortcutModifiers: TGuiEventModifiers;
    FShortcutText: String;
    FOnClick: TNotifyEvent;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TGuiMenuItem;
  public
    property Caption: String read FCaption write FCaption;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Checked: Boolean read FChecked write FChecked;
    property AutoCheck: Boolean read FAutoCheck write FAutoCheck;
    property Separator: Boolean read FSeparator write FSeparator;
    property ShortcutKey: Integer read FShortcutKey write FShortcutKey;
    property ShortcutModifiers: TGuiEventModifiers read FShortcutModifiers write FShortcutModifiers;
    property ShortcutText: String read FShortcutText write FShortcutText;
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    constructor Create(const ACaption: String);
    destructor Destroy; override;
    function Add(const ACaption: String; AOnClick: TNotifyEvent = nil): TGuiMenuItem;
    function AddSeparator: TGuiMenuItem;
    function ShortcutCaption: String;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TGuiMenuItem read GetItem; default;
  end;

  TGuiMenuBar = class(TGuiPopupControl)
  private
    FRoots, FPath: TList;
    FHot, FFirst: array of Integer;
    FPopupWidths: array of TGuiFloat;
    FContextPopup: Boolean;
    FPopupPoint: TGuiPoint;
    procedure ItemsChanged(Sender: TObject);
    function RootMenu(AIndex: Integer): TGuiMenuItem;
    function PopupRect(ALevel: Integer): TGuiRect;
    function PopupIndex(const APoint: TGuiPoint; out ALevel: Integer): Integer;
    procedure OpenLevel(ALevel: Integer; AMenu: TGuiMenuItem);
    procedure OpenRoot(AIndex: Integer);
    procedure MoveRoot(ADirection: Integer);
    procedure ActivateItem(ALevel, AIndex: Integer);
    procedure MoveItem(ADirection: Integer);
    function TryMenuKey(var AEvent: TGuiEvent): Boolean;
  private
    FItems: TStringList;
    FSelectedIndex: Integer;
    FHoveredIndex: Integer;
    FItemWidth: TGuiFloat;
    FMinPopupWidth: TGuiFloat;
    FMaxPopupWidth: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    function ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure ClosePopup; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddItem(const ACaption: String): Integer;
    function AddMenu(const ACaption: String): TGuiMenuItem;
  public
    property MinPopupWidth: TGuiFloat read FMinPopupWidth write FMinPopupWidth;
    property MaxPopupWidth: TGuiFloat read FMaxPopupWidth write FMaxPopupWidth;
    procedure PaintOverlay(ACanvas: TGuiCanvas); override;
    function HitTestOverlay(const APoint: TGuiPoint): TGuiControl; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function DispatchShortcut(var AEvent: TGuiEvent): Boolean; override;
    property Items: TStringList read FItems;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property HoveredIndex: Integer read FHoveredIndex;
    property ItemWidth: TGuiFloat read FItemWidth write FItemWidth;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiPopupMenu = class(TGuiMenuBar)
  private
    FMenu: TGuiMenuItem;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
    procedure ClosePopup; override;
  public
    constructor Create; override;
    procedure PopupAt(const APoint: TGuiPoint); override;
    function PopupOpen: Boolean; override;
    property Menu: TGuiMenuItem read FMenu;
  end;

  TGuiDropDownButton = class(TGuiButton)
  private
    FDraggingPopupBar: Boolean;
    FPopupDragY: TGuiFloat;
    FPopupDragFirst: Integer;
    FFirstVisible: Integer;
    FItems: TStringList;
    FSelectedIndex: Integer;
    FDroppedDown: Boolean;
    FHoveredIndex: Integer;
    FItemHeight: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    function PopupTrackRect: TGuiRect;
    function PopupThumbRect: TGuiRect;
    function HandlePopupScroll(var AEvent: TGuiEvent): Boolean;
    function DropDownRect: TGuiRect;
    function ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure ClosePopup; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddItem(const AText: String): Integer;
    procedure PaintOverlay(ACanvas: TGuiCanvas); override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HitTestOverlay(const APoint: TGuiPoint): TGuiControl; override;
    property Items: TStringList read FItems;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property DroppedDown: Boolean read FDroppedDown write FDroppedDown;
    property ItemHeight: TGuiFloat read FItemHeight write FItemHeight;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

implementation

function GuiMenuCaption(const AText: String): String;
var
  I: Integer;
begin
  Result:='';
  I:=1;
  while I <= Length(AText) do
  begin
    if AText[I] = '&' then
    begin
      Inc(I);
      if I > Length(AText) then
        Break;
    end;
    Result:=Result + AText[I];
    Inc(I);
  end;
end;

function GuiMenuMnemonic(const AText: String): Integer;
var
  I: Integer;
begin
  Result:=0;
  I:=1;
  while I < Length(AText) do
  begin
    if AText[I] = '&' then
    begin
      if AText[I + 1] <> '&' then
      begin
        Result:=Ord(UpCase(AText[I + 1]));
        Exit;
      end;
      Inc(I);
    end;
    Inc(I);
  end;
end;

function GuiMenuKey(AKey: Integer): Integer;
begin
  Result:=AKey;
  if (AKey >= Ord('a')) AND (AKey <= Ord('z')) then
    Dec(Result, 32);
end;

constructor TGuiDropDownButton.Create;
begin
  inherited Create;
  FItems:=TStringList.Create;
  FSelectedIndex:=-1;
  FDroppedDown:=False;
  FHoveredIndex:=-1;
  FItemHeight:=30;
  Padding:=GuiBoxLTRB(10, 4, 26, 4);
end;

destructor TGuiDropDownButton.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TGuiDropDownButton.AddItem(const AText: String): Integer;
begin
  Result:=FItems.Add(AText);
  if FSelectedIndex < 0 then
    FSelectedIndex:=0;

  InvalidateLayout;
end;

procedure TGuiDropDownButton.SetSelectedIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue:=-1;

  if AValue >= FItems.Count then
    AValue:=FItems.Count - 1;

  if FSelectedIndex = AValue then
    Exit;

  FSelectedIndex:=AValue;
  if FSelectedIndex < FFirstVisible then FFirstVisible:=Max(0, FSelectedIndex);
  if FSelectedIndex >= FFirstVisible + 6 then FFirstVisible:=FSelectedIndex - 5;

  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

function TGuiDropDownButton.PopupTrackRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(DropDownRect, goVertical, Max(8, Style.ScrollBarSize));
end;

function TGuiDropDownButton.PopupThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(PopupTrackRect, 6, FItems.Count, FFirstVisible);
end;

function TGuiDropDownButton.HandlePopupScroll(var AEvent: TGuiEvent): Boolean;
var
  Track, Thumb: TGuiRect;
  Limit: Integer;
begin
  Result:=False;
  Limit:=Max(0, FItems.Count - 6);
  FFirstVisible:=EnsureRange(FFirstVisible, 0, Limit);
  if (NOT FDroppedDown) OR (Limit = 0) OR
    (AEvent.Kind IN [gekCancel, gekBlur]) then FDraggingPopupBar:=False;
  if NOT FDroppedDown then Exit;
  Track:=PopupTrackRect;
  Thumb:=PopupThumbRect;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) AND
    (Limit > 0) AND GuiRectContains(Track, AEvent.Position) then
  begin
    if NOT GuiRectContains(Thumb, AEvent.Position) then
      FFirstVisible:=EnsureRange(FFirstVisible + Round(GuiScrollOffsetFromThumbDelta(
        AEvent.Position.Y - Thumb.Top - Thumb.Height / 2,
        Track.Height, Thumb.Height, Limit)), 0, Limit);
    FDraggingPopupBar:=True;
    FPopupDragY:=AEvent.Position.Y;
    FPopupDragFirst:=FFirstVisible;
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseMove) AND FDraggingPopupBar then
  begin
    FFirstVisible:=EnsureRange(FPopupDragFirst + Round(GuiScrollOffsetFromThumbDelta(
      AEvent.Position.Y - FPopupDragY, Track.Height, Thumb.Height, Limit)), 0, Limit);
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND FDraggingPopupBar then
  begin
    FDraggingPopupBar:=False;
    Result:=True;
  end;
  if Result then
  begin
    FHoveredIndex:=-1;
    AEvent.Handled:=True;
  end;
end;

function TGuiDropDownButton.DropDownRect: TGuiRect;
var
  Rect: TGuiRect;
  DropCount: Integer;
begin
  Rect:=AbsoluteBounds;
  DropCount:=FItems.Count;
  if DropCount > 6 then
    DropCount:=6;

  Result:=GuiRect(Rect.Left, Rect.Top + Rect.Height, Rect.Width, DropCount * FItemHeight);
end;

function TGuiDropDownButton.ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
begin
  Result:=-1;
  Rect:=DropDownRect;
  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  if FItemHeight <= 0 then Exit;
  Result:=FFirstVisible + Trunc((APoint.Y - Rect.Top) / FItemHeight);
  if (Result < 0) OR (Result >= FItems.Count) then
    Result:=-1;
end;

procedure TGuiDropDownButton.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));
  DrawControlText(ACanvas, Caption, GuiInflateRect(Rect,
    GuiBoxLTRB(Padding.Left, Padding.Top, Max(Padding.Right, 30), Padding.Bottom)),
    GuiResolveTextColor(Style, States), TextHorizontalAlign, TextVerticalAlign);
  ACanvas.FillRect(GuiRect(Rect.Left + Rect.Width - 24, Rect.Top + 6, 1, Max(0, Rect.Height - 12)), Style.BorderColor);
  ACanvas.DrawChevron(GuiRect(Rect.Left + Rect.Width - 16, Rect.Top + (Rect.Height / 2) - 2, 8, 4), GuiResolveTextColor(Style, States));

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
end;

procedure TGuiDropDownButton.ClosePopup;
begin
  FDraggingPopupBar:=False;
  FDroppedDown:=False;
  FHoveredIndex:=-1;
end;

procedure TGuiDropDownButton.PaintOverlay(ACanvas: TGuiCanvas);
var
  DropRect: TGuiRect;
  ItemsRect: TGuiRect;
  ItemRect, TextRect: TGuiRect;
  I: Integer;
begin
  if FDroppedDown then
  begin
    DropRect:=DropDownRect;
    ACanvas.DrawSurface(Style.Background, DropRect, Style.CornerRadius);
    DrawControlBorder(ACanvas, DropRect, Style.BorderColor);
    ItemsRect:=GuiInflateRect(DropRect, GuiBox(1));
    ACanvas.PushClipRect(ItemsRect);
    try
      FFirstVisible:=EnsureRange(FFirstVisible, 0, Max(0, FItems.Count - 6));
      for I:=FFirstVisible to Min(FItems.Count - 1, FFirstVisible + 5) do
      begin
        ItemRect:=GuiRect(ItemsRect.Left, DropRect.Top + ((I - FFirstVisible) * FItemHeight), ItemsRect.Width, FItemHeight);
        PaintItemBackground(ACanvas, ItemRect, I = FSelectedIndex);

        TextRect:=ItemRect;
        if FItems.Count > 6 then
          TextRect.Width:=Max(0, PopupTrackRect.Left - 4 - TextRect.Left);
        ACanvas.PushClipRect(TextRect);
        try
          DrawControlText(ACanvas, FItems[I], GuiInflateRect(TextRect, GuiBoxLTRB(8, 2, 8, 2)), Style.TextColor, ghtaLeft, gvtaCenter);
        finally
          ACanvas.PopClipRect;
        end;
      end;
    finally
      ACanvas.PopClipRect;
    end;
    if FItems.Count > 6 then
      PaintScrollBar(ACanvas, PopupTrackRect, PopupThumbRect, goVertical, FDraggingPopupBar, True);
  end;

  inherited PaintOverlay(ACanvas);
end;

procedure TGuiDropDownButton.HandleEvent(var AEvent: TGuiEvent);
var
  Index: Integer;
begin
  if HandlePopupScroll(AEvent) then Exit;
  inherited HandleEvent(AEvent);

  case AEvent.Kind of
    gekMouseWheel:
      if FDroppedDown then
      begin
        FFirstVisible:=EnsureRange(FFirstVisible - Round(AEvent.Delta.Y), 0, Max(0, FItems.Count - 6));
        AEvent.Handled:=True;
      end;
    gekBlur:
    begin
      FDroppedDown:=False;
      FHoveredIndex:=-1;
    end;

    gekMouseLeave:
    begin
      if NOT FDroppedDown then
        FHoveredIndex:=-1;
    end;

    gekMouseMove:
    begin
      if FDroppedDown then
      begin
        FHoveredIndex:=ItemIndexAtPoint(AEvent.Position);
        AEvent.Handled:=True;
      end;
    end;

    gekMouseDown:
    begin
      if FDroppedDown then
      begin
        Index:=ItemIndexAtPoint(AEvent.Position);
        if Index >= 0 then
        begin
          SelectedIndex:=Index;
          FDroppedDown:=False;
          FHoveredIndex:=-1;
        end else
          FDroppedDown:=False;
      end else
      begin
        FDroppedDown:=True;
        FHoveredIndex:=ItemIndexAtPoint(AEvent.Position);
      end;

      AEvent.Handled:=True;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        13, 32:
        begin
          FDroppedDown:=NOT FDroppedDown;
          if NOT FDroppedDown then
            FHoveredIndex:=-1;

          AEvent.Handled:=True;
        end;

        27:
        begin
          FDroppedDown:=False;
          FHoveredIndex:=-1;
          AEvent.Handled:=True;
        end;
      end;
    end;
  end;
end;

function TGuiDropDownButton.HitTestOverlay(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=inherited HitTestOverlay(APoint);

  if Assigned(Result) then
    Exit;

  if FDroppedDown AND Visible AND Enabled AND GuiRectContains(DropDownRect, APoint) then
    Result:=Self;
end;

function TGuiMenuItem.ShortcutCaption: String;
begin
  Result:=ShortcutText;
  if Result <> '' then Exit;
  if ShortcutKey = 0 then Exit;
  if gemCtrl IN ShortcutModifiers then Result:=Result + 'Ctrl+';
  if gemAlt IN ShortcutModifiers then Result:=Result + 'Alt+';
  if gemShift IN ShortcutModifiers then Result:=Result + 'Shift+';
  case ShortcutKey of
    13: Result:=Result + 'Enter';
    27: Result:=Result + 'Esc';
    32: Result:=Result + 'Space';
    127: Result:=Result + 'Del';
    $4000003A..$40000045: Result:=Result + 'F' + IntToStr(ShortcutKey - $4000003A + 1);
    else
      if (ShortcutKey >= 33) AND (ShortcutKey <= 126) then Result:=Result + Char(GuiMenuKey(ShortcutKey))
      else Result:=Result + IntToStr(ShortcutKey);
  end;
end;

function TGuiMenuBar.TryMenuKey(var AEvent: TGuiEvent): Boolean;
var I: Integer;
Item: TGuiMenuItem;
Handler: TNotifyEvent;
  function FindShortcut(AMenu: TGuiMenuItem): TGuiMenuItem;
  var J: Integer;
  begin
    Result:=nil;
    if NOT Assigned(AMenu) OR NOT AMenu.Enabled OR AMenu.Separator then Exit;
    if (AMenu.Count = 0) AND (AMenu.ShortcutKey <> 0) AND
      (GuiMenuKey(AMenu.ShortcutKey) = GuiMenuKey(AEvent.KeyCode)) AND
      (AMenu.ShortcutModifiers = AEvent.Modifiers) then
      begin
        Result:=AMenu;
        Exit;
      end;
    for J:=0 to AMenu.Count - 1 do
    begin
      Result:=FindShortcut(AMenu[J]);
      if Assigned(Result) then Exit;
    end;
  end;
begin
  Result:=False;
  if NOT Visible OR NOT Enabled OR (AEvent.Kind <> gekKeyDown) then Exit;
  if NOT (Self IS TGuiPopupMenu) AND
    ((AEvent.Modifiers = [gemAlt]) OR ((AEvent.KeyCode = $40000043) AND (AEvent.Modifiers = []))) then
    for I:=0 to FItems.Count - 1 do
      if ((GuiMenuMnemonic(FItems[I]) <> 0) AND (GuiMenuMnemonic(FItems[I]) = GuiMenuKey(AEvent.KeyCode))) OR
        ((AEvent.KeyCode = $40000043) AND (I = Max(0, FSelectedIndex))) then
      begin
        Item:=RootMenu(I);
        if Assigned(Item) AND NOT Item.Enabled then Continue;
        if Assigned(Context) then Context.SetFocus(Self);
        OpenRoot(I);
        MoveItem(1);
        AEvent.Handled:=True;
        Result:=True;
        Exit;
      end;
  { Unmodified printable keys belong to text entry, not global accelerators. }
  if (AEvent.Modifiers = []) AND (AEvent.KeyCode < $4000003A) then Exit;
  for I:=0 to FItems.Count - 1 do
  begin
    Item:=FindShortcut(RootMenu(I));
    if Assigned(Item) then
    begin
      AEvent.Handled:=True;
      Result:=True;
      if Item.AutoCheck then Item.Checked:=NOT Item.Checked;
      Handler:=Item.OnClick;
      ClosePopup;
      if Assigned(Handler) then Handler(Item);
      Exit;
    end;
  end;
end;

constructor TGuiPopupMenu.Create;
begin
  inherited Create;
  FMenu:=AddMenu('');
  CanFocus:=False;
  Bounds:=GuiRect(0, 0, 0, 0);
end;

procedure TGuiPopupMenu.PaintSelf(ACanvas: TGuiCanvas);
begin
end;

procedure TGuiPopupMenu.ClosePopup;
begin
  inherited ClosePopup;
  CanFocus:=False;
end;

procedure TGuiPopupMenu.PopupAt(const APoint: TGuiPoint);
begin
  if NOT Assigned(Context) OR NOT Enabled OR NOT Visible OR NOT FMenu.Enabled OR (FMenu.Count = 0) then Exit;
  if Assigned(Context.ModalControl) AND NOT Context.ControlContains(Context.ModalControl, Self) then Exit;
  Context.CancelInput;
  Context.ClosePopups(Self);
  FContextPopup:=True;
  FPopupPoint:=APoint;
  FSelectedIndex:=0;
  OpenLevel(0, FMenu);
  CanFocus:=True;
  Context.SetFocus(Self);
end;

function TGuiPopupMenu.PopupOpen: Boolean;
begin
  Result:=FPath.Count > 0;
end;

function TGuiMenuBar.DispatchShortcut(var AEvent: TGuiEvent): Boolean;
begin
  Result:=False;
  if NOT Visible OR NOT Enabled then
    Exit;
  Result:=TryMenuKey(AEvent);
  if NOT Result then
    Result:=inherited DispatchShortcut(AEvent);
end;

constructor TGuiMenuItem.Create(const ACaption: String);
begin
  inherited Create;
  Caption:=ACaption;
  Enabled:=True;
  FChildren:=TList.Create;
end;

destructor TGuiMenuItem.Destroy;
var I: Integer;
begin
  for I:=0 to Count - 1 do Items[I].Free;
  FChildren.Free;
  inherited Destroy;
end;

function TGuiMenuItem.GetCount: Integer;
begin
  Result:=FChildren.Count;
end;

function TGuiMenuItem.GetItem(AIndex: Integer): TGuiMenuItem;
begin
  Result:=TGuiMenuItem(FChildren[AIndex]);
end;

function TGuiMenuItem.Add(const ACaption: String; AOnClick: TNotifyEvent): TGuiMenuItem;
begin
  Result:=TGuiMenuItem.Create(ACaption);
  Result.OnClick:=AOnClick;
  FChildren.Add(Result);
end;

function TGuiMenuItem.AddSeparator: TGuiMenuItem;
begin
  Result:=Add('');
  Result.Separator:=True;
  Result.Enabled:=False;
end;

procedure TGuiMenuBar.ItemsChanged(Sender: TObject);
begin
  ClosePopup;
  FSelectedIndex:=Min(FSelectedIndex, FItems.Count - 1);
end;

function TGuiMenuBar.AddMenu(const ACaption: String): TGuiMenuItem;
begin
  Result:=TGuiMenuItem.Create(ACaption);
  FRoots.Add(Result);
  FItems.AddObject(ACaption, Result);
  if FSelectedIndex < 0 then FSelectedIndex:=0;
end;

function TGuiMenuBar.RootMenu(AIndex: Integer): TGuiMenuItem;
begin
  Result:=nil;
  if (AIndex >= 0) AND (AIndex < FItems.Count) AND
    (FRoots.IndexOf(FItems.Objects[AIndex]) >= 0) then Result:=TGuiMenuItem(FItems.Objects[AIndex]);
end;

procedure TGuiMenuBar.ClosePopup;
begin
  FPath.Clear;
  SetLength(FHot, 0);
  SetLength(FFirst, 0);
end;

procedure TGuiMenuBar.OpenLevel(ALevel: Integer; AMenu: TGuiMenuItem);
var I: Integer;
Width: TGuiFloat;
begin
  FPath.Count:=ALevel;
  FPath.Add(AMenu);
  SetLength(FHot, ALevel + 1);
  SetLength(FFirst, ALevel + 1);
  FHot[ALevel]:=-1;
  FFirst[ALevel]:=0;
  Width:=MinPopupWidth;
  for I:=0 to AMenu.Count - 1 do
    Width:=Max(Width, (Length(GuiMenuCaption(AMenu[I].Caption)) + Length(AMenu[I].ShortcutCaption)) * 8 + 76);
  SetLength(FPopupWidths, ALevel + 1);
  FPopupWidths[ALevel]:=Min(Max(MinPopupWidth, MaxPopupWidth), Width);
end;

procedure TGuiMenuBar.OpenRoot(AIndex: Integer);
var Menu: TGuiMenuItem;
begin
  ClosePopup;
  FContextPopup:=False;
  Menu:=RootMenu(AIndex);
  if Assigned(Menu) AND NOT Menu.Enabled then Exit;
  FSelectedIndex:=AIndex;
  if Assigned(Menu) AND (Menu.Count > 0) then OpenLevel(0, Menu);
end;

procedure TGuiMenuBar.MoveRoot(ADirection: Integer);
var I, Index: Integer;
Menu: TGuiMenuItem;
begin
  if FItems.Count = 0 then Exit;
  Index:=FSelectedIndex;
  for I:=1 to FItems.Count do
  begin
    Index:=(Index + ADirection + FItems.Count) MOD FItems.Count;
    Menu:=RootMenu(Index);
    if (NOT Assigned(Menu)) OR Menu.Enabled then
    begin
      OpenRoot(Index);
      MoveItem(1);
      Exit;
    end;
  end;
end;

function TGuiMenuBar.PopupRect(ALevel: Integer): TGuiRect;
var ParentRect, Screen: TGuiRect;
Menu: TGuiMenuItem;
begin
  Menu:=TGuiMenuItem(FPath[ALevel]);
  Screen:=GuiRect(0, 0, 100000, 100000);
  if Assigned(Context) then Screen:=Context.Root.AbsoluteBounds;
  Result:=GuiRect(AbsoluteBounds.Left + FSelectedIndex * FItemWidth,
    AbsoluteBounds.Top + AbsoluteBounds.Height, Min(FPopupWidths[ALevel], Screen.Width),
    Min(Menu.Count * 28 + 8, Max(0, Screen.Height)));
  if (ALevel = 0) AND FContextPopup then
  begin
    Result.Left:=FPopupPoint.X;
    Result.Top:=FPopupPoint.Y;
  end;
  if ALevel > 0 then
  begin
    ParentRect:=PopupRect(ALevel - 1);
    Result.Left:=ParentRect.Left + ParentRect.Width;
    Result.Top:=ParentRect.Top + 4 + (FHot[ALevel - 1] - FFirst[ALevel - 1]) * 28;
    if Result.Left + Result.Width > Screen.Left + Screen.Width then Result.Left:=ParentRect.Left - Result.Width;
  end;
  Result.Left:=EnsureRange(Result.Left, Screen.Left, Max(Screen.Left, Screen.Left + Screen.Width - Result.Width));
  Result.Top:=EnsureRange(Result.Top, Screen.Top, Max(Screen.Top, Screen.Top + Screen.Height - Result.Height));
end;

function TGuiMenuBar.PopupIndex(const APoint: TGuiPoint; out ALevel: Integer): Integer;
var I: Integer;
R: TGuiRect;
begin
  Result:=-1;
  ALevel:=-1;
  for I:=FPath.Count - 1 downto 0 do
  begin
    R:=PopupRect(I);
    if GuiRectContains(R, APoint) then
    begin
      ALevel:=I;
      if (APoint.Y < R.Top + 4) OR (APoint.Y >= R.Top + R.Height - 4) then Exit;
      Result:=FFirst[I] + Floor((APoint.Y - R.Top - 4) / 28);
      if Result >= TGuiMenuItem(FPath[I]).Count then Result:=-1;
      Exit;
    end;
  end;
end;

function TGuiMenuBar.HitTestOverlay(const APoint: TGuiPoint): TGuiControl;
var Level: Integer;
begin
  Result:=inherited HitTestOverlay(APoint);
  if Assigned(Result) OR NOT Visible OR NOT Enabled then Exit;
  PopupIndex(APoint, Level);
  if Level >= 0 then Result:=Self;
end;

procedure TGuiMenuBar.ActivateItem(ALevel, AIndex: Integer);
var Item: TGuiMenuItem;
Handler: TNotifyEvent;
begin
  if (ALevel < 0) OR (ALevel >= FPath.Count) then Exit;
  if (AIndex < 0) OR (AIndex >= TGuiMenuItem(FPath[ALevel]).Count) then Exit;
  Item:=TGuiMenuItem(FPath[ALevel])[AIndex];
  if NOT Item.Enabled OR Item.Separator then Exit;
  FHot[ALevel]:=AIndex;
  if Item.Count > 0 then
  begin
    OpenLevel(ALevel + 1, Item);
    MoveItem(1);
    Exit;
  end;
  if Item.AutoCheck then Item.Checked:=NOT Item.Checked;
  Handler:=Item.OnClick;
  ClosePopup;
  if (Self IS TGuiPopupMenu) AND Assigned(Context) then Context.RestoreFocus;
  if Assigned(Handler) then Handler(Item);
end;

procedure TGuiMenuBar.MoveItem(ADirection: Integer);
var Level, I, Index, VisibleRows: Integer;
Menu: TGuiMenuItem;
R: TGuiRect;
begin
  Level:=FPath.Count - 1;
  if Level < 0 then Exit;
  Menu:=TGuiMenuItem(FPath[Level]);
  if Menu.Count = 0 then Exit;
  Index:=FHot[Level];
  if (Index < 0) AND (ADirection < 0) then Index:=0;
  for I:=1 to Menu.Count do
  begin
    Index:=(Index + ADirection + Menu.Count) MOD Menu.Count;
    if Menu[Index].Enabled AND NOT Menu[Index].Separator then
    begin
      FHot[Level]:=Index;
      R:=PopupRect(Level);
      VisibleRows:=Max(1, Floor((R.Height - 8) / 28));
      if Index < FFirst[Level] then FFirst[Level]:=Index;
      if Index >= FFirst[Level] + VisibleRows then FFirst[Level]:=Index - VisibleRows + 1;
      Exit;
    end;
  end;
end;

procedure TGuiMenuBar.PaintOverlay(ACanvas: TGuiCanvas);
var Width, ShortcutWidth: TGuiFloat;
  Level, I: Integer;
  Menu, Item: TGuiMenuItem;
  R, Row, TextRect: TGuiRect;
  Color: TGuiColor;
begin
  if NOT Visible OR NOT Enabled then Exit;
  for Level:=0 to FPath.Count - 1 do
  begin
    Menu:=TGuiMenuItem(FPath[Level]);
    Width:=Max(80, MinPopupWidth);
    for I:=0 to Menu.Count - 1 do
      Width:=Max(Width, ACanvas.MeasureText(GuiMenuCaption(Menu[I].Caption)).Width +
        ACanvas.MeasureText(Menu[I].ShortcutCaption).Width + 76);
    FPopupWidths[Level]:=Min(Max(Max(80, MinPopupWidth), MaxPopupWidth), Width);
    R:=PopupRect(Level);
    ACanvas.DrawSurface(Style.Background, R, Style.CornerRadius);
    DrawControlBorder(ACanvas, R, Style.BorderColor);
    ACanvas.PushClipRect(GuiInflateRect(R, GuiBox(4)));
    try
      for I:=FFirst[Level] to Menu.Count - 1 do
      begin
        Row:=GuiRect(R.Left + 4, R.Top + 4 + (I - FFirst[Level]) * 28, R.Width - 8, 28);
        if Row.Top >= R.Top + R.Height - 4 then Break;
        Item:=Menu[I];
        if Item.Separator then
          ACanvas.FillRect(GuiRect(Row.Left + 8, Row.Top + 13, Max(0, Row.Width - 16), 1), Style.BorderColor)
        else
        begin
          if (I = FHot[Level]) AND Item.Enabled then ACanvas.DrawSurface(Style.Selection, Row, Min(4, Style.CornerRadius));
          Color:=Style.TextColor;
          if NOT Item.Enabled then Color:=GuiResolveTextColor(Style, [gcvsDisabled]);
          ShortcutWidth:=0;
          if Item.ShortcutCaption <> '' then ShortcutWidth:=ACanvas.MeasureText(Item.ShortcutCaption).Width + 20;
          TextRect:=GuiInflateRect(Row, GuiBoxLTRB(26, 2, 24 + ShortcutWidth, 2));
          ACanvas.PushClipRect(TextRect);
          try
            DrawControlText(ACanvas, GuiMenuCaption(Item.Caption), TextRect, Color, ghtaLeft, gvtaCenter);
          finally
            ACanvas.PopClipRect;
          end;
          if ShortcutWidth > 0 then
            DrawControlText(ACanvas, Item.ShortcutCaption, GuiInflateRect(Row, GuiBoxLTRB(26, 2, 24, 2)), Color, ghtaRight, gvtaCenter);
          if Item.Checked then
          begin
            ACanvas.DrawLine(GuiPoint(Row.Left + 8, Row.Top + 14), GuiPoint(Row.Left + 12, Row.Top + 18), 2, Color);
            ACanvas.DrawLine(GuiPoint(Row.Left + 12, Row.Top + 18), GuiPoint(Row.Left + 19, Row.Top + 10), 2, Color);
          end;
          if Item.Count > 0 then
          begin
            ACanvas.DrawLine(GuiPoint(Row.Left + Row.Width - 17, Row.Top + 10), GuiPoint(Row.Left + Row.Width - 13, Row.Top + 14), 1.5, Color);
            ACanvas.DrawLine(GuiPoint(Row.Left + Row.Width - 13, Row.Top + 14), GuiPoint(Row.Left + Row.Width - 17, Row.Top + 18), 1.5, Color);
          end;
        end;
      end;
    finally
      ACanvas.PopClipRect;
    end;
  end;
  inherited PaintOverlay(ACanvas);
end;

constructor TGuiMenuBar.Create;
begin
  inherited Create;
  MinPopupWidth:=180;
  MaxPopupWidth:=420;
  FRoots:=TList.Create;
  FPath:=TList.Create;
  FItems:=TStringList.Create;
  FItems.OnChange:=ItemsChanged;
  FSelectedIndex:=-1;
  FHoveredIndex:=-1;
  FItemWidth:=76;
  CanFocus:=True;
  TabStop:=True;
  ShowFocus:=True;
  Padding:=GuiBox(0);
end;

destructor TGuiMenuBar.Destroy;
var I: Integer;
begin
  FItems.OnChange:=nil;
  for I:=0 to FRoots.Count - 1 do TObject(FRoots[I]).Free;
  FRoots.Free;
  FPath.Free;
  FItems.Free;
  inherited Destroy;
end;

function TGuiMenuBar.AddItem(const ACaption: String): Integer;
begin
  Result:=FItems.Add(ACaption);
  if FSelectedIndex < 0 then
    FSelectedIndex:=0;

  InvalidateLayout;
end;

procedure TGuiMenuBar.SetSelectedIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue:=-1;

  if AValue >= FItems.Count then
    AValue:=FItems.Count - 1;

  if FSelectedIndex = AValue then
    Exit;

  ClosePopup;
  FSelectedIndex:=AValue;

  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

function TGuiMenuBar.ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
begin
  Result:=-1;
  Rect:=AbsoluteBounds;

  if (FItemWidth <= 0) OR (NOT GuiRectContains(Rect, APoint)) then
    Exit;

  Result:=Trunc((APoint.X - Rect.Left) / FItemWidth);

  if (Result < 0) OR (Result >= FItems.Count) then
    Result:=-1;
end;

procedure TGuiMenuBar.PaintSelf(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
  ItemRect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, Style.BackgroundColor);

  for I:=0 to FItems.Count - 1 do
  begin
    States:=[gcvsNormal];
    if I = FSelectedIndex then
      Include(States, gcvsChecked)
    else
    if I = FHoveredIndex then
      Include(States, gcvsHovered);

    if NOT Enabled OR (Assigned(RootMenu(I)) AND NOT RootMenu(I).Enabled) then
      Include(States, gcvsDisabled);

    ItemRect:=GuiRect(Rect.Left + (I * FItemWidth), Rect.Top, FItemWidth, Rect.Height);
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), ItemRect, Style.CornerRadius);
    DrawControlText(ACanvas, GuiMenuCaption(FItems[I]),
      GuiInflateRect(ItemRect, GuiBoxLTRB(10, 2, 10, 2)),
      GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
  end;

  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top, Rect.Width, 1), Style.BorderColor);
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top, 1, Rect.Height), Style.BorderColor);
  ACanvas.FillRect(GuiRect(Rect.Left + Rect.Width - 1, Rect.Top, 1, Rect.Height), Style.BorderColor);
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 1, Rect.Width, 1), Style.BorderColor);

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
end;

procedure TGuiMenuBar.HandleEvent(var AEvent: TGuiEvent);
var
  Index, Level, Direction, VisibleRows: Integer;
  Item: TGuiMenuItem;
  R: TGuiRect;
begin
  inherited HandleEvent(AEvent);
  if (AEvent.Kind = gekKeyDown) AND (FPath.Count > 0) AND
    ((AEvent.Modifiers = []) OR (AEvent.Modifiers = [gemAlt])) then
  begin
    Level:=FPath.Count - 1;
    for Index:=0 to TGuiMenuItem(FPath[Level]).Count - 1 do
    begin
      Item:=TGuiMenuItem(FPath[Level])[Index];
      if Item.Enabled AND NOT Item.Separator AND (GuiMenuMnemonic(Item.Caption) <> 0) AND
        (GuiMenuMnemonic(Item.Caption) = GuiMenuKey(AEvent.KeyCode)) then
      begin
        AEvent.Handled:=True;
        ActivateItem(Level, Index);
        Exit;
      end;
    end;
  end;
  case AEvent.Kind of
    gekCancel, gekBlur: ClosePopup;
    gekMouseLeave: FHoveredIndex:=-1;
    gekMouseMove, gekMouseDown:
    begin
      if (AEvent.Kind = gekMouseDown) AND (AEvent.Button <> gmbLeft) then Exit;
      Index:=PopupIndex(AEvent.Position, Level);
      if Level >= 0 then
      begin
        AEvent.Handled:=True;
        if Index < 0 then Exit;
        Item:=TGuiMenuItem(FPath[Level])[Index];
        if NOT Item.Enabled OR Item.Separator then
        begin
          FPath.Count:=Level + 1;
          FHot[Level]:=-1;
          Exit;
        end;
        if FHot[Level] <> Index then
        begin
          FPath.Count:=Level + 1;
          FHot[Level]:=Index;
          if Item.Count > 0 then OpenLevel(Level + 1, Item);
        end;
        if AEvent.Kind = gekMouseDown then ActivateItem(Level, Index);
        Exit;
      end;
      Index:=ItemIndexAtPoint(AEvent.Position);
      FHoveredIndex:=Index;
      if Index < 0 then Exit;
      Item:=RootMenu(Index);
      if Assigned(Item) AND NOT Item.Enabled then Exit;
      if AEvent.Kind = gekMouseDown then
      begin
        AEvent.Handled:=True;
        if (FPath.Count > 0) AND (FSelectedIndex = Index) then ClosePopup
        else
        begin
          OpenRoot(Index);
          if Assigned(FOnSelect) then FOnSelect(Self);
        end;
      end
      else if (FPath.Count > 0) AND (FSelectedIndex <> Index) then OpenRoot(Index);
    end;
    gekMouseWheel:
    begin
      PopupIndex(AEvent.Position, Level);
      if Level < 0 then Exit;
      FPath.Count:=Level + 1;
      R:=PopupRect(Level);
      VisibleRows:=Max(1, Floor((R.Height - 8) / 28));
      FFirst[Level]:=EnsureRange(FFirst[Level] - Round(AEvent.Delta.Y), 0,
        Max(0, TGuiMenuItem(FPath[Level]).Count - VisibleRows));
      FHot[Level]:=-1;
      AEvent.Handled:=True;
    end;
    gekKeyDown:
    begin
      if FItems.Count = 0 then Exit;
      Level:=FPath.Count - 1;
      case AEvent.KeyCode of
        27:
          if Level > 0 then FPath.Count:=Level else ClosePopup;
        9:
        begin
          ClosePopup;
          Exit;
        end;
        13, 32:
          if Level < 0 then
          begin
            OpenRoot(Max(0, FSelectedIndex));
            MoveItem(1);
          end
          else
          begin
            AEvent.Handled:=True;
            ActivateItem(Level, FHot[Level]);
            Exit;
          end;
        $40000051, $40000052:
        begin
          Direction:=1;
          if AEvent.KeyCode = $40000052 then Direction:=-1;
          if Level < 0 then OpenRoot(Max(0, FSelectedIndex));
          MoveItem(Direction);
        end;
        $4000004A:
        begin
          if Level >= 0 then FHot[Level]:=-1;
          MoveItem(1);
        end;
        $4000004D:
        begin
          if Level >= 0 then FHot[Level]:=-1;
          MoveItem(-1);
        end;
        $40000050:
          if Level > 0 then FPath.Count:=Level
          else if NOT FContextPopup then MoveRoot(-1);
        $4000004F:
        begin
          Item:=nil;
          if (Level >= 0) AND (FHot[Level] >= 0) then Item:=TGuiMenuItem(FPath[Level])[FHot[Level]];
          if Assigned(Item) AND Item.Enabled AND (Item.Count > 0) then
          begin
            OpenLevel(Level + 1, Item);
            MoveItem(1);
          end
          else if NOT FContextPopup then MoveRoot(1);
        end;
        else Exit;
      end;
      AEvent.Handled:=True;
    end;
  end;
  if (AEvent.Kind = gekKeyDown) AND (Self IS TGuiPopupMenu) AND (FPath.Count = 0) AND Assigned(Context) AND
    (Context.FocusedControl = Self) then Context.RestoreFocus;
end;

end.
