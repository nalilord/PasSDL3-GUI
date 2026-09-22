unit PasSDL3.GUI.Host.SDL3;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SDL3,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls.Text,
  PasSDL3.GUI.Controls.Lists,
  PasSDL3.GUI.Input.SDL3,
  PasSDL3.GUI.Renderer.SDL3,
  PasSDL3.GUI.Fonts.SDLTTF;

type
  TGuiSDL3Host = class
  private
    FContext: TGuiContext;
    FCanvas: TGuiSDL3Canvas;
    FOwnsContext: Boolean;
    FWindow: PSDL_Window;
    FGamepads: array of PSDL_Gamepad;
    FManageTextInput: Boolean;
    { Identity only; never dereferenced after a control may have been destroyed. }
    FTextInputControl: TGuiControl;
    FTextInputFocusRevision: UInt64;
    FCompositionCancellationRevision: UInt64;
    FManageMouseCursor: Boolean;
    FCursors: array[TGuiMouseCursor] of PSDL_Cursor;
    FCursorTried: array[TGuiMouseCursor] of Boolean;
    procedure SyncMouseCursor;
    procedure SyncTextInput;
    procedure OpenGamepad(AID: TSDL_JoystickID);
    procedure CloseGamepad(AID: TSDL_JoystickID);
    procedure SyncSize;
    function GetFontRenderer: TGuiSDLTTFFontRenderer;
    procedure SetFontRenderer(AValue: TGuiSDLTTFFontRenderer);
  public
    constructor Create(ARenderer: PSDL_Renderer; AContext: TGuiContext = nil);
    destructor Destroy; override;
    function ProcessEvent(const ASdlEvent: TSDL_Event): Boolean;
    procedure Resize(AWidth, AHeight: TGuiFloat);
    procedure Render;
    property Context: TGuiContext read FContext;
    property Canvas: TGuiSDL3Canvas read FCanvas;
    property FontRenderer: TGuiSDLTTFFontRenderer read GetFontRenderer write SetFontRenderer;
    property ManageTextInput: Boolean read FManageTextInput write FManageTextInput;
    property ManageMouseCursor: Boolean read FManageMouseCursor write FManageMouseCursor;
  end;

implementation

uses Math;

function TGuiSDL3Host.GetFontRenderer: TGuiSDLTTFFontRenderer;
begin
  Result:=FCanvas.FontRenderer;
end;

procedure TGuiSDL3Host.SetFontRenderer(AValue: TGuiSDLTTFFontRenderer);
begin
  FCanvas.FontRenderer:=AValue;
end;

constructor TGuiSDL3Host.Create(ARenderer: PSDL_Renderer; AContext: TGuiContext);
var
  IDs, ID: PSDL_JoystickID;
  Count, I: Integer;
begin
  inherited Create;

  FOwnsContext:=NOT Assigned(AContext);
  if Assigned(AContext) then
    FContext:=AContext
  else
    FContext:=TGuiContext.Create;

  FCanvas:=TGuiSDL3Canvas.Create(ARenderer);
  FWindow:=SDL_GetRenderWindow(ARenderer);
  FManageTextInput:=True;
  FManageMouseCursor:=True;
  SyncSize;
  IDs:=SDL_GetGamepads(@Count);
  try
    ID:=IDs;
    for I:=0 to Count - 1 do
    begin
      OpenGamepad(ID^);
      Inc(ID);
    end;
  finally
    SDL_free(IDs);
  end;
end;

procedure TGuiSDL3Host.SyncMouseCursor;
const
  IDs: array[TGuiMouseCursor] of TSDL_SystemCursor = (
    SDL_SYSTEM_CURSOR_DEFAULT, SDL_SYSTEM_CURSOR_DEFAULT, SDL_SYSTEM_CURSOR_TEXT,
    SDL_SYSTEM_CURSOR_POINTER, SDL_SYSTEM_CURSOR_MOVE, SDL_SYSTEM_CURSOR_EW_RESIZE,
    SDL_SYSTEM_CURSOR_NS_RESIZE, SDL_SYSTEM_CURSOR_NWSE_RESIZE, SDL_SYSTEM_CURSOR_NESW_RESIZE);
