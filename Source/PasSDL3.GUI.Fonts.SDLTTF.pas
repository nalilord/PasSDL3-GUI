unit PasSDL3.GUI.Fonts.SDLTTF;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils,
  SDL3,
  SDL3_ttf,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Fonts;

type
  TGuiTextCacheEntry = record
  private
    FText: String;
    FColor: TGuiColor;
    FRenderer: PSDL_Renderer;
    FSurface: PSDL_Surface;
    FTexture: PSDL_Texture;
  public
    property Text: String read FText write FText;
    property Color: TGuiColor read FColor write FColor;
    property Renderer: PSDL_Renderer read FRenderer write FRenderer;
    property Surface: PSDL_Surface read FSurface write FSurface;
    property Texture: PSDL_Texture read FTexture write FTexture;
  end;

  TGuiSDLTTFFontEntry = record
  private
    FName: String;
    FRenderer: TObject;
    FOwnsRenderer: Boolean;
  public
    property Name: String read FName write FName;
    property Renderer: TObject read FRenderer write FRenderer;
    property OwnsRenderer: Boolean read FOwnsRenderer write FOwnsRenderer;
  end;

  TGuiSDLTTFFontRenderer = class
  private
    class var FTTFRefCount: Integer;
  private
    FFont: PTTF_Font;
    FAcquiredTTF: Boolean;
    FCache: array[0..127] of TGuiTextCacheEntry;
    FNextCache: Integer;
    FCacheHits: UInt64;
    FVisualTop, FVisualHeight: TGuiFloat;
    FVisualMeasured: Boolean;
    FSpec: TGuiFontSpec;
    FCenterYOffset: TGuiFloat;
    FMetricsRevision: UInt64;
    class procedure AcquireTTF;
    class procedure ReleaseTTF;
    function ToSDLColor(const AColor: TGuiColor): TSDL_Color;
    function GetTextVisualBounds(const AText: String; ASurfaceHeight: Integer; out ATop, AHeight: TGuiFloat): Boolean;
  public
    constructor Create(const AFontFile: String; APointSize: Single); overload;
    constructor Create(const ASpec: TGuiFontSpec); overload;
    destructor Destroy; override;
    procedure ClearCache;
    function MeasureText(const AText: String): TGuiSize;
    function MeasureLineHeight: TGuiFloat;
    function TextOrigin(const ASize: TGuiSize; const ARect: TGuiRect;
      AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign): TGuiPoint;
    procedure DrawText(ARenderer: PSDL_Renderer; const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
      AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign);
    property Font: PTTF_Font read FFont;
    property Spec: TGuiFontSpec read FSpec;
    property CenterYOffset: TGuiFloat read FCenterYOffset write FCenterYOffset;
    property CacheHits: UInt64 read FCacheHits;
    property MetricsRevision: UInt64 read FMetricsRevision;
  end;

  TGuiSDLTTFFontCollection = class
  private
    FEntries: array of TGuiSDLTTFFontEntry;
    FCount: Integer;
    FDefaultFont: TGuiSDLTTFFontRenderer;
    function GetFontByName(const AName: String): TGuiSDLTTFFontRenderer;
  public
    destructor Destroy; override;
    function AddFont(const ASpec: TGuiFontSpec): TGuiSDLTTFFontRenderer; overload;
    procedure AddFont(const AName: String; ARenderer: TGuiSDLTTFFontRenderer; AOwnsRenderer: Boolean = True); overload;
    function FindFont(const AName: String): TGuiSDLTTFFontRenderer;
    property DefaultFont: TGuiSDLTTFFontRenderer read FDefaultFont write FDefaultFont;
    property Fonts[const AName: String]: TGuiSDLTTFFontRenderer read GetFontByName; default;
  end;

implementation

uses Math;

class procedure TGuiSDLTTFFontRenderer.AcquireTTF;
begin
  if FTTFRefCount = 0 then
  begin
    if NOT TTF_Init then
      raise Exception.CreateFmt('TTF_Init failed: %s', [String(SDL_GetError)]);
  end;

  Inc(FTTFRefCount);
end;

class procedure TGuiSDLTTFFontRenderer.ReleaseTTF;
begin
  if FTTFRefCount <= 0 then
    Exit;

  Dec(FTTFRefCount);

  if FTTFRefCount = 0 then
    TTF_Quit;
end;

constructor TGuiSDLTTFFontRenderer.Create(const AFontFile: String; APointSize: Single);
begin
  Create(GuiFontSpec('', AFontFile, APointSize));
end;

