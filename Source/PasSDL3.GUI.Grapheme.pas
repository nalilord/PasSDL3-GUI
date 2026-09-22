unit PasSDL3.GUI.Grapheme;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

type
  TGuiTextOffsets = array of Integer;
  TGuiGraphemeMap = record
  private
    FText: String;
    FOffsets: TGuiTextOffsets;
    function Locate(const AText: String; AIndex: Integer): Integer;
  public
    function Boundary(const AText: String; AIndex: Integer): Integer;
    function Previous(const AText: String; AIndex: Integer): Integer;
    function Next(const AText: String; AIndex: Integer): Integer;
  end;

{ Unicode 17.0.0 extended grapheme boundaries, as String offsets (UTF-8 FPC,
  UTF-16 Delphi). Includes 0 and Length; empty text returns just [0].
  Malformed encoding consumes one code unit as U+FFFD, never skips data. }
function GuiGraphemeBoundaries(const AText: String): TGuiTextOffsets;

implementation

uses PasSDL3.GUI.Text;

type
  TUnicodeRange = record
  private
    FLo: Cardinal;
    FHi: Cardinal;
    FValue: Byte;
  public
    property Lo: Cardinal read FLo write FLo;
    property Hi: Cardinal read FHi write FHi;
    property Value: Byte read FValue write FValue;
  end;

{$I PasSDL3.GUI.Grapheme.Data.inc}

const
  gpCR = 1;
  gpLF = 2;
  gpControl = 3;
  gpExtend = 4;
  gpZWJ = 5;
  gpRI = 6;
  gpPrepend = 7;
  gpSpacingMark = 8;
  gpL = 9;
  gpV = 10;
  gpT = 11;
  gpLV = 12;
  gpLVT = 13;

function PropertyOf(C: Cardinal; const Ranges: array of TUnicodeRange): Byte;
var L, H, M: Integer;
begin
  L:=0;
  H:=High(Ranges);
  while L <= H do
  begin
    M:=L + (H - L) DIV 2;
    if C < Ranges[M].Lo then H:=M - 1
    else if C > Ranges[M].Hi then L:=M + 1
    else
    begin
      Result:=Ranges[M].Value;
      Exit;
    end;
  end;
  Result:=0;
end;

function GuiGraphemeBoundaries(const AText: String): TGuiTextOffsets;
var
  Offset, Start, Count, RIParity: Integer;
  C: Cardinal;
  Previous, Current, Indic, IndicState: Byte;
  Pictographic, EmojiExtend, PreviousEmojiZWJ, BreakHere, First: Boolean;
begin
  Result:=nil;
  SetLength(Result, Length(AText) + 1);
  Result[0]:=0;
  Count:=1;
  Offset:=0;
  Previous:=0;
  RIParity:=0;
  IndicState:=0;
  EmojiExtend:=False;
  PreviousEmojiZWJ:=False;
  First:=True;
  while Offset < Length(AText) do
  begin
    Start:=Offset;
    C:=GuiReadScalar(AText, Offset);
    Current:=PropertyOf(C, GraphemeProperties);
    Indic:=PropertyOf(C, IndicProperties);
    Pictographic:=PropertyOf(C, PictographicProperties) <> 0;
    BreakHere:=NOT First;
    if (Previous = gpCR) AND (Current = gpLF) then BreakHere:=False
    else if (Previous IN [gpCR,gpLF,gpControl]) OR (Current IN [gpCR,gpLF,gpControl]) then
      BreakHere:=NOT First
    else if (Previous = gpL) AND (Current IN [gpL,gpV,gpLV,gpLVT]) then BreakHere:=False
    else if (Previous IN [gpLV,gpV]) AND (Current IN [gpV,gpT]) then BreakHere:=False
    else if (Previous IN [gpLVT,gpT]) AND (Current = gpT) then BreakHere:=False
    else if Current IN [gpExtend,gpZWJ,gpSpacingMark] then BreakHere:=False
    else if Previous = gpPrepend then BreakHere:=False
    else if (Indic = 1) AND (IndicState = 2) then BreakHere:=False
    else if Pictographic AND PreviousEmojiZWJ then BreakHere:=False
    else if (Previous = gpRI) AND (Current = gpRI) AND (RIParity = 1) then BreakHere:=False;
    if BreakHere then
    begin
      Result[Count]:=Start;
      Inc(Count);
    end;

    { GB9c state: consonant, followed by extends/linkers, at least one linker. }
    if Indic = 1 then IndicState:=1
    else if (Indic = 3) AND (IndicState <> 0) then IndicState:=2
    else if Indic <> 2 then IndicState:=0;
    { GB11: Extended_Pictographic Extend* ZWJ. }
    PreviousEmojiZWJ:=(Current = gpZWJ) AND EmojiExtend;
    if Pictographic then EmojiExtend:=True
    else if Current <> gpExtend then EmojiExtend:=False;
    if Current = gpRI then RIParity:=1 - RIParity else RIParity:=0;
    Previous:=Current;
    First:=False;
  end;
  if Length(AText) > 0 then
  begin
    Result[Count]:=Length(AText);
    Inc(Count);
  end;
  SetLength(Result, Count);
end;

function TGuiGraphemeMap.Locate(const AText: String; AIndex: Integer): Integer;
var L, H, M: Integer;
begin
  if (FOffsets = nil) OR (FText <> AText) then
  begin
    FOffsets:=GuiGraphemeBoundaries(AText);
    FText:=AText;
  end;
  L:=0;
  H:=High(FOffsets);
  while L <= H do
  begin
    M:=L + (H - L) DIV 2;
    if FOffsets[M] <= AIndex then L:=M + 1 else H:=M - 1;
  end;
  Result:=H;
  if Result < 0 then Result:=0;
end;

function TGuiGraphemeMap.Boundary(const AText: String; AIndex: Integer): Integer;
var I: Integer;
begin
  I:=Locate(AText, AIndex);
  Result:=FOffsets[I];
end;

function TGuiGraphemeMap.Previous(const AText: String; AIndex: Integer): Integer;
var I: Integer;
begin
  if AIndex > Length(AText) then AIndex:=Length(AText);
  if AIndex > 0 then Dec(AIndex);
  I:=Locate(AText, AIndex);
  Result:=FOffsets[I];
end;

function TGuiGraphemeMap.Next(const AText: String; AIndex: Integer): Integer;
var I: Integer;
begin
  I:=Locate(AText, AIndex);
  if I < High(FOffsets) then Inc(I);
  Result:=FOffsets[I];
end;

end.
