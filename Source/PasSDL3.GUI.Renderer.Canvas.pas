unit PasSDL3.GUI.Renderer.Canvas;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  PasSDL3.GUI.Types;

type
  TGuiCaretPositions = array of TGuiFloat;

  TGuiTextRow = record
  private
    FStartIndex: Integer;
    FTextLength: Integer;
    FWidth: TGuiFloat;
    FCaretX: TGuiCaretPositions;
  public
    property StartIndex: Integer read FStartIndex write FStartIndex;
    property TextLength: Integer read FTextLength write FTextLength;
    property Width: TGuiFloat read FWidth write FWidth;
    property CaretX: TGuiCaretPositions read FCaretX write FCaretX;
  end;
  TGuiTextRows = array of TGuiTextRow;

  TGuiCanvas = class
  private
    FFontName: String;
    procedure DrawNineSlice(const ADrawable: TGuiDrawable; const ARect: TGuiRect);
    procedure PaintRounded(const ARect: TGuiRect; ARadius, AWidth: TGuiFloat; const AColor, AEndColor: TGuiColor; AGradient: Boolean);
  public
    property FontName: String read FFontName write FFontName;
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor); virtual; abstract;
    procedure DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat; const AColor: TGuiColor); virtual; abstract;
    procedure DrawLine(const AStart, AEnd: TGuiPoint; AWidth: TGuiFloat; const AColor: TGuiColor); virtual;
    procedure FillRoundedRect(const ARect: TGuiRect; ARadius: TGuiFloat; const AColor: TGuiColor); virtual;
    procedure FillRoundedGradient(const ARect: TGuiRect; ARadius: TGuiFloat; const ATop, ABottom: TGuiColor); virtual;
    procedure DrawRoundedBorder(const ARect: TGuiRect; ARadius, AWidth: TGuiFloat; const AColor: TGuiColor); virtual;
    procedure DrawSurface(const ADrawable: TGuiDrawable; const ARect: TGuiRect; ARadius: TGuiFloat); virtual;
    procedure DrawCheckMark(const ARect: TGuiRect; const AColor: TGuiColor); virtual;
    procedure DrawChevron(const ARect: TGuiRect; const AColor: TGuiColor; AUp: Boolean = False); virtual;
    procedure DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect); virtual; abstract;
    procedure DrawImagePart(ATexture: TGuiTexture; const ASourceRect, ADestRect: TGuiRect); virtual;
    procedure DrawBrush(const ABrush: TGuiBrush; const ARect: TGuiRect); virtual;
    procedure DrawDrawable(const ADrawable: TGuiDrawable; const ARect: TGuiRect); virtual;
    procedure DrawText(const AText: String; const ARect: TGuiRect; const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign = ghtaLeft;
      AVerticalAlign: TGuiVerticalTextAlign = gvtaCenter); virtual; abstract;
    function MeasureText(const AText: String): TGuiSize; virtual;
    function TextMetricsKey: String; virtual;
    procedure PushClipRect(const ARect: TGuiRect); virtual; abstract;
    procedure PopClipRect; virtual; abstract;
  end;

{ Preserves source offsets and hard line breaks. A nil canvas uses an eight-unit
  character estimate until real font metrics are available. }
function GuiLayoutText(ACanvas: TGuiCanvas; const AText: String;
  AWidth: TGuiFloat; AWrap: Boolean): TGuiTextRows;

implementation

uses SysUtils, Math, PasSDL3.GUI.Text, PasSDL3.GUI.Grapheme;

function GuiLayoutText(ACanvas: TGuiCanvas; const AText: String;
  AWidth: TGuiFloat; AWrap: Boolean): TGuiTextRows;
