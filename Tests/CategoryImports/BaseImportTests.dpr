program BaseImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Base;

var
  Layout: TGuiLayoutState;
  NotifyEvent: TGuiNotifyEvent;
  MouseEvent: TGuiMouseEvent;
  FocusEvent: TGuiFocusChangedEvent;

begin
  FillChar(Layout, SizeOf(Layout), 0);
  NotifyEvent:=nil;
  MouseEvent:=nil;
  FocusEvent:=nil;
  CheckControlClass(TGuiControl);
  CheckControlClass(TGuiContainer);
  CheckControlClass(TGuiPopupControl);
  Pass('Base');
end.
