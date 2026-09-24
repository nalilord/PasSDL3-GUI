unit PasSDL3.GUI.Controls.Dialogs;

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
  PasSDL3.GUI.Controls.Containers,
  PasSDL3.GUI.Controls.Buttons;

type
  TGuiModalResult = (
    gmrNone,
    gmrOk,
    gmrCancel,
    gmrClose,
    gmrYes,
    gmrNo,
    gmrCustom
  );

  TGuiDialogWindowMode = (gdwmEmbedded, gdwmFixed, gdwmMovable, gdwmResizable);
  TGuiDialogButton = (gdbMinimize, gdbMaximize, gdbClose);
  TGuiDialogButtons = set of TGuiDialogButton;
  TGuiDialogState = (gdsNormal, gdsMinimized, gdsMaximized);

  TGuiDialog = class(TGuiPanel)
  private
    FWindowMode: TGuiDialogWindowMode;
    FShowTitleBar, FMovable, FResizable: Boolean;
    FTitleBarHeight: TGuiFloat;
    FTitleButtons: TGuiDialogButtons;
    FWindowState, FBeforeMinimize: TGuiDialogState;
    FNormalBounds: TGuiRect;
    FClientWasVisible, FButtonsWereVisible: Boolean;
    FPressedTitleButton: Integer;
    FDragEdges: Integer;
    FDragPoint: TGuiPoint;
    FDragBounds: TGuiRect;
    FUserPlaced: Boolean;
    procedure SetWindowMode(AValue: TGuiDialogWindowMode);
    procedure SetShowTitleBar(AValue: Boolean);
    procedure SetTitleBarHeight(AValue: TGuiFloat);
    procedure SetMovable(AValue: Boolean);
    procedure SetResizable(AValue: Boolean);
    procedure SetTitleButtons(AValue: TGuiDialogButtons);
    procedure SetWindowState(AValue: TGuiDialogState);
    function TitleButtonRect(AButton: TGuiDialogButton): TGuiRect;
    function TitleButtonAt(const APoint: TGuiPoint): Integer;
    function GetActive: Boolean;
    function DragEdgesAt(const APoint: TGuiPoint): Integer;
  private
    FTitle: String;
    FMessage: String;
    FClientPanel: TGuiPanel;
    FButtonPanel: TGuiStackPanel;
    FDefaultButton: TGuiButton;
    FCancelButton: TGuiButton;
    FButtonResults: TList;
    FModalResult: TGuiModalResult;
    FOnClose: TGuiNotifyEvent;
    procedure DialogButtonClicked(Sender: TGuiControl);
    procedure SetTitle(const AValue: String);
    procedure SetMessage(const AValue: String);
    function GetButtonCount: Integer;
    function GetButtonModalResult(AButton: TGuiButton): TGuiModalResult;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddButton(const ACaption: String; ADefault: Boolean = False; AModalResult: TGuiModalResult = gmrClose): TGuiButton;
    procedure Close(AModalResult: TGuiModalResult = gmrClose); virtual;
    procedure ExecuteDefault;
    procedure ExecuteCancel;
    procedure Activate;
    function ActivateWindow: Boolean; override;
    function KeepCurrentFocusOnPointerDown: Boolean; override;
    function DefinesFocusScope: Boolean; override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    procedure Minimize;
    procedure Maximize;
    procedure Restore;
    function HasUserPlacement: Boolean;
    property TitleButtons: TGuiDialogButtons read FTitleButtons write SetTitleButtons;
    property WindowState: TGuiDialogState read FWindowState write SetWindowState;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    property WindowMode: TGuiDialogWindowMode read FWindowMode write SetWindowMode;
    property ShowTitleBar: Boolean read FShowTitleBar write SetShowTitleBar;
    property TitleBarHeight: TGuiFloat read FTitleBarHeight write SetTitleBarHeight;
    property Movable: Boolean read FMovable write SetMovable;
    property Resizable: Boolean read FResizable write SetResizable;
    property Active: Boolean read GetActive;
    procedure Arrange(const ABounds: TGuiRect); override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property Title: String read FTitle write SetTitle;
    property MessageText: String read FMessage write SetMessage;
    property ClientPanel: TGuiPanel read FClientPanel;
    property ButtonPanel: TGuiStackPanel read FButtonPanel;
    property DefaultButton: TGuiButton read FDefaultButton;
    property CancelButton: TGuiButton read FCancelButton;
    property ButtonCount: Integer read GetButtonCount;
    property ModalResult: TGuiModalResult read FModalResult write FModalResult;
    property OnClose: TGuiNotifyEvent read FOnClose write FOnClose;
  end;

  TGuiModalOverlay = class(TGuiPanel)
  private
    FDialog: TGuiDialog;
    FDimColor: TGuiColor;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    class function CreateWithDialog(ADialog: TGuiDialog): TGuiModalOverlay;
    procedure Arrange(const ABounds: TGuiRect); override;
    property Dialog: TGuiDialog read FDialog;
    property DimColor: TGuiColor read FDimColor write FDimColor;
  end;

