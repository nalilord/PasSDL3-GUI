program ImagesImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Images;

var
  Fit: TGuiImageFit;

begin
  Fit:=gifCover;
  if Ord(Fit) <> 2 then
    Halt(1);
  CheckControlClass(TGuiImage);
  CheckControlClass(TGuiIcon);
  Pass('Images');
end.
