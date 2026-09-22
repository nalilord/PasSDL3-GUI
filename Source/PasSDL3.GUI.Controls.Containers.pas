unit PasSDL3.GUI.Controls.Containers;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core;

type
  TGuiPanel = class(TGuiContainer)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiFrame = class(TGuiPanel)
  private
    FTitle: String;
    FShowHeader: Boolean;
    FShowFooter: Boolean;
    FHeaderHeight: TGuiFloat;
    FFooterHeight: TGuiFloat;
    FTitleAlign: TGuiHorizontalTextAlign;
    FHeaderColor: TGuiColor;
    FFooterColor: TGuiColor;
    FHeaderTextColor: TGuiColor;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure Arrange(const ABounds: TGuiRect); override;
    function ContentRect: TGuiRect;
    property Title: String read FTitle write FTitle;
    property ShowHeader: Boolean read FShowHeader write FShowHeader;
    property ShowFooter: Boolean read FShowFooter write FShowFooter;
    property HeaderHeight: TGuiFloat read FHeaderHeight write FHeaderHeight;
    property FooterHeight: TGuiFloat read FFooterHeight write FFooterHeight;
    property TitleAlign: TGuiHorizontalTextAlign read FTitleAlign write FTitleAlign;
    property HeaderColor: TGuiColor read FHeaderColor write FHeaderColor;
    property FooterColor: TGuiColor read FFooterColor write FFooterColor;
    property HeaderTextColor: TGuiColor read FHeaderTextColor write FHeaderTextColor;
  end;

  TGuiStackPanel = class(TGuiPanel)
  private
    FOrientation: TGuiOrientation;
    FSpacing: TGuiFloat;
    FAutoSizeToContent: Boolean;
    procedure ArrangeChildren;
    procedure SetOrientation(AValue: TGuiOrientation);
    procedure SetSpacing(AValue: TGuiFloat);
    procedure SetAutoSizeToContent(AValue: Boolean);
  public
    constructor Create; override;
    procedure Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize); override;
    procedure Add(AControl: TGuiControl); override;
    procedure Arrange(const ABounds: TGuiRect); override;
    property Orientation: TGuiOrientation read FOrientation write SetOrientation;
    property Spacing: TGuiFloat read FSpacing write SetSpacing;
    property AutoSizeToContent: Boolean read FAutoSizeToContent write SetAutoSizeToContent;
  end;

  TGuiGridPanel = class(TGuiPanel)
  private
    FColumns: Integer;
    FCellWidth: TGuiFloat;
    FCellHeight: TGuiFloat;
    FColumnSpacing: TGuiFloat;
    FRowSpacing: TGuiFloat;
    FAutoSizeToContent: Boolean;
    procedure ArrangeChildren;
    procedure SetColumns(AValue: Integer);
    procedure SetCellWidth(AValue: TGuiFloat);
    procedure SetCellHeight(AValue: TGuiFloat);
    procedure SetColumnSpacing(AValue: TGuiFloat);
    procedure SetRowSpacing(AValue: TGuiFloat);
    procedure SetAutoSizeToContent(AValue: Boolean);
  public
    constructor Create; override;
    procedure Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize); override;
    procedure Add(AControl: TGuiControl); override;
    procedure Arrange(const ABounds: TGuiRect); override;
    property Columns: Integer read FColumns write SetColumns;
    property CellWidth: TGuiFloat read FCellWidth write SetCellWidth;
    property CellHeight: TGuiFloat read FCellHeight write SetCellHeight;
    property ColumnSpacing: TGuiFloat read FColumnSpacing write SetColumnSpacing;
    property RowSpacing: TGuiFloat read FRowSpacing write SetRowSpacing;
    property AutoSizeToContent: Boolean read FAutoSizeToContent write SetAutoSizeToContent;
  end;

  TGuiScrollBox = class(TGuiContainer)
  private
    FScrollX, FContentWidth: TGuiFloat;
    FViewportWidth, FViewportHeight: TGuiFloat;
    FDraggingHorizontal: Boolean;
    FDragStartX, FDragStartScrollX: TGuiFloat;
    FScrollY: TGuiFloat;
    FContentHeight: TGuiFloat;
    FDraggingScrollBar: Boolean;
    FDragStartY: TGuiFloat;
    FDragStartScrollY: TGuiFloat;
    procedure SetScrollX(AValue: TGuiFloat);
    function GetMaxScrollX: TGuiFloat;
    function HorizontalBarRect: TGuiRect;
    function HorizontalThumbRect: TGuiRect;
    procedure SetScrollY(AValue: TGuiFloat);
    function GetMaxScrollY: TGuiFloat;
    function GetScrollBarRect: TGuiRect;
    function GetScrollThumbRect: TGuiRect;
    function ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
    procedure RecalculateContentHeight;
  protected
    function GetChildPaintOffset: TGuiPoint; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure Add(AControl: TGuiControl); override;
    procedure Arrange(const ABounds: TGuiRect); override;
    procedure Paint(ACanvas: TGuiCanvas); override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    property ScrollY: TGuiFloat read FScrollY write SetScrollY;
    property ScrollX: TGuiFloat read FScrollX write SetScrollX;
    property ContentWidth: TGuiFloat read FContentWidth;
    property ViewportWidth: TGuiFloat read FViewportWidth;
    property ViewportHeight: TGuiFloat read FViewportHeight;
    property MaxScrollX: TGuiFloat read GetMaxScrollX;
    property ContentHeight: TGuiFloat read FContentHeight write FContentHeight;
    property MaxScrollY: TGuiFloat read GetMaxScrollY;
  end;

  TGuiGroupBox = class(TGuiPanel)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
  end;

  TGuiTransparentPanel = class(TGuiPanel)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiTransparentStackPanel = class(TGuiStackPanel)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiSplitter = class(TGuiControl)
  private
    FOrientation: TGuiOrientation;
    FTargetControl: TGuiControl;
    FMinTargetSize: TGuiFloat;
    FLastMousePosition: TGuiPoint;
    FDelta: TGuiFloat;
    FOnMoved: TGuiNotifyEvent;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    property Orientation: TGuiOrientation read FOrientation write FOrientation;
    property TargetControl: TGuiControl read FTargetControl write FTargetControl;
    property MinTargetSize: TGuiFloat read FMinTargetSize write FMinTargetSize;
    property Delta: TGuiFloat read FDelta;
    property OnMoved: TGuiNotifyEvent read FOnMoved write FOnMoved;
  end;

