unit PasSDL3.GUI.Input.SDL3;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SDL3,
  PasSDL3.GUI.Types;

function GuiEventFromSDL3(const ASdlEvent: TSDL_Event; out AEvent: TGuiEvent): Boolean;

implementation

function MouseButtonFromSDL3(AButton: Byte): TGuiMouseButton;
begin
  Result:=gmbNone;

  case AButton of
    SDL_BUTTON_LEFT: Result:=gmbLeft;
    SDL_BUTTON_MIDDLE: Result:=gmbMiddle;
    SDL_BUTTON_RIGHT: Result:=gmbRight;
  end;
end;

function GuiEventFromSDL3(const ASdlEvent: TSDL_Event; out AEvent: TGuiEvent): Boolean;
begin
  Result:=True;

  AEvent.Kind:=gekNone;
  AEvent.Position:=GuiPoint(0, 0);
  AEvent.Delta:=GuiPoint(0, 0);
  AEvent.Button:=gmbNone;
  AEvent.Clicks:=0;
  AEvent.KeyCode:=0;
  AEvent.Modifiers:=[];
  AEvent.Text:='';
  AEvent.HasCompositionRange:=False;
  AEvent.CompositionStart:=-1;
  AEvent.CompositionLength:=-1;
  AEvent.Handled:=False;

  case ASdlEvent.type_ of
    SDL_EVENT_MOUSE_MOTION:
    begin
      AEvent.Kind:=gekMouseMove;
      AEvent.Position:=GuiPoint(ASdlEvent.motion.x, ASdlEvent.motion.y);
      AEvent.Delta:=GuiPoint(ASdlEvent.motion.xrel, ASdlEvent.motion.yrel);
    end;

    SDL_EVENT_MOUSE_BUTTON_DOWN:
    begin
      AEvent.Kind:=gekMouseDown;
      AEvent.Position:=GuiPoint(ASdlEvent.button.x, ASdlEvent.button.y);
      AEvent.Button:=MouseButtonFromSDL3(ASdlEvent.button.button);
      AEvent.Clicks:=ASdlEvent.button.clicks;
      if (SDL_GetModState AND SDL_KMOD_SHIFT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemShift];
      if (SDL_GetModState AND SDL_KMOD_CTRL) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemCtrl];
      if (SDL_GetModState AND SDL_KMOD_ALT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemAlt];
    end;

    SDL_EVENT_MOUSE_BUTTON_UP:
    begin
      AEvent.Kind:=gekMouseUp;
      AEvent.Position:=GuiPoint(ASdlEvent.button.x, ASdlEvent.button.y);
      AEvent.Button:=MouseButtonFromSDL3(ASdlEvent.button.button);
      AEvent.Clicks:=ASdlEvent.button.clicks;
    end;

    SDL_EVENT_MOUSE_WHEEL:
    begin
      AEvent.Kind:=gekMouseWheel;
      if (SDL_GetModState AND SDL_KMOD_SHIFT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemShift];
      AEvent.Position:=GuiPoint(ASdlEvent.wheel.mouse_x, ASdlEvent.wheel.mouse_y);
      AEvent.Delta:=GuiPoint(ASdlEvent.wheel.x, ASdlEvent.wheel.y);
      if ASdlEvent.wheel.direction = SDL_MOUSEWHEEL_FLIPPED then
        AEvent.Delta:=GuiPoint(-AEvent.Delta.X, -AEvent.Delta.Y);
    end;

    SDL_EVENT_KEY_DOWN:
    begin
      AEvent.Kind:=gekKeyDown;
      AEvent.KeyCode:=ASdlEvent.key.key;
      AEvent.KeyRepeat:=ASdlEvent.key.repeat_;
      if (ASdlEvent.key.mod_ AND SDL_KMOD_SHIFT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemShift];

      if (ASdlEvent.key.mod_ AND SDL_KMOD_CTRL) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemCtrl];

      if (ASdlEvent.key.mod_ AND SDL_KMOD_ALT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemAlt];
    end;

    SDL_EVENT_KEY_UP:
    begin
      AEvent.Kind:=gekKeyUp;
      AEvent.KeyCode:=ASdlEvent.key.key;
      if (ASdlEvent.key.mod_ AND SDL_KMOD_SHIFT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemShift];

      if (ASdlEvent.key.mod_ AND SDL_KMOD_CTRL) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemCtrl];

      if (ASdlEvent.key.mod_ AND SDL_KMOD_ALT) <> 0 then
        AEvent.Modifiers:=AEvent.Modifiers + [gemAlt];
    end;

    SDL_EVENT_TEXT_EDITING:
    begin
      AEvent.Kind:=gekTextEditing;
      AEvent.Text:=UTF8String(ASdlEvent.edit.text);
      AEvent.HasCompositionRange:=True;
      AEvent.CompositionStart:=ASdlEvent.edit.start;
      AEvent.CompositionLength:=ASdlEvent.edit.length;
    end;

    SDL_EVENT_TEXT_INPUT:
    begin
      AEvent.Kind:=gekTextInput;
      AEvent.Text:=UTF8String(ASdlEvent.text.text);
    end;

    SDL_EVENT_GAMEPAD_BUTTON_DOWN:
    begin
      AEvent.Kind:=gekGamepadButtonDown;
      AEvent.KeyCode:=ASdlEvent.gbutton.button;
    end;

    SDL_EVENT_GAMEPAD_BUTTON_UP:
    begin
      AEvent.Kind:=gekGamepadButtonUp;
      AEvent.KeyCode:=ASdlEvent.gbutton.button;
    end;

    SDL_EVENT_GAMEPAD_AXIS_MOTION:
    begin
      AEvent.Kind:=gekGamepadAxis;
      AEvent.KeyCode:=ASdlEvent.gaxis.axis;
      if ASdlEvent.gaxis.axis = 0 then
        AEvent.Delta:=GuiPoint(ASdlEvent.gaxis.value, 0)
      else
        AEvent.Delta:=GuiPoint(0, ASdlEvent.gaxis.value);
    end;

    else Result:=False;
  end;
end;

end.