implementation

constructor TGuiDialog.Create;
begin
  inherited Create;
  FTitle:='Dialog';
  FShowTitleBar:=True;
  FTitleBarHeight:=32;
  FPressedTitleButton:=-1;
  FMessage:='';
  StyleClass:='Card';
  Padding:=GuiBoxLTRB(18, 40, 18, 64);
  ClipChildren:=True;
  MinWidth:=260;
  MinHeight:=160;
  FButtonResults:=TList.Create;
  FModalResult:=gmrNone;

  FClientPanel:=TGuiTransparentPanel.Create;
  FClientPanel.BackgroundColor:=GuiColor(0, 0, 0, 0);
  FClientPanel.BorderColor:=GuiColor(0, 0, 0, 0);
  inherited Add(FClientPanel);

  FButtonPanel:=TGuiTransparentStackPanel.Create;
  FButtonPanel.Orientation:=goHorizontal;
  FButtonPanel.Spacing:=8;
  FButtonPanel.AutoSizeToContent:=False;
  FButtonPanel.BackgroundColor:=GuiColor(0, 0, 0, 0);
  FButtonPanel.BorderColor:=GuiColor(0, 0, 0, 0);
  FButtonPanel.Visible:=False;
  inherited Add(FButtonPanel);
end;

destructor TGuiDialog.Destroy;
begin
  FButtonResults.Free;
  inherited Destroy;
end;

procedure TGuiDialog.SetTitle(const AValue: String);
begin
  FTitle:=AValue;
end;

procedure TGuiDialog.SetMessage(const AValue: String);
begin
  FMessage:=AValue;
end;

function TGuiDialog.GetButtonCount: Integer;
begin
  Result:=FButtonPanel.ChildCount;
end;

function TGuiDialog.GetButtonModalResult(AButton: TGuiButton): TGuiModalResult;
var
  I: Integer;
begin
  Result:=gmrClose;

  if NOT Assigned(AButton) then
    Exit;

  for I:=0 to FButtonPanel.ChildCount - 1 do
    if FButtonPanel.Children[I] = AButton then
    begin
      if I < FButtonResults.Count then
        Result:=TGuiModalResult(NativeInt(FButtonResults[I]));
      Exit;
    end;
end;

procedure TGuiDialog.DialogButtonClicked(Sender: TGuiControl);
begin
  if Sender IS TGuiButton then
    Close(GetButtonModalResult(TGuiButton(Sender)))
  else
    Close(gmrClose);
end;

function TGuiDialog.AddButton(const ACaption: String; ADefault: Boolean; AModalResult: TGuiModalResult): TGuiButton;
begin
  Result:=TGuiButton.Create;
  Result.Bounds:=GuiRect(0, 0, 104, 38);
  Result.Caption:=ACaption;
  Result.OnClick:=DialogButtonClicked;

  if ADefault then
    FDefaultButton:=Result;

  if AModalResult IN [gmrCancel, gmrClose] then
    FCancelButton:=Result;

  FButtonPanel.Add(Result);
  FButtonPanel.Visible:=True;
  FButtonResults.Add(Pointer(NativeInt(AModalResult)));
end;

procedure TGuiDialog.Close(AModalResult: TGuiModalResult);
begin
  FModalResult:=AModalResult;
  FDragEdges:=0;
  if FWindowMode <> gdwmEmbedded then
  begin
    Visible:=False;
    if Assigned(Context) then
    begin
      if Parent IS TGuiModalOverlay then Context.CloseModal(Parent)
      else if Context.ModalControl = Self then Context.CloseModal(Self)
      else Context.RestoreFocus;
    end;
  end;

  if Assigned(FOnClose) then
    FOnClose(Self);