implementation

procedure TGuiPanel.PaintSelf(ACanvas: TGuiCanvas);
begin
  inherited PaintSelf(ACanvas);
end;

constructor TGuiFrame.Create;
begin
  inherited Create;
  FTitle:='';
  FShowHeader:=True;
  FShowFooter:=False;
  FHeaderHeight:=28;
  FFooterHeight:=0;
  FTitleAlign:=ghtaLeft;
  FHeaderColor:=GuiColor(0, 0, 0, 0);
  FFooterColor:=GuiColor(0, 0, 0, 0);
  FHeaderTextColor:=GuiColor(0, 0, 0, 0);
  Padding:=GuiBoxLTRB(10, 8, 10, 10);
end;

function TGuiFrame.ContentRect: TGuiRect;
begin
  Result:=GuiRect(Padding.Left, Padding.Top, Bounds.Width - Padding.Left - Padding.Right, Bounds.Height - Padding.Top - Padding.Bottom);

  if FShowHeader then
  begin
    Result.Top:=Result.Top + FHeaderHeight;
    Result.Height:=Result.Height - FHeaderHeight;
  end;

  if FShowFooter then
    Result.Height:=Result.Height - FFooterHeight;

  if Result.Width < 0 then
    Result.Width:=0;

  if Result.Height < 0 then
    Result.Height:=0;
end;

procedure TGuiFrame.Arrange(const ABounds: TGuiRect);
var
  SavedPadding: TGuiBox;
  AdjustedPadding: TGuiBox;
begin
  SavedPadding:=Padding;
  AdjustedPadding:=SavedPadding;

  if FShowHeader then
    AdjustedPadding.Top:=AdjustedPadding.Top + FHeaderHeight;

  if FShowFooter then
    AdjustedPadding.Bottom:=AdjustedPadding.Bottom + FFooterHeight;

  Padding:=AdjustedPadding;
  inherited Arrange(ABounds);
  Padding:=SavedPadding;
end;

procedure TGuiFrame.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  HeaderRect: TGuiRect;
  FooterRect: TGuiRect;
  HeaderColor: TGuiColor;
  FooterColor: TGuiColor;
  TextColor: TGuiColor;
