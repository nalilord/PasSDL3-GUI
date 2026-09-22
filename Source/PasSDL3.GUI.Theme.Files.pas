unit PasSDL3.GUI.Theme.Files;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils,
  IniFiles,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Theme;

function GuiColorToHex(const AColor: TGuiColor): String;
function GuiColorFromHex(const AValue: String; const ADefault: TGuiColor): TGuiColor;
function GuiLoadThemeFromIni(const AFileName: String; const ABaseTheme: TGuiTheme): TGuiTheme;
procedure GuiSaveThemeToIni(const AFileName: String; const ATheme: TGuiTheme);

implementation

function GuiColorToHex(const AColor: TGuiColor): String;
begin
  Result:=Format('#%.2x%.2x%.2x%.2x', [AColor.R, AColor.G, AColor.B, AColor.A]);
end;

function GuiColorFromHex(const AValue: String; const ADefault: TGuiColor): TGuiColor;
var
  Value: String;
begin
  Result:=ADefault;
  Value:=Trim(AValue);

  if (Value <> '') AND (Value[1] = '#') then
    Delete(Value, 1, 1);

  if Length(Value) = 6 then
  begin
    Result.R:=StrToIntDef('$' + Copy(Value, 1, 2), ADefault.R);
    Result.G:=StrToIntDef('$' + Copy(Value, 3, 2), ADefault.G);
    Result.B:=StrToIntDef('$' + Copy(Value, 5, 2), ADefault.B);
    Result.A:=255;
  end else
  if Length(Value) = 8 then
  begin
    Result.R:=StrToIntDef('$' + Copy(Value, 1, 2), ADefault.R);
    Result.G:=StrToIntDef('$' + Copy(Value, 3, 2), ADefault.G);
    Result.B:=StrToIntDef('$' + Copy(Value, 5, 2), ADefault.B);
    Result.A:=StrToIntDef('$' + Copy(Value, 7, 2), ADefault.A);
  end;
end;

function ReadColor(AIni: TCustomIniFile; const AName: String; const ADefault: TGuiColor): TGuiColor;
begin
  Result:=GuiColorFromHex(AIni.ReadString('Colors', AName, GuiColorToHex(ADefault)), ADefault);
end;

function ReadBox(AIni: TCustomIniFile; const ASection, AName: String; const ADefault: TGuiBox): TGuiBox;
begin
  Result.Left:=AIni.ReadFloat(ASection, AName + 'Left', ADefault.Left);
  Result.Top:=AIni.ReadFloat(ASection, AName + 'Top', ADefault.Top);
  Result.Right:=AIni.ReadFloat(ASection, AName + 'Right', ADefault.Right);
  Result.Bottom:=AIni.ReadFloat(ASection, AName + 'Bottom', ADefault.Bottom);
end;

procedure WriteColor(AIni: TCustomIniFile; const AName: String; const AColor: TGuiColor);
begin
  AIni.WriteString('Colors', AName, GuiColorToHex(AColor));
end;

procedure WriteBox(AIni: TCustomIniFile; const ASection, AName: String; const ABox: TGuiBox);
begin
  AIni.WriteFloat(ASection, AName + 'Left', ABox.Left);
  AIni.WriteFloat(ASection, AName + 'Top', ABox.Top);
  AIni.WriteFloat(ASection, AName + 'Right', ABox.Right);
  AIni.WriteFloat(ASection, AName + 'Bottom', ABox.Bottom);
end;

function GuiLoadThemeFromIni(const AFileName: String; const ABaseTheme: TGuiTheme): TGuiTheme;
var
  Ini: TMemIniFile;
  Metrics: TGuiThemeMetrics;
  TextOffset: TGuiPoint;