end;

procedure TGuiDialog.ExecuteDefault;
begin
  if Assigned(FDefaultButton) AND FDefaultButton.Enabled AND FDefaultButton.Visible then
    FDefaultButton.PerformClick
  else
    Close(gmrOk);
end;

procedure TGuiDialog.ExecuteCancel;
begin
  if Assigned(FCancelButton) AND FCancelButton.Enabled AND FCancelButton.Visible then
    FCancelButton.PerformClick
  else
    Close(gmrCancel);
end;

procedure TGuiDialog.Arrange(const ABounds: TGuiRect);
var
  ChildBounds: TGuiRect;
  DialogBounds: TGuiRect;
begin
  Bounds:=ABounds;
  if (FWindowState = gdsMaximized) AND Assigned(Parent) then
    Bounds:=GuiRect(0, 0, Parent.Bounds.Width, Parent.Bounds.Height);
  if FWindowState = gdsMinimized then
  begin
    DialogBounds:=Bounds;
    DialogBounds.Height:=FTitleBarHeight + 2;
    Bounds:=DialogBounds;
  end;
  ChildBounds:=GuiRect(Padding.Left, Padding.Top, Bounds.Width - Padding.Left - Padding.Right,
    Bounds.Height - Padding.Top - Padding.Bottom);
  GuiClampControlBounds(FClientPanel, ChildBounds);
  FClientPanel.Bounds:=ChildBounds;
  FClientPanel.Arrange(ChildBounds);

  ChildBounds:=GuiRect(Bounds.Width - Padding.Right - 224, Bounds.Height - 50, 224, 38);
  GuiClampControlBounds(FButtonPanel, ChildBounds);
  FButtonPanel.Bounds:=ChildBounds;
  FButtonPanel.Arrange(ChildBounds);

  CompleteArrange;
end;

procedure TGuiDialog.SetWindowMode(AValue: TGuiDialogWindowMode);
begin
  if (AValue = gdwmEmbedded) AND (FWindowState <> gdsNormal) then SetWindowState(gdsNormal);
  FWindowMode:=AValue;
  FDragEdges:=0;
  FMovable:=AValue IN [gdwmMovable, gdwmResizable];
  FResizable:=AValue = gdwmResizable;
  CanFocus:=AValue <> gdwmEmbedded;
  TabStop:=CanFocus;
end;

procedure TGuiDialog.SetShowTitleBar(AValue: Boolean);
var
  CurrentPadding: TGuiBox;
begin
  if FShowTitleBar = AValue then Exit;
  if (NOT AValue) AND (FWindowState = gdsMinimized) then Restore;
  CurrentPadding:=Padding;
  if AValue then CurrentPadding.Top:=CurrentPadding.Top + FTitleBarHeight
  else CurrentPadding.Top:=Max(0, CurrentPadding.Top - FTitleBarHeight);
  Padding:=CurrentPadding;
  FShowTitleBar:=AValue;
  FDragEdges:=0;
  InvalidateLayout;
end;

procedure TGuiDialog.SetTitleBarHeight(AValue: TGuiFloat);
var
  CurrentPadding: TGuiBox;
begin
  AValue:=Max(20, AValue);
  if FShowTitleBar then
  begin
    CurrentPadding:=Padding;
    CurrentPadding.Top:=Max(0, CurrentPadding.Top + AValue - FTitleBarHeight);
    Padding:=CurrentPadding;
  end;
  FTitleBarHeight:=AValue;
  FDragEdges:=0;
  InvalidateLayout;
end;

procedure TGuiDialog.SetTitleButtons(AValue: TGuiDialogButtons);
begin
  FTitleButtons:=AValue;
  FPressedTitleButton:=-1;
end;

