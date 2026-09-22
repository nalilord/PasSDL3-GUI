unit PasSDL3.GUI.Fonts;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils,
  PasSDL3.GUI.Types;

type
  TGuiFontWeight = (
    gfwRegular,
    gfwMedium,
    gfwSemiBold,
    gfwBold
  );

  TGuiFontSlant = (
    gfsNormal,
    gfsItalic
  );

  TGuiFontSpec = record
  private
    FName: String;
    FFileName: String;
    FPointSize: Single;
    FWeight: TGuiFontWeight;
    FSlant: TGuiFontSlant;
    FCenterYOffset: TGuiFloat;
    FLineHeight: TGuiFloat;
  public
    property Name: String read FName write FName;
    property FileName: String read FFileName write FFileName;
    property PointSize: Single read FPointSize write FPointSize;
    property Weight: TGuiFontWeight read FWeight write FWeight;
    property Slant: TGuiFontSlant read FSlant write FSlant;
    property CenterYOffset: TGuiFloat read FCenterYOffset write FCenterYOffset;
    property LineHeight: TGuiFloat read FLineHeight write FLineHeight;
  end;

function GuiFontSpec(const AName, AFileName: String; APointSize: Single): TGuiFontSpec;
function GuiDefaultFontFile(AMonospace: Boolean = False): String;

implementation

function GuiDefaultFontFile(AMonospace: Boolean): String;
var
  Candidates: array[0..5] of String;
  I: Integer;
begin
  Result:=GetEnvironmentVariable('PASSDL3_GUI_FONT');
  if (Result <> '') AND FileExists(Result) then Exit;
  if AMonospace then
  begin
    Candidates[0]:=GetEnvironmentVariable('WINDIR') + '\Fonts\consola.ttf';
    Candidates[1]:='/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf';
    Candidates[2]:='/usr/share/fonts/truetype/liberation2/LiberationMono-Regular.ttf';
    Candidates[3]:='/System/Library/Fonts/Menlo.ttc';
    Candidates[5]:='/usr/share/fonts/liberation-fonts/LiberationMono-Regular.ttf';
  end else
  begin
    Candidates[0]:=GetEnvironmentVariable('WINDIR') + '\Fonts\segoeui.ttf';
    Candidates[1]:='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';
    Candidates[2]:='/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf';
    Candidates[3]:='/System/Library/Fonts/Helvetica.ttc';
    Candidates[5]:='/usr/share/fonts/liberation-fonts/LiberationSans-Regular.ttf';
  end;
  Candidates[4]:=ExtractFilePath(ParamStr(0)) + 'font.ttf';
  for I:=Low(Candidates) to High(Candidates) do
    if FileExists(Candidates[I]) then
    begin
      Result:=Candidates[I];
      Exit;
    end;
  raise Exception.Create('No GUI font found. Set PASSDL3_GUI_FONT or place font.ttf beside the executable.');
end;

function GuiFontSpec(const AName, AFileName: String; APointSize: Single): TGuiFontSpec;
begin
  Result.Name:=AName;
  Result.FileName:=AFileName;
  Result.PointSize:=APointSize;
  Result.Weight:=gfwRegular;
  Result.Slant:=gfsNormal;
  Result.CenterYOffset:=0;
  Result.LineHeight:=0;
end;

end.
