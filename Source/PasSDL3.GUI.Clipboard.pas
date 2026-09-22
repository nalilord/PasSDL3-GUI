unit PasSDL3.GUI.Clipboard;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TGuiClipboardGetTextFunc = function: String;
  TGuiClipboardSetTextProc = procedure(const AText: String);

procedure GuiRegisterClipboardProvider(AGetText: TGuiClipboardGetTextFunc; ASetText: TGuiClipboardSetTextProc);
function GuiClipboardGetText: String;
procedure GuiClipboardSetText(const AText: String);

implementation

var
  GuiClipboardGetTextFunc: TGuiClipboardGetTextFunc = nil;
  GuiClipboardSetTextProc: TGuiClipboardSetTextProc = nil;

procedure GuiRegisterClipboardProvider(AGetText: TGuiClipboardGetTextFunc; ASetText: TGuiClipboardSetTextProc);
begin
  GuiClipboardGetTextFunc:=AGetText;
  GuiClipboardSetTextProc:=ASetText;
end;

function GuiClipboardGetText: String;
begin
  Result:='';

  if Assigned(GuiClipboardGetTextFunc) then
    Result:=GuiClipboardGetTextFunc;
end;

procedure GuiClipboardSetText(const AText: String);
begin
  if Assigned(GuiClipboardSetTextProc) then
    GuiClipboardSetTextProc(AText);
end;

end.