function TGuiDialog.TitleButtonRect(AButton: TGuiDialogButton): TGuiRect;
var B: TGuiDialogButton;
Offset, Size: TGuiFloat;
R: TGuiRect;
begin
  R:=AbsoluteBounds;
  Result:=GuiRect(0, 0, 0, 0);
  if (FWindowMode = gdwmEmbedded) OR NOT FShowTitleBar OR NOT (AButton IN FTitleButtons) then Exit;
  Size:=Max(20, FTitleBarHeight - 4);
  Offset:=4;
  for B:=High(TGuiDialogButton) downto Low(TGuiDialogButton) do
    if B IN FTitleButtons then
    begin
      if B = AButton then
      begin
        Result:=GuiRect(R.Left + R.Width - Offset - Size, R.Top + 2, Size, FTitleBarHeight - 4);
        Exit;
      end;
      Offset:=Offset + Size + 2;
    end;
end;

function TGuiDialog.TitleButtonAt(const APoint: TGuiPoint): Integer;
var B: TGuiDialogButton;
begin
  Result:=-1;
  for B:=Low(TGuiDialogButton) to High(TGuiDialogButton) do
    if GuiRectContains(TitleButtonRect(B), APoint) then
    begin
      Result:=Ord(B);
      Exit;
    end;
end;

procedure TGuiDialog.SetWindowState(AValue: TGuiDialogState);
var R: TGuiRect;
begin
  if (AValue = FWindowState) OR (FWindowMode = gdwmEmbedded) OR (Align <> gaNone) then Exit;
  if (AValue = gdsMinimized) AND NOT FShowTitleBar then Exit;
  if FWindowState = gdsNormal then FNormalBounds:=Bounds;
  if FWindowState = gdsMinimized then
  begin
    FClientPanel.Visible:=FClientWasVisible;
    FButtonPanel.Visible:=FButtonsWereVisible;
  end;
  if AValue = gdsMinimized then
  begin
    FBeforeMinimize:=FWindowState;
    FClientWasVisible:=FClientPanel.Visible;
    FButtonsWereVisible:=FButtonPanel.Visible;
    FClientPanel.Visible:=False;
    FButtonPanel.Visible:=False;
  end;
  R:=Bounds;
  if AValue = gdsNormal then R:=FNormalBounds;
  FWindowState:=AValue;
  FDragEdges:=0;
  FPressedTitleButton:=-1;
  FUserPlaced:=True;
  Arrange(R);
  if Assigned(Context) AND Active AND (AValue = gdsMinimized) then Context.SetFocus(Self);
end;

procedure TGuiDialog.Minimize;
begin
  SetWindowState(gdsMinimized);
end;

procedure TGuiDialog.Maximize;
begin
  SetWindowState(gdsMaximized);
end;

procedure TGuiDialog.Restore;
begin
  if FWindowState = gdsMinimized then SetWindowState(FBeforeMinimize)
  else SetWindowState(gdsNormal);
  if Assigned(Context) AND (Context.FocusedControl = Self) then
    Context.RestoreFocusWithin(Self, Self);
  Activate;
end;

function TGuiDialog.HasUserPlacement: Boolean;
begin
  Result:=FUserPlaced;
end;

procedure TGuiDialog.SetMovable(AValue: Boolean);
begin
  FMovable:=AValue;
  FDragEdges:=0;
end;

procedure TGuiDialog.SetResizable(AValue: Boolean);
begin
  FResizable:=AValue;
  FDragEdges:=0;
end;

function TGuiDialog.GetActive: Boolean;
begin
  Result:=Assigned(Context) AND Context.ControlContains(Self, Context.FocusedControl);
end;

procedure TGuiDialog.Activate;
begin
  if (FWindowMode = gdwmEmbedded) OR NOT Visible OR NOT Enabled OR NOT Assigned(Context) then Exit;
  if Assigned(Context.ModalControl) AND NOT Context.ControlContains(Context.ModalControl, Self) then Exit;
  BringToFront;
  if Active then Exit;
  if Context.RestoreFocusWithin(Self, nil) then Exit;
  if Assigned(FDefaultButton) AND Context.SetFocus(FDefaultButton) then Exit;
  Context.SetFocus(Self);
end;

function TGuiDialog.DragEdgesAt(const APoint: TGuiPoint): Integer;
var R: TGuiRect;
begin
  Result:=0;
  R:=AbsoluteBounds;
  if FWindowMode = gdwmEmbedded then Exit;
  if (TitleButtonAt(APoint) >= 0) OR (FWindowState = gdsMaximized) then Exit;
  if (Align <> gaNone) OR NOT GuiRectContains(R, APoint) then Exit;
  if FResizable AND (FWindowState = gdsNormal) then
  begin
    if APoint.X < R.Left + 6 then Result:=Result OR 1;
    if APoint.X >= R.Left + R.Width - 6 then Result:=Result OR 2;
    if APoint.Y < R.Top + 6 then Result:=Result OR 4;
    if APoint.Y >= R.Top + R.Height - 6 then Result:=Result OR 8;
  end;
  if (Result = 0) AND FMovable AND FShowTitleBar AND
    (APoint.Y < R.Top + FTitleBarHeight) then Result:=16;
