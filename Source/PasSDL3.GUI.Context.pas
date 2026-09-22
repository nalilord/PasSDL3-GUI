unit PasSDL3.GUI.Context;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Text,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Containers;

type
  TGuiLayerKind = (
    glkWorld,
    glkHud,
    glkDialog,
    glkPopup,
    glkDebug
  );

  TGuiLayerControl = class(TGuiPanel)
  public
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    function HitTestOverlay(const APoint: TGuiPoint): TGuiControl; override;
  end;

  TGuiContext = class(TGuiContextServices)
  private
    FRoot: TGuiControl;
    FLayers: array[TGuiLayerKind] of TGuiControl;
    FModalStack: TList;
    FFocusHistory: TList;
    FHoveredControl: TGuiControl;
    FFocusedControl: TGuiControl;
    FFocusRevision: UInt64;
    FCapturedControl: TGuiControl;
    FPressedControl: TGuiControl;
    FOnFocusChanged: TGuiFocusChangedEvent;
    FGamepadAxisXState: Integer;
    FGamepadAxisYState: Integer;
    FShowFocus: Boolean;
    FKeyboardFocus: Boolean;
    FHoverSince: UInt64;
    FMousePosition: TGuiPoint;
    FTooltipDelay: Cardinal;
    FTooltipMaxWidth: TGuiFloat;
    FTooltipsEnabled: Boolean;
    function DispatchMenuKey(AControl: TGuiControl; var AEvent: TGuiEvent): Boolean;
    procedure SetShowFocus(AValue: Boolean);
    procedure SetKeyboardFocus(AValue: Boolean);
    procedure SetHoveredControl(AControl: TGuiControl; const APosition: TGuiPoint);
    procedure SetFocusedControl(AControl: TGuiControl);
    procedure ActivateFocusedControl(var AEvent: TGuiEvent);
    procedure MoveFocus(AReverse: Boolean; var AEvent: TGuiEvent);
    function GamepadAxisState(AValue: TGuiFloat): Integer;
    function CanFocusControl(AControl: TGuiControl): Boolean;
    function HitTest(const APoint: TGuiPoint): TGuiControl;
    function ActiveFocusRoot: TGuiControl;
    function GetLayer(AKind: TGuiLayerKind): TGuiControl;
    function NextFocusableControl(AFrom: TGuiControl; AReverse: Boolean): TGuiControl;
    function FindFocusableAfter(AControl, AFrom: TGuiControl; AReverse: Boolean; var AFoundFrom: Boolean): TGuiControl;
    function FindFirstFocusable(AControl: TGuiControl; AReverse: Boolean): TGuiControl;
  protected
    function GetRoot: TGuiControl; override;
    function GetModalControl: TGuiControl; override;
    function GetHoveredControl: TGuiControl; override;
    function GetFocusedControl: TGuiControl; override;
    function GetPressedControl: TGuiControl; override;
    function GetMousePosition: TGuiPoint; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Resize(AWidth, AHeight: TGuiFloat);
    procedure UpdateLayout;
    procedure Paint(ACanvas: TGuiCanvas);
    procedure ProcessEvent(var AEvent: TGuiEvent);
    procedure ShowModal(AControl: TGuiControl);
    procedure DetachControl(AControl: TGuiControl); override;
    procedure CloseModal(AControl: TGuiControl = nil); override;
    procedure RestoreFocus; override;
    function RestoreFocusWithin(ARoot, AExcept: TGuiControl): Boolean; override;
    function MouseCursor: TGuiMouseCursor;
    function SetFocus(AControl: TGuiControl): Boolean; override;
    function FocusFirst: Boolean;
    function FocusNext: Boolean;
    function FocusPrevious: Boolean;
    procedure ClearFocus;
    procedure CancelInput; override;
    function ControlContains(AParent, AControl: TGuiControl): Boolean; override;
    procedure ClosePopups(AExcept: TGuiControl); override;
    property Root: TGuiControl read FRoot;
    property Layers[AKind: TGuiLayerKind]: TGuiControl read GetLayer;
    property ModalControl: TGuiControl read GetModalControl;
    property HoveredControl: TGuiControl read FHoveredControl;
    property FocusedControl: TGuiControl read FFocusedControl;
    property FocusRevision: UInt64 read FFocusRevision;
    property CapturedControl: TGuiControl read FCapturedControl;
    property PressedControl: TGuiControl read FPressedControl;
    property ShowFocus: Boolean read FShowFocus write SetShowFocus;
    property TooltipDelay: Cardinal read FTooltipDelay write FTooltipDelay;
    property TooltipMaxWidth: TGuiFloat read FTooltipMaxWidth write FTooltipMaxWidth;
    property TooltipsEnabled: Boolean read FTooltipsEnabled write FTooltipsEnabled;
    property OnFocusChanged: TGuiFocusChangedEvent read FOnFocusChanged write FOnFocusChanged;
  end;

