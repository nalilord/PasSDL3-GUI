program FoundationBoundaryTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Controls.Base;

type
  TTestContext = class(TGuiContextServices)
  private
    FRootControl: TGuiControl;
    FFocusedControl: TGuiControl;
    FDetachCount: Integer;
    FMousePosition: TGuiPoint;
  protected
    function GetRoot: TGuiControl;
    override;
    function GetModalControl: TGuiControl;
    override;
    function GetHoveredControl: TGuiControl;
    override;
    function GetFocusedControl: TGuiControl;
    override;
    function GetPressedControl: TGuiControl;
    override;
    function GetMousePosition: TGuiPoint;
    override;
  public
    procedure DetachControl(AControl: TGuiControl);
    override;
    function SetFocus(AControl: TGuiControl): Boolean;
    override;
    procedure RestoreFocus;
    override;
    function RestoreFocusWithin(ARoot, AExcept: TGuiControl): Boolean;
    override;
    procedure CloseModal(AControl: TGuiControl);
    override;
    procedure CancelInput;
    override;
    function ControlContains(AParent, AControl: TGuiControl): Boolean;
    override;
    procedure ClosePopups(AExcept: TGuiControl);
    override;
    property RootControl: TGuiControl read FRootControl write FRootControl;
    property DetachCount: Integer read FDetachCount;
  end;

  TShortcutControl = class(TGuiControl)
  private
    FDispatchCount: Integer;
  public
    property DispatchCount: Integer read FDispatchCount write FDispatchCount;
    function DispatchShortcut(var AEvent: TGuiEvent): Boolean;
    override;
  end;

  TTestPopup = class(TGuiPopupControl)
  private
    FOpen: Boolean;
  public
    procedure PopupAt(const APoint: TGuiPoint);
    override;
    function PopupOpen: Boolean;
    override;
  end;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then
  begin
    WriteLn('FAIL: ', AMessage);
    Halt(1);
  end;
end;

function TTestContext.GetRoot: TGuiControl;
begin
  Result:=FRootControl;
end;

function TTestContext.GetModalControl: TGuiControl;
begin
  Result:=nil;
end;

function TTestContext.GetHoveredControl: TGuiControl;
begin
  Result:=nil;
end;

function TTestContext.GetFocusedControl: TGuiControl;
begin
  Result:=FFocusedControl;
end;

function TTestContext.GetPressedControl: TGuiControl;
begin
  Result:=nil;
end;

function TTestContext.GetMousePosition: TGuiPoint;
begin
  Result:=FMousePosition;
end;

procedure TTestContext.DetachControl(AControl: TGuiControl);
begin
  Inc(FDetachCount);
  if FFocusedControl = AControl then
    FFocusedControl:=nil;
end;

function TTestContext.SetFocus(AControl: TGuiControl): Boolean;
begin
  FFocusedControl:=AControl;
  Result:=Assigned(AControl);
end;

procedure TTestContext.RestoreFocus;
begin
end;

function TTestContext.RestoreFocusWithin(ARoot, AExcept: TGuiControl): Boolean;
begin
  Result:=False;
end;

procedure TTestContext.CloseModal(AControl: TGuiControl);
begin
end;

procedure TTestContext.CancelInput;
begin
end;

function TTestContext.ControlContains(AParent, AControl: TGuiControl): Boolean;
var
  I: Integer;
begin
  Result:=AParent = AControl;
  if Result OR NOT Assigned(AParent) then
    Exit;
  for I:=0 to AParent.ChildCount - 1 do
  begin
    Result:=ControlContains(AParent.Children[I], AControl);
    if Result then
      Exit;
  end;
end;

procedure TTestContext.ClosePopups(AExcept: TGuiControl);
begin
  if Assigned(FRootControl) then
    FRootControl.ClosePopups(AExcept);
end;

function TShortcutControl.DispatchShortcut(var AEvent: TGuiEvent): Boolean;
begin
  Inc(FDispatchCount);
  AEvent.Handled:=True;
  Result:=True;
end;

procedure TTestPopup.PopupAt(const APoint: TGuiPoint);
begin
  FOpen:=True;
end;

function TTestPopup.PopupOpen: Boolean;
begin
  Result:=FOpen;
end;

var
  Context: TTestContext;
  Root: TGuiControl;
  First: TGuiControl;
  Shortcut: TShortcutControl;
  Popup: TTestPopup;
  Event: TGuiEvent;

begin
  Context:=TTestContext.Create;
  Root:=TGuiControl.Create;
  Popup:=TTestPopup.Create;
  try
    Context.RootControl:=Root;
    Root.AttachContext(Context);
    First:=TGuiControl.Create;
    Shortcut:=TShortcutControl.Create;
    Root.Add(First);
    Root.Add(Shortcut);
    Check(First.HasContext(Context), 'context propagates to added children');
    Check(Root.IndexOfChild(First) = 0, 'initial child order is stable');
    First.BringToFront;
    Check(Root.IndexOfChild(First) = 1, 'BringToFront uses the base ordering boundary');

    FillChar(Event, SizeOf(Event), 0);
    Check(Root.DispatchShortcut(Event), 'shortcut dispatch traverses descendants');
    Check((Shortcut.DispatchCount = 1) AND Event.Handled,
      'shortcut dispatch stops after a handled descendant');

    Root.PopupMenu:=Popup;
    Popup.PopupAt(GuiPoint(10, 20));
    Check(Root.PopupMenu.PopupOpen, 'popup contract preserves assignment and dispatch');

    Root.Remove(First);
    Check(NOT First.HasContext(Context), 'removal clears the context contract');
    Check(Context.DetachCount = 1, 'removal notifies the context exactly once');
    First.Free;
  finally
    Root.Free;
    Popup.Free;
    Context.Free;
  end;
  WriteLn('PASS: foundation context, ordering, shortcut, and popup boundaries');
end.