var
  StartIndex, StopIndex, Index, NextIndex, LastBreak, RowEnd, RowCount: Integer;
  Graphemes: TGuiGraphemeMap;
  function WidthOf(AStart, AEnd: Integer): TGuiFloat;
  var P: Integer;
  begin
    if Assigned(ACanvas) then Result:=ACanvas.MeasureText(Copy(AText, AStart + 1, AEnd - AStart)).Width
    else
    begin
      Result:=0;
      P:=AStart;
      while P < AEnd do
      begin
        Result:=Result + 8;
        P:=Graphemes.Next(AText, P);
      end;
    end;
  end;
  procedure AddRow(AStart, AEnd: Integer);
  var P, N, J: Integer;
  X: TGuiFloat;
  begin
    if RowCount = Length(Result) then SetLength(Result, Max(8, RowCount * 2));
    Result[RowCount].FStartIndex:=AStart;
    Result[RowCount].FTextLength:=AEnd - AStart;
    SetLength(Result[RowCount].FCaretX, AEnd - AStart + 1);
    Result[RowCount].FCaretX[0]:=0;
    P:=AStart;
    while P < AEnd do
    begin
      N:=Min(AEnd, Graphemes.Next(AText, P));
      X:=WidthOf(AStart, N);
      for J:=P + 1 to N - 1 do
        Result[RowCount].FCaretX[J - AStart]:=Result[RowCount].FCaretX[P - AStart];
      Result[RowCount].FCaretX[N - AStart]:=X;
      P:=N;
    end;
    Result[RowCount].FWidth:=Result[RowCount].FCaretX[AEnd - AStart];
    Inc(RowCount);
  end;