begin
  Result:=ABaseTheme;
  Metrics:=Result.Metrics;
  TextOffset:=Result.ControlTextOffset;
  Ini:=TMemIniFile.Create(AFileName);
  try
    Result.WindowBackground:=ReadColor(Ini, 'WindowBackground', Result.WindowBackground);
    Result.PanelBackground:=ReadColor(Ini, 'PanelBackground', Result.PanelBackground);
    Result.PanelBorder:=ReadColor(Ini, 'PanelBorder', Result.PanelBorder);
    Result.SurfaceBackground:=ReadColor(Ini, 'SurfaceBackground', Result.SurfaceBackground);
    Result.CardBackground:=ReadColor(Ini, 'CardBackground', Result.CardBackground);
    Result.CardBorder:=ReadColor(Ini, 'CardBorder', Result.CardBorder);
    Result.ControlBackground:=ReadColor(Ini, 'ControlBackground', Result.ControlBackground);
    Result.ControlBorder:=ReadColor(Ini, 'ControlBorder', Result.ControlBorder);
    Result.PrimaryAccent:=ReadColor(Ini, 'PrimaryAccent', Result.PrimaryAccent);
    Result.SecondaryAccent:=ReadColor(Ini, 'SecondaryAccent', Result.SecondaryAccent);
    Result.FocusAccent:=ReadColor(Ini, 'FocusAccent', Result.FocusAccent);
    Result.Text:=ReadColor(Ini, 'Text', Result.Text);
    Result.MutedText:=ReadColor(Ini, 'MutedText', Result.MutedText);
    Result.PriceText:=ReadColor(Ini, 'PriceText', Result.PriceText);
    Result.SuccessText:=ReadColor(Ini, 'SuccessText', Result.SuccessText);

    TextOffset.X:=Ini.ReadFloat('Theme', 'ControlTextOffsetX', TextOffset.X);
    TextOffset.Y:=Ini.ReadFloat('Theme', 'ControlTextOffsetY', TextOffset.Y);
    Result.ControlTextOffset:=TextOffset;
    Result.ControlBorderWidth:=Ini.ReadFloat('Theme', 'ControlBorderWidth', Result.ControlBorderWidth);
    Result.SurfaceGradientStrength:=Ini.ReadFloat('Theme', 'SurfaceGradientStrength', Result.SurfaceGradientStrength);

    Metrics.Spacing:=Ini.ReadFloat('Metrics', 'Spacing', Metrics.Spacing);
    Metrics.SmallSpacing:=Ini.ReadFloat('Metrics', 'SmallSpacing', Metrics.SmallSpacing);
    Metrics.LargeSpacing:=Ini.ReadFloat('Metrics', 'LargeSpacing', Metrics.LargeSpacing);
    Metrics.ControlHeight:=Ini.ReadFloat('Metrics', 'ControlHeight', Metrics.ControlHeight);
    Metrics.CompactControlHeight:=Ini.ReadFloat('Metrics', 'CompactControlHeight', Metrics.CompactControlHeight);
    Metrics.ItemHeight:=Ini.ReadFloat('Metrics', 'ItemHeight', Metrics.ItemHeight);
    Metrics.RowHeight:=Ini.ReadFloat('Metrics', 'RowHeight', Metrics.RowHeight);
    Metrics.HeaderHeight:=Ini.ReadFloat('Metrics', 'HeaderHeight', Metrics.HeaderHeight);
    Metrics.LineHeight:=Ini.ReadFloat('Metrics', 'LineHeight', Metrics.LineHeight);
    Metrics.ScrollBarSize:=Ini.ReadFloat('Metrics', 'ScrollBarSize', Metrics.ScrollBarSize);
    Metrics.ControlCornerRadius:=Ini.ReadFloat('Metrics', 'ControlCornerRadius', Metrics.ControlCornerRadius);
    Metrics.PanelCornerRadius:=Ini.ReadFloat('Metrics', 'PanelCornerRadius', Metrics.PanelCornerRadius);
    Metrics.FocusWidth:=Ini.ReadFloat('Metrics', 'FocusWidth', Metrics.FocusWidth);
    Metrics.ControlPadding:=ReadBox(Ini, 'Metrics', 'ControlPadding', Metrics.ControlPadding);
    Metrics.TextPadding:=ReadBox(Ini, 'Metrics', 'TextPadding', Metrics.TextPadding);
    Metrics.ButtonPadding:=ReadBox(Ini, 'Metrics', 'ButtonPadding', Metrics.ButtonPadding);
    Metrics.CheckPadding:=ReadBox(Ini, 'Metrics', 'CheckPadding', Metrics.CheckPadding);
    Result.Metrics:=Metrics;
  finally
    Ini.Free;
  end;
