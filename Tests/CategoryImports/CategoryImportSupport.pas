unit CategoryImportSupport;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  PasSDL3.GUI.Controls.Base;

type
  TGuiControlClass = class of TGuiControl;

procedure CheckControlClass(AClass: TGuiControlClass);
procedure Pass(const ACategory: String);

implementation

procedure CheckControlClass(AClass: TGuiControlClass);
var
  Instance: TGuiControl;
begin
  Instance:=AClass.Create;
  Instance.Free;
end;

procedure Pass(const ACategory: String);
begin
  WriteLn('PASS: standalone ', ACategory, ' category import');
end;

end.