begin
  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(Style.Background, Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, Style.BorderColor);

  if FShowHeader AND (FHeaderHeight > 0) then
  begin
    HeaderColor:=FHeaderColor;
    if HeaderColor.A = 0 then
      HeaderColor:=Style.HoverBackgroundColor;

    HeaderRect:=GuiRect(Rect.Left + 1, Rect.Top + 1, Rect.Width - 2, FHeaderHeight);
    if HeaderColor.A > 0 then
      ACanvas.FillRect(HeaderRect, HeaderColor);

    ACanvas.FillRect(GuiRect(HeaderRect.Left, HeaderRect.Top + HeaderRect.Height - 1, HeaderRect.Width, 1), Style.BorderColor);

    TextColor:=FHeaderTextColor;
    if TextColor.A = 0 then
      TextColor:=Style.TextColor;

    if FTitle <> '' then
      DrawControlText(ACanvas, FTitle, GuiInflateRect(HeaderRect, GuiBoxLTRB(10, 0, 10, 0)), TextColor, FTitleAlign, gvtaCenter);
  end;

  if FShowFooter AND (FFooterHeight > 0) then
  begin
    FooterColor:=FFooterColor;
    if FooterColor.A = 0 then
      FooterColor:=Style.PressedBackgroundColor;

    FooterRect:=GuiRect(Rect.Left + 1, Rect.Top + Rect.Height - FFooterHeight - 1, Rect.Width - 2, FFooterHeight);
    if FooterColor.A > 0 then
      ACanvas.FillRect(FooterRect, FooterColor);

    ACanvas.FillRect(GuiRect(FooterRect.Left, FooterRect.Top, FooterRect.Width, 1), Style.BorderColor);
  end;
end;

constructor TGuiStackPanel.Create;
begin
  inherited Create;
  FOrientation:=goVertical;
  FSpacing:=8;
  FAutoSizeToContent:=True;
end;

procedure TGuiStackPanel.SetOrientation(AValue: TGuiOrientation);
begin
  if FOrientation = AValue then
    Exit;

  FOrientation:=AValue;
  InvalidateLayout;
end;

procedure TGuiStackPanel.SetSpacing(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then
    raise EArgumentException.Create('Stack spacing must be finite');
  if AValue < 0 then
    AValue:=0;

  if FSpacing = AValue then
    Exit;

  FSpacing:=AValue;
  InvalidateLayout;
end;

procedure TGuiStackPanel.SetAutoSizeToContent(AValue: Boolean);
begin
  if FAutoSizeToContent = AValue then
    Exit;

  FAutoSizeToContent:=AValue;
  InvalidateLayout;
end;

procedure TGuiStackPanel.Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize);
var
  I: Integer;
  Child: TGuiControl;
  ChildSize: TGuiSize;
  Width: TGuiFloat;
  Height: TGuiFloat;
  VisibleCount: Integer;
begin
  Width:=Padding.Left + Padding.Right;
  Height:=Padding.Top + Padding.Bottom;
  VisibleCount:=0;

  for I:=0 to ChildCount - 1 do
  begin
    Child:=Children[I];
    if NOT Child.Visible then
      Continue;

    Child.Measure(AAvailableSize, ChildSize);

    if FOrientation = goVertical then
    begin
      if ChildSize.Width + Child.Margin.Left + Child.Margin.Right + Padding.Left + Padding.Right > Width then
        Width:=ChildSize.Width + Child.Margin.Left + Child.Margin.Right + Padding.Left + Padding.Right;

      Height:=Height + ChildSize.Height + Child.Margin.Top + Child.Margin.Bottom;
    end else
    begin
      Width:=Width + ChildSize.Width + Child.Margin.Left + Child.Margin.Right;

      if ChildSize.Height + Child.Margin.Top + Child.Margin.Bottom + Padding.Top + Padding.Bottom > Height then
        Height:=ChildSize.Height + Child.Margin.Top + Child.Margin.Bottom + Padding.Top + Padding.Bottom;
    end;

    Inc(VisibleCount);
  end;

  if VisibleCount > 1 then
  begin
    if FOrientation = goVertical then
      Height:=Height + ((VisibleCount - 1) * FSpacing)
    else
      Width:=Width + ((VisibleCount - 1) * FSpacing);
  end;

  ADesiredSize:=GuiSize(Width, Height);
end;

procedure TGuiStackPanel.ArrangeChildren;
var
  I: Integer;
  Cursor: TGuiFloat;
  Child: TGuiControl;
  ClientRect: TGuiRect;
  ChildBounds: TGuiRect;
  ChildSize: TGuiSize;
  Width: TGuiFloat;
  Height: TGuiFloat;
  VisibleCount: Integer;
  NewBounds: TGuiRect;