end;

procedure GuiSaveThemeToIni(const AFileName: String; const ATheme: TGuiTheme);
var
  Ini: TMemIniFile;
begin
  Ini:=TMemIniFile.Create(AFileName);
  try
    WriteColor(Ini, 'WindowBackground', ATheme.WindowBackground);
    WriteColor(Ini, 'PanelBackground', ATheme.PanelBackground);
    WriteColor(Ini, 'PanelBorder', ATheme.PanelBorder);
    WriteColor(Ini, 'SurfaceBackground', ATheme.SurfaceBackground);
    WriteColor(Ini, 'CardBackground', ATheme.CardBackground);
    WriteColor(Ini, 'CardBorder', ATheme.CardBorder);
    WriteColor(Ini, 'ControlBackground', ATheme.ControlBackground);
    WriteColor(Ini, 'ControlBorder', ATheme.ControlBorder);
    WriteColor(Ini, 'PrimaryAccent', ATheme.PrimaryAccent);
    WriteColor(Ini, 'SecondaryAccent', ATheme.SecondaryAccent);
    WriteColor(Ini, 'FocusAccent', ATheme.FocusAccent);
    WriteColor(Ini, 'Text', ATheme.Text);
    WriteColor(Ini, 'MutedText', ATheme.MutedText);
    WriteColor(Ini, 'PriceText', ATheme.PriceText);
    WriteColor(Ini, 'SuccessText', ATheme.SuccessText);

    Ini.WriteFloat('Theme', 'ControlTextOffsetX', ATheme.ControlTextOffset.X);
    Ini.WriteFloat('Theme', 'ControlTextOffsetY', ATheme.ControlTextOffset.Y);
    Ini.WriteFloat('Theme', 'ControlBorderWidth', ATheme.ControlBorderWidth);
    Ini.WriteFloat('Theme', 'SurfaceGradientStrength', ATheme.SurfaceGradientStrength);

    Ini.WriteFloat('Metrics', 'Spacing', ATheme.Metrics.Spacing);
    Ini.WriteFloat('Metrics', 'SmallSpacing', ATheme.Metrics.SmallSpacing);
    Ini.WriteFloat('Metrics', 'LargeSpacing', ATheme.Metrics.LargeSpacing);
    Ini.WriteFloat('Metrics', 'ControlHeight', ATheme.Metrics.ControlHeight);
    Ini.WriteFloat('Metrics', 'CompactControlHeight', ATheme.Metrics.CompactControlHeight);
    Ini.WriteFloat('Metrics', 'ItemHeight', ATheme.Metrics.ItemHeight);
    Ini.WriteFloat('Metrics', 'RowHeight', ATheme.Metrics.RowHeight);
    Ini.WriteFloat('Metrics', 'HeaderHeight', ATheme.Metrics.HeaderHeight);
    Ini.WriteFloat('Metrics', 'LineHeight', ATheme.Metrics.LineHeight);
    Ini.WriteFloat('Metrics', 'ScrollBarSize', ATheme.Metrics.ScrollBarSize);
    Ini.WriteFloat('Metrics', 'ControlCornerRadius', ATheme.Metrics.ControlCornerRadius);
    Ini.WriteFloat('Metrics', 'PanelCornerRadius', ATheme.Metrics.PanelCornerRadius);
    Ini.WriteFloat('Metrics', 'FocusWidth', ATheme.Metrics.FocusWidth);
    WriteBox(Ini, 'Metrics', 'ControlPadding', ATheme.Metrics.ControlPadding);
    WriteBox(Ini, 'Metrics', 'TextPadding', ATheme.Metrics.TextPadding);
    WriteBox(Ini, 'Metrics', 'ButtonPadding', ATheme.Metrics.ButtonPadding);
    WriteBox(Ini, 'Metrics', 'CheckPadding', ATheme.Metrics.CheckPadding);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
