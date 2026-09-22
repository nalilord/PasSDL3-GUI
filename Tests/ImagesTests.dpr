program ImagesTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Controls.Images;

type
  TImageCanvas = class(TGuiCanvas)
  private
    FImageCount: Integer;
  public
    property ImageCount: Integer read FImageCount write FImageCount;
  private
    FClipDepth: Integer;
  public
    property ClipDepth: Integer read FClipDepth write FClipDepth;
  private
    FLastTexture: TGuiTexture;
  public
    property LastTexture: TGuiTexture read FLastTexture write FLastTexture;
  private
    FLastSource: TGuiRect;
  public
    property LastSource: TGuiRect read FLastSource write FLastSource;
  private
    FLastDest: TGuiRect;
  public
    property LastDest: TGuiRect read FLastDest write FLastDest;
  private
    FLastClip: TGuiRect;
  public
    property LastClip: TGuiRect read FLastClip write FLastClip;
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
    override;
    procedure DrawBorder(const ARect: TGuiRect; ABorderWidth: TGuiFloat;
      const AColor: TGuiColor);
      override;
    procedure DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect);
    override;
    procedure DrawImagePart(ATexture: TGuiTexture; const ASourceRect,
      ADestRect: TGuiRect);
      override;
    procedure DrawText(const AText: String; const ARect: TGuiRect;
      const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign;
      AVerticalAlign: TGuiVerticalTextAlign);
      override;
    procedure PushClipRect(const ARect: TGuiRect);
    override;
    procedure PopClipRect;
    override;
  end;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if NOT ACondition then
  begin
    WriteLn('FAIL: ', AMessage);
    Halt(1);
  end;
end;

function SameValue(AValue, AExpected: TGuiFloat): Boolean;
begin
  Result:=Abs(AValue - AExpected) < 0.01;
end;

procedure CheckRect(const ARect: TGuiRect; ALeft, ATop, AWidth,
  AHeight: TGuiFloat; const AMessage: String);
begin
  Check(SameValue(ARect.Left, ALeft) AND SameValue(ARect.Top, ATop) AND
    SameValue(ARect.Width, AWidth) AND SameValue(ARect.Height, AHeight),
    AMessage);
end;

procedure TImageCanvas.FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
begin
end;

procedure TImageCanvas.DrawBorder(const ARect: TGuiRect;
  ABorderWidth: TGuiFloat; const AColor: TGuiColor);
begin
end;

procedure TImageCanvas.DrawImage(ATexture: TGuiTexture; const ARect: TGuiRect);
begin
  Inc(FImageCount);
  LastTexture:=ATexture;
  LastDest:=ARect;
end;

procedure TImageCanvas.DrawImagePart(ATexture: TGuiTexture;
  const ASourceRect, ADestRect: TGuiRect);
begin
  Inc(FImageCount);
  LastTexture:=ATexture;
  LastSource:=ASourceRect;
  LastDest:=ADestRect;
end;

procedure TImageCanvas.DrawText(const AText: String; const ARect: TGuiRect;
  const AColor: TGuiColor; AHorizontalAlign: TGuiHorizontalTextAlign;
  AVerticalAlign: TGuiVerticalTextAlign);
begin
end;

procedure TImageCanvas.PushClipRect(const ARect: TGuiRect);
begin
  Inc(FClipDepth);
  LastClip:=ARect;
end;

procedure TImageCanvas.PopClipRect;
begin
  Dec(FClipDepth);
end;

var
  Canvas: TImageCanvas;
  ImageControl: TGuiImage;
  Icon: TGuiIcon;
  Texture: TGuiTexture;

begin
  Texture:=Pointer(NativeUInt($1234));
  Canvas:=TImageCanvas.Create;
  ImageControl:=TGuiImage.Create;
  Icon:=TGuiIcon.Create;
  try
    Check(NOT ImageControl.Enabled, 'images are passive by default');
    Check(ImageControl.Texture = nil, 'images start without an owned texture');
    ImageControl.Bounds:=GuiRect(10, 20, 100, 50);
    ImageControl.Padding:=GuiBox(2);
    ImageControl.Texture:=Texture;
    ImageControl.Paint(Canvas);
    Check((Canvas.ImageCount = 1) AND (Canvas.LastTexture = Texture),
      'image painting forwards the non-owning texture');
    CheckRect(Canvas.LastDest, 12, 22, 96, 46,
      'image painting honors control padding');

    Check(NOT Icon.Enabled, 'icons are passive by default');
    Icon.Bounds:=GuiRect(0, 0, 100, 100);
    Icon.Drawable:=GuiImageDrawable(Texture, GuiRect(0, 0, 200, 100));

    Icon.Fit:=gifStretch;
    Icon.Paint(Canvas);
    CheckRect(Canvas.LastDest, 0, 0, 100, 100,
      'stretch fills the destination');

    Icon.Fit:=gifContain;
    Icon.Paint(Canvas);
    CheckRect(Canvas.LastDest, 0, 25, 100, 50,
      'contain preserves aspect ratio inside the destination');

    Icon.Fit:=gifCover;
    Icon.Paint(Canvas);
    CheckRect(Canvas.LastDest, -50, 0, 200, 100,
      'cover preserves aspect ratio across the destination');
    CheckRect(Canvas.LastClip, 0, 0, 100, 100,
      'cover is clipped to the padded control rectangle');
    Check((Canvas.ClipDepth = 0) AND (Canvas.LastTexture = Texture),
      'icon clipping balances and preserves drawable texture/alpha dispatch');
  finally
    Icon.Free;
    ImageControl.Free;
    Canvas.Free;
  end;
  WriteLn('PASS: image ownership, padding, fit modes, drawable dispatch, and clipping');
end.