end;

function TGuiDialog.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=inherited HitTest(APoint);
  if Assigned(Result) AND ((DragEdgesAt(APoint) <> 0) OR (TitleButtonAt(APoint) >= 0)) then Result:=Self;
end;

procedure TGuiDialog.HandleEvent(var AEvent: TGuiEvent);
var R: TGuiRect;
DX, DY, W, H: TGuiFloat;
ButtonIndex: Integer;
begin
  if AEvent.Kind = gekCancel then FPressedTitleButton:=-1;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) then
  begin
    FPressedTitleButton:=TitleButtonAt(AEvent.Position);
    if FPressedTitleButton >= 0 then
    begin
      Activate;
      AEvent.Handled:=True;
      Exit;
    end;
  end;
  if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND (FPressedTitleButton >= 0) then
  begin
    ButtonIndex:=FPressedTitleButton;
    FPressedTitleButton:=-1;
    AEvent.Handled:=True;
    if ButtonIndex = TitleButtonAt(AEvent.Position) then
      case TGuiDialogButton(ButtonIndex) of
        gdbClose: Close(gmrClose);
        gdbMinimize: if FWindowState = gdsMinimized then Restore else Minimize;
        gdbMaximize: if FWindowState = gdsMaximized then Restore else Maximize;
      end;
    Exit;
  end;
  if (AEvent.Kind = gekKeyDown) AND (AEvent.Modifiers = [gemAlt]) AND
    (AEvent.KeyCode = $4000003D) AND (gdbClose IN FTitleButtons) then
  begin
    AEvent.Handled:=True;
    Close(gmrClose);
    Exit;
  end;
  if AEvent.Kind = gekCancel then FDragEdges:=0;
  if (FDragEdges <> 0) AND (AEvent.Kind = gekKeyDown) AND (AEvent.KeyCode = 27) then
  begin
    Arrange(FDragBounds);
    FDragEdges:=0;
    AEvent.Handled:=True;
    Exit;
  end;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) then
  begin
    FDragEdges:=DragEdgesAt(AEvent.Position);
    if FDragEdges <> 0 then
    begin
      Activate;
      FDragPoint:=AEvent.Position;
      FDragBounds:=Bounds;
      AEvent.Handled:=True;
      Exit;
    end;
  end;
  if (AEvent.Kind = gekMouseMove) AND (FDragEdges <> 0) then
  begin
    R:=FDragBounds;
    DX:=AEvent.Position.X - FDragPoint.X;
    DY:=AEvent.Position.Y - FDragPoint.Y;
    if FDragEdges = 16 then
    begin
      R.Left:=R.Left + DX;
      R.Top:=R.Top + DY;
    end
    else
    begin
      W:=R.Width;
      H:=R.Height;
      if (FDragEdges AND 1) <> 0 then W:=W - DX;
      if (FDragEdges AND 2) <> 0 then W:=W + DX;
      if (FDragEdges AND 4) <> 0 then H:=H - DY;
      if (FDragEdges AND 8) <> 0 then H:=H + DY;
      W:=Max(Max(1, MinWidth), W);
      H:=Max(Max(1, MinHeight), H);
      if MaxWidth > 0 then W:=Min(W, MaxWidth);
      if MaxHeight > 0 then H:=Min(H, MaxHeight);
      if (FDragEdges AND 1) <> 0 then R.Left:=R.Left + R.Width - W;
      if (FDragEdges AND 4) <> 0 then R.Top:=R.Top + R.Height - H;
      R.Width:=W;
      R.Height:=H;
    end;
    if Assigned(Parent) then
    begin
      R.Left:=EnsureRange(R.Left, 0, Max(0, Parent.Bounds.Width - R.Width));
      R.Top:=EnsureRange(R.Top, 0, Max(0, Parent.Bounds.Height - R.Height));
    end;
    FUserPlaced:=True;
    Arrange(R);
    AEvent.Handled:=True;
    Exit;
  end;
  if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND (FDragEdges <> 0) then
  begin
    FDragEdges:=0;
    AEvent.Handled:=True;
    Exit;
  end;
  inherited HandleEvent(AEvent);

  if AEvent.Handled OR (AEvent.Kind <> gekKeyDown) then
    Exit;

  case AEvent.KeyCode of
    13:
    begin
      ExecuteDefault;
      AEvent.Handled:=True;
    end;

    27:
    begin
      ExecuteCancel;
      AEvent.Handled:=True;
    end;
  end;