var Kind: TGuiMouseCursor;
Desired: PSDL_Cursor;
begin
  if NOT FManageMouseCursor OR NOT Assigned(FWindow) OR (SDL_GetMouseFocus <> FWindow) then Exit;
  Kind:=FContext.MouseCursor;
  if NOT FCursorTried[Kind] then
  begin
    FCursorTried[Kind]:=True;
    FCursors[Kind]:=SDL_CreateSystemCursor(IDs[Kind]);
  end;
  Desired:=FCursors[Kind];
  if NOT Assigned(Desired) then Desired:=SDL_GetDefaultCursor;
  if Assigned(Desired) AND (SDL_GetCursor <> Desired) then SDL_SetCursor(Desired);
end;

procedure TGuiSDL3Host.SyncTextInput;
var
  Control,Ancestor: TGuiControl;
  Bounds: TGuiRect;
  Rect: TSDL_Rect;
  X, Y, RightValue, BottomValue: Single;
begin
  if (NOT FManageTextInput) OR (NOT Assigned(FWindow)) then Exit;
  Control:=FContext.FocusedControl;
  Ancestor:=Control;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      Control:=nil;
      Break;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if (Control IS TGuiEdit) AND TGuiEdit(Control).ReadOnly then
    if NOT ((Control IS TGuiComboBox) AND TGuiComboBox(Control).TypeAhead) then Control:=nil;
  if NOT (Control IS TGuiEdit) then Control:=nil;
  if (Control<>FTextInputControl) OR (FTextInputFocusRevision<>FContext.FocusRevision) then
  begin
    if SDL_TextInputActive(FWindow) then SDL_ClearComposition(FWindow);
    FTextInputControl:=Control;
    FTextInputFocusRevision:=FContext.FocusRevision;
    FCompositionCancellationRevision:=0;
    if Assigned(Control) then
      FCompositionCancellationRevision:=TGuiEdit(Control).CompositionCancellationRevision;
  end;
  if Assigned(Control) AND
    (FCompositionCancellationRevision<>TGuiEdit(Control).CompositionCancellationRevision) then
  begin
    if SDL_TextInputActive(FWindow) then SDL_ClearComposition(FWindow);
    FCompositionCancellationRevision:=TGuiEdit(Control).CompositionCancellationRevision;
  end;
  if Control IS TGuiEdit then
  begin
    if NOT SDL_TextInputActive(FWindow) then SDL_StartTextInput(FWindow);
    Bounds:=TGuiEdit(Control).TextInputRect(FCanvas);
    SDL_RenderCoordinatesToWindow(FCanvas.Renderer, Bounds.Left, Bounds.Top, @X, @Y);
    SDL_RenderCoordinatesToWindow(FCanvas.Renderer, Bounds.Left + Bounds.Width, Bounds.Top + Bounds.Height, @RightValue, @BottomValue);
    Rect.x:=Floor(X);
    Rect.y:=Floor(Y);
    Rect.w:=Max(1,Ceil(RightValue)-Rect.x);
    Rect.h:=Max(1,Ceil(BottomValue)-Rect.y);
    SDL_SetTextInputArea(FWindow, @Rect, 0);
  end else
  if SDL_TextInputActive(FWindow) then
    SDL_StopTextInput(FWindow);
end;

destructor TGuiSDL3Host.Destroy;
var
  I: Integer;
  Kind: TGuiMouseCursor;
begin
  for Kind:=Low(TGuiMouseCursor) to High(TGuiMouseCursor) do
    if Assigned(FCursors[Kind]) then
    begin
      if SDL_GetCursor = FCursors[Kind] then SDL_SetCursor(SDL_GetDefaultCursor);
      SDL_DestroyCursor(FCursors[Kind]);
    end;
  for I:=0 to Length(FGamepads) - 1 do
    SDL_CloseGamepad(FGamepads[I]);
  FCanvas.Free;

  if FOwnsContext then
    FContext.Free;

  inherited Destroy;
