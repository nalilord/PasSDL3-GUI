unit PasSDL3.GUI.Controls.Images;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core;

type
  TGuiImageFit = (
    gifStretch,
    gifContain,
    gifCover
  );

  TGuiImage = class(TGuiControl)
  private
    FTexture: TGuiTexture;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property Texture: TGuiTexture read FTexture write FTexture;
  end;

  TGuiIcon = class(TGuiControl)
  private
    FDrawable: TGuiDrawable;
    FFit: TGuiImageFit;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    property Drawable: TGuiDrawable read FDrawable write FDrawable;
    property Fit: TGuiImageFit read FFit write FFit;
  end;

implementation

function GuiFitRect(const ASourceSize: TGuiSize; const ADestRect: TGuiRect;
  AFit: TGuiImageFit): TGuiRect;
var
  SourceRatio: TGuiFloat;
  DestRatio: TGuiFloat;
begin
  Result:=ADestRect;
  if (ASourceSize.Width <= 0) OR (ASourceSize.Height <= 0) OR
    (ADestRect.Width <= 0) OR (ADestRect.Height <= 0) then
    Exit;
  if AFit = gifStretch then
    Exit;

  SourceRatio:=ASourceSize.Width / ASourceSize.Height;
  DestRatio:=ADestRect.Width / ADestRect.Height;
  if ((AFit = gifContain) AND (SourceRatio > DestRatio)) OR
    ((AFit = gifCover) AND (SourceRatio < DestRatio)) then
  begin
    Result.Width:=ADestRect.Width;
    Result.Height:=ADestRect.Width / SourceRatio;
  end else
  begin
    Result.Height:=ADestRect.Height;
    Result.Width:=ADestRect.Height * SourceRatio;
  end;
  Result.Left:=ADestRect.Left + ((ADestRect.Width - Result.Width) / 2);
  Result.Top:=ADestRect.Top + ((ADestRect.Height - Result.Height) / 2);
end;

constructor TGuiImage.Create;
begin
  inherited Create;
  Enabled:=False;
  FTexture:=nil;
end;

procedure TGuiImage.PaintSelf(ACanvas: TGuiCanvas);
begin
  inherited PaintSelf(ACanvas);
  ACanvas.DrawImage(FTexture, GuiInflateRect(AbsoluteBounds, Padding));
end;

constructor TGuiIcon.Create;
begin
  inherited Create;
  Enabled:=False;
  FDrawable:=GuiEmptyDrawable;
  FFit:=gifContain;
  Padding:=GuiBox(0);
end;

procedure TGuiIcon.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  SourceSize: TGuiSize;
begin
  inherited PaintSelf(ACanvas);
  Rect:=GuiInflateRect(AbsoluteBounds, Padding);
  SourceSize:=GuiSize(FDrawable.SourceRect.Width, FDrawable.SourceRect.Height);
  ACanvas.PushClipRect(Rect);
  try
    ACanvas.DrawDrawable(FDrawable, GuiFitRect(SourceSize, Rect, FFit));
  finally
    ACanvas.PopClipRect;
  end;
end;

end.
