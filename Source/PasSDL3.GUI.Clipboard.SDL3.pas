unit PasSDL3.GUI.Clipboard.SDL3;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SDL3,
  PasSDL3.GUI.Clipboard;

implementation

function GuiSDL3ClipboardGetText: String;
var
  Text: PAnsiChar;
begin
  Result:='';
  Text:=SDL_GetClipboardText;
  if NOT Assigned(Text) then
    Exit;

  try
    Result:=String(UTF8String(Text));
  finally
    SDL_free(Text);
  end;
end;

procedure GuiSDL3ClipboardSetText(const AText: String);
var
  Text: UTF8String;
begin
  Text:=UTF8String(AText);
  SDL_SetClipboardText(PAnsiChar(Text));
end;

initialization
  GuiRegisterClipboardProvider(GuiSDL3ClipboardGetText, GuiSDL3ClipboardSetText);

finalization
  GuiRegisterClipboardProvider(nil, nil);

end.