begin
  Result:=nil;
  RowCount:=0;
  StartIndex:=0;
  AWidth:=Max(1, AWidth);
  repeat
    StopIndex:=StartIndex;
    while (StopIndex < Length(AText)) AND (AText[StopIndex + 1] <> #10) AND
      (AText[StopIndex + 1] <> #13) do Inc(StopIndex);
    if (NOT AWrap) OR (StartIndex = StopIndex) then AddRow(StartIndex, StopIndex)
    else
      while StartIndex < StopIndex do
      begin
        Index:=StartIndex;
        LastBreak:=-1;
        while Index < StopIndex do
        begin
          NextIndex:=Min(StopIndex, Graphemes.Next(AText, Index));
          if (Index > StartIndex) AND (WidthOf(StartIndex, NextIndex) > AWidth) then Break;
          Index:=NextIndex;
          if AText[Index] IN [' ', #9] then LastBreak:=Index;
        end;
        RowEnd:=Index;
        if (Index < StopIndex) AND (LastBreak > StartIndex) then RowEnd:=LastBreak;
        AddRow(StartIndex, RowEnd);
        StartIndex:=RowEnd;
      end;
    StartIndex:=StopIndex + 1;
    if (StopIndex + 1 < Length(AText)) AND (AText[StopIndex + 1] = #13) AND
      (AText[StopIndex + 2] = #10) then Inc(StartIndex);
  until StartIndex > Length(AText);
  SetLength(Result, RowCount);
end;

function TGuiCanvas.TextMetricsKey: String;
begin
  Result:=FontName;
end;

procedure TGuiCanvas.PaintRounded(const ARect: TGuiRect; ARadius, AWidth: TGuiFloat; const AColor, AEndColor: TGuiColor; AGradient: Boolean);
var
  Row: Integer;
  Y, H, Inset, InnerInset, InnerRadius, InnerY: TGuiFloat;
  RowColor: TGuiColor;

  function CurveInset(AY, AHeight, AR: TGuiFloat): TGuiFloat;
  var D: TGuiFloat;
  begin
    D:=Max(0, AR - Min(AY, AHeight - AY));
    Result:=AR - Sqrt(Max(0, AR * AR - D * D));
  end;

  procedure Span(ALeft, ARight: TGuiFloat);
  var L, R: Integer;
  C: TGuiColor;
  begin
    if ARight <= ALeft then Exit;
    L:=Floor(ALeft);
    R:=Floor(ARight);
    C:=RowColor;
    if L = R then
    begin
      C.A:=Round(RowColor.A * (ARight - ALeft));
      FillRect(GuiRect(L, Y, 1, H), C);
      Exit;
    end;
    C.A:=Round(RowColor.A * (L + 1 - ALeft));
    FillRect(GuiRect(L, Y, 1, H), C);
    if R > L + 1 then FillRect(GuiRect(L + 1, Y, R - L - 1, H), RowColor);
    C.A:=Round(RowColor.A * (ARight - R));
    if C.A > 0 then FillRect(GuiRect(R, Y, 1, H), C);
  end;

begin
  if (ARect.Width <= 0) OR (ARect.Height <= 0) OR ((AColor.A = 0) AND (AEndColor.A = 0)) then Exit;
  ARadius:=Max(0, Min(ARadius, Min(ARect.Width, ARect.Height) / 2));
  InnerRadius:=Max(0, ARadius - AWidth);
  Row:=0;
  RowColor:=AColor;
  while Row < Ceil(ARect.Height) do
  begin
    Y:=ARect.Top + Row;
    H:=Min(1, ARect.Height - Row);
    { Batch straight middle sections; large panels cost only corner scanlines. }
    if (NOT AGradient) AND (Row >= Ceil(Max(ARadius, AWidth))) AND
      (Row < Floor(ARect.Height - Max(ARadius, AWidth))) then
      H:=Floor(ARect.Height - Max(ARadius, AWidth)) - Row;
    if AGradient then RowColor:=GuiMixColor(AColor, AEndColor, Row / Max(1, ARect.Height - 1));
    Inset:=CurveInset(Row + H / 2, ARect.Height, ARadius);
    InnerY:=Row + H / 2 - AWidth;
    if (AWidth <= 0) OR (InnerY <= 0) OR
      (InnerY >= ARect.Height - 2 * AWidth) OR (ARect.Width <= 2 * AWidth) then
      Span(ARect.Left + Inset, ARect.Left + ARect.Width - Inset)
    else
    begin
      InnerInset:=AWidth + CurveInset(InnerY, ARect.Height - 2 * AWidth, InnerRadius);
      Span(ARect.Left + Inset, ARect.Left + InnerInset);
      Span(ARect.Left + ARect.Width - InnerInset, ARect.Left + ARect.Width - Inset);
    end;
    Inc(Row, Ceil(H));
  end;
end;

procedure TGuiCanvas.FillRoundedRect(const ARect: TGuiRect; ARadius: TGuiFloat; const AColor: TGuiColor);
begin
  if (ARect.Width <= 0) OR (ARect.Height <= 0) OR (AColor.A = 0) then Exit;
  if ARadius <= 0 then FillRect(ARect, AColor)
  else PaintRounded(ARect, ARadius, 0, AColor, AColor, False);
end;

procedure TGuiCanvas.FillRoundedGradient(const ARect: TGuiRect; ARadius: TGuiFloat; const ATop, ABottom: TGuiColor);
begin
  if (ATop.R = ABottom.R) AND (ATop.G = ABottom.G) AND (ATop.B = ABottom.B) AND (ATop.A = ABottom.A) then
    FillRoundedRect(ARect, ARadius, ATop)
  else PaintRounded(ARect, ARadius, 0, ATop, ABottom, True);
end;

procedure TGuiCanvas.DrawRoundedBorder(const ARect: TGuiRect; ARadius, AWidth: TGuiFloat; const AColor: TGuiColor);
begin
  if (AWidth <= 0) OR (ARect.Width <= 0) OR (ARect.Height <= 0) OR (AColor.A = 0) then Exit;
  if ARadius <= 0 then DrawBorder(ARect, AWidth, AColor)
  else PaintRounded(ARect, ARadius, AWidth, AColor, AColor, False);
end;

procedure TGuiCanvas.DrawSurface(const ADrawable: TGuiDrawable; const ARect: TGuiRect; ARadius: TGuiFloat);
begin
  { Only procedural colour surfaces are rounded. Images and nine-slice skins
    retain their original drawing semantics. }
  if ADrawable.Kind = gdkLinearGradient then
    FillRoundedGradient(ARect, ARadius, ADrawable.Brush.Color, ADrawable.GradientEnd)
  else if (ADrawable.Kind = gdkBrush) AND (ADrawable.Brush.Kind = gbkColor) then
    FillRoundedRect(ARect, ARadius, ADrawable.Brush.Color)
  else DrawDrawable(ADrawable, ARect);
end;

procedure TGuiCanvas.DrawCheckMark(const ARect: TGuiRect; const AColor: TGuiColor);
begin
  DrawLine(GuiPoint(ARect.Left, ARect.Top + ARect.Height * 0.5),
    GuiPoint(ARect.Left + ARect.Width * 0.35, ARect.Top + ARect.Height), 2, AColor);
  DrawLine(GuiPoint(ARect.Left + ARect.Width * 0.35, ARect.Top + ARect.Height),
    GuiPoint(ARect.Left + ARect.Width, ARect.Top), 2, AColor);
end;

procedure TGuiCanvas.DrawChevron(const ARect: TGuiRect; const AColor: TGuiColor; AUp: Boolean);
var Y1, Y2: TGuiFloat;
begin
  Y1:=ARect.Top;
  Y2:=ARect.Top + ARect.Height;
  if AUp then
  begin
    Y1:=Y2;
    Y2:=ARect.Top;
  end;
  DrawLine(GuiPoint(ARect.Left, Y1), GuiPoint(ARect.Left + ARect.Width / 2, Y2), 2, AColor);
  DrawLine(GuiPoint(ARect.Left + ARect.Width / 2, Y2), GuiPoint(ARect.Left + ARect.Width, Y1), 2, AColor);
end;

procedure TGuiCanvas.DrawNineSlice(const ADrawable: TGuiDrawable; const ARect: TGuiRect);
var
  Src: TGuiRect;
  Slice: TGuiBox;
  SrcLeft: TGuiFloat;
  SrcCenterWidth: TGuiFloat;
  SrcRight: TGuiFloat;
  SrcTop: TGuiFloat;
  SrcCenterHeight: TGuiFloat;
  SrcBottom: TGuiFloat;
  DstLeft: TGuiFloat;
  DstCenterWidth: TGuiFloat;
  DstRight: TGuiFloat;
  DstTop: TGuiFloat;
  DstCenterHeight: TGuiFloat;
  DstBottom: TGuiFloat;
begin
  if NOT Assigned(ADrawable.Texture) then
    Exit;

  Src:=ADrawable.SourceRect;
  Slice:=ADrawable.Slice;

  if (Src.Width <= 0) OR (Src.Height <= 0) then
  begin
    DrawImage(ADrawable.Texture, ARect);
    Exit;
  end;

  SrcLeft:=Slice.Left;
  SrcRight:=Slice.Right;
  SrcTop:=Slice.Top;
  SrcBottom:=Slice.Bottom;
  SrcCenterWidth:=Src.Width - SrcLeft - SrcRight;
  SrcCenterHeight:=Src.Height - SrcTop - SrcBottom;

  DstLeft:=Slice.Left;
  DstRight:=Slice.Right;
  DstTop:=Slice.Top;
  DstBottom:=Slice.Bottom;

  if DstLeft + DstRight > ARect.Width then
  begin
    DstLeft:=ARect.Width / 2;
    DstRight:=ARect.Width - DstLeft;
  end;

  if DstTop + DstBottom > ARect.Height then
  begin
    DstTop:=ARect.Height / 2;
    DstBottom:=ARect.Height - DstTop;
  end;

  DstCenterWidth:=ARect.Width - DstLeft - DstRight;
  DstCenterHeight:=ARect.Height - DstTop - DstBottom;

  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left, Src.Top, SrcLeft, SrcTop),
    GuiRect(ARect.Left, ARect.Top, DstLeft, DstTop));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + SrcLeft, Src.Top, SrcCenterWidth, SrcTop),
    GuiRect(ARect.Left + DstLeft, ARect.Top, DstCenterWidth, DstTop));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + Src.Width - SrcRight, Src.Top, SrcRight, SrcTop),
    GuiRect(ARect.Left + ARect.Width - DstRight, ARect.Top, DstRight, DstTop));

  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left, Src.Top + SrcTop, SrcLeft, SrcCenterHeight),
    GuiRect(ARect.Left, ARect.Top + DstTop, DstLeft, DstCenterHeight));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + SrcLeft, Src.Top + SrcTop, SrcCenterWidth, SrcCenterHeight),
    GuiRect(ARect.Left + DstLeft, ARect.Top + DstTop, DstCenterWidth, DstCenterHeight));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + Src.Width - SrcRight, Src.Top + SrcTop, SrcRight, SrcCenterHeight),
    GuiRect(ARect.Left + ARect.Width - DstRight, ARect.Top + DstTop, DstRight, DstCenterHeight));

  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left, Src.Top + Src.Height - SrcBottom, SrcLeft, SrcBottom),
    GuiRect(ARect.Left, ARect.Top + ARect.Height - DstBottom, DstLeft, DstBottom));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + SrcLeft, Src.Top + Src.Height - SrcBottom, SrcCenterWidth, SrcBottom),
    GuiRect(ARect.Left + DstLeft, ARect.Top + ARect.Height - DstBottom,
      DstCenterWidth, DstBottom));
  DrawImagePart(ADrawable.Texture,
    GuiRect(Src.Left + Src.Width - SrcRight, Src.Top + Src.Height - SrcBottom,
      SrcRight, SrcBottom),
    GuiRect(ARect.Left + ARect.Width - DstRight,
      ARect.Top + ARect.Height - DstBottom, DstRight, DstBottom));