begin
  ClientRect:=GuiInflateRect(GuiRect(0, 0, Bounds.Width, Bounds.Height), Padding);
  VisibleCount:=0;

  if FOrientation = goVertical then
    Cursor:=ClientRect.Top
  else
    Cursor:=ClientRect.Left;

  for I:=0 to ChildCount - 1 do
  begin
    Child:=Children[I];
    if NOT Child.Visible then
      Continue;

    Child.Measure(GuiSize(ClientRect.Width, ClientRect.Height), ChildSize);

    if VisibleCount > 0 then
      Cursor:=Cursor + FSpacing;

    if FOrientation = goVertical then
    begin
      Width:=ClientRect.Width - Child.Margin.Left - Child.Margin.Right;
      if (Child.Bounds.Width > 0) AND (NOT Child.AutoSize) then
        Width:=Child.Bounds.Width;

      Height:=Child.Bounds.Height;
      if Child.AutoSize OR (Height <= 0) then
        Height:=ChildSize.Height;

      ChildBounds:=GuiRect(ClientRect.Left + Child.Margin.Left, Cursor + Child.Margin.Top, Width, Height);
      GuiClampControlBounds(Child, ChildBounds);
      Child.Bounds:=ChildBounds;
      Cursor:=Cursor + Child.Bounds.Height + Child.Margin.Top + Child.Margin.Bottom;
    end else
    begin
      Width:=Child.Bounds.Width;
      if Child.AutoSize OR (Width <= 0) then
        Width:=ChildSize.Width;

      Height:=ClientRect.Height - Child.Margin.Top - Child.Margin.Bottom;
      if (Child.Bounds.Height > 0) AND (NOT Child.AutoSize) then
        Height:=Child.Bounds.Height;

      ChildBounds:=GuiRect(Cursor + Child.Margin.Left, ClientRect.Top + Child.Margin.Top, Width, Height);
      GuiClampControlBounds(Child, ChildBounds);
      Child.Bounds:=ChildBounds;
      Cursor:=Cursor + Child.Bounds.Width + Child.Margin.Left + Child.Margin.Right;
    end;

    Inc(VisibleCount);
  end;

  if (VisibleCount > 0) AND FAutoSizeToContent then
  begin
    NewBounds:=Bounds;
    if FOrientation = goVertical then
      NewBounds.Height:=Cursor + Padding.Bottom
    else
      NewBounds.Width:=Cursor + Padding.Right;
    Bounds:=NewBounds;
  end;
end;

procedure TGuiStackPanel.Add(AControl: TGuiControl);
begin
  inherited Add(AControl);
  InvalidateLayout;
end;

procedure TGuiStackPanel.Arrange(const ABounds: TGuiRect);
var
  I: Integer;
begin
  Bounds:=ABounds;
  ArrangeChildren;

  for I:=0 to ChildCount - 1 do
    Children[I].Arrange(Children[I].Bounds);

  CompleteArrange;
end;

constructor TGuiGridPanel.Create;
begin
  inherited Create;
  FColumns:=1;
  FCellWidth:=100;
  FCellHeight:=100;
  FColumnSpacing:=8;
  FRowSpacing:=8;
  FAutoSizeToContent:=True;
end;

procedure TGuiGridPanel.SetColumns(AValue: Integer);
begin
  if AValue < 1 then
    AValue:=1;

  if FColumns = AValue then
    Exit;

  FColumns:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.SetCellWidth(AValue: TGuiFloat);
begin
  if FCellWidth = AValue then
    Exit;

  FCellWidth:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.SetCellHeight(AValue: TGuiFloat);
