program ContextImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Context;

var
  Context: TGuiContext;
  LayerKind: TGuiLayerKind;

begin
  LayerKind:=glkDebug;
  if Ord(LayerKind) <> 4 then
    Halt(1);
  Context:=TGuiContext.Create;
  Context.Free;
  Pass('Context');
end.