constructor TGuiSDLTTFFontRenderer.Create(const ASpec: TGuiFontSpec);
var
  FontFile: UTF8String;
begin
  inherited Create;
  FSpec:=ASpec;
  FCenterYOffset:=ASpec.CenterYOffset;

  AcquireTTF;
  FAcquiredTTF:=True;
  FontFile:=UTF8String(ASpec.FileName);
  FFont:=TTF_OpenFont(PAnsiChar(FontFile), ASpec.PointSize);

  if NOT Assigned(FFont) then
  begin
    raise Exception.CreateFmt('TTF_OpenFont failed for "%s": %s', [ASpec.FileName, String(SDL_GetError)]);
  end;
end;

destructor TGuiSDLTTFFontRenderer.Destroy;
begin
  ClearCache;
  if Assigned(FFont) then
  begin
    TTF_CloseFont(FFont);
    FFont:=nil;
  end;

  if FAcquiredTTF then
    ReleaseTTF;

  inherited Destroy;
end;

procedure TGuiSDLTTFFontRenderer.ClearCache;
var
  I: Integer;
begin
  FVisualMeasured:=False;
  Inc(FMetricsRevision);
  for I:=Low(FCache) to High(FCache) do
  begin
    if Assigned(FCache[I].Texture) then SDL_DestroyTexture(FCache[I].Texture);
    if Assigned(FCache[I].Surface) then SDL_DestroySurface(FCache[I].Surface);
    FCache[I]:=Default(TGuiTextCacheEntry);
  end;
end;

function TGuiSDLTTFFontRenderer.ToSDLColor(const AColor: TGuiColor): TSDL_Color;
begin
  Result.r:=AColor.R;
  Result.g:=AColor.G;
  Result.b:=AColor.B;
  Result.a:=AColor.A;
end;

function TGuiSDLTTFFontRenderer.GetTextVisualBounds(const AText: String; ASurfaceHeight: Integer; out ATop, AHeight: TGuiFloat): Boolean;
var
  I: Integer;
  CodePoint: Cardinal;
  HighSurrogate: Word;
  LowSurrogate: Word;
  MinX: Integer;
  MaxX: Integer;
  MinY: Integer;
  MaxY: Integer;
  Advance: Integer;
  Ascent: Integer;
  TopValue: TGuiFloat;
  BottomValue: TGuiFloat;
  GlyphTop: TGuiFloat;
  GlyphBottom: TGuiFloat;
begin
  Result:=False;
  ATop:=0;
  AHeight:=ASurfaceHeight;

  if (AText = '') OR (NOT Assigned(FFont)) then
    Exit;

  Ascent:=TTF_GetFontAscent(FFont);
  TopValue:=ASurfaceHeight;
  BottomValue:=0;
  I:=1;

  while I <= Length(AText) do
  begin
    CodePoint:=Ord(AText[I]);

    if (CodePoint >= $D800) AND (CodePoint <= $DBFF) AND (I < Length(AText)) then
    begin
      HighSurrogate:=Word(CodePoint);
      LowSurrogate:=Word(Ord(AText[I + 1]));
      if (LowSurrogate >= $DC00) AND (LowSurrogate <= $DFFF) then
      begin
        CodePoint:=$10000 + (((HighSurrogate - $D800) SHL 10) OR (LowSurrogate - $DC00));
        Inc(I);
      end;
    end;

    MinX:=0;
    MaxX:=0;
    MinY:=0;
    MaxY:=0;
    Advance:=0;

    if TTF_GetGlyphMetrics(FFont, CodePoint, @MinX, @MaxX, @MinY, @MaxY, @Advance) then
    begin
      GlyphTop:=Ascent - MaxY;
      GlyphBottom:=Ascent - MinY;

      if GlyphTop < TopValue then
        TopValue:=GlyphTop;

      if GlyphBottom > BottomValue then
        BottomValue:=GlyphBottom;

      Result:=True;
    end;

    Inc(I);
  end;

  if Result then
  begin
    if TopValue < 0 then
      TopValue:=0;

    if BottomValue > ASurfaceHeight then
      BottomValue:=ASurfaceHeight;

    if BottomValue <= TopValue then
    begin
      ATop:=0;
      AHeight:=ASurfaceHeight;
      Result:=False;
    end else
    begin
      ATop:=TopValue;
      AHeight:=BottomValue - TopValue;
    end;
  end;
end;

function TGuiSDLTTFFontRenderer.MeasureText(const AText: String): TGuiSize;
var
  Text: UTF8String;
  Width: Integer;
  Height: Integer;