implementation

function TGuiContext.MouseCursor: TGuiMouseCursor;
var Control, Ancestor: TGuiControl;
begin
  Result:=gmcArrow;
  Control:=FCapturedControl;
  if NOT Assigned(Control) then Control:=FHoveredControl;
  if NOT Assigned(Control) then Exit;
  Ancestor:=Control;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Visible OR NOT Ancestor.Enabled then Exit;
    Ancestor:=Ancestor.Parent;
  end;
  Result:=Control.MouseCursorAt(FMousePosition);
end;

function TGuiContext.DispatchMenuKey(AControl: TGuiControl; var AEvent: TGuiEvent): Boolean;
begin
  Result:=Assigned(AControl) AND AControl.DispatchShortcut(AEvent);
end;

function TGuiLayerControl.HitTest(const APoint: TGuiPoint): TGuiControl;
var
  I: Integer;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) OR (NOT GuiRectContains(AbsoluteBounds, APoint)) then
    Exit;

  for I:=ChildCount - 1 downto 0 do
  begin
    Result:=Children[I].HitTest(APoint);
    if Assigned(Result) then
      Exit;
  end;
end;

function TGuiLayerControl.HitTestOverlay(const APoint: TGuiPoint): TGuiControl;
var
  I: Integer;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) OR (NOT GuiRectContains(AbsoluteBounds, APoint)) then
    Exit;

  for I:=ChildCount - 1 downto 0 do
  begin
    Result:=Children[I].HitTestOverlay(APoint);
    if Assigned(Result) then
      Exit;
  end;
end;

function TGuiContext.GetRoot: TGuiControl;
begin
  Result:=FRoot;
end;

function TGuiContext.GetHoveredControl: TGuiControl;
begin
  Result:=FHoveredControl;
end;

function TGuiContext.GetFocusedControl: TGuiControl;
begin
  Result:=FFocusedControl;
end;

function TGuiContext.GetPressedControl: TGuiControl;
begin
  Result:=FPressedControl;
end;

function TGuiContext.GetMousePosition: TGuiPoint;
begin
  Result:=FMousePosition;
end;

constructor TGuiContext.Create;
var
  LayerKind: TGuiLayerKind;
begin
  inherited Create;
  for LayerKind:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
  begin
    FLayers[LayerKind]:=TGuiLayerControl.Create;
    FLayers[LayerKind].AttachContext(Self);
    FLayers[LayerKind].Name:='Layer';
    FLayers[LayerKind].BackgroundColor:=GuiColor(0, 0, 0, 0);
    FLayers[LayerKind].BorderColor:=GuiColor(0, 0, 0, 0);
  end;

  FRoot:=FLayers[glkWorld];
  FRoot.Name:='Root';
  FRoot.BackgroundColor:=GuiColor(22, 25, 29);
  FModalStack:=TList.Create;
  FFocusHistory:=TList.Create;
  FGamepadAxisXState:=0;
  FGamepadAxisYState:=0;
  FShowFocus:=True;
  FTooltipsEnabled:=True;
  FTooltipDelay:=500;
  FTooltipMaxWidth:=320;
end;

destructor TGuiContext.Destroy;
var
  LayerKind: TGuiLayerKind;
begin
  for LayerKind:=High(TGuiLayerKind) downto Low(TGuiLayerKind) do
  begin
    FLayers[LayerKind].Free;
    FLayers[LayerKind]:=nil;
  end;
  FModalStack.Free;
  FFocusHistory.Free;

  inherited Destroy;
end;

