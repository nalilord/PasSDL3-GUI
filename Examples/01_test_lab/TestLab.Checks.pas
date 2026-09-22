unit TestLab.Checks;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TLabCheck = procedure(ACondition: Boolean; const AMessage: String) of object;

procedure RunLabChecks(ACheck: TLabCheck);

implementation

uses
  SysUtils, Classes, PasSDL3.GUI.Types, PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Text, PasSDL3.GUI.Resources, PasSDL3.GUI.Theme, PasSDL3.GUI.Theme.Files;

procedure Key(AContext: TGuiContext; ACode: Integer; AModifiers: TGuiEventModifiers = []);
var E: TGuiEvent;
begin
  E:=Default(TGuiEvent);
  E.Kind:=gekKeyDown;
  E.KeyCode:=ACode;
  E.Modifiers:=AModifiers;
  AContext.ProcessEvent(E);
end;

procedure Input(AContext: TGuiContext; const AText: UTF8String);
var E: TGuiEvent;
begin
  E:=Default(TGuiEvent);
  E.Kind:=gekTextInput;
  E.Text:=AText;
  AContext.ProcessEvent(E);
end;

procedure Mouse(AContext: TGuiContext; AKind: TGuiEventKind; AX, AY: Single; AWheel: Single = 0);
var E: TGuiEvent;
begin
  E:=Default(TGuiEvent);
  E.Kind:=AKind;
  E.Position:=GuiPoint(AX, AY);
  E.Button:=gmbLeft;
  E.Delta:=GuiPoint(0, AWheel);
  AContext.ProcessEvent(E);
end;

procedure Ownership(ACheck: TLabCheck);
var C: TGuiContext;
P, Other: TGuiPanel;
B: TGuiButton;
I: Integer;
Rejected: Boolean;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(800, 600);
    P:=TGuiPanel.Create;
    P.Bounds:=GuiRect(10, 10, 300, 200);
    C.Root.Add(P);
    Other:=TGuiPanel.Create;
    Other.Bounds:=GuiRect(400, 10, 300, 200);
    C.Root.Add(Other);
    B:=TGuiButton.Create;
    B.Bounds:=GuiRect(0, 0, 100, 30);
    P.Add(B);
    ACheck(C.SetFocus(B), 'Focus attached enabled control');
    P.Visible:=False;
    ACheck(NOT C.SetFocus(B), 'Reject focus through hidden ancestor');
    P.Visible:=True;
    P.Enabled:=False;
    ACheck(NOT C.SetFocus(B), 'Reject focus through disabled ancestor');
    P.Enabled:=True;
    C.SetFocus(B);
    Other.Add(B);
    ACheck((P.ChildCount = 0) AND (Other.ChildCount = 1) AND (B.Parent = Other), 'Reparent transfers ownership');
    ACheck(C.FocusedControl = nil, 'Reparent clears old focus');
    C.SetFocus(B);
    B.Free;
    ACheck((Other.ChildCount = 0) AND (C.FocusedControl = nil), 'Free clears ownership and focus');
    Rejected:=False;
    try
      P.Add(C.Root);
    except
      on E: EArgumentException do Rejected:=True;
    end;
    ACheck(Rejected, 'Reject ancestor cycle');
    for I:=1 to 100 do P.Add(TGuiButton.Create);
    P.Clear;
    ACheck(P.ChildCount = 0, 'Clear releases all children');
    B:=TGuiButton.Create;
    B.Bounds:=GuiRect(0, 0, 100, 30);
    P.Add(B);
    Mouse(C, gekMouseDown, 20, 20);
    ACheck(C.CapturedControl = B, 'Mouse-down establishes capture');
    C.CancelInput;
    ACheck((C.CapturedControl = nil) AND (NOT B.Pressed), 'Cancel input releases press and capture');
  finally
    C.Free;
  end;
end;

