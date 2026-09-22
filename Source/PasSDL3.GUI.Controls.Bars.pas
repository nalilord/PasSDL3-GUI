unit PasSDL3.GUI.Controls.Bars;

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
  PasSDL3.GUI.Controls.Containers;

type
  TGuiSeparator = class(TGuiControl)
  private
    FOrientation: TGuiOrientation;
    FThickness: TGuiFloat;
    procedure SetOrientation(AValue: TGuiOrientation);
    procedure SetThickness(AValue: TGuiFloat);
  public
    property Orientation: TGuiOrientation read FOrientation write SetOrientation;
    property Thickness: TGuiFloat read FThickness write SetThickness;
    constructor Create; override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiStatusBar = class(TGuiPanel)
  private
    FSizingGrip: Boolean;
  public
    property SizingGrip: Boolean read FSizingGrip write FSizingGrip;
    constructor Create; override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiToolBar = class(TGuiStackPanel)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
  end;

  TGuiCommandBar = class(TGuiToolBar)
  private
    FTitle: String;
    FShowSectionSeparators: Boolean;
    FSectionColor: TGuiColor;
  public
    property Title: String read FTitle write FTitle;
    property ShowSectionSeparators: Boolean read FShowSectionSeparators write FShowSectionSeparators;
    property SectionColor: TGuiColor read FSectionColor write FSectionColor;
    constructor Create; override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

implementation

constructor TGuiSeparator.Create;
begin
  inherited Create;
  Orientation:=goHorizontal;
  Thickness:=1;
  Enabled:=False;
  BackgroundColor:=GuiColor(0, 0, 0, 0);
  BorderColor:=GuiColor(78, 92, 112);
end;

procedure TGuiSeparator.SetOrientation(AValue: TGuiOrientation);
begin
  if NOT (AValue IN [goHorizontal,goVertical]) then raise EArgumentException.Create('Invalid separator orientation');
  FOrientation:=AValue;
  InvalidateLayout;
end;

procedure TGuiSeparator.SetThickness(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then
    raise EArgumentException.Create('Separator thickness must be nonnegative and finite');
  FThickness:=AValue;
  InvalidateLayout;
end;

procedure TGuiSeparator.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  LineRect: TGuiRect;
  Size: TGuiFloat;
begin
  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) OR (Thickness=0) then Exit;

  if Orientation = goHorizontal then
  begin
    Size:=Min(Thickness,Rect.Height);
    LineRect:=GuiRect(Rect.Left, Rect.Top + ((Rect.Height - Size) / 2), Rect.Width, Size);
  end
  else
  begin
    Size:=Min(Thickness,Rect.Width);
    LineRect:=GuiRect(Rect.Left + ((Rect.Width - Size) / 2), Rect.Top, Size, Rect.Height);
  end;

  ACanvas.FillRect(LineRect, Style.BorderColor);
end;

constructor TGuiStatusBar.Create;
begin
  inherited Create;
  Padding:=GuiBoxLTRB(8, 2, 24, 2);
  SizingGrip:=True;
end;

procedure TGuiStatusBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  GripRect: TGuiRect;
  I: Integer;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, Style.BackgroundColor);
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top, Rect.Width, 1), Style.BorderColor);
  DrawControlText(ACanvas, Caption, GuiInflateRect(Rect, Padding), Style.TextColor, ghtaLeft, gvtaCenter);

  if SizingGrip then
  begin
    for I:=0 to 2 do
    begin
      GripRect:=GuiRect(Rect.Left + Rect.Width - 6 - (I * 5), Rect.Top + Rect.Height - 6, 3, 3);
      ACanvas.FillRect(GripRect, Style.BorderColor);
      GripRect:=GuiRect(Rect.Left + Rect.Width - 6, Rect.Top + Rect.Height - 6 - (I * 5), 3, 3);
      ACanvas.FillRect(GripRect, Style.BorderColor);
    end;
  end;
end;

constructor TGuiToolBar.Create;
begin
  inherited Create;
  Orientation:=goHorizontal;
  Spacing:=4;
  AutoSizeToContent:=False;
  Padding:=GuiBoxLTRB(6, 5, 6, 5);
  ClipChildren:=True;
end;

procedure TGuiToolBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
begin
  Rect:=AbsoluteBounds;

  if Style.BackgroundColor.A > 0 then
    ACanvas.FillRect(Rect, Style.BackgroundColor);

  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top, 1, Rect.Height), Style.BorderColor);
  ACanvas.FillRect(GuiRect(Rect.Left + Rect.Width - 1, Rect.Top, 1, Rect.Height), Style.BorderColor);
  ACanvas.FillRect(GuiRect(Rect.Left, Rect.Top + Rect.Height - 1, Rect.Width, 1), Style.BorderColor);
end;

constructor TGuiCommandBar.Create;
begin
  inherited Create;
  Title:='';
  ShowSectionSeparators:=True;
  SectionColor:=GuiColor(255, 255, 255, 45);
  Padding:=GuiBoxLTRB(8, 5, 8, 5);
end;

procedure TGuiCommandBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  I: Integer;
  Child: TGuiControl;
  SeparatorX: TGuiFloat;
begin
  inherited PaintSelf(ACanvas);
  Rect:=AbsoluteBounds;

  if Title <> '' then
    DrawControlText(ACanvas, Title, GuiRect(Rect.Left + 10, Rect.Top, 180, Rect.Height), Style.TextColor, ghtaLeft, gvtaCenter);

  if ShowSectionSeparators then
  begin
    for I:=0 to ChildCount - 2 do
    begin
      Child:=Children[I];
      if Child.Visible then
      begin
        SeparatorX:=Rect.Left + Child.Bounds.Left + Child.Bounds.Width + (Spacing / 2);
        ACanvas.FillRect(GuiRect(SeparatorX, Rect.Top + 6, 1, Rect.Height - 12), SectionColor);
      end;
    end;
  end;
end;

end.
