program GraphemeTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses SysUtils, PasSDL3.GUI.Grapheme;
var Cases: Integer;

procedure CheckCase(const Scalars: array of Cardinal; const Expected: array of Integer);
var S: String;
U: UnicodeString;
Offsets, Actual: TGuiTextOffsets;
I: Integer;
C: Cardinal;
begin
  S:='';
  SetLength(Offsets, Length(Scalars) + 1);
  Offsets[0]:=0;
  for I:=0 to High(Scalars) do
  begin
    C:=Scalars[I];
    if C <= $FFFF then U:=WideChar(C)
    else
    begin
      C:=C - $10000;
      U:=UnicodeString(WideChar($D800 + (C SHR 10))) + WideChar($DC00 + (C AND $3FF));
    end;
    {$IFDEF FPC}
    S:=S + UTF8Encode(U);
    {$ELSE}
    S:=S + U;
    {$ENDIF}
    Offsets[I+1]:=Length(S);
  end;
  Actual:=GuiGraphemeBoundaries(S);
  Inc(Cases);
  if Length(Actual) <> Length(Expected) then
    raise Exception.CreateFmt('Case %d: expected %d boundaries, got %d', [Cases,Length(Expected),Length(Actual)]);
  for I:=0 to High(Expected) do
    if Actual[I] <> Offsets[Expected[I]] then
      raise Exception.CreateFmt('Case %d boundary %d: expected %d, got %d', [Cases,I,Offsets[Expected[I]],Actual[I]]);
end;

begin
  try
    {$I Unicode/GraphemeCases.inc}
    CheckCase([], [0]);
    Writeln('PASS: Unicode 17.0.0 grapheme conformance: ', Cases, ' cases');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      Halt(1);
    end;
  end;
end.