begin
  Result:=GuiSize(0, 0);

  if (AText = '') OR (NOT Assigned(FFont)) then
    Exit;

  Text:=UTF8String(AText);
  Width:=0;
  Height:=0;

  if TTF_GetStringSize(FFont, PAnsiChar(Text), Length(Text), @Width, @Height) then
    Result:=GuiSize(Width, Height);
end;

function TGuiSDLTTFFontRenderer.MeasureLineHeight: TGuiFloat;
begin
  Result:=0;

  if Assigned(FFont) then
    Result:=TTF_GetFontHeight(FFont);
end;

function TGuiSDLTTFFontRenderer.TextOrigin(const ASize: TGuiSize; const ARect: TGuiRect;
  AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign): TGuiPoint;
begin
  case AHorizontalAlign of
    ghtaCenter: Result.X:=ARect.Left + (ARect.Width - ASize.Width) / 2;
    ghtaRight: Result.X:=ARect.Left + ARect.Width - ASize.Width;
    else Result.X:=ARect.Left;
  end;
  case AVerticalAlign of
    gvtaTop: Result.Y:=ARect.Top;
    gvtaBottom: Result.Y:=ARect.Top + ARect.Height - ASize.Height;
    else
    begin
      if (NOT FVisualMeasured) AND Assigned(FFont) then
      begin
        { A shared cap-height reference keeps labels on the same baseline,
          without letting descenders push ordinary button captions upwards. }
        GetTextVisualBounds('H', TTF_GetFontHeight(FFont), FVisualTop, FVisualHeight);
        FVisualMeasured:=True;
      end;
      if FVisualHeight > 0 then
        Result.Y:=ARect.Top + (ARect.Height - FVisualHeight) / 2 - FVisualTop + FCenterYOffset
      else Result.Y:=ARect.Top + (ARect.Height - ASize.Height) / 2 + FCenterYOffset;
    end;
  end;
  if Result.X < ARect.Left then Result.X:=ARect.Left;
  { Round halves consistently: banker's rounding alternates with pixel parity. }
  Result.X:=Floor(Result.X + 0.5);
  Result.Y:=Floor(Result.Y + 0.5);
end;

procedure TGuiSDLTTFFontRenderer.DrawText(ARenderer: PSDL_Renderer; const AText: String; const ARect: TGuiRect; const AColor: TGuiColor;
  AHorizontalAlign: TGuiHorizontalTextAlign; AVerticalAlign: TGuiVerticalTextAlign);
var
  Text: UTF8String;
  Color: TSDL_Color;
  Surface: PSDL_Surface;
  Texture: PSDL_Texture;
  DestRect: TSDL_FRect;
  ClipEnabled: Boolean;
  OldClipRect: TSDL_Rect;
  NewClipRect: TSDL_Rect;
  LeftValue: Integer;
  TopValue: Integer;
  RightValue: Integer;
  BottomValue: Integer;
  OldRight: Integer;
  OldBottom: Integer;
  Origin: TGuiPoint;
  I: Integer;
  Cached: Boolean;
begin
  if (AText = '') OR (NOT Assigned(FFont)) OR (NOT Assigned(ARenderer)) then
    Exit;

  Text:=UTF8String(AText);
  Color:=ToSDLColor(AColor);
  Surface:=nil;
  Texture:=nil;
  Cached:=False;
  for I:=Low(FCache) to High(FCache) do
    if (FCache[I].Text = AText) AND (FCache[I].Renderer = ARenderer) AND
      CompareMem(@FCache[I].Color, @AColor, SizeOf(AColor)) then
    begin
      Surface:=FCache[I].Surface;
      Texture:=FCache[I].Texture;
      Cached:=True;
      Inc(FCacheHits);
      Break;
    end;
  if NOT Cached then
    Surface:=TTF_RenderText_Blended(FFont, PAnsiChar(Text), Length(Text), Color);

  if NOT Assigned(Surface) then
    Exit;

  try
    if NOT Cached then
      Texture:=SDL_CreateTextureFromSurface(ARenderer, Surface);
    if NOT Assigned(Texture) then
      Exit;

    SDL_SetTextureScaleMode(Texture, SDL_SCALEMODE_NEAREST);

    // Bound retained CPU and GPU memory; unusually large strings remain transient.
    if (NOT Cached) AND (Int64(Surface.w) * Surface.h <= 65536) then
    begin
      I:=FNextCache;
      FNextCache:=(FNextCache + 1) MOD Length(FCache);
      if Assigned(FCache[I].Texture) then SDL_DestroyTexture(FCache[I].Texture);
      if Assigned(FCache[I].Surface) then SDL_DestroySurface(FCache[I].Surface);
      FCache[I].Text:=AText;
      FCache[I].Color:=AColor;
      FCache[I].Renderer:=ARenderer;
      FCache[I].Surface:=Surface;
      FCache[I].Texture:=Texture;
      Cached:=True;
    end;

    DestRect.w:=Surface.w;
    DestRect.h:=Surface.h;

    Origin:=TextOrigin(GuiSize(Surface.w, Surface.h), ARect, AHorizontalAlign, AVerticalAlign);
    DestRect.x:=Origin.X;
    DestRect.y:=Origin.Y;

    ClipEnabled:=SDL_RenderClipEnabled(ARenderer);
    SDL_GetRenderClipRect(ARenderer, @OldClipRect);
    NewClipRect.x:=Round(ARect.Left);
    NewClipRect.y:=Round(ARect.Top);
    NewClipRect.w:=Round(ARect.Width);
    NewClipRect.h:=Round(ARect.Height);

    if ClipEnabled then
    begin
      LeftValue:=NewClipRect.x;
      TopValue:=NewClipRect.y;
      RightValue:=NewClipRect.x + NewClipRect.w;
      BottomValue:=NewClipRect.y + NewClipRect.h;
      OldRight:=OldClipRect.x + OldClipRect.w;
      OldBottom:=OldClipRect.y + OldClipRect.h;

      if OldClipRect.x > LeftValue then
        LeftValue:=OldClipRect.x;

      if OldClipRect.y > TopValue then
        TopValue:=OldClipRect.y;

      if OldRight < RightValue then
        RightValue:=OldRight;

      if OldBottom < BottomValue then
        BottomValue:=OldBottom;

      if (RightValue <= LeftValue) OR (BottomValue <= TopValue) then
        Exit;

      NewClipRect.x:=LeftValue;
      NewClipRect.y:=TopValue;
      NewClipRect.w:=RightValue - LeftValue;
      NewClipRect.h:=BottomValue - TopValue;
    end;

    SDL_SetRenderClipRect(ARenderer, @NewClipRect);
    try
      SDL_RenderTexture(ARenderer, Texture, nil, @DestRect);
    finally
      if ClipEnabled then
        SDL_SetRenderClipRect(ARenderer, @OldClipRect)
      else
        SDL_SetRenderClipRect(ARenderer, nil);
    end;
  finally
    if NOT Cached then
    begin
      if Assigned(Texture) then SDL_DestroyTexture(Texture);
      SDL_DestroySurface(Surface);
    end;
  end;
end;

destructor TGuiSDLTTFFontCollection.Destroy;
var
  I: Integer;
begin
  for I:=0 to FCount - 1 do
    if FEntries[I].OwnsRenderer then
      FEntries[I].Renderer.Free;

  inherited Destroy;
end;

function TGuiSDLTTFFontCollection.AddFont(const ASpec: TGuiFontSpec): TGuiSDLTTFFontRenderer;
var
  Name: String;
begin
  Result:=TGuiSDLTTFFontRenderer.Create(ASpec);
  Name:=ASpec.Name;

  if Name = '' then
    Name:='default';

  AddFont(Name, Result, True);

  if NOT Assigned(FDefaultFont) then
    FDefaultFont:=Result;
end;

procedure TGuiSDLTTFFontCollection.AddFont(const AName: String; ARenderer: TGuiSDLTTFFontRenderer; AOwnsRenderer: Boolean);
begin
  if NOT Assigned(ARenderer) then
    Exit;

  if Length(FEntries) <= FCount then
    SetLength(FEntries, FCount + 8);

  FEntries[FCount].Name:=AName;
  FEntries[FCount].Renderer:=ARenderer;
  FEntries[FCount].OwnsRenderer:=AOwnsRenderer;
  Inc(FCount);

  if NOT Assigned(FDefaultFont) then
    FDefaultFont:=ARenderer;
end;

function TGuiSDLTTFFontCollection.FindFont(const AName: String): TGuiSDLTTFFontRenderer;
var
  I: Integer;
begin
  Result:=nil;

  for I:=0 to FCount - 1 do
    if SameText(FEntries[I].Name, AName) then
    begin
      Result:=TGuiSDLTTFFontRenderer(FEntries[I].Renderer);
      Exit;
    end;
end;

function TGuiSDLTTFFontCollection.GetFontByName(const AName: String): TGuiSDLTTFFontRenderer;
begin
  Result:=FindFont(AName);
end;

end.