end;

procedure TGuiDialog.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  TitleRect: TGuiRect;
  MessageRect: TGuiRect;
  SeparatorRect: TGuiRect;
  FrameColor: TGuiColor;
  I: Integer;
  B: TGuiDialogButton;
  ButtonRect: TGuiRect;
  X, Y, CaptionRight: TGuiFloat;
  Hot: Boolean;
begin
  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(Style.Background, Rect, Style.CornerRadius);
  FrameColor:=Style.BorderColor;
  if (FWindowMode <> gdwmEmbedded) AND Active then FrameColor:=Style.FocusedBorderColor;
  DrawControlBorder(ACanvas, Rect, FrameColor);
  TitleRect:=GuiRect(Rect.Left + 1, Rect.Top + 1, Max(0, Rect.Width - 2),
    Max(0, Min(FTitleBarHeight - 1, Rect.Height - 2)));
  if (FWindowMode <> gdwmEmbedded) AND FShowTitleBar then
  begin
    if Active then ACanvas.FillRoundedGradient(TitleRect, Style.CornerRadius,
      GuiMixColor(Style.BackgroundColor, FrameColor, 0.18),
      GuiMixColor(Style.BackgroundColor, FrameColor, 0.06))
    else ACanvas.DrawSurface(Style.HoverBackground, TitleRect, Style.CornerRadius);
    ACanvas.FillRect(GuiRect(Rect.Left + 1, TitleRect.Top + TitleRect.Height, Max(0, Rect.Width - 2), 1), FrameColor);
  end;
  if (FWindowMode <> gdwmEmbedded) AND FResizable AND (FWindowState = gdsNormal) then
  begin
      for I:=0 to 2 do
        ACanvas.DrawLine(GuiPoint(Rect.Left + Rect.Width - 6 - I * 4, Rect.Top + Rect.Height - 6),
          GuiPoint(Rect.Left + Rect.Width - 6, Rect.Top + Rect.Height - 6 - I * 4), 1, FrameColor);
  end;

  if FShowTitleBar then
  begin
    CaptionRight:=TitleRect.Left + TitleRect.Width;
    for B:=Low(TGuiDialogButton) to High(TGuiDialogButton) do
    begin
      ButtonRect:=TitleButtonRect(B);
      if ButtonRect.Width <= 0 then Continue;
      CaptionRight:=Min(CaptionRight, ButtonRect.Left - 2);
      Hot:=Assigned(Context) AND (Context.HoveredControl = Self) AND
        GuiRectContains(ButtonRect, Context.MousePosition);
      if Hot then
      begin
        if FPressedTitleButton = Ord(B) then ACanvas.DrawSurface(Style.Selection, ButtonRect, 3)
        else ACanvas.DrawSurface(Style.HoverBackground, ButtonRect, 3);
      end;
      X:=Floor(ButtonRect.Left + ButtonRect.Width / 2 - 4);
      Y:=Floor(ButtonRect.Top + ButtonRect.Height / 2 - 4);
      case B of
        gdbClose:
        begin
          ACanvas.DrawLine(GuiPoint(X, Y), GuiPoint(X + 8, Y + 8), 1.5, Style.TextColor);
          ACanvas.DrawLine(GuiPoint(X + 8, Y), GuiPoint(X, Y + 8), 1.5, Style.TextColor);
        end;
        gdbMinimize:
          if FWindowState = gdsMinimized then ACanvas.DrawBorder(GuiRect(X, Y, 9, 9), 1, Style.TextColor)
          else ACanvas.DrawLine(GuiPoint(X, Y + 7), GuiPoint(X + 8, Y + 7), 1.5, Style.TextColor);
        gdbMaximize:
        begin
          if FWindowState = gdsMaximized then
          begin
            ACanvas.DrawBorder(GuiRect(X + 2, Y, 8, 7), 1, Style.TextColor);
            ACanvas.DrawBorder(GuiRect(X, Y + 3, 8, 7), 1, Style.TextColor);
          end
          else
            ACanvas.DrawBorder(GuiRect(X, Y, 9, 9), 1, Style.TextColor);
        end;
      end;
    end;
    TitleRect.Width:=Max(0, CaptionRight - TitleRect.Left);
    ACanvas.PushClipRect(TitleRect);
    try
      DrawControlText(ACanvas, FTitle, GuiInflateRect(TitleRect, GuiBoxLTRB(12, 0, 12, 0)),
        Style.TextColor, ghtaLeft, gvtaCenter);
    finally
      ACanvas.PopClipRect;
    end;
  end;

  if FWindowState = gdsMinimized then Exit;
  if FMessage <> '' then
  begin
    MessageRect:=GuiRect(Rect.Left + Padding.Left, Rect.Top + Padding.Top, Rect.Width - Padding.Left - Padding.Right, 48);
    DrawControlText(ACanvas, FMessage, MessageRect, Style.TextColor, ghtaLeft, gvtaTop);
  end;

  if FButtonPanel.Visible then
  begin
    SeparatorRect:=GuiRect(Rect.Left, Rect.Top + Rect.Height - 62, Rect.Width, 1);
    ACanvas.FillRect(SeparatorRect, Style.BorderColor);
  end;