end;

procedure TGuiCanvas.DrawImagePart(ATexture: TGuiTexture; const ASourceRect, ADestRect: TGuiRect);
begin
  DrawImage(ATexture, ADestRect);
end;

procedure TGuiCanvas.DrawLine(const AStart, AEnd: TGuiPoint; AWidth: TGuiFloat; const AColor: TGuiColor);
var
  LeftValue: TGuiFloat;
  TopValue: TGuiFloat;
  LengthValue: TGuiFloat;
  I, Steps: Integer;
begin
  if AWidth <= 0 then
    Exit;

  if Abs(AStart.Y - AEnd.Y) < 0.01 then
  begin
    if AStart.X < AEnd.X then
    begin
      LeftValue:=AStart.X;
      LengthValue:=AEnd.X - AStart.X;
    end else
    begin
      LeftValue:=AEnd.X;
      LengthValue:=AStart.X - AEnd.X;
    end;

    FillRect(GuiRect(LeftValue, AStart.Y - (AWidth / 2), LengthValue, AWidth), AColor);
  end
  else
  if Abs(AStart.X - AEnd.X) < 0.01 then
  begin
    if AStart.Y < AEnd.Y then
    begin
      TopValue:=AStart.Y;
      LengthValue:=AEnd.Y - AStart.Y;
    end else
    begin
      TopValue:=AEnd.Y;
      LengthValue:=AStart.Y - AEnd.Y;
    end;

    FillRect(GuiRect(AStart.X - (AWidth / 2), TopValue, AWidth, LengthValue), AColor);
  end else
  begin
    Steps:=Ceil(Max(Abs(AEnd.X - AStart.X), Abs(AEnd.Y - AStart.Y)));
    for I:=0 to Steps do
      FillRect(GuiRect(AStart.X + (AEnd.X - AStart.X) * I / Steps - AWidth / 2,
        AStart.Y + (AEnd.Y - AStart.Y) * I / Steps - AWidth / 2, AWidth, AWidth), AColor);
  end;
end;

procedure TGuiCanvas.DrawBrush(const ABrush: TGuiBrush; const ARect: TGuiRect);
begin
  case ABrush.Kind of
    gbkColor:
      if ABrush.Color.A > 0 then
        FillRect(ARect, ABrush.Color);

    gbkTexture:
      DrawImage(ABrush.Texture, ARect);
  end;
end;

procedure TGuiCanvas.DrawDrawable(const ADrawable: TGuiDrawable; const ARect: TGuiRect);
begin
  case ADrawable.Kind of
    gdkLinearGradient: FillRoundedGradient(ARect, 0, ADrawable.Brush.Color, ADrawable.GradientEnd);
    gdkBrush: DrawBrush(ADrawable.Brush, ARect);
    gdkImage: DrawImagePart(ADrawable.Texture, ADrawable.SourceRect, ARect);
    gdkNineSlice: DrawNineSlice(ADrawable, ARect);
  end;
end;

function TGuiCanvas.MeasureText(const AText: String): TGuiSize;
begin
  Result:=GuiSize(0, 0);
end;

end.
