unit PasSDL3.GUI.Text;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TGuiUnicodeScalars = array of Cardinal;
  TGuiStringOffsets = array of Integer;
  TGuiDecodedText = record
  private
    FScalars: TGuiUnicodeScalars;
    FOffsets: TGuiStringOffsets;
  public
    property Scalars: TGuiUnicodeScalars read FScalars write FScalars;
    property Offsets: TGuiStringOffsets read FOffsets write FOffsets;
  end;

{ Read one scalar at a String offset, advancing Offset. Malformed encoding
  consumes one code unit as U+FFFD; an offset outside the text raises ERangeError. }
function GuiReadScalar(const S: String; var Offset: Integer): Cardinal;
{ Offsets includes the final Length(S), preserving exact source positions. }
function GuiDecodeText(const S: String): TGuiDecodedText;

// Indices are offsets into String (UTF-16 in Delphi, UTF-8 in FPC).
function GuiTextBoundary(const AText: String; AIndex: Integer): Integer;
function GuiTextPrevious(const AText: String; AIndex: Integer): Integer;
function GuiTextNext(const AText: String; AIndex: Integer): Integer;

implementation

uses SysUtils;

function GuiTextBoundary(const AText: String; AIndex: Integer): Integer;
begin
  Result:=AIndex;
  if Result < 0 then Result:=0;
  if Result > Length(AText) then Result:=Length(AText);
  if (Result = 0) OR (Result = Length(AText)) then Exit;
  {$IFDEF FPC}
  while (Result > 0) AND ((Ord(AText[Result + 1]) AND $C0) = $80) do
    Dec(Result);
  {$ELSE}
  if (Ord(AText[Result]) >= $D800) AND (Ord(AText[Result]) <= $DBFF) AND
    (Ord(AText[Result + 1]) >= $DC00) AND (Ord(AText[Result + 1]) <= $DFFF) then
    Dec(Result);
  {$ENDIF}
end;

function GuiTextPrevious(const AText: String; AIndex: Integer): Integer;
begin
  Result:=GuiTextBoundary(AText, AIndex - 1);
end;

function GuiTextNext(const AText: String; AIndex: Integer): Integer;
begin
  Result:=GuiTextBoundary(AText, AIndex) + 1;
  while (Result < Length(AText)) AND (GuiTextBoundary(AText, Result) <> Result) do
    Inc(Result);
  if Result > Length(AText) then Result:=Length(AText);
end;

function GuiReadScalar(const S: String; var Offset: Integer): Cardinal;
var First, C: Cardinal;
{$IFDEF FPC}
  N, I: Integer;
  Minimum: Cardinal;
{$ENDIF}
begin
  if (Offset < 0) OR (Offset >= Length(S)) then
    raise ERangeError.Create('Scalar offset is outside text');
  First:=Ord(S[Offset + 1]);
  Inc(Offset);
  Result:=First;
  {$IFDEF FPC}
  if First < $80 then Exit;
  Result:=$FFFD;
  if (First >= $C2) AND (First <= $DF) then
  begin
    N:=1;
    C:=First AND $1F;
    Minimum:=$80;
  end
  else if (First >= $E0) AND (First <= $EF) then
  begin
    N:=2;
    C:=First AND $0F;
    Minimum:=$800;
  end
  else if (First >= $F0) AND (First <= $F4) then
  begin
    N:=3;
    C:=First AND $07;
    Minimum:=$10000;
  end
  else Exit;
  if Offset + N > Length(S) then Exit;
  for I:=1 to N do
  begin
    First:=Ord(S[Offset + I]);
    if (First AND $C0) <> $80 then Exit;
    C:=(C SHL 6) OR (First AND $3F);
  end;
  if (C < Minimum) OR (C > $10FFFF) OR ((C >= $D800) AND (C <= $DFFF)) then Exit;
  Inc(Offset, N);
  Result:=C;
  {$ELSE}
  if (First >= $D800) AND (First <= $DBFF) AND (Offset < Length(S)) then
  begin
    C:=Ord(S[Offset + 1]);
    if (C >= $DC00) AND (C <= $DFFF) then
    begin
      Result:=$10000 + ((First - $D800) SHL 10) + C - $DC00;
      Inc(Offset);
      Exit;
    end;
  end;
  if (First >= $D800) AND (First <= $DFFF) then Result:=$FFFD;
  {$ENDIF}
end;

function GuiDecodeText(const S: String): TGuiDecodedText;
var Offset, Count: Integer;
begin
  SetLength(Result.FScalars,Length(S));
  SetLength(Result.FOffsets,Length(S)+1);
  Offset:=0;
  Count:=0;
  while Offset < Length(S) do
  begin
    Result.FOffsets[Count]:=Offset;
    Result.FScalars[Count]:=GuiReadScalar(S,Offset);
    Inc(Count);
  end;
  Result.FOffsets[Count]:=Offset;
  SetLength(Result.FScalars,Count);
  SetLength(Result.FOffsets,Count+1);
end;

end.