procedure TGuiContext.DetachControl(AControl: TGuiControl);
var
  I: Integer;
  Layer: TGuiLayerKind;
  procedure ClearPopupReferences(ANode: TGuiControl);
  var J: Integer;
  begin
    if NOT Assigned(ANode) then Exit;
    if Assigned(ANode.PopupMenu) AND ControlContains(AControl, ANode.PopupMenu) then ANode.PopupMenu:=nil;
    for J:=0 to ANode.ChildCount - 1 do ClearPopupReferences(ANode.Children[J]);
  end;
  function ContainsPopup(ANode: TGuiControl): Boolean;
  var J: Integer;
  begin
    Result:=ANode IS TGuiPopupControl;
    if Result then Exit;
    for J:=0 to ANode.ChildCount - 1 do
      if ContainsPopup(ANode.Children[J]) then
      begin
        Result:=True;
        Exit;
      end;
  end;
begin
  if ContainsPopup(AControl) then
    for Layer:=Low(TGuiLayerKind) to High(TGuiLayerKind) do ClearPopupReferences(FLayers[Layer]);
  if Assigned(FFocusHistory) then
    for I:=FFocusHistory.Count - 1 downto 0 do
      if ControlContains(AControl, TGuiControl(FFocusHistory[I])) then FFocusHistory.Delete(I);
  // Detachment also runs during destruction: do not invoke application callbacks.
  if ControlContains(AControl, FFocusedControl) then
  begin
    FFocusedControl.Focused:=False;
    FFocusedControl.FocusVisible:=False;
    FFocusedControl.DetachedFromContext;
    FFocusedControl:=nil;
    Inc(FFocusRevision);
  end;
  if ControlContains(AControl, FHoveredControl) then
  begin
    FHoveredControl.Hovered:=False;
    FHoveredControl:=nil;
  end;
  if ControlContains(AControl, FCapturedControl) then
  begin
    FCapturedControl.Pressed:=False;
    FCapturedControl:=nil;
  end;
  if ControlContains(AControl, FPressedControl) then
    FPressedControl:=nil;
  if Assigned(FModalStack) then
    for I:=FModalStack.Count - 1 downto 0 do
      if ControlContains(AControl, TGuiControl(FModalStack[I])) then
        FModalStack.Delete(I);
end;

procedure TGuiContext.Resize(AWidth, AHeight: TGuiFloat);
var
  LayerKind: TGuiLayerKind;
begin
  for LayerKind:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
  begin
    FLayers[LayerKind].Bounds:=GuiRect(0, 0, AWidth, AHeight);
    FLayers[LayerKind].InvalidateLayout;
  end;
end;

procedure TGuiContext.UpdateLayout;
var
  LayerKind: TGuiLayerKind;
begin
  for LayerKind:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
  begin
    if FLayers[LayerKind].LayoutDirty then
    begin
      FLayers[LayerKind].Arrange(FLayers[LayerKind].Bounds);
      FLayers[LayerKind].CaptureLayoutState;
    end;
  end;
end;

procedure TGuiContext.Paint(ACanvas: TGuiCanvas);
var
  LayerKind: TGuiLayerKind;
  InteractionStage: TGuiInteractionStage;
  Control: TGuiControl;
  Size: TGuiSize;
  Rect: TGuiRect;
  PreviousFont: String;
  HintText: String;
  Rows: TGuiTextRows;
  I: Integer;
  LineHeight, Width: TGuiFloat;