begin
  if FCellHeight = AValue then
    Exit;

  FCellHeight:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.SetColumnSpacing(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if FColumnSpacing = AValue then
    Exit;

  FColumnSpacing:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.SetRowSpacing(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if FRowSpacing = AValue then
    Exit;

  FRowSpacing:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.SetAutoSizeToContent(AValue: Boolean);
begin
  if FAutoSizeToContent = AValue then
    Exit;

  FAutoSizeToContent:=AValue;
  InvalidateLayout;
end;

procedure TGuiGridPanel.Measure(const AAvailableSize: TGuiSize; out ADesiredSize: TGuiSize);
var
  I: Integer;
  VisibleCount: Integer;
  RowCount: Integer;
  CellWidth: TGuiFloat;
  CellHeight: TGuiFloat;
  ChildSize: TGuiSize;
begin
  if FColumns < 1 then
    FColumns:=1;

  CellWidth:=FCellWidth;
  CellHeight:=FCellHeight;
  VisibleCount:=0;

  for I:=0 to ChildCount - 1 do
  begin
    if NOT Children[I].Visible then
      Continue;

    Children[I].Measure(AAvailableSize, ChildSize);

    if (CellWidth <= 0) AND (ChildSize.Width > CellWidth) then
      CellWidth:=ChildSize.Width;

    if (CellHeight <= 0) AND (ChildSize.Height > CellHeight) then
      CellHeight:=ChildSize.Height;

    Inc(VisibleCount);
  end;

  if CellWidth < 0 then
    CellWidth:=0;

  if CellHeight < 0 then
    CellHeight:=0;

  RowCount:=(VisibleCount + FColumns - 1) DIV FColumns;

  if VisibleCount > 0 then
    ADesiredSize:=GuiSize(Padding.Left + Padding.Right + (FColumns * CellWidth) + ((FColumns - 1) * FColumnSpacing),
      Padding.Top + Padding.Bottom + (RowCount * CellHeight) + ((RowCount - 1) * FRowSpacing))
  else
    ADesiredSize:=GuiSize(Padding.Left + Padding.Right, Padding.Top + Padding.Bottom);
end;

procedure TGuiGridPanel.ArrangeChildren;
var
  I: Integer;
  VisibleIndex: Integer;
  Row: Integer;
  Column: Integer;
  RowCount: Integer;
  CellWidth: TGuiFloat;
  CellHeight: TGuiFloat;
  ChildSize: TGuiSize;
  ClientRect: TGuiRect;
  ChildBounds: TGuiRect;
  NewBounds: TGuiRect;
begin
  if FColumns < 1 then
    FColumns:=1;

  CellWidth:=FCellWidth;
  CellHeight:=FCellHeight;
  ClientRect:=GuiInflateRect(GuiRect(0, 0, Bounds.Width, Bounds.Height), Padding);

  if (CellWidth <= 0) OR (CellHeight <= 0) then
  begin
    for I:=0 to ChildCount - 1 do
    begin
      if NOT Children[I].Visible then
        Continue;

      Children[I].Measure(GuiSize(ClientRect.Width, ClientRect.Height), ChildSize);

      if (CellWidth <= 0) AND (ChildSize.Width > CellWidth) then
        CellWidth:=ChildSize.Width;

      if (CellHeight <= 0) AND (ChildSize.Height > CellHeight) then
        CellHeight:=ChildSize.Height;
    end;
  end;

  if CellWidth < 0 then
    CellWidth:=0;

  if CellHeight < 0 then
    CellHeight:=0;

  VisibleIndex:=0;
  for I:=0 to ChildCount - 1 do
  begin
    if NOT Children[I].Visible then
      Continue;

    Row:=VisibleIndex DIV FColumns;
    Column:=VisibleIndex MOD FColumns;
    ChildBounds:=GuiRect(ClientRect.Left + (Column * (CellWidth + FColumnSpacing)),
      ClientRect.Top + (Row * (CellHeight + FRowSpacing)), CellWidth, CellHeight);
    GuiClampControlBounds(Children[I], ChildBounds);
    Children[I].Bounds:=ChildBounds;
    Inc(VisibleIndex);
  end;

  if FAutoSizeToContent then
  begin
    RowCount:=(VisibleIndex + FColumns - 1) DIV FColumns;
    NewBounds:=Bounds;

    if RowCount > 0 then
      NewBounds.Height:=Padding.Top + Padding.Bottom + (RowCount * CellHeight) + ((RowCount - 1) * FRowSpacing)
    else
      NewBounds.Height:=Padding.Top + Padding.Bottom;

    NewBounds.Width:=Padding.Left + Padding.Right + (FColumns * CellWidth) + ((FColumns - 1) * FColumnSpacing);
    Bounds:=NewBounds;
  end;
end;

procedure TGuiGridPanel.Add(AControl: TGuiControl);
begin
  inherited Add(AControl);
  InvalidateLayout;
end;

procedure TGuiGridPanel.Arrange(const ABounds: TGuiRect);
var
  I: Integer;
begin
  Bounds:=ABounds;
  ArrangeChildren;

  for I:=0 to ChildCount - 1 do
    Children[I].Arrange(Children[I].Bounds);

  CompleteArrange;
end;

constructor TGuiScrollBox.Create;
begin
  inherited Create;
  BackgroundColor:=GuiColor(0, 0, 0, 0);
  BorderColor:=GuiColor(0, 0, 0, 0);
  FScrollY:=0;
  FContentHeight:=0;
  FDraggingScrollBar:=False;
end;

procedure TGuiScrollBox.SetScrollY(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if AValue > MaxScrollY then
    AValue:=MaxScrollY;

  FScrollY:=AValue;
end;

procedure TGuiScrollBox.SetScrollX(AValue: TGuiFloat);
begin
  FScrollX:=EnsureRange(AValue, 0, MaxScrollX);
end;

function TGuiScrollBox.GetMaxScrollX: TGuiFloat;
begin
  Result:=Max(0, FContentWidth - FViewportWidth);
end;

function TGuiScrollBox.HorizontalBarRect: TGuiRect;
var Rect: TGuiRect;
begin
  Rect:=AbsoluteBounds;
  Rect.Width:=FViewportWidth;
  Result:=GuiScrollTrackRect(Rect, goHorizontal, Max(0, Bounds.Height - FViewportHeight));
end;

function TGuiScrollBox.HorizontalThumbRect: TGuiRect;
var
  Rect: TGuiRect;
  Size: TGuiFloat;
begin
  Rect:=HorizontalBarRect;
  Size:=GuiScrollThumbLength(FViewportWidth, FContentWidth, Rect.Width, 24);
  Result:=GuiRect(Rect.Left, Rect.Top, Size, Rect.Height);
  if MaxScrollX > 0 then Result.Left:=Result.Left + FScrollX / MaxScrollX * (Rect.Width - Size);
end;

function TGuiScrollBox.GetMaxScrollY: TGuiFloat;
begin
  Result:=FContentHeight - FViewportHeight;

  if Result < 0 then
    Result:=0;
end;

function TGuiScrollBox.GetScrollBarRect: TGuiRect;
var Rect: TGuiRect;
begin
  Rect:=AbsoluteBounds;
  Rect.Height:=FViewportHeight;
  Result:=GuiScrollTrackRect(Rect, goVertical, Max(0, Bounds.Width - FViewportWidth));
end;

function TGuiScrollBox.GetScrollThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(GetScrollBarRect, FViewportHeight, FContentHeight, FScrollY);
end;

function TGuiScrollBox.ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
var
  Rect: TGuiRect;
  ThumbRect: TGuiRect;
  TrackHeight: TGuiFloat;
begin
  Result:=0;

  if MaxScrollY <= 0 then
    Exit;

  Rect:=GetScrollBarRect;
  ThumbRect:=GetScrollThumbRect;
  TrackHeight:=Rect.Height;
  Result:=GuiScrollOffsetFromThumbDelta(ADeltaY, TrackHeight, ThumbRect.Height, MaxScrollY);
end;

procedure TGuiScrollBox.RecalculateContentHeight;
var
  I, Pass: Integer;
  ChildBottom: TGuiFloat;
  BarSize: TGuiFloat;
begin
  FContentHeight:=0;
  FContentWidth:=0;

  for I:=0 to ChildCount - 1 do
  begin
    if NOT Children[I].Visible then Continue;
    FContentWidth:=Max(FContentWidth, Children[I].Bounds.Left + Children[I].Bounds.Width);
    ChildBottom:=Children[I].Bounds.Top + Children[I].Bounds.Height;
    if ChildBottom > FContentHeight then
      FContentHeight:=ChildBottom;
  end;

  FViewportWidth:=Max(0, Bounds.Width);
  FViewportHeight:=Max(0, Bounds.Height);
  BarSize:=Max(8, Style.ScrollBarSize);
  { A gutter on one axis can make the other axis overflow as well. }
  for Pass:=0 to 1 do
  begin
    if FContentHeight > FViewportHeight then FViewportWidth:=Max(0, Bounds.Width - BarSize);
    if FContentWidth > FViewportWidth then FViewportHeight:=Max(0, Bounds.Height - BarSize);
  end;
  SetScrollY(FScrollY);
  SetScrollX(FScrollX);
end;

function TGuiScrollBox.GetChildPaintOffset: TGuiPoint;
begin
  Result:=GuiPoint(-FScrollX, -FScrollY);
end;

procedure TGuiScrollBox.PaintSelf(ACanvas: TGuiCanvas);
begin
  ACanvas.DrawSurface(GuiColorDrawable(BackgroundColor), AbsoluteBounds, Style.CornerRadius);
end;

procedure TGuiScrollBox.Add(AControl: TGuiControl);
begin
  inherited Add(AControl);
  RecalculateContentHeight;
end;

procedure TGuiScrollBox.Arrange(const ABounds: TGuiRect);
begin
  inherited Arrange(ABounds);
  RecalculateContentHeight;
end;

procedure TGuiScrollBox.Paint(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
begin
  if NOT Visible then
    Exit;

  PaintSelf(ACanvas);

  RecalculateContentHeight;
  Rect:=AbsoluteBounds;
  ACanvas.PushClipRect(GuiRect(Rect.Left, Rect.Top, FViewportWidth, FViewportHeight));
  try
    for I:=0 to ChildCount - 1 do
      Children[I].Paint(ACanvas);
  finally
    ACanvas.PopClipRect;
  end;

  if MaxScrollY > 0 then
    PaintScrollBar(ACanvas, GetScrollBarRect, GetScrollThumbRect, goVertical, FDraggingScrollBar);
  if MaxScrollX > 0 then
    PaintScrollBar(ACanvas, HorizontalBarRect, HorizontalThumbRect, goHorizontal, FDraggingHorizontal);
  { Children may touch the frame; keep the scroll area's outline continuous. }
  DrawControlBorder(ACanvas, Rect, BorderColor);
end;

procedure TGuiScrollBox.HandleEvent(var AEvent: TGuiEvent);
var
  ThumbRect: TGuiRect;
  ScrollBarRect: TGuiRect;
  OldX, OldY: TGuiFloat;
begin
  inherited HandleEvent(AEvent);
  if AEvent.Kind = gekCancel then
  begin
    FDraggingHorizontal:=False;
    FDraggingScrollBar:=False;
    Exit;
  end;
  RecalculateContentHeight;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) AND
    (MaxScrollX > 0) AND GuiRectContains(HorizontalBarRect, AEvent.Position) then
  begin
    ThumbRect:=HorizontalThumbRect;
    if NOT GuiRectContains(ThumbRect, AEvent.Position) then
      SetScrollX(FScrollX + GuiScrollOffsetFromThumbDelta(AEvent.Position.X - ThumbRect.Left - ThumbRect.Width / 2,
        HorizontalBarRect.Width, ThumbRect.Width, MaxScrollX));
    FDraggingHorizontal:=True;
    FDragStartX:=AEvent.Position.X;
    FDragStartScrollX:=FScrollX;
    AEvent.Handled:=True;
    Exit;
  end;
  if FDraggingHorizontal then
  begin
    if AEvent.Kind = gekMouseMove then
      SetScrollX(FDragStartScrollX + GuiScrollOffsetFromThumbDelta(AEvent.Position.X - FDragStartX,
        HorizontalBarRect.Width, HorizontalThumbRect.Width, MaxScrollX));
    if AEvent.Kind = gekMouseUp then FDraggingHorizontal:=False;
    AEvent.Handled:=True;
    Exit;
  end;

  case AEvent.Kind of
    gekMouseWheel:
    begin
      OldX:=FScrollX;
      OldY:=FScrollY;
      SetScrollX(FScrollX - (AEvent.Delta.X * 42));
      if gemShift IN AEvent.Modifiers then
        SetScrollX(FScrollX - (AEvent.Delta.Y * 42))
      else
        SetScrollY(FScrollY - (AEvent.Delta.Y * 42));
      AEvent.Handled:=(OldX <> FScrollX) OR (OldY <> FScrollY);
    end;

    gekMouseDown:
    begin
      ScrollBarRect:=GetScrollBarRect;
      if (AEvent.Button = gmbLeft) AND (MaxScrollY > 0) AND GuiRectContains(ScrollBarRect, AEvent.Position) then
      begin
        ThumbRect:=GetScrollThumbRect;
        if NOT GuiRectContains(ThumbRect, AEvent.Position) then
          SetScrollY(FScrollY + ScrollFromThumbDelta(AEvent.Position.Y - (ThumbRect.Top + (ThumbRect.Height / 2))));

        FDraggingScrollBar:=True;
        FDragStartY:=AEvent.Position.Y;
        FDragStartScrollY:=FScrollY;
        AEvent.Handled:=True;
      end;
    end;

    gekMouseMove:
    begin
      if FDraggingScrollBar then
      begin
        SetScrollY(FDragStartScrollY + ScrollFromThumbDelta(AEvent.Position.Y - FDragStartY));
        AEvent.Handled:=True;
      end;
    end;

    gekMouseUp:
    begin
      if FDraggingScrollBar then
      begin
        FDraggingScrollBar:=False;
        AEvent.Handled:=True;
      end;
    end;
  end;
end;

function TGuiScrollBox.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=nil;

  if (NOT Visible) OR (NOT Enabled) then
    Exit;

  if NOT GuiRectContains(AbsoluteBounds, APoint) then
    Exit;
  RecalculateContentHeight;
  if (MaxScrollX > 0) AND GuiRectContains(HorizontalBarRect, APoint) then
  begin
    Result:=Self;
    Exit;
  end;

  if (MaxScrollY > 0) AND GuiRectContains(GetScrollBarRect, APoint) then
  begin
    Result:=Self;
    Exit;
  end;

  if (APoint.X >= AbsoluteBounds.Left + FViewportWidth) OR
    (APoint.Y >= AbsoluteBounds.Top + FViewportHeight) then
  begin
    Result:=Self;
    Exit;
  end;

  Result:=inherited HitTest(APoint);
end;

constructor TGuiGroupBox.Create;
begin
  inherited Create;
  Padding:=GuiBoxLTRB(12, 24, 12, 12);
  ClipChildren:=True;
end;

procedure TGuiGroupBox.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  CaptionRect: TGuiRect;
  CaptionSize: TGuiSize;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, Style.BackgroundColor);
  DrawControlBorder(ACanvas, GuiRect(Rect.Left, Rect.Top + 10, Rect.Width, Rect.Height - 10), Style.BorderColor);

  if Caption <> '' then
  begin
    CaptionSize:=ACanvas.MeasureText(Caption);
    CaptionRect:=GuiRect(Rect.Left + 10, Rect.Top, CaptionSize.Width + 16, 22);
    ACanvas.FillRect(CaptionRect, Style.BackgroundColor);
    DrawControlText(ACanvas, Caption, GuiInflateRect(CaptionRect, GuiBoxLTRB(8, 0, 8, 0)), Style.TextColor, ghtaLeft, gvtaCenter);
  end;
end;

procedure TGuiTransparentPanel.PaintSelf(ACanvas: TGuiCanvas);
begin
end;

procedure TGuiTransparentStackPanel.PaintSelf(ACanvas: TGuiCanvas);
begin
end;

constructor TGuiSplitter.Create;
begin
  inherited Create;
  FOrientation:=goVertical;
  FTargetControl:=nil;
  FMinTargetSize:=60;
  FDelta:=0;
  CanFocus:=False;
  TabStop:=False;
  ShowFocus:=False;
end;

procedure TGuiSplitter.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  GripRect: TGuiRect;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, Style.BackgroundColor);

  if FOrientation = goVertical then
    GripRect:=GuiRect(Rect.Left + (Rect.Width / 2) - 1, Rect.Top + 8, 2, Rect.Height - 16)
  else
    GripRect:=GuiRect(Rect.Left + 8, Rect.Top + (Rect.Height / 2) - 1, Rect.Width - 16, 2);

  ACanvas.FillRect(GripRect, Style.BorderColor);
end;

procedure TGuiSplitter.HandleEvent(var AEvent: TGuiEvent);
var
  TargetBounds: TGuiRect;
  SplitterBounds: TGuiRect;
begin
  inherited HandleEvent(AEvent);

  case AEvent.Kind of
    gekMouseDown:
    begin
      FLastMousePosition:=AEvent.Position;
      AEvent.Handled:=True;
    end;

    gekMouseMove:
    begin
      if Pressed then
      begin
        if FOrientation = goVertical then
          FDelta:=AEvent.Position.X - FLastMousePosition.X
        else
          FDelta:=AEvent.Position.Y - FLastMousePosition.Y;

        if Assigned(FTargetControl) then
        begin
          TargetBounds:=FTargetControl.Bounds;
          SplitterBounds:=Bounds;

          if FOrientation = goVertical then
          begin
            if TargetBounds.Width + FDelta < FMinTargetSize then
              FDelta:=FMinTargetSize - TargetBounds.Width;

            TargetBounds.Width:=TargetBounds.Width + FDelta;
            SplitterBounds.Left:=SplitterBounds.Left + FDelta;
          end else
          begin
            if TargetBounds.Height + FDelta < FMinTargetSize then
              FDelta:=FMinTargetSize - TargetBounds.Height;

            TargetBounds.Height:=TargetBounds.Height + FDelta;
            SplitterBounds.Top:=SplitterBounds.Top + FDelta;
          end;

          FTargetControl.Bounds:=TargetBounds;
          Bounds:=SplitterBounds;
        end;

        FLastMousePosition:=AEvent.Position;

        if Assigned(FOnMoved) then
          FOnMoved(Self);

        AEvent.Handled:=True;
      end;
    end;
  end;
end;

function TGuiSplitter.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if NOT Enabled OR (Cursor <> gmcAuto) then
    Exit;
  if Orientation = goVertical then
    Result:=gmcSizeWE
  else
    Result:=gmcSizeNS;
end;

end.