procedure Layout(ACheck: TLabCheck);
var C: TGuiContext;
P: TGuiPanel;
B: TGuiButton;
S: TGuiStackPanel;
G: TGuiGridPanel;
I: Integer;
PanelBounds: TGuiRect;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(800, 600);
    P:=TGuiPanel.Create;
    P.Bounds:=GuiRect(50, 40, 200, 160);
    C.Root.Add(P);
    B:=TGuiButton.Create;
    B.Align:=gaClient;
    P.Add(B);
    C.UpdateLayout;
    ACheck((B.AbsoluteBounds.Left = 50) AND (B.AbsoluteBounds.Top = 40), 'Nested client alignment uses local origin');
    P.Padding:=GuiBox(10);
    C.UpdateLayout;
    ACheck((B.Bounds.Left = 10) AND (B.Bounds.Width = 180), 'Padding changes are detected');
    B.Align:=gaNone;
    B.Bounds:=GuiRect(10, 10, 100, 30);
    B.Anchors:=[ganLeft, ganTop, ganRight];
    C.UpdateLayout;
    PanelBounds:=P.Bounds;
    PanelBounds.Width:=300;
    P.Bounds:=PanelBounds;
    C.UpdateLayout;
    ACheck(B.Bounds.Width = 200, 'Right anchor stretches by parent size delta');
    S:=TGuiStackPanel.Create;
    S.Bounds:=GuiRect(0, 220, 300, 200);
    S.Spacing:=7;
    C.Root.Add(S);
    for I:=0 to 2 do
    begin
      B:=TGuiButton.Create;
      B.Bounds:=GuiRect(0, 0, 100, 30);
      S.Add(B);
    end;
    C.UpdateLayout;
    ACheck(S.Children[1].Bounds.Top >= S.Children[0].Bounds.Top + 37, 'Vertical stack includes spacing');
    G:=TGuiGridPanel.Create;
    G.Columns:=2;
    G.CellWidth:=100;
    G.CellHeight:=40;
    G.ColumnSpacing:=5;
    G.RowSpacing:=5;
    C.Root.Add(G);
    for I:=0 to 3 do G.Add(TGuiButton.Create);
    C.UpdateLayout;
    ACheck((G.Children[1].Bounds.Left > G.Children[0].Bounds.Left) AND (G.Children[2].Bounds.Top > G.Children[0].Bounds.Top), 'Grid wraps into another row');
  finally
    C.Free;
  end;
end;

