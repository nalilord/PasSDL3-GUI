program ImageCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Images;

var
  CoreImage: PasSDL3.GUI.Controls.TGuiImage;
  OwnedImage: PasSDL3.GUI.Controls.Images.TGuiImage;
  CoreIcon: PasSDL3.GUI.Controls.TGuiIcon;
  OwnedIcon: PasSDL3.GUI.Controls.Images.TGuiIcon;
  CoreFit: PasSDL3.GUI.Controls.TGuiImageFit;
  OwnedFit: PasSDL3.GUI.Controls.Images.TGuiImageFit;

begin
  OwnedImage:=PasSDL3.GUI.Controls.Images.TGuiImage.Create;
  OwnedIcon:=PasSDL3.GUI.Controls.Images.TGuiIcon.Create;
  try
    CoreImage:=OwnedImage;
    CoreIcon:=OwnedIcon;
    OwnedFit:=PasSDL3.GUI.Controls.Images.gifCover;
    CoreFit:=OwnedFit;
    if (CoreImage <> OwnedImage) OR (CoreIcon <> OwnedIcon) OR
      (CoreFit <> PasSDL3.GUI.Controls.gifCover) then
      Halt(1);
  finally
    OwnedIcon.Free;
    OwnedImage.Free;
  end;
  WriteLn('PASS: aggregate image compatibility aliases preserve exact type identity');
end.