end;

constructor TGuiModalOverlay.Create;
begin
  inherited Create;
  FDialog:=nil;
  FDimColor:=GuiColor(3, 6, 10, 150);
  BorderColor:=GuiColor(0, 0, 0, 0);
  BackgroundColor:=GuiColor(0, 0, 0, 0);
  ClipChildren:=False;
end;

class function TGuiModalOverlay.CreateWithDialog(ADialog: TGuiDialog): TGuiModalOverlay;
begin
  Result:=TGuiModalOverlay.Create;
  if Assigned(ADialog) then
  begin
    Result.FDialog:=ADialog;
    Result.Add(ADialog);
  end;
end;

procedure TGuiModalOverlay.Arrange(const ABounds: TGuiRect);
var
  DialogBounds: TGuiRect;
begin
  Bounds:=ABounds;

  if Assigned(FDialog) then
  begin
    DialogBounds:=FDialog.Bounds;
    if NOT FDialog.HasUserPlacement then
    begin
      DialogBounds.Left:=(Bounds.Width - DialogBounds.Width) / 2;
      DialogBounds.Top:=(Bounds.Height - DialogBounds.Height) / 2;
    end else
    begin
      DialogBounds.Left:=EnsureRange(DialogBounds.Left, 0, Max(0, Bounds.Width - DialogBounds.Width));
      DialogBounds.Top:=EnsureRange(DialogBounds.Top, 0, Max(0, Bounds.Height - DialogBounds.Height));
    end;
    FDialog.Arrange(DialogBounds);
  end;

  CompleteArrange;
end;

procedure TGuiModalOverlay.PaintSelf(ACanvas: TGuiCanvas);
begin
  ACanvas.DrawBrush(GuiColorBrush(FDimColor), AbsoluteBounds);
end;

function TGuiDialog.ActivateWindow: Boolean;
begin
  Activate;
  Result:=True;
end;

function TGuiDialog.KeepCurrentFocusOnPointerDown: Boolean;
begin
  Result:=Active;
end;

function TGuiDialog.DefinesFocusScope: Boolean;
begin
  Result:=WindowMode <> gdwmEmbedded;
end;

function TGuiDialog.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
var
  Edges: Integer;
begin
  Result:=inherited MouseCursorAt(APoint);
  if NOT Enabled OR (Cursor <> gmcAuto) then
    Exit;
  Edges:=FDragEdges;
  if Edges = 0 then
    Edges:=DragEdgesAt(APoint);
  case Edges of
    1, 2: Result:=gmcSizeWE;
    4, 8: Result:=gmcSizeNS;
    5, 10: Result:=gmcSizeNWSE;
    6, 9: Result:=gmcSizeNESW;
    16: Result:=gmcMove;
  end;
end;

end.