procedure Editing(ACheck: TLabCheck);
var C: TGuiContext;
E: TGuiEdit;
M: TGuiMemo;
Emoji: UTF8String;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(800, 600);
    E:=TGuiEdit.Create;
    E.Bounds:=GuiRect(0, 0, 400, 40);
    C.Root.Add(E);
    C.SetFocus(E);
    Input(C, 'abc');
    ACheck(E.Text = 'abc', 'SDL-style text input inserts text');
    Key(C, 122, [gemCtrl]);
    ACheck(E.Text = '', 'Ctrl+Z undoes first insertion');
    Key(C, 121, [gemCtrl]);
    ACheck(E.Text = 'abc', 'Ctrl+Y redoes insertion');
    E.SetSelection(1, 3);
    Input(C, 'X');
    ACheck(E.Text = 'aX', 'Typing replaces selected text');
    E.Undo;
    ACheck(E.Text = 'abc', 'Undo selection replacement atomically');
    E.ReadOnly:=True;
    Input(C, 'changed');
    Key(C, 8);
    ACheck(E.Text = 'abc', 'Read-only ignores edits');
    E.ReadOnly:=False;
    E.Text:='';
    Emoji:=UTF8Encode(UnicodeString(#$D83D#$DE00));
    Input(C, Emoji);
    Key(C, 8);
    ACheck(E.Text = '', 'Backspace removes full supplementary Unicode character');
    E.Text:='';
    E.MaxLength:=4;
    Input(C, '123456789');
    ACheck(E.Text = '1234', 'Maximum length clamps insertion');
    E.MaxLength:=0;
    E.Text:='';
    Input(C, 'a' + #13#10 + 'b');
    ACheck(E.Text = 'ab', 'Single-line editor strips newlines');
    M:=TGuiMemo.Create;
    M.Bounds:=GuiRect(0, 80, 400, 200);
    C.Root.Add(M);
    C.SetFocus(M);
    Input(C, 'one');
    Key(C, 13);
    Input(C, 'two');
    ACheck((M.Lines.Count = 2) AND (M.Text = 'one' + #10 + 'two'), 'Memo synchronizes lines and text');
    Key(C, $40000052);
    ACheck(M.CaretIndex = 3, 'Memo up preserves column');
    M.SelectAll;
    Input(C, 'replacement');
    M.Undo;
    ACheck(M.Lines.Count = 2, 'Memo undo restores multiple lines');
    M.Lines[0]:='external';
    ACheck(Pos('external', M.Text) = 1, 'External Lines mutation updates text');
  finally
    C.Free;
  end;
end;

procedure Selection(ACheck: TLabCheck);
var C: TGuiContext;
Box: TGuiCheckBox;
R1, R2: TGuiRadioButton;
Combo: TGuiComboBox;
    Pages: TGuiPageControl;
    Page: TGuiPage;
    I: Integer;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(800, 600);
    Box:=TGuiCheckBox.Create;
    C.Root.Add(Box);
    C.SetFocus(Box);
    Key(C, 32);
    ACheck(Box.Checked, 'Space toggles checkbox');
    Key(C, 13);
    ACheck(NOT Box.Checked, 'Enter toggles checkbox back');
    R1:=TGuiRadioButton.Create;
    R1.GroupName:='test';
    C.Root.Add(R1);
    R2:=TGuiRadioButton.Create;
    R2.GroupName:='test';
    C.Root.Add(R2);
    C.SetFocus(R1);
    Key(C, 32);
    C.SetFocus(R2);
    Key(C, 32);
    ACheck(R2.Checked AND (NOT R1.Checked), 'Radio group is exclusive');
    Combo:=TGuiComboBox.Create;
    Combo.Bounds:=GuiRect(10, 10, 200, 30);
    C.Root.Add(Combo);
    Combo.SelectedIndex:=99;
    ACheck(Combo.SelectedIndex = -1, 'Empty combo clamps selection');
    for I:=0 to 19 do Combo.AddItem(IntToStr(I));
    Combo.DroppedDown:=True;
    Mouse(C, gekMouseWheel, 20, 60, -14);
    Mouse(C, gekMouseDown, 20, 205);
    Mouse(C, gekMouseUp, 20, 205);
    ACheck(Combo.SelectedIndex = 19, 'Mouse selects last item beyond first six popup rows');
    Pages:=TGuiPageControl.Create;
    C.Root.Add(Pages);
    Page:=Pages.AddPage('first');
    Pages.AddPage('second');
    Pages.SelectedIndex:=1;
    ACheck((NOT Page.Visible) AND Pages.Pages[1].Visible, 'Page selection changes visibility');
    Page.Free;
    ACheck((Pages.PageCount = 1) AND (Pages.SelectedIndex = 0), 'Free page maintains selected index');
  finally
    C.Free;
  end;
end;

procedure RangesAndData(ACheck: TLabCheck);
var S: TGuiSlider;
Spin: TGuiSpinEdit;
P: TGuiProgressBar;
D: TGuiDialGauge;
Scope: TGuiScope;
    Tree: TGuiTreeView;
    Table: TGuiListView;
    Header: TGuiHeaderControl;
    Resources: TGuiResourceCatalog;
begin
  S:=TGuiSlider.Create;
  Spin:=TGuiSpinEdit.Create;
  P:=TGuiProgressBar.Create;
  D:=TGuiDialGauge.Create;
  Scope:=TGuiScope.Create;
  Tree:=TGuiTreeView.Create;
  Table:=TGuiListView.Create;
  Header:=TGuiHeaderControl.Create;
  Resources:=TGuiResourceCatalog.Create;
  try
    S.MinValue:=-10;
    S.MaxValue:=10;
    S.Value:=999;
    ACheck(S.Value = 10, 'Slider upper clamp');
    S.Value:=-999;
    ACheck(S.Value = -10, 'Slider lower clamp');
    Spin.MinValue:=-5;
    Spin.MaxValue:=5;
    Spin.Value:=9;
    ACheck(Spin.Value = 5, 'Spin edit clamps value');
    P.Value:=999;
    ACheck(P.Value = P.MaxValue, 'Progress clamps value');
    D.Value:=-999;
    ACheck(D.Value = D.MinValue, 'Dial clamps value');
    Scope.AddMarker(0, 0, GuiColor(255, 255, 255));
    Scope.AddMarker(1, 1, GuiColor(255, 0, 0));
    ACheck(Scope.MarkerCount = 2, 'Scope registers markers');
    Scope.ClearMarkers;
    ACheck(Scope.MarkerCount = 0, 'Scope clears markers');
    Tree.AddNode('root');
    Tree.AddNode('child', 1);
    ACheck(Tree.NodeCount = 2, 'Tree nodes registered');
    Tree.ClearNodes;
    ACheck(Tree.NodeCount = 0, 'Tree clear resets nodes');
    Table.AddColumn('A', 100);
    Table.AddColumn('B', 80);
    Table.AddRow(['one', 'two']);
    ACheck((Table.ColumnCount = 2) AND (Table.RowCount = 1), 'Table columns and rows');
    Table.ClearRows;
    ACheck(Table.RowCount = 0, 'Table clear resets rows');
    Header.AddColumn('A', 120);
    ACheck(Header.ColumnWidth[0] = 120, 'Header preserves column width');
    Resources.RegisterRegion('test', nil, GuiRect(0, 0, 20, 20));
    Resources.RegisterRegion('test', nil, GuiRect(0, 0, 40, 40));
    ACheck((Resources.RegionCount = 1) AND (Resources.FindRegion('test').SourceRect.Width = 40), 'Resource replacement does not duplicate names');
    ACheck(Resources.FindRegion('missing') = nil, 'Unknown resource returns nil');
    ACheck(GuiColorToHex(GuiColorFromHex('#12345678', GuiColor(0, 0, 0))) = '#12345678', 'Theme RGBA color roundtrip');
  finally
    Resources.Free;
    Header.Free;
    Table.Free;
    Tree.Free;
    Scope.Free;
    D.Free;
    P.Free;
    Spin.Free;
    S.Free;
  end;
end;

procedure ModalAndScroll(ACheck: TLabCheck);
var C: TGuiContext;
B: TGuiButton;
D1, D2: TGuiDialog;
Scroll: TGuiScrollBox;
begin
  C:=TGuiContext.Create;
  try
    C.Resize(800, 600);
    B:=TGuiButton.Create;
    C.Root.Add(B);
    D1:=TGuiDialog.Create;
    D1.AddButton('OK', True, gmrOk);
    C.ShowModal(D1);
    ACheck(NOT C.SetFocus(B), 'Modal rejects focus on background control');
    D2:=TGuiDialog.Create;
    C.ShowModal(D2);
    ACheck(C.ModalControl = D2, 'Nested modal is active');
    C.CloseModal;
    ACheck(C.ModalControl = D1, 'Closing nested modal restores prior modal');
    D1.ExecuteDefault;
    ACheck(D1.ModalResult = gmrOk, 'Dialog default button resolves OK');
    D1.Free;
    ACheck(C.ModalControl = nil, 'Free modal removes context stack reference');
    Scroll:=TGuiScrollBox.Create;
    Scroll.Bounds:=GuiRect(0, 0, 100, 100);
    C.Root.Add(Scroll);
    B:=TGuiButton.Create;
    B.Bounds:=GuiRect(0, 0, 300, 300);
    Scroll.Add(B);
    Scroll.ScrollX:=999;
    Scroll.ScrollY:=999;
    ACheck((Scroll.ScrollX = Scroll.MaxScrollX) AND (Scroll.ScrollY = Scroll.MaxScrollY), 'Both scroll offsets clamp to content');
  finally
    C.Free;
  end;
end;

procedure RunLabChecks(ACheck: TLabCheck);
begin
  try
    Ownership(ACheck);
  except
    on E: Exception do ACheck(False, 'Ownership exception: ' + E.Message);
  end;
  try
    Layout(ACheck);
  except
    on E: Exception do ACheck(False, 'Layout exception: ' + E.Message);
  end;
  try
    Editing(ACheck);
  except
    on E: Exception do ACheck(False, 'Editing exception: ' + E.Message);
  end;
  try
    Selection(ACheck);
  except
    on E: Exception do ACheck(False, 'Selection exception: ' + E.Message);
  end;
  try
    RangesAndData(ACheck);
  except
    on E: Exception do ACheck(False, 'Ranges/data exception: ' + E.Message);
  end;
  try
    ModalAndScroll(ACheck);
  except
    on E: Exception do ACheck(False, 'Modal/scroll exception: ' + E.Message);
  end;
end;

end.
