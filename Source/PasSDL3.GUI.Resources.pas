unit PasSDL3.GUI.Resources;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  PasSDL3.GUI.Types;

type
  TGuiResourceRegion = class
  private
    FName: String;
    FTexture: TGuiTexture;
    FSourceRect: TGuiRect;
  public
    property Name: String read FName write FName;
    property Texture: TGuiTexture read FTexture write FTexture;
    property SourceRect: TGuiRect read FSourceRect write FSourceRect;
    constructor Create(const AName: String; ATexture: TGuiTexture; const ASourceRect: TGuiRect);
  end;

  TGuiResourceCatalog = class
  private
    FRegions: TStringList;
    function GetRegionCount: Integer;
    function GetRegions(AIndex: Integer): TGuiResourceRegion;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function RegisterRegion(const AName: String; ATexture: TGuiTexture; const ASourceRect: TGuiRect): TGuiResourceRegion;
    function FindRegion(const AName: String): TGuiResourceRegion;
    function ImageDrawable(const AName: String): TGuiDrawable;
    function NineSliceDrawable(const AName: String; const ASlice: TGuiBox): TGuiDrawable;
    procedure ApplyImageBackground(var AStyle: TGuiStyle; const AName: String);
    procedure ApplyNineSliceBackground(var AStyle: TGuiStyle; const AName: String; const ASlice: TGuiBox);
    property RegionCount: Integer read GetRegionCount;
    property Regions[AIndex: Integer]: TGuiResourceRegion read GetRegions;
  end;

implementation

constructor TGuiResourceRegion.Create(const AName: String; ATexture: TGuiTexture; const ASourceRect: TGuiRect);
begin
  inherited Create;
  Name:=AName;
  Texture:=ATexture;
  SourceRect:=ASourceRect;
end;

constructor TGuiResourceCatalog.Create;
begin
  inherited Create;
  FRegions:=TStringList.Create;
  FRegions.Sorted:=False;
  FRegions.OwnsObjects:=True;
end;

destructor TGuiResourceCatalog.Destroy;
begin
  FRegions.Free;
  inherited Destroy;
end;

procedure TGuiResourceCatalog.Clear;
begin
  FRegions.Clear;
end;

function TGuiResourceCatalog.GetRegionCount: Integer;
begin
  Result:=FRegions.Count;
end;

function TGuiResourceCatalog.GetRegions(AIndex: Integer): TGuiResourceRegion;
begin
  Result:=TGuiResourceRegion(FRegions.Objects[AIndex]);
end;

function TGuiResourceCatalog.RegisterRegion(const AName: String; ATexture: TGuiTexture; const ASourceRect: TGuiRect): TGuiResourceRegion;
var
  Index: Integer;
begin
  Index:=FRegions.IndexOf(AName);
  if Index >= 0 then
  begin
    Result:=TGuiResourceRegion(FRegions.Objects[Index]);
    Result.Texture:=ATexture;
    Result.SourceRect:=ASourceRect;
    Exit;
  end;

  Result:=TGuiResourceRegion.Create(AName, ATexture, ASourceRect);
  FRegions.AddObject(AName, Result);
end;

function TGuiResourceCatalog.FindRegion(const AName: String): TGuiResourceRegion;
var
  Index: Integer;
begin
  Result:=nil;
  Index:=FRegions.IndexOf(AName);
  if Index >= 0 then
    Result:=TGuiResourceRegion(FRegions.Objects[Index]);
end;

function TGuiResourceCatalog.ImageDrawable(const AName: String): TGuiDrawable;
var
  Region: TGuiResourceRegion;
begin
  Result:=GuiEmptyDrawable;
  Region:=FindRegion(AName);
  if Assigned(Region) then
    Result:=GuiImageDrawable(Region.Texture, Region.SourceRect);
end;

function TGuiResourceCatalog.NineSliceDrawable(const AName: String; const ASlice: TGuiBox): TGuiDrawable;
var
  Region: TGuiResourceRegion;
begin
  Result:=GuiEmptyDrawable;
  Region:=FindRegion(AName);
  if Assigned(Region) then
    Result:=GuiNineSliceDrawable(Region.Texture, Region.SourceRect, ASlice);
end;

procedure TGuiResourceCatalog.ApplyImageBackground(var AStyle: TGuiStyle; const AName: String);
begin
  AStyle.Background:=ImageDrawable(AName);
  AStyle.HoverBackground:=AStyle.Background;
  AStyle.PressedBackground:=AStyle.Background;
  AStyle.CheckedBackground:=AStyle.Background;
end;

procedure TGuiResourceCatalog.ApplyNineSliceBackground(var AStyle: TGuiStyle; const AName: String; const ASlice: TGuiBox);
begin
  AStyle.Background:=NineSliceDrawable(AName, ASlice);
  AStyle.HoverBackground:=AStyle.Background;
  AStyle.PressedBackground:=AStyle.Background;
  AStyle.CheckedBackground:=AStyle.Background;
end;

end.