end;

procedure TGuiSDL3Host.OpenGamepad(AID: TSDL_JoystickID);
var
  I: Integer;
  Gamepad: PSDL_Gamepad;
begin
  for I:=0 to Length(FGamepads) - 1 do
    if SDL_GetGamepadID(FGamepads[I]) = AID then Exit;
  Gamepad:=SDL_OpenGamepad(AID);
  if Assigned(Gamepad) then
  begin
    SetLength(FGamepads, Length(FGamepads) + 1);
    FGamepads[High(FGamepads)]:=Gamepad;
  end;
end;

procedure TGuiSDL3Host.CloseGamepad(AID: TSDL_JoystickID);
var
  I: Integer;
begin
  for I:=0 to Length(FGamepads) - 1 do
    if SDL_GetGamepadID(FGamepads[I]) = AID then
    begin
      SDL_CloseGamepad(FGamepads[I]);
      FGamepads[I]:=FGamepads[High(FGamepads)];
      SetLength(FGamepads, Length(FGamepads) - 1);
      Exit;
    end;
end;

procedure TGuiSDL3Host.SyncSize;
var
  Viewport: TSDL_Rect;
begin
  // SDL already expresses this viewport in scaled, logical rendering coordinates.
  if SDL_GetRenderViewport(FCanvas.Renderer, @Viewport) then
    FContext.Resize(Viewport.w, Viewport.h);
end;

function TGuiSDL3Host.ProcessEvent(const ASdlEvent: TSDL_Event): Boolean;
var
  Event: TGuiEvent;
  Converted: TSDL_Event;
  InputControl: TGuiControl;
begin
  Result:=False;
  case ASdlEvent.type_ of
    SDL_EVENT_GAMEPAD_ADDED: OpenGamepad(ASdlEvent.gdevice.which);
    SDL_EVENT_GAMEPAD_REMOVED: CloseGamepad(ASdlEvent.gdevice.which);
    SDL_EVENT_WINDOW_FOCUS_LOST:
      if ASdlEvent.window.windowID = SDL_GetWindowID(FWindow) then FContext.CancelInput;
    SDL_EVENT_WINDOW_RESIZED, SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
      if ASdlEvent.window.windowID = SDL_GetWindowID(FWindow) then SyncSize;
  end;
  case ASdlEvent.type_ of
    SDL_EVENT_MOUSE_MOTION, SDL_EVENT_MOUSE_BUTTON_DOWN, SDL_EVENT_MOUSE_BUTTON_UP,
    SDL_EVENT_MOUSE_WHEEL, SDL_EVENT_KEY_DOWN, SDL_EVENT_KEY_UP, SDL_EVENT_TEXT_INPUT, SDL_EVENT_TEXT_EDITING:
      if Assigned(FWindow) AND (ASdlEvent.window.windowID <> SDL_GetWindowID(FWindow)) then Exit;
  end;
  Converted:=ASdlEvent;
  if NOT SDL_ConvertEventToRenderCoordinates(FCanvas.Renderer, @Converted) then Exit;
  if GuiEventFromSDL3(Converted, Event) then
  begin
    InputControl:=FContext.FocusedControl;
    if InputControl IS TGuiEdit then TGuiEdit(InputControl).PrepareTextLayout(FCanvas);
    if Event.Kind IN [gekMouseDown,gekMouseMove,gekMouseUp] then
    begin
      InputControl:=FContext.Root.HitTest(Event.Position);
      if InputControl IS TGuiEdit then TGuiEdit(InputControl).PrepareTextLayout(FCanvas);
    end;
    FContext.ProcessEvent(Event);
    Result:=Event.Handled;
  end;
  SyncTextInput;
  SyncMouseCursor;
end;

procedure TGuiSDL3Host.Resize(AWidth, AHeight: TGuiFloat);
begin
  FContext.Resize(AWidth, AHeight);
end;

procedure TGuiSDL3Host.Render;
begin
  SyncMouseCursor;
  FContext.Paint(FCanvas);
  SyncTextInput;
end;

end.
