program PlatformProbe;
{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}
uses SysUtils, SDL3;
var
  Displays, Display: PSDL_DisplayID;
  Gamepads: PSDL_JoystickID;
  Count, I, Created: Integer;
  Rect: TSDL_Rect;
  Cursor: PSDL_Cursor;
  Driver: String;
const
  Cursors: array[0..7] of TSDL_SystemCursor = (
    SDL_SYSTEM_CURSOR_DEFAULT, SDL_SYSTEM_CURSOR_TEXT, SDL_SYSTEM_CURSOR_POINTER,
    SDL_SYSTEM_CURSOR_MOVE, SDL_SYSTEM_CURSOR_EW_RESIZE, SDL_SYSTEM_CURSOR_NS_RESIZE,
    SDL_SYSTEM_CURSOR_NWSE_RESIZE, SDL_SYSTEM_CURSOR_NESW_RESIZE);
begin
  Writeln('Platform capability probe ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  Writeln('SDL runtime version: ', SDL_GetVersion);
  if NOT SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD) then
  begin
    Writeln('UNAVAILABLE: ', String(SDL_GetError));
    Halt(2);
  end;
  try
    Driver:=String(SDL_GetCurrentVideoDriver);
    Writeln('Video driver: ', Driver);
    if (Driver = 'dummy') OR (Driver = 'offscreen') then
      Writeln('NOT NATIVE VALIDATION: synthetic/offscreen driver');
    Displays:=SDL_GetDisplays(@Count);
    try
      Writeln('Displays reported by driver: ', Count);
      Display:=Displays;
      for I:=0 to Count - 1 do
      begin
        if SDL_GetDisplayBounds(Display^, @Rect) then
          Writeln('Display ', I, ': ', Rect.w, 'x', Rect.h, ' at ', Rect.x, ',', Rect.y,
            '; content scale ', SDL_GetDisplayContentScale(Display^):0:2);
        Inc(Display);
      end;
    finally
      SDL_free(Displays);
    end;
    Gamepads:=SDL_GetGamepads(@Count);
    try
      Writeln('Connected gamepads reported by driver: ', Count);
    finally
      SDL_free(Gamepads);
    end;
    Created:=0;
    for I:=Low(Cursors) to High(Cursors) do
    begin
      Cursor:=SDL_CreateSystemCursor(Cursors[I]);
      if Assigned(Cursor) then
      begin
        Inc(Created);
        SDL_DestroyCursor(Cursor);
      end;
    end;
    Writeln('System cursor creation supported: ', Created, '/8');
    Writeln('Clipboard advertises text: ', BoolToStr(SDL_HasClipboardText, True));
    Writeln('Clipboard content was neither read nor changed.');
    Writeln('PENDING: cross-application clipboard, real IME candidate/commit,');
    Writeln('physical controller unplug/replug, native cursor appearance, mixed-DPI window movement.');
    Writeln('Capabilities are observations, not PASS results for those interactions.');
  finally
    SDL_Quit;
  end;
end.
