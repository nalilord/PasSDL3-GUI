program TestLab;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
  {$IFNDEF FPC}
  Winapi.ActiveX,
  {$ENDIF}
  TestLab.App;

var
  App: TTestLab;
begin
  {$IFNDEF FPC}
  CoInitialize(nil);
  {$ENDIF}
  try
    try
      App:=TTestLab.Create;
      try
        if NOT App.Run then ExitCode:=1;
      finally
        App.Free;
      end;
    except
      on E: Exception do
      begin
        Writeln('TEST LAB ERROR: ', E.ClassName, ': ', E.Message);
        ExitCode:=1;
      end;
    end;
  finally
    {$IFNDEF FPC}
    CoUninitialize;
    {$ENDIF}
  end;
end.