begin
  { Timed activation runs before traversal: handlers may remove controls safely. }
  for InteractionStage:=Low(TGuiInteractionStage) to High(TGuiInteractionStage) do
  begin
    if Assigned(FCapturedControl) then
      FCapturedControl.UpdateInteraction(InteractionStage);
    if Assigned(FFocusedControl) then
      FFocusedControl.UpdateInteraction(InteractionStage);
  end;
  UpdateLayout;

  for LayerKind:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
    FLayers[LayerKind].Paint(ACanvas);

  for LayerKind:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
    FLayers[LayerKind].PaintOverlay(ACanvas);
  if FTooltipsEnabled AND (NOT Assigned(FCapturedControl)) AND (TThread.GetTickCount64 - FHoverSince >= FTooltipDelay) then
  begin
    Control:=FHoveredControl;
    while Assigned(Control) AND (Control.Hint = '') do Control:=Control.Parent;
    if Assigned(Control) AND Control.Visible then
    begin
      PreviousFont:=ACanvas.FontName;
      ACanvas.FontName:=Control.FontName;
      try
        HintText:=StringReplace(Control.Hint, #13#10, #10, [rfReplaceAll]);
        HintText:=StringReplace(HintText, #13, #10, [rfReplaceAll]);
        Width:=Max(1, Min(Max(16, FTooltipMaxWidth), FRoot.Bounds.Width) - 16);
        Rows:=GuiLayoutText(ACanvas, HintText, Width, True);
        Size:=ACanvas.MeasureText('Mg');
        LineHeight:=Max(1, Size.Height);
        Width:=0;
        for I:=0 to High(Rows) do Width:=Max(Width, Rows[I].Width);
        Rect:=GuiRect(FMousePosition.X + 12, FMousePosition.Y + 18,
          Min(FRoot.Bounds.Width, Width + 16), Min(FRoot.Bounds.Height, Length(Rows) * LineHeight + 12));
        Rect.Left:=Max(0, Min(Rect.Left, FRoot.Bounds.Width - Rect.Width));
        Rect.Top:=Max(0, Min(Rect.Top, FRoot.Bounds.Height - Rect.Height));
        ACanvas.DrawSurface(Control.Style.Background, Rect, Control.Style.CornerRadius);
        ACanvas.DrawRoundedBorder(Rect, Control.Style.CornerRadius, 1, Control.Style.BorderColor);
        ACanvas.PushClipRect(GuiInflateRect(Rect, GuiBoxLTRB(8, 6, 8, 6)));
        try
          for I:=0 to High(Rows) do
          begin
            if I * LineHeight >= Rect.Height - 12 then Break;
            ACanvas.DrawText(Copy(HintText, Rows[I].StartIndex + 1, Rows[I].TextLength),
              GuiRect(Rect.Left + 8, Rect.Top + 6 + I * LineHeight, Max(0, Rect.Width - 16), LineHeight), Control.Style.TextColor);
          end;
        finally
          ACanvas.PopClipRect;
        end;
      finally
        ACanvas.FontName:=PreviousFont;
      end;
    end;
  end;
end;

procedure TGuiContext.SetHoveredControl(AControl: TGuiControl; const APosition: TGuiPoint);
var
  Event: TGuiEvent;
begin
  FMousePosition:=APosition;
  if FHoveredControl = AControl then
    Exit;
  FHoverSince:=TThread.GetTickCount64;

  Event.Kind:=gekMouseLeave;
  Event.Position:=APosition;
  Event.Handled:=False;

  if Assigned(FHoveredControl) then
    FHoveredControl.HandleEvent(Event);

  FHoveredControl:=AControl;

  Event.Kind:=gekMouseEnter;
  Event.Handled:=False;

  if Assigned(FHoveredControl) then
    FHoveredControl.HandleEvent(Event);
end;

procedure TGuiContext.SetFocusedControl(AControl: TGuiControl);
var
  Event: TGuiEvent;
  OldControl: TGuiControl;
begin
  if FFocusedControl = AControl then
    Exit;

  OldControl:=FFocusedControl;
  Event.Kind:=gekBlur;
  Event.Position:=GuiPoint(0, 0);
  Event.Handled:=False;

  if Assigned(FFocusedControl) then
  begin
    FFocusedControl.Focused:=False;
    FFocusedControl.FocusVisible:=False;
    FFocusedControl.HandleEvent(Event);
  end;

  FFocusedControl:=AControl;
  Inc(FFocusRevision);
  if Assigned(AControl) then
  begin
    FFocusHistory.Remove(AControl);
    FFocusHistory.Add(AControl);
  end;

  Event.Kind:=gekFocus;
  Event.Handled:=False;

  if Assigned(FFocusedControl) then
  begin
    FFocusedControl.Focused:=True;
    FFocusedControl.FocusVisible:=FShowFocus AND FKeyboardFocus AND FFocusedControl.ShowFocus;
    FFocusedControl.HandleEvent(Event);
  end;

  if Assigned(FOnFocusChanged) then
    FOnFocusChanged(Self, OldControl, FFocusedControl);
end;

procedure TGuiContext.SetShowFocus(AValue: Boolean);
begin
  FShowFocus:=AValue;

  if Assigned(FFocusedControl) then
    FFocusedControl.FocusVisible:=FShowFocus AND FKeyboardFocus AND FFocusedControl.ShowFocus;
end;

procedure TGuiContext.SetKeyboardFocus(AValue: Boolean);
begin
  FKeyboardFocus:=AValue;
  if Assigned(FFocusedControl) then
    FFocusedControl.FocusVisible:=FShowFocus AND FKeyboardFocus AND FFocusedControl.ShowFocus;
end;

function TGuiContext.FindFirstFocusable(AControl: TGuiControl; AReverse: Boolean): TGuiControl;
var
  I: Integer;
begin
  Result:=nil;

  if NOT Assigned(AControl) then
    Exit;

  if AReverse then
  begin
    for I:=AControl.ChildCount - 1 downto 0 do
    begin
      Result:=FindFirstFocusable(AControl.Children[I], AReverse);
      if Assigned(Result) then
        Exit;
    end;
  end;

  if CanFocusControl(AControl) then
  begin
    Result:=AControl;
    Exit;
  end;

  if NOT AReverse then
  begin
    for I:=0 to AControl.ChildCount - 1 do
    begin
      Result:=FindFirstFocusable(AControl.Children[I], AReverse);
      if Assigned(Result) then
        Exit;
    end;
  end;
end;

function TGuiContext.FindFocusableAfter(AControl, AFrom: TGuiControl; AReverse: Boolean; var AFoundFrom: Boolean): TGuiControl;
var
  I: Integer;
begin
  Result:=nil;

  if NOT Assigned(AControl) then
    Exit;

  if AReverse then
  begin
    for I:=AControl.ChildCount - 1 downto 0 do
    begin
      Result:=FindFocusableAfter(AControl.Children[I], AFrom, AReverse, AFoundFrom);
      if Assigned(Result) then
        Exit;
    end;
  end;

  if AControl = AFrom then
  begin
    AFoundFrom:=True;
    Exit;
  end;

  if AFoundFrom AND CanFocusControl(AControl) then
  begin
    Result:=AControl;
    Exit;
  end;

  if NOT AReverse then
  begin
    for I:=0 to AControl.ChildCount - 1 do
    begin
      Result:=FindFocusableAfter(AControl.Children[I], AFrom, AReverse, AFoundFrom);
      if Assigned(Result) then
        Exit;
    end;
  end;
end;

function TGuiContext.NextFocusableControl(AFrom: TGuiControl; AReverse: Boolean): TGuiControl;
var
  FoundFrom: Boolean;
  FocusRoot: TGuiControl;
begin
  FocusRoot:=ActiveFocusRoot;

  if NOT Assigned(AFrom) then
  begin
    Result:=FindFirstFocusable(FocusRoot, AReverse);
    Exit;
  end;

  FoundFrom:=False;
  Result:=FindFocusableAfter(FocusRoot, AFrom, AReverse, FoundFrom);

  if NOT Assigned(Result) then
    Result:=FindFirstFocusable(FocusRoot, AReverse);
end;

function TGuiContext.SetFocus(AControl: TGuiControl): Boolean;
begin
  Result:=CanFocusControl(AControl);

  if Result then
    SetFocusedControl(AControl);
end;

function TGuiContext.FocusFirst: Boolean;
begin
  Result:=SetFocus(FindFirstFocusable(ActiveFocusRoot, False));
end;

function TGuiContext.FocusNext: Boolean;
begin
  Result:=SetFocus(NextFocusableControl(FFocusedControl, False));
end;

function TGuiContext.FocusPrevious: Boolean;
begin
  Result:=SetFocus(NextFocusableControl(FFocusedControl, True));
end;

procedure TGuiContext.ClearFocus;
begin
  SetFocusedControl(nil);
end;

procedure TGuiContext.CancelInput;
var
  Event: TGuiEvent;
begin
  Event:=Default(TGuiEvent);
  Event.Kind:=gekCancel;
  if Assigned(FCapturedControl) then FCapturedControl.HandleEvent(Event);
  FCapturedControl:=nil;
  FPressedControl:=nil;
  FGamepadAxisXState:=0;
  FGamepadAxisYState:=0;
  SetHoveredControl(nil, GuiPoint(0, 0));
  ClearFocus;
end;

procedure TGuiContext.ActivateFocusedControl(var AEvent: TGuiEvent);
begin
  if Assigned(FFocusedControl) then
  begin
    FFocusedControl.PerformClick;
    AEvent.Handled:=True;
  end;
end;

procedure TGuiContext.MoveFocus(AReverse: Boolean; var AEvent: TGuiEvent);
var
  NextControl: TGuiControl;
begin
  if Assigned(FFocusedControl) AND FFocusedControl.HandleFocusNavigation(AReverse) then
  begin
    AEvent.Handled:=True;
    Exit;
  end;
  NextControl:=NextFocusableControl(FFocusedControl, AReverse);
  if Assigned(NextControl) then
    NextControl.PrepareFocusNavigation(AReverse);
  SetFocusedControl(NextControl);
  AEvent.Handled:=True;
end;

function TGuiContext.GamepadAxisState(AValue: TGuiFloat): Integer;
begin
  Result:=0;

  if AValue < -16000 then
    Result:=-1
  else
  if AValue > 16000 then
    Result:=1;
end;

function TGuiContext.CanFocusControl(AControl: TGuiControl): Boolean;
var
  Ancestor: TGuiControl;
begin
  Result:=False;
  if NOT Assigned(AControl) then
    Exit;
  if (NOT AControl.HasContext(Self)) OR (NOT AControl.CanFocus) OR (NOT AControl.TabStop) then
    Exit;
  if Assigned(ModalControl) AND (NOT ControlContains(ModalControl, AControl)) then
    Exit;
  Ancestor:=AControl;
  while Assigned(Ancestor) do
  begin
    if (NOT Ancestor.Visible) OR (NOT Ancestor.Enabled) then
      Exit;
    Ancestor:=Ancestor.Parent;
  end;
  Result:=True;
end;

function TGuiContext.ActiveFocusRoot: TGuiControl;
var Ancestor: TGuiControl;
begin
  Result:=ModalControl;
  if NOT Assigned(Result) then
  begin
    Ancestor:=FFocusedControl;
    while Assigned(Ancestor) do
    begin
      if Ancestor.DefinesFocusScope then
      begin
        Result:=Ancestor;
        Exit;
      end;
      Ancestor:=Ancestor.Parent;
    end;
  end;
  if NOT Assigned(Result) then
    Result:=FRoot;
end;

function TGuiContext.ControlContains(AParent, AControl: TGuiControl): Boolean;
var
  I: Integer;
begin
  Result:=False;

  if (NOT Assigned(AParent)) OR (NOT Assigned(AControl)) then
    Exit;

  if AParent = AControl then
  begin
    Result:=True;
    Exit;
  end;

  for I:=0 to AParent.ChildCount - 1 do
  begin
    Result:=ControlContains(AParent.Children[I], AControl);
    if Result then
      Exit;
  end;
end;

function TGuiContext.GetLayer(AKind: TGuiLayerKind): TGuiControl;
begin
  Result:=FLayers[AKind];
end;

function TGuiContext.GetModalControl: TGuiControl;
begin
  Result:=nil;
  if FModalStack.Count > 0 then
    Result:=TGuiControl(FModalStack[FModalStack.Count - 1]);
end;

function TGuiContext.HitTest(const APoint: TGuiPoint): TGuiControl;
var
  LayerKind: TGuiLayerKind;
  Modal: TGuiControl;
begin
  Modal:=ModalControl;
  if Assigned(Modal) then
  begin
    Result:=Modal.HitTestOverlay(APoint);
    if NOT Assigned(Result) then
      Result:=Modal.HitTest(APoint);

    if NOT Assigned(Result) then
      Result:=Modal;

    Exit;
  end;

  for LayerKind:=High(TGuiLayerKind) downto Low(TGuiLayerKind) do
  begin
    Result:=FLayers[LayerKind].HitTestOverlay(APoint);
    if Assigned(Result) then
      Exit;

    Result:=FLayers[LayerKind].HitTest(APoint);
    if Assigned(Result) then
      Exit;
  end;

  Result:=nil;
end;

procedure TGuiContext.ShowModal(AControl: TGuiControl);
begin
  if NOT Assigned(AControl) then
    Exit;

  if FModalStack.IndexOf(AControl) >= 0 then
    Exit;
  CancelInput;

  if Assigned(AControl.Parent) then
    AControl.Parent.Remove(AControl);

  FLayers[glkDialog].Add(AControl);
  AControl.Visible:=True;
  FModalStack.Add(AControl);
  ClearFocus;
end;

procedure TGuiContext.RestoreFocus;
var I: Integer;
Control: TGuiControl;
begin
  for I:=FFocusHistory.Count - 1 downto 0 do
  begin
    Control:=TGuiControl(FFocusHistory[I]);
    if CanFocusControl(Control) then
    begin
      SetFocusedControl(Control);
      Exit;
    end;
  end;
  ClearFocus;
end;

function TGuiContext.RestoreFocusWithin(ARoot, AExcept: TGuiControl): Boolean;
var
  I: Integer;
  Control: TGuiControl;
begin
  Result:=False;
  for I:=FFocusHistory.Count - 1 downto 0 do
  begin
    Control:=TGuiControl(FFocusHistory[I]);
    if (Control <> AExcept) AND ControlContains(ARoot, Control) AND
      CanFocusControl(Control) then
    begin
      SetFocusedControl(Control);
      Result:=True;
      Exit;
    end;
  end;
end;

procedure TGuiContext.ClosePopups(AExcept: TGuiControl);
var
  Layer: TGuiLayerKind;
begin
  for Layer:=Low(TGuiLayerKind) to High(TGuiLayerKind) do
    FLayers[Layer].ClosePopups(AExcept);
end;

procedure TGuiContext.CloseModal(AControl: TGuiControl);
var
  Index: Integer;
  Control: TGuiControl;
begin
  if FModalStack.Count <= 0 then
    Exit;

  if Assigned(AControl) then
    Index:=FModalStack.IndexOf(AControl)
  else
    Index:=FModalStack.Count - 1;

  if Index < 0 then
    Exit;

  Control:=TGuiControl(FModalStack[Index]);
  FModalStack.Delete(Index);

  if ControlContains(Control, FFocusedControl) then
    ClearFocus;

  Control.Visible:=False;
  if NOT Assigned(FFocusedControl) then RestoreFocus;
end;

procedure TGuiContext.ProcessEvent(var AEvent: TGuiEvent);
var
  Target: TGuiControl;
  WindowControl: TGuiControl;
  BubbleTarget: TGuiControl;
  AxisState: Integer;
  Modal: TGuiControl;
  MenuOwner: TGuiControl;
  Layer: TGuiLayerKind;
  function DispatchAvailableMenuKey: Boolean;
  var Kind: TGuiLayerKind;
  begin
    if Assigned(ModalControl) then
    begin
      Result:=DispatchMenuKey(ModalControl, AEvent);
      Exit;
    end;
    Result:=DispatchMenuKey(ActiveFocusRoot, AEvent);
    if Result then Exit;
    for Kind:=High(TGuiLayerKind) downto Low(TGuiLayerKind) do
      if DispatchMenuKey(FLayers[Kind], AEvent) then
      begin
        Result:=True;
        Exit;
      end;
  end;
begin
  UpdateLayout;
  if AEvent.Kind = gekMouseDown then SetKeyboardFocus(False)
  else if (AEvent.Kind IN [gekKeyDown, gekGamepadButtonDown]) OR
    ((AEvent.Kind = gekGamepadAxis) AND (Abs(AEvent.Delta.X) >= 0.5)) then
    SetKeyboardFocus(True);
  if Assigned(FFocusedControl) AND (NOT CanFocusControl(FFocusedControl)) then
    ClearFocus;
  case AEvent.Kind of
    gekMouseMove:
    begin
      Target:=HitTest(AEvent.Position);
      SetHoveredControl(Target, AEvent.Position);

      if Assigned(FCapturedControl) then
        Target:=FCapturedControl;
    end;

    gekMouseDown:
    begin
      Target:=HitTest(AEvent.Position);
      WindowControl:=Target;
      while Assigned(WindowControl) do
      begin
        if WindowControl.ActivateWindow then
          Break;
        WindowControl:=WindowControl.Parent;
      end;
      if AEvent.Button = gmbRight then
      begin
        MenuOwner:=Target;
        while Assigned(MenuOwner) AND NOT Assigned(MenuOwner.PopupMenu) do MenuOwner:=MenuOwner.Parent;
        if Assigned(MenuOwner) AND MenuOwner.PopupMenu.HasContext(Self) then
        begin
          MenuOwner.PopupMenu.PopupAt(AEvent.Position);
          if MenuOwner.PopupMenu.PopupOpen then
          begin
            AEvent.Handled:=True;
            Exit;
          end;
        end;
      end;
      Modal:=ModalControl;
      if Assigned(Modal) then
        Modal.ClosePopups(Target)
      else
      begin
        for Layer:=Low(TGuiLayerKind) to High(TGuiLayerKind) do FLayers[Layer].ClosePopups(Target);
      end;

      SetHoveredControl(Target, AEvent.Position);
      if CanFocusControl(Target) AND NOT Target.KeepCurrentFocusOnPointerDown then
        SetFocusedControl(Target);
      if Assigned(FFocusedControl) AND NOT CanFocusControl(FFocusedControl) then RestoreFocus;
      FCapturedControl:=Target;
      FPressedControl:=Target;
    end;

    gekMouseUp:
    begin
      if Assigned(FCapturedControl) then
      begin
        Target:=FCapturedControl;
        if (AEvent.Button = gmbLeft) AND GuiRectContains(Target.AbsoluteBounds, AEvent.Position) then
        begin
          Target.BeforePointerRelease(AEvent);
          if FCapturedControl <> Target then
            Target:=nil;
        end;
      end
      else
        Target:=HitTest(AEvent.Position);
    end;

    gekMouseWheel:
    begin
      Target:=HitTest(AEvent.Position);
      SetHoveredControl(Target, AEvent.Position);
    end;

    gekKeyDown,
    gekKeyUp,
    gekTextEditing,
    gekTextInput: Target:=FFocusedControl;

    gekGamepadButtonDown,
    gekGamepadButtonUp,
    gekGamepadAxis: Target:=FFocusedControl;

    else Target:=FHoveredControl;
  end;

  if AEvent.Kind = gekKeyDown then
  begin
    if (AEvent.Modifiers = [gemAlt]) OR (AEvent.KeyCode = $40000043) then
      if DispatchAvailableMenuKey then Exit;
    case AEvent.KeyCode of
      9:
      begin
        MoveFocus(gemShift IN AEvent.Modifiers, AEvent);
      end;

    end;

    if (NOT AEvent.Handled) AND Assigned(Target) then
      Target.HandleEvent(AEvent);

    if NOT AEvent.Handled then
      if DispatchAvailableMenuKey then Exit;

    if NOT AEvent.Handled then
    begin
      case AEvent.KeyCode of
        13, 32:
        begin
          ActivateFocusedControl(AEvent);
        end;
      end;
    end;
  end else
  if AEvent.Kind IN [gekTextInput, gekTextEditing] then
  begin
    if Assigned(Target) then
      Target.HandleEvent(AEvent);
  end else
  if AEvent.Kind = gekGamepadButtonDown then
  begin
    if Assigned(Target) then
    begin
      Target.BeforeFocusedActivation(AEvent);
      if AEvent.Handled then
        Exit;
    end;
    case AEvent.KeyCode of
      0: ActivateFocusedControl(AEvent);
      11, 13: MoveFocus(True, AEvent);
      12, 14: MoveFocus(False, AEvent);
    end;

    if (NOT AEvent.Handled) AND Assigned(Target) then
      Target.HandleEvent(AEvent);
  end else
  if AEvent.Kind = gekGamepadAxis then
  begin
    case AEvent.KeyCode of
      0:
      begin
        AxisState:=GamepadAxisState(AEvent.Delta.X);
        if (AxisState <> 0) AND (AxisState <> FGamepadAxisXState) then
          MoveFocus(AxisState < 0, AEvent)
        else
          AEvent.Handled:=True;

        FGamepadAxisXState:=AxisState;
      end;

      1:
      begin
        AxisState:=GamepadAxisState(AEvent.Delta.Y);
        if (AxisState <> 0) AND (AxisState <> FGamepadAxisYState) then
          MoveFocus(AxisState < 0, AEvent)
        else
          AEvent.Handled:=True;

        FGamepadAxisYState:=AxisState;
      end;
    end;

    if (NOT AEvent.Handled) AND Assigned(Target) then
      Target.HandleEvent(AEvent);
  end else
  if AEvent.Kind = gekMouseWheel then
  begin
    BubbleTarget:=Target;
    while Assigned(BubbleTarget) AND (NOT AEvent.Handled) do
    begin
      BubbleTarget.HandleEvent(AEvent);
      BubbleTarget:=BubbleTarget.Parent;
    end;
  end else
  if Assigned(Target) then
    Target.HandleEvent(AEvent);

  if AEvent.Kind = gekMouseUp then
  begin
    if Assigned(FPressedControl) AND (FPressedControl = HitTest(AEvent.Position)) AND (AEvent.Button = gmbLeft) then
      if NOT FPressedControl.SuppressReleaseClick then
        FPressedControl.PerformClick;

    FCapturedControl:=nil;
    FPressedControl:=nil;
  end;
end;

end.
