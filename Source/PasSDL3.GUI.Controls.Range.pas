unit PasSDL3.GUI.Controls.Range;

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
  TGuiSnapMode = (gsmNoSnap, gsmSnapAlways, gsmSnapOnRelease);

  TGuiRangeThumb = (grtLower, grtUpper);
  TGuiRangeMovedEvent = procedure(Sender: TGuiControl;
    AThumb: TGuiRangeThumb) of object;

  TGuiKnobInputMode = (gkiCircular, gkiHorizontal, gkiVertical);
  TGuiWrapDirection = (gwdClockwise, gwdCounterClockwise);
  TGuiKnobWrapEvent = procedure(Sender: TGuiControl;
    ADirection: TGuiWrapDirection) of object;

  TGuiSlider = class(TGuiControl)
  private type
    PSliderEventGuard = ^TSliderEventGuard;
    TSliderEventGuard = record
    private
      FPrevious: PSliderEventGuard;
      FAlive: Boolean;
    public
      property Previous: PSliderEventGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FSliderEventGuard: PSliderEventGuard;
    procedure BeginSliderEvent(var AGuard: TSliderEventGuard);
    procedure EndSliderEvent(var AGuard: TSliderEventGuard);
  private
    FStepSize,FPreviewValue: TGuiFloat;
    FLive,FDragging: Boolean;
    FSnapMode: TGuiSnapMode;
    FOnMoved: TGuiNotifyEvent;
    procedure CancelDrag;
    procedure SetStepSize(AValue: TGuiFloat);
    procedure SetLive(AValue: Boolean);
    procedure SetSnapMode(AValue: TGuiSnapMode);
    procedure SetOrientation(AValue: TGuiOrientation);
    function GetPreviewValue: TGuiFloat;
    function SnapValue(AValue: TGuiFloat): TGuiFloat;
    procedure AssignValue(AValue: TGuiFloat);
  private
    FMinValue: TGuiFloat;
    FMaxValue: TGuiFloat;
    FValue: TGuiFloat;
    FOrientation: TGuiOrientation;
    FOnChange: TGuiNotifyEvent;
    procedure SetMinValue(AValue: TGuiFloat);
    procedure SetMaxValue(AValue: TGuiFloat);
    procedure SetValue(AValue: TGuiFloat);
    function TrackRect: TGuiRect;
    function ThumbRect: TGuiRect;
    procedure SetValueFromPoint(const APoint: TGuiPoint; ARelease: Boolean = False);
  protected
    function ValueFromPoint(const APoint: TGuiPoint; out AValue: TGuiFloat): Boolean; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property MinValue: TGuiFloat read FMinValue write SetMinValue;
    property MaxValue: TGuiFloat read FMaxValue write SetMaxValue;
    property Value: TGuiFloat read FValue write SetValue;
    property Orientation: TGuiOrientation read FOrientation write SetOrientation;
    property StepSize: TGuiFloat read FStepSize write SetStepSize;
    property SnapMode: TGuiSnapMode read FSnapMode write SetSnapMode;
    property Live: Boolean read FLive write SetLive;
    property PreviewValue: TGuiFloat read GetPreviewValue;
    property OnMoved: TGuiNotifyEvent read FOnMoved write FOnMoved;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
  end;

  TGuiRangeSlider = class(TGuiControl)
  private type
    PRangeEventGuard = ^TRangeEventGuard;
    TRangeEventGuard = record
    private
      FPrevious: PRangeEventGuard;
      FAlive: Boolean;
    public
      property Previous: PRangeEventGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FRangeEventGuard: PRangeEventGuard;
    procedure BeginRangeEvent(var AGuard: TRangeEventGuard);
    procedure EndRangeEvent(var AGuard: TRangeEventGuard);
  private
    FGrabOffset: TGuiFloat;
    FRevision: Integer;
    FMinValue,FMaxValue,FStepSize: TGuiFloat;
    FValues,FPreview: array[TGuiRangeThumb] of TGuiFloat;
    FActiveThumb: TGuiRangeThumb;
    FOrientation: TGuiOrientation;
    FSnapMode: TGuiSnapMode;
    FLive,FDragging: Boolean;
    FOnChange: TGuiNotifyEvent;
    FOnMoved: TGuiRangeMovedEvent;
    procedure CancelDrag;
    procedure SetMinValue(AValue: TGuiFloat);
    procedure SetMaxValue(AValue: TGuiFloat);
    procedure SetLowerValue(AValue: TGuiFloat);
    procedure SetUpperValue(AValue: TGuiFloat);
    procedure SetStepSize(AValue: TGuiFloat);
    procedure SetOrientation(AValue: TGuiOrientation);
    procedure SetSnapMode(AValue: TGuiSnapMode);
    procedure SetLive(AValue: Boolean);
    procedure SetActiveThumb(AValue: TGuiRangeThumb);
    function GetLowerValue: TGuiFloat;
    function GetUpperValue: TGuiFloat;
    function GetPreview(AThumb: TGuiRangeThumb): TGuiFloat;
    procedure AssignValues(ALower,AUpper: TGuiFloat);
    function SnapValue(AValue: TGuiFloat): TGuiFloat;
    function RawValueAtPoint(const APoint: TGuiPoint): TGuiFloat;
    procedure MoveValue(AValue: TGuiFloat; ARelease: Boolean; ASnap: Boolean = True);
  protected
    function TrackRect: TGuiRect; virtual;
    function ThumbRect(AThumb: TGuiRangeThumb): TGuiRect; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
    procedure DoClick; override;
  public
    constructor Create; override;
    procedure SetValues(ALower,AUpper: TGuiFloat);
    destructor Destroy; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HandleFocusNavigation(AReverse: Boolean): Boolean; override;
    procedure PrepareFocusNavigation(AReverse: Boolean); override;
    function ValueAt(APosition: TGuiFloat): TGuiFloat;
    function Position(AThumb: TGuiRangeThumb): TGuiFloat;
    property MinValue: TGuiFloat read FMinValue write SetMinValue;
    property MaxValue: TGuiFloat read FMaxValue write SetMaxValue;
    property LowerValue: TGuiFloat read GetLowerValue write SetLowerValue;
    property UpperValue: TGuiFloat read GetUpperValue write SetUpperValue;
    property PreviewValue[AThumb: TGuiRangeThumb]: TGuiFloat read GetPreview;
    property ActiveThumb: TGuiRangeThumb read FActiveThumb write SetActiveThumb;
    property Orientation: TGuiOrientation read FOrientation write SetOrientation;
    property StepSize: TGuiFloat read FStepSize write SetStepSize;
    property SnapMode: TGuiSnapMode read FSnapMode write SetSnapMode;
    property Live: Boolean read FLive write SetLive;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
    property OnMoved: TGuiRangeMovedEvent read FOnMoved write FOnMoved;
  end;

  TGuiKnob = class(TGuiSlider)
  private
    FInputMode: TGuiKnobInputMode;
    FStartAngle,FEndAngle,FDragDistance,FDragValue: TGuiFloat;
    FDragOrigin: TGuiPoint;
    FWrap: Boolean;
    FHasPointerAngle: Boolean;
    FPreviousRatio: TGuiFloat;
    FPreviousAngle,FUnwrappedAngle: TGuiFloat;
    FPreviousRelative: Double;
    FPendingWrap: Integer;
    FOnWrapped: TGuiKnobWrapEvent;
    procedure NotifyWrap;
    procedure SetWrap(AValue: Boolean);
    procedure SetInputMode(AValue: TGuiKnobInputMode);
    procedure SetStartAngle(AValue: TGuiFloat);
    procedure SetEndAngle(AValue: TGuiFloat);
    procedure SetDragDistance(AValue: TGuiFloat);
    function DialRect: TGuiRect;
  protected
    function ValueFromPoint(const APoint: TGuiPoint; out AValue: TGuiFloat): Boolean; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure SetAngles(AStart,AEnd: TGuiFloat);
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property Wrap: Boolean read FWrap write SetWrap;
    property InputMode: TGuiKnobInputMode read FInputMode write SetInputMode;
    property StartAngle: TGuiFloat read FStartAngle write SetStartAngle;
    property EndAngle: TGuiFloat read FEndAngle write SetEndAngle;
    property DragDistance: TGuiFloat read FDragDistance write SetDragDistance;
    property OnWrapped: TGuiKnobWrapEvent read FOnWrapped write FOnWrapped;
  end;

  TGuiScrollBar = class(TGuiControl)
  private
    FMinValue: TGuiFloat;
    FMaxValue: TGuiFloat;
    FValue: TGuiFloat;
    FPageSize: TGuiFloat;
    FDragOffset: TGuiFloat;
    FOrientation: TGuiOrientation;
    FOnChange: TGuiNotifyEvent;
    procedure SetMinValue(AValue: TGuiFloat);
    procedure SetMaxValue(AValue: TGuiFloat);
    procedure SetValue(AValue: TGuiFloat);
    function TrackRect: TGuiRect;
    function ThumbRect: TGuiRect;
    procedure SetValueFromPoint(const APoint: TGuiPoint);
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property MinValue: TGuiFloat read FMinValue write SetMinValue;
    property MaxValue: TGuiFloat read FMaxValue write SetMaxValue;
    property Value: TGuiFloat read FValue write SetValue;
    property PageSize: TGuiFloat read FPageSize write FPageSize;
    property Orientation: TGuiOrientation read FOrientation write FOrientation;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
  end;

implementation

constructor TGuiSlider.Create;
begin
  inherited Create;
  FLive:=True;
  CanFocus:=True;
  TabStop:=True;
  FMinValue:=0;
  FMaxValue:=100;
  FValue:=50;
  FOrientation:=goHorizontal;
  Padding:=GuiBoxLTRB(8, 4, 8, 4);
end;

destructor TGuiSlider.Destroy;
var Guard: PSliderEventGuard;
begin
  Guard:=FSliderEventGuard;
  while Guard<>nil do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  inherited;
end;

procedure TGuiSlider.BeginSliderEvent(var AGuard: TSliderEventGuard);
begin
  AGuard.Previous:=FSliderEventGuard;
  AGuard.Alive:=True;
  FSliderEventGuard:=@AGuard;
end;

procedure TGuiSlider.EndSliderEvent(var AGuard: TSliderEventGuard);
begin
  FSliderEventGuard:=AGuard.Previous;
end;

procedure TGuiSlider.SetMinValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid slider minimum');
  FMinValue:=AValue;
  if FMaxValue < FMinValue then
    FMaxValue:=FMinValue;

  SetValue(FValue);
end;

procedure TGuiSlider.SetMaxValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid slider maximum');
  FMaxValue:=AValue;
  if FMinValue > FMaxValue then
    FMinValue:=FMaxValue;

  SetValue(FValue);
end;

procedure TGuiSlider.SetValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid slider value');
  CancelDrag;
  AssignValue(AValue);
end;

procedure TGuiSlider.CancelDrag;
begin
  FDragging:=False;
  Pressed:=False;
  FPreviewValue:=FValue;
end;

procedure TGuiSlider.SetStepSize(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then raise EArgumentException.Create('Invalid slider step');
  CancelDrag;
  FStepSize:=AValue;
end;

procedure TGuiSlider.SetLive(AValue: Boolean);
begin
  CancelDrag;
  FLive:=AValue;
end;

procedure TGuiSlider.SetSnapMode(AValue: TGuiSnapMode);
begin
  if (Ord(AValue)<Ord(Low(TGuiSnapMode))) OR (Ord(AValue)>Ord(High(TGuiSnapMode))) then
    raise EArgumentOutOfRangeException.Create('Invalid slider snap mode');
  CancelDrag;
  FSnapMode:=AValue;
end;

procedure TGuiSlider.SetOrientation(AValue: TGuiOrientation);
begin
  CancelDrag;
  FOrientation:=AValue;
end;

function TGuiSlider.GetPreviewValue: TGuiFloat;
begin
  if FDragging AND Enabled then Result:=FPreviewValue else Result:=FValue;
end;

function TGuiSlider.SnapValue(AValue: TGuiFloat): TGuiFloat;
var Offset: Double;
begin
  Result:=EnsureRange(AValue,FMinValue,FMaxValue);
  if (FStepSize>0) AND (Result>FMinValue) AND (Result<FMaxValue) then
  begin
    Offset:=Result;
    Offset:=(Offset-FMinValue)/FStepSize;
    Result:=EnsureRange(FMinValue+Int(Offset+0.5)*FStepSize,FMinValue,FMaxValue);
  end;
end;

procedure TGuiSlider.AssignValue(AValue: TGuiFloat);
begin
  if AValue < FMinValue then
    AValue:=FMinValue;

  if AValue > FMaxValue then
    AValue:=FMaxValue;

  if FValue = AValue then
    Exit;

  FValue:=AValue;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TGuiSlider.TrackRect: TGuiRect;
var
  Rect: TGuiRect;
begin
  Rect:=GuiInflateRect(AbsoluteBounds, Padding);
  if FOrientation = goHorizontal then
    Result:=GuiRect(Rect.Left, Rect.Top + ((Rect.Height - 4) / 2), Rect.Width, 4)
  else
    Result:=GuiRect(Rect.Left + ((Rect.Width - 4) / 2), Rect.Top, 4, Rect.Height);
end;

function TGuiSlider.ThumbRect: TGuiRect;
var
  Track: TGuiRect;
  Ratio: TGuiFloat;
  Lo,Hi,V: Double;
begin
  Track:=TrackRect;
  Ratio:=0;
  if FMaxValue > FMinValue then
  begin
    Lo:=FMinValue;
    Hi:=FMaxValue;
    V:=PreviewValue;
    Ratio:=(V-Lo)/(Hi-Lo);
  end;

  if FOrientation = goHorizontal then
    Result:=GuiRect(Track.Left + (Track.Width * Ratio) - 7, Track.Top - 6, 14, 16)
  else
    Result:=GuiRect(Track.Left - 6, Track.Top + Track.Height - (Track.Height * Ratio) - 7, 16, 14);
end;

function TGuiSlider.ValueFromPoint(const APoint: TGuiPoint; out AValue: TGuiFloat): Boolean;
var
  Track: TGuiRect;
  Ratio,Lo,Hi: Double;
begin
  Result:=False;
  Track:=TrackRect;
  if FOrientation = goHorizontal then
  begin
    if Track.Width <= 0 then
      Exit;

    Ratio:=APoint.X;
    Ratio:=(Ratio - Track.Left) / Track.Width;
  end else
  begin
    if Track.Height <= 0 then
      Exit;

    Ratio:=Track.Top;
    Ratio:=(Ratio + Track.Height - APoint.Y) / Track.Height;
  end;

  if Ratio < 0 then
    Ratio:=0;

  if Ratio > 1 then
    Ratio:=1;

  Lo:=FMinValue;
  Hi:=FMaxValue;
  AValue:=EnsureRange(Lo+(Hi-Lo)*Ratio,Lo,Hi);
  Result:=True;
end;

procedure TGuiSlider.SetValueFromPoint(const APoint: TGuiPoint; ARelease: Boolean);
var NewValue,OldPreview: TGuiFloat;
Guard: TSliderEventGuard;
begin
  BeginSliderEvent(Guard);
  try
  if NOT ValueFromPoint(APoint,NewValue) then Exit;
  if NOT Guard.Alive then Exit;
  if (FSnapMode=gsmSnapAlways) OR (ARelease AND (FSnapMode=gsmSnapOnRelease)) then NewValue:=SnapValue(NewValue);
  OldPreview:=PreviewValue;
  FPreviewValue:=NewValue;
  if FLive OR ARelease then AssignValue(NewValue);
  if NOT Guard.Alive then Exit;
  if NOT Enabled then Exit;
  if (OldPreview<>NewValue) AND Assigned(FOnMoved) then FOnMoved(Self);
  finally
    if Guard.Alive then EndSliderEvent(Guard);
  end;
end;

procedure TGuiSlider.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  Track: TGuiRect;
  Thumb: TGuiRect;
  Fill: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) then Exit;
  ACanvas.PushClipRect(Rect);
  try
  Track:=TrackRect;
  Thumb:=ThumbRect;
  if FOrientation = goHorizontal then
    Fill:=GuiRect(Track.Left, Track.Top, Thumb.Left + (Thumb.Width / 2) - Track.Left, Track.Height)
  else
    Fill:=GuiRect(Track.Left, Thumb.Top + (Thumb.Height / 2), Track.Width, Track.Top + Track.Height - Thumb.Top - (Thumb.Height / 2));

  ACanvas.FillRoundedRect(Track, Style.CornerRadius, Style.BorderColor);
  if Enabled then ACanvas.DrawSurface(Style.Thumb, Fill, Style.CornerRadius)
  else ACanvas.FillRoundedRect(Fill,Style.CornerRadius,Style.DisabledTextColor);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Thumb, Style.CornerRadius);
  DrawControlBorder(ACanvas, Thumb, GuiResolveBorderColor(Style, States));

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiSlider.HandleEvent(var AEvent: TGuiEvent);
var
  Step,NewValue: Double;
  OldValue: TGuiFloat;
  Guard: TSliderEventGuard;
begin
  BeginSliderEvent(Guard);
  try
  inherited HandleEvent(AEvent);
  if NOT Guard.Alive then Exit;
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur]) then
  begin
    CancelDrag;
    Exit;
  end;
  if (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27) AND FDragging then
  begin
    CancelDrag;
    AEvent.Handled:=True;
    Exit;
  end;
  case AEvent.Kind of
    gekMouseDown:
    begin
      if AEvent.Button<>gmbLeft then Exit;
      FDragging:=True;
      FPreviewValue:=FValue;
      SetValueFromPoint(AEvent.Position);
      AEvent.Handled:=True;
    end;

    gekMouseMove:
    begin
      if FDragging then
      begin
        SetValueFromPoint(AEvent.Position);
        AEvent.Handled:=True;
      end;
    end;

    gekMouseUp:
      if (AEvent.Button=gmbLeft) AND FDragging then
      begin
        AEvent.Handled:=True;
        SetValueFromPoint(AEvent.Position,True);
        if NOT Guard.Alive then Exit;
        CancelDrag;
      end;

    gekKeyDown,gekMouseWheel:
    begin
      if FDragging then Exit;
      Step:=FStepSize;
      if Step=0 then
      begin
        Step:=FMaxValue;
        Step:=(Step-FMinValue)/20;
      end;
      if Step <= 0 then
        Step:=1;
      NewValue:=FValue;
      if AEvent.Kind=gekMouseWheel then
      begin
        if AEvent.Delta.Y>0 then NewValue:=FValue+Step
        else if AEvent.Delta.Y<0 then NewValue:=FValue-Step;
      end else
      case AEvent.KeyCode of
        $40000050,$40000051: NewValue:=FValue-Step;
        $4000004F,$40000052: NewValue:=FValue+Step;
        $4000004A: NewValue:=FMinValue;
        $4000004D: NewValue:=FMaxValue;
        $4000004B: NewValue:=FValue+Step*10;
        $4000004E: NewValue:=FValue-Step*10;
        else Exit;
      end;
      if NewValue<FMinValue then NewValue:=FMinValue;
      if NewValue>FMaxValue then NewValue:=FMaxValue;
      OldValue:=FValue;
      AEvent.Handled:=(AEvent.Kind=gekKeyDown) OR (OldValue<>NewValue);
      AssignValue(NewValue);
      if NOT Guard.Alive then Exit;
      AEvent.Handled:=(AEvent.Kind=gekKeyDown) OR (OldValue<>FValue);
      if NOT Enabled then Exit;
      if (OldValue<>FValue) AND Assigned(FOnMoved) then FOnMoved(Self);
    end;
  end;
  finally
    if Guard.Alive then EndSliderEvent(Guard);
  end;
end;

constructor TGuiRangeSlider.Create;
begin
  inherited;
  CanFocus:=True;
  TabStop:=True;
  Bounds:=GuiRect(0,0,240,34);
  Padding:=GuiBox(10);
  FMaxValue:=100;
  FValues[grtLower]:=25;
  FValues[grtUpper]:=75;
  FLive:=True;
  CancelDrag;
end;

procedure TGuiRangeSlider.CancelDrag;
begin
  Inc(FRevision);
  FDragging:=False;
  Pressed:=False;
  FPreview:=FValues;
end;

destructor TGuiRangeSlider.Destroy;
var Guard: PRangeEventGuard;
begin
  Guard:=FRangeEventGuard;
  while Guard<>nil do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  inherited;
end;

procedure TGuiRangeSlider.BeginRangeEvent(var AGuard: TRangeEventGuard);
begin
  AGuard.Previous:=FRangeEventGuard;
  AGuard.Alive:=True;
  FRangeEventGuard:=@AGuard;
end;

procedure TGuiRangeSlider.EndRangeEvent(var AGuard: TRangeEventGuard);
begin
  FRangeEventGuard:=AGuard.Previous;
end;

procedure TGuiRangeSlider.AssignValues(ALower,AUpper: TGuiFloat);
begin
  AUpper:=EnsureRange(AUpper,FMinValue,FMaxValue);
  ALower:=EnsureRange(ALower,FMinValue,AUpper);
  if (FValues[grtLower]=ALower) AND (FValues[grtUpper]=AUpper) then Exit;
  FValues[grtLower]:=ALower;
  FValues[grtUpper]:=AUpper;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TGuiRangeSlider.SetValues(ALower,AUpper: TGuiFloat);
begin
  if IsNan(ALower) OR IsInfinite(ALower) OR IsNan(AUpper) OR IsInfinite(AUpper) then
    raise EArgumentException.Create('Invalid range-slider values');
  CancelDrag;
  AssignValues(ALower,AUpper);
end;

procedure TGuiRangeSlider.SetMinValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid range-slider minimum');
  CancelDrag;
  FMinValue:=AValue;
  FMaxValue:=Max(FMaxValue,FMinValue);
  AssignValues(FValues[grtLower],FValues[grtUpper]);
end;

procedure TGuiRangeSlider.SetMaxValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid range-slider maximum');
  CancelDrag;
  FMaxValue:=AValue;
  FMinValue:=Min(FMinValue,FMaxValue);
  AssignValues(FValues[grtLower],FValues[grtUpper]);
end;

procedure TGuiRangeSlider.SetLowerValue(AValue: TGuiFloat);
begin
  SetValues(AValue,FValues[grtUpper]);
end;

procedure TGuiRangeSlider.SetUpperValue(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then raise EArgumentException.Create('Invalid range-slider upper value');
  SetValues(FValues[grtLower],Max(AValue,FValues[grtLower]));
end;

function TGuiRangeSlider.GetLowerValue: TGuiFloat;
begin
  Result:=FValues[grtLower];
end;

function TGuiRangeSlider.GetUpperValue: TGuiFloat;
begin
  Result:=FValues[grtUpper];
end;

function TGuiRangeSlider.GetPreview(AThumb: TGuiRangeThumb): TGuiFloat;
begin
  if (Ord(AThumb)<Ord(Low(TGuiRangeThumb))) OR (Ord(AThumb)>Ord(High(TGuiRangeThumb))) then
    raise EArgumentException.Create('Invalid range-slider thumb');
  if FDragging AND Enabled then Result:=FPreview[AThumb] else Result:=FValues[AThumb];
end;

procedure TGuiRangeSlider.SetStepSize(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<0) then raise EArgumentException.Create('Invalid range-slider step');
  CancelDrag;
  FStepSize:=AValue;
end;

procedure TGuiRangeSlider.SetOrientation(AValue: TGuiOrientation);
begin
  if (Ord(AValue)<Ord(Low(TGuiOrientation))) OR (Ord(AValue)>Ord(High(TGuiOrientation))) then
    raise EArgumentException.Create('Invalid range-slider orientation');
  CancelDrag;
  FOrientation:=AValue;
end;

procedure TGuiRangeSlider.SetSnapMode(AValue: TGuiSnapMode);
begin
  if (Ord(AValue)<Ord(Low(TGuiSnapMode))) OR (Ord(AValue)>Ord(High(TGuiSnapMode))) then
    raise EArgumentException.Create('Invalid range-slider snap mode');
  CancelDrag;
  FSnapMode:=AValue;
end;

procedure TGuiRangeSlider.SetLive(AValue: Boolean);
begin
  CancelDrag;
  FLive:=AValue;
end;

procedure TGuiRangeSlider.SetActiveThumb(AValue: TGuiRangeThumb);
begin
  if (Ord(AValue)<Ord(Low(TGuiRangeThumb))) OR (Ord(AValue)>Ord(High(TGuiRangeThumb))) then
    raise EArgumentException.Create('Invalid range-slider thumb');
  CancelDrag;
  FActiveThumb:=AValue;
end;

function TGuiRangeSlider.SnapValue(AValue: TGuiFloat): TGuiFloat;
var Offset,Snapped: Double;
begin
  Result:=EnsureRange(AValue,FMinValue,FMaxValue);
  if (FStepSize<=0) OR (Result=FMinValue) OR (Result=FMaxValue) then Exit;
  Offset:=Result;
  Offset:=(Offset-FMinValue)/FStepSize;
  Snapped:=FStepSize;
  Snapped:=FMinValue+Int(Offset+0.5)*Snapped;
  Result:=Max(FMinValue,Min(FMaxValue,Snapped));
end;

function TGuiRangeSlider.ValueAt(APosition: TGuiFloat): TGuiFloat;
var Span: Double;
begin
  if IsNan(APosition) OR IsInfinite(APosition) then raise EArgumentException.Create('Invalid range-slider position');
  Span:=FMaxValue;
  Span:=Span-FMinValue;
  Result:=SnapValue(FMinValue+Span*EnsureRange(APosition,0,1));
end;

function TGuiRangeSlider.Position(AThumb: TGuiRangeThumb): TGuiFloat;
var Value,Span: Double;
begin
  Result:=0;
  if FMinValue=FMaxValue then Exit;
  Value:=GetPreview(AThumb);
  Span:=FMaxValue;
  Result:=EnsureRange((Value-FMinValue)/(Span-FMinValue),0,1);
end;

function TGuiRangeSlider.TrackRect: TGuiRect;
var R: TGuiRect;
begin
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  if FOrientation=goHorizontal then Result:=GuiRect(R.Left,R.Top+R.Height/2-2,R.Width,4)
  else Result:=GuiRect(R.Left+R.Width/2-2,R.Top,4,R.Height);
end;

function TGuiRangeSlider.ThumbRect(AThumb: TGuiRangeThumb): TGuiRect;
var R: TGuiRect;
P: TGuiFloat;
begin
  R:=TrackRect;
  P:=Position(AThumb);
  if FOrientation=goHorizontal then Result:=GuiRect(R.Left+R.Width*P-8,R.Top+R.Height/2-10,16,20)
  else Result:=GuiRect(R.Left+R.Width/2-10,R.Top+R.Height*(1-P)-8,20,16);
end;

procedure TGuiRangeSlider.PaintSelf(ACanvas: TGuiCanvas);
var Track,Fill,L,U,R: TGuiRect;
Thumb: TGuiRangeThumb;
States: TGuiControlVisualStates;
  procedure PaintThumb(AThumb: TGuiRangeThumb);
  begin
    States:=[gcvsNormal];
    if NOT Enabled then Include(States,gcvsDisabled);
    if Enabled AND Assigned(Context) AND GuiRectContains(ThumbRect(AThumb),Context.MousePosition) then
      Include(States,gcvsHovered);
    if AThumb=FActiveThumb then
    begin
      if FDragging then Include(States,gcvsPressed);
      if Focused then Include(States,gcvsFocused);
    end;
    R:=ThumbRect(AThumb);
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),R,Style.CornerRadius);
    DrawControlBorder(ACanvas,R,GuiResolveBorderColor(Style,States));
    if Enabled AND Focused AND FocusVisible AND (AThumb=FActiveThumb) then GuiPaintFocusIndicator(ACanvas,R,Style);
  end;
begin
  R:=AbsoluteBounds;
  if (R.Width<=0) OR (R.Height<=0) then Exit;
  ACanvas.PushClipRect(R);
  try
  Track:=TrackRect;
  L:=ThumbRect(grtLower);
  U:=ThumbRect(grtUpper);
  if FOrientation=goHorizontal then Fill:=GuiRect(L.Left+L.Width/2,Track.Top,U.Left-L.Left,Track.Height)
  else Fill:=GuiRect(Track.Left,U.Top+U.Height/2,Track.Width,L.Top-U.Top);
  ACanvas.FillRoundedRect(Track,Style.CornerRadius,Style.BorderColor);
  if Enabled then ACanvas.DrawSurface(Style.Thumb,Fill,Style.CornerRadius)
  else ACanvas.FillRoundedRect(Fill,Style.CornerRadius,Style.DisabledTextColor);
  for Thumb:=Low(TGuiRangeThumb) to High(TGuiRangeThumb) do if Thumb<>FActiveThumb then PaintThumb(Thumb);
  PaintThumb(FActiveThumb);
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiRangeSlider.DoClick;
begin
  { Mouse release must not change the active thumb. }
end;

function TGuiRangeSlider.RawValueAtPoint(const APoint: TGuiPoint): TGuiFloat;
var R: TGuiRect;
Ratio,Span: Double;
begin
  R:=TrackRect;
  Ratio:=0;
  if FOrientation=goHorizontal then
  begin
    if R.Width>0 then Ratio:=(APoint.X-FGrabOffset-R.Left)/R.Width;
  end
  else if R.Height>0 then Ratio:=1-(APoint.Y-FGrabOffset-R.Top)/R.Height;
  Span:=FMaxValue;
  Span:=Span-FMinValue;
  Result:=FMinValue+Span*EnsureRange(Ratio,0,1);
end;

procedure TGuiRangeSlider.MoveValue(AValue: TGuiFloat; ARelease: Boolean; ASnap: Boolean);
var OldValue: TGuiFloat;
Thumb: TGuiRangeThumb;
Revision: Integer;
Commit: Boolean;
  Guard: TRangeEventGuard;
begin
  BeginRangeEvent(Guard);
  try
  Thumb:=FActiveThumb;
  OldValue:=GetPreview(Thumb);
  if ASnap AND ((FSnapMode=gsmSnapAlways) OR ((FSnapMode=gsmSnapOnRelease) AND ARelease)) then AValue:=SnapValue(AValue);
  if Thumb=grtLower then AValue:=EnsureRange(AValue,FMinValue,FValues[grtUpper])
  else AValue:=EnsureRange(AValue,FValues[grtLower],FMaxValue);
  Commit:=FLive OR ARelease OR NOT FDragging;
  FPreview[Thumb]:=AValue;
  if ARelease then
  begin
    FDragging:=False;
    Pressed:=False;
  end;
  Revision:=FRevision;
  if Commit then
  begin
    if Thumb=grtLower then AssignValues(AValue,FValues[grtUpper]) else AssignValues(FValues[grtLower],AValue);
  end;
  if NOT Guard.Alive then Exit;
  if NOT Enabled then Exit;
  if (Revision=FRevision) AND (OldValue<>AValue) AND Assigned(FOnMoved) then FOnMoved(Self,Thumb);
  finally
    if Guard.Alive then EndRangeEvent(Guard);
  end;
end;

procedure TGuiRangeSlider.HandleEvent(var AEvent: TGuiEvent);
var L,U,R: TGuiRect;
LowerDistance,UpperDistance,Coordinate,OldValue: TGuiFloat;
  Step,NewValue: Double;
  Guard: TRangeEventGuard;
begin
  BeginRangeEvent(Guard);
  try
  inherited;
  if NOT Guard.Alive then Exit;
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur]) then
  begin
    CancelDrag;
    Exit;
  end;
  if (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27) AND FDragging then
  begin
    CancelDrag;
    AEvent.Handled:=True;
    Exit;
  end;
  case AEvent.Kind of
    gekMouseDown:
      if AEvent.Button=gmbLeft then
      begin
        CancelDrag;
        L:=ThumbRect(grtLower);
        U:=ThumbRect(grtUpper);
        if FOrientation=goHorizontal then
        begin
          Coordinate:=AEvent.Position.X;
          LowerDistance:=Coordinate-L.Left-L.Width/2;
          UpperDistance:=Coordinate-U.Left-U.Width/2;
        end
        else
        begin
          Coordinate:=AEvent.Position.Y;
          LowerDistance:=Coordinate-L.Top-L.Height/2;
          UpperDistance:=Coordinate-U.Top-U.Height/2;
        end;
        if Abs(LowerDistance)<Abs(UpperDistance) then FActiveThumb:=grtLower
        else if Abs(UpperDistance)<Abs(LowerDistance) then FActiveThumb:=grtUpper
        else if FValues[grtLower]=FValues[grtUpper] then
        begin
          if ((FOrientation=goHorizontal) AND (LowerDistance<0)) OR
            ((FOrientation=goVertical) AND (LowerDistance>0)) then FActiveThumb:=grtLower
          else if LowerDistance<>0 then FActiveThumb:=grtUpper;
        end;
        R:=ThumbRect(FActiveThumb);
        FGrabOffset:=0;
        if GuiRectContains(R,AEvent.Position) then
        begin
          if FOrientation=goHorizontal then FGrabOffset:=Coordinate-R.Left-R.Width/2
          else FGrabOffset:=Coordinate-R.Top-R.Height/2;
        end;
        FDragging:=True;
        Pressed:=True;
        FPreview:=FValues;
        AEvent.Handled:=True;
        MoveValue(RawValueAtPoint(AEvent.Position),False);
      end;
    gekMouseMove:
      if FDragging then
      begin
        AEvent.Handled:=True;
        MoveValue(RawValueAtPoint(AEvent.Position),False);
      end;
    gekMouseUp:
      if (AEvent.Button=gmbLeft) AND FDragging then
      begin
        AEvent.Handled:=True;
        MoveValue(RawValueAtPoint(AEvent.Position),True);
      end;
    gekKeyDown,gekMouseWheel:
      begin
        if FDragging then Exit;
        if (AEvent.Kind=gekKeyDown) AND ((AEvent.KeyCode=32) OR (AEvent.KeyCode=13)) then
        begin
          if FActiveThumb=grtLower then ActiveThumb:=grtUpper else ActiveThumb:=grtLower;
          AEvent.Handled:=True;
          Exit;
        end;
        Step:=FStepSize;
        if Step=0 then
        begin
          Step:=FMaxValue;
          Step:=(Step-FMinValue)/20;
        end;
        if Step<=0 then Step:=1;
        OldValue:=FValues[FActiveThumb];
        NewValue:=OldValue;
        if AEvent.Kind=gekMouseWheel then
        begin
          if AEvent.Delta.Y>0 then NewValue:=OldValue+Step else if AEvent.Delta.Y<0 then NewValue:=OldValue-Step;
        end
        else case AEvent.KeyCode of
          $40000050,$40000051: NewValue:=OldValue-Step;
          $4000004F,$40000052: NewValue:=OldValue+Step;
          $4000004A: NewValue:=FMinValue;
          $4000004D: NewValue:=FMaxValue;
          $4000004B: NewValue:=OldValue+Step*10;
          $4000004E: NewValue:=OldValue-Step*10;
          else Exit;
        end;
        if FActiveThumb=grtLower then NewValue:=EnsureRange(NewValue,FMinValue,FValues[grtUpper])
        else NewValue:=EnsureRange(NewValue,FValues[grtLower],FMaxValue);
        AEvent.Handled:=(AEvent.Kind=gekKeyDown) OR (NewValue<>OldValue);
        MoveValue(NewValue,True,False);
      end;
  end;
  finally
    if Guard.Alive then EndRangeEvent(Guard);
  end;
end;

constructor TGuiKnob.Create;
begin
  inherited Create;
  FStartAngle:=135;
  FEndAngle:=405;
  FDragDistance:=150;
  Bounds:=GuiRect(0,0,100,100);
  Padding:=GuiBox(6);
end;

procedure TGuiKnob.SetWrap(AValue: Boolean);
begin
  CancelDrag;
  FHasPointerAngle:=False;
  FWrap:=AValue;
end;

procedure TGuiKnob.SetInputMode(AValue: TGuiKnobInputMode);
begin
  if (Ord(AValue)<Ord(Low(TGuiKnobInputMode))) OR (Ord(AValue)>Ord(High(TGuiKnobInputMode))) then
    raise EArgumentOutOfRangeException.Create('Invalid knob input mode');
  CancelDrag;
  FHasPointerAngle:=False;
  FInputMode:=AValue;
end;

procedure TGuiKnob.SetAngles(AStart,AEnd: TGuiFloat);
begin
  if IsNan(AStart) OR IsInfinite(AStart) OR IsNan(AEnd) OR IsInfinite(AEnd) OR
    (AStart< -360) OR (AEnd>720) OR (AEnd<=AStart) OR (AEnd-AStart>360) then
    raise EArgumentException.Create('Invalid knob angle range');
  CancelDrag;
  FHasPointerAngle:=False;
  FStartAngle:=AStart;
  FEndAngle:=AEnd;
end;

procedure TGuiKnob.SetStartAngle(AValue: TGuiFloat);
begin
  SetAngles(AValue,FEndAngle);
end;

procedure TGuiKnob.SetEndAngle(AValue: TGuiFloat);
begin
  SetAngles(FStartAngle,AValue);
end;

procedure TGuiKnob.SetDragDistance(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<1) then
    raise EArgumentException.Create('Invalid knob drag distance');
  CancelDrag;
  FDragDistance:=AValue;
end;

function TGuiKnob.DialRect: TGuiRect;
var R: TGuiRect;
Size: TGuiFloat;
begin
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  Size:=Max(0,Min(R.Width,R.Height));
  Result:=GuiRect(R.Left+(R.Width-Size)/2,R.Top+(R.Height-Size)/2,Size,Size);
end;

function TGuiKnob.ValueFromPoint(const APoint: TGuiPoint; out AValue: TGuiFloat): Boolean;
var R: TGuiRect;
X,Y,Angle,Ratio,Span,Delta: TGuiFloat;
RelativeValue,RangeSize: Double;
  function TurnOf(V: Double): Double;
  var N: Double;
  begin
    N:=(V-MinValue)/RangeSize;
    if (N>=0) AND (N<=1) then Exit(0);
    Result:=Int(N);
    if N<Result then Result:=Result-1;
  end;
begin
  Result:=False;
  R:=DialRect;
  if R.Width<=0 then Exit;
  if FInputMode<>gkiCircular then
  begin
    if FInputMode=gkiHorizontal then RelativeValue:=APoint.X-FDragOrigin.X
    else RelativeValue:=FDragOrigin.Y-APoint.Y;
    RangeSize:=MaxValue;
    RangeSize:=RangeSize-MinValue;
    RelativeValue:=FDragValue+RelativeValue/FDragDistance*RangeSize;
    if Wrap AND (RangeSize>0) AND (TurnOf(RelativeValue)<>TurnOf(FPreviousRelative)) then
      if RelativeValue>FPreviousRelative then FPendingWrap:=1 else FPendingWrap:=-1;
    FPreviousRelative:=RelativeValue;
    if Wrap AND (RangeSize>0) AND ((RelativeValue<MinValue) OR (RelativeValue>MaxValue)) then
    begin
      RelativeValue:=RelativeValue-MinValue;
      RelativeValue:=Frac(RelativeValue/RangeSize);
      if RelativeValue<0 then RelativeValue:=RelativeValue+1;
      RelativeValue:=RelativeValue*RangeSize+MinValue;
    end;
    AValue:=EnsureRange(RelativeValue,MinValue,MaxValue);
    Result:=True;
    Exit;
  end;
  X:=APoint.X-R.Left-R.Width/2;
  Y:=APoint.Y-R.Top-R.Height/2;
  if X*X+Y*Y<4 then Exit;
  Span:=FEndAngle-FStartAngle;
  Angle:=RadToDeg(ArcTan2(Y,X))-FStartAngle;
  while Angle<0 do Angle:=Angle+360;
  while Angle>=360 do Angle:=Angle-360;
  if Angle<=Span then Ratio:=Angle/Span
  else if Angle<(Span+360)/2 then Ratio:=1 else Ratio:=0;
  if FHasPointerAngle then
  begin
    Delta:=Angle-FPreviousAngle;
    if Delta>180 then Delta:=Delta-360 else if Delta< -180 then Delta:=Delta+360;
    FUnwrappedAngle:=FUnwrappedAngle+Delta;
    if Wrap then
    begin
      if (Delta>0) AND (Ratio<FPreviousRatio) then FPendingWrap:=1
      else if (Delta<0) AND (Ratio>FPreviousRatio) then FPendingWrap:=-1;
    end
    else Ratio:=EnsureRange(FUnwrappedAngle/Span,0,1);
  end else
  begin
    FUnwrappedAngle:=Angle;
    if (Angle>Span) AND (Ratio=0) then FUnwrappedAngle:=Angle-360;
  end;
  FPreviousAngle:=Angle;
  FPreviousRatio:=Ratio;
  FHasPointerAngle:=True;
  RangeSize:=MaxValue;
  RangeSize:=RangeSize-MinValue;
  AValue:=EnsureRange(MinValue+RangeSize*Ratio,MinValue,MaxValue);
  Result:=True;
end;

procedure TGuiKnob.NotifyWrap;
var Direction: TGuiWrapDirection;
begin
  if FPendingWrap=0 then Exit;
  if FPendingWrap>0 then Direction:=gwdClockwise else Direction:=gwdCounterClockwise;
  FPendingWrap:=0;
  if Wrap AND Enabled AND (MaxValue>MinValue) AND Assigned(FOnWrapped) then FOnWrapped(Self,Direction);
end;

procedure TGuiKnob.HandleEvent(var AEvent: TGuiEvent);
var Direction: Integer;
Old: TGuiFloat;
Step,Next: Double;
  Guard: TSliderEventGuard;
begin
  BeginSliderEvent(Guard);
  try
  FPendingWrap:=0;
  if Enabled AND (AEvent.Kind=gekMouseDown) AND (AEvent.Button=gmbLeft) then
  begin
    FDragOrigin:=AEvent.Position;
    FDragValue:=Value;
    FPreviousRelative:=Value;
  end;
  if ((AEvent.Kind=gekMouseDown) AND (AEvent.Button=gmbLeft)) OR
    (AEvent.Kind IN [gekCancel,gekBlur]) then FHasPointerAngle:=False;
  if Wrap AND Enabled AND NOT FDragging AND (AEvent.Kind IN [gekKeyDown,gekMouseWheel]) then
  begin
    Direction:=0;
    if AEvent.Kind=gekMouseWheel then
    begin
      if AEvent.Delta.Y>0 then Direction:=1 else if AEvent.Delta.Y<0 then Direction:=-1;
    end else
      case AEvent.KeyCode of
        $4000004F,$40000052: Direction:=1;
        $40000050,$40000051: Direction:=-1;
      end;
    if Direction<>0 then
    begin
      Step:=StepSize;
      if Step=0 then
      begin
        Step:=MaxValue;
        Step:=(Step-MinValue)/20;
      end;
      Next:=Value+Direction*Step;
      if Next>MaxValue then
      begin
        Next:=MinValue;
        FPendingWrap:=1;
      end
      else if Next<MinValue then
      begin
        Next:=MaxValue;
        FPendingWrap:=-1;
      end;
      Old:=Value;
      AssignValue(Next);
      AEvent.Handled:=True;
      if NOT Guard.Alive then Exit;
      if NOT Enabled then Exit;
      if (Value<>Old) AND Assigned(FOnMoved) then FOnMoved(Self);
      if NOT Guard.Alive then Exit;
      NotifyWrap;
      Exit;
    end;
  end;
  inherited;
  if NOT Guard.Alive then Exit;
  NotifyWrap;
  if NOT Guard.Alive then Exit;
  if AEvent.Kind=gekMouseUp then FHasPointerAngle:=False;
  finally
    if Guard.Alive then EndSliderEvent(Guard);
  end;
end;

procedure TGuiKnob.PaintSelf(ACanvas: TGuiCanvas);
var R,Body: TGuiRect;
Center,P,Q: TGuiPoint;
Radius,A,B,Ratio: TGuiFloat;
  RangeSize,Offset: Double;
  I: Integer;
  States: TGuiControlVisualStates;
  Color: TGuiColor;
begin
  R:=DialRect;
  if R.Width<4 then Exit;
  Center:=GuiPoint(R.Left+R.Width/2,R.Top+R.Height/2);
  Radius:=Max(0,R.Width/2-2);
  Ratio:=0;
  if MaxValue>MinValue then
  begin
    RangeSize:=MaxValue;
    RangeSize:=RangeSize-MinValue;
    Offset:=PreviewValue;
    Ratio:=(Offset-MinValue)/RangeSize;
  end;
  States:=[gcvsNormal];
  if Hovered then Include(States,gcvsHovered);
  if Pressed then Include(States,gcvsPressed);
  if NOT Enabled then Include(States,gcvsDisabled);
  ACanvas.PushClipRect(AbsoluteBounds);
  try
    for I:=0 to 63 do
    begin
      A:=DegToRad(FStartAngle+(FEndAngle-FStartAngle)*I/64);
      B:=DegToRad(FStartAngle+(FEndAngle-FStartAngle)*(I+1)/64);
      P:=GuiPoint(Center.X+Cos(A)*Radius,Center.Y+Sin(A)*Radius);
      Q:=GuiPoint(Center.X+Cos(B)*Radius,Center.Y+Sin(B)*Radius);
      Color:=Style.BorderColor;
      if (I+1)/64<=Ratio then Color:=Style.CheckedBorderColor;
      if NOT Enabled then Color:=Style.DisabledTextColor;
      ACanvas.DrawLine(P,Q,2,Color);
    end;
    Body:=GuiInflateRect(R,GuiBox(Min(8,R.Width/4)));
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),Body,Body.Width/2);
    ACanvas.DrawRoundedBorder(Body,Body.Width/2,Style.BorderWidth,GuiResolveBorderColor(Style,States));
    A:=DegToRad(FStartAngle+(FEndAngle-FStartAngle)*Ratio);
    Radius:=Body.Width/2;
    P:=GuiPoint(Center.X+Cos(A)*Radius*0.4,Center.Y+Sin(A)*Radius*0.4);
    Q:=GuiPoint(Center.X+Cos(A)*Radius*0.8,Center.Y+Sin(A)*Radius*0.8);
    Color:=Style.CheckedBorderColor;
    if NOT Enabled then Color:=Style.DisabledTextColor;
    ACanvas.DrawLine(P,Q,3,Color);
    if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas,AbsoluteBounds,Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

constructor TGuiScrollBar.Create;
begin
  inherited Create;
  CanFocus:=False;
  TabStop:=False;
  ShowFocus:=False;
  FMinValue:=0;
  FMaxValue:=100;
  FValue:=0;
  FPageSize:=20;
  FOrientation:=goVertical;
  Padding:=GuiBox(2);
end;

procedure TGuiScrollBar.SetMinValue(AValue: TGuiFloat);
begin
  FMinValue:=AValue;
  if FMaxValue < FMinValue then
    FMaxValue:=FMinValue;

  SetValue(FValue);
end;

procedure TGuiScrollBar.SetMaxValue(AValue: TGuiFloat);
begin
  FMaxValue:=AValue;
  if FMinValue > FMaxValue then
    FMinValue:=FMaxValue;

  SetValue(FValue);
end;

procedure TGuiScrollBar.SetValue(AValue: TGuiFloat);
begin
  if AValue < FMinValue then
    AValue:=FMinValue;

  if AValue > FMaxValue then
    AValue:=FMaxValue;

  if FValue = AValue then
    Exit;

  FValue:=AValue;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TGuiScrollBar.TrackRect: TGuiRect;
var Size: TGuiFloat;
begin
  Result:=GuiInflateRect(AbsoluteBounds, Padding);
  Size:=Max(8, Style.ScrollBarSize);
  if FOrientation = goVertical then
  begin
    Size:=Min(Size, Result.Width);
    Result.Left:=Result.Left + (Result.Width - Size) / 2;
    Result.Width:=Size;
  end else
  begin
    Size:=Min(Size, Result.Height);
    Result.Top:=Result.Top + (Result.Height - Size) / 2;
    Result.Height:=Size;
  end;
end;

function TGuiScrollBar.ThumbRect: TGuiRect;
var
  Track: TGuiRect;
  Range: TGuiFloat;
  Ratio: TGuiFloat;
  ThumbSize: TGuiFloat;
begin
  Track:=TrackRect;
  Range:=FMaxValue - FMinValue;
  Ratio:=0;
  if Range > 0 then
    Ratio:=(FValue - FMinValue) / Range;

  if FOrientation = goHorizontal then
  begin
    ThumbSize:=Track.Width;
    if Range > 0 then
      ThumbSize:=Track.Width * (Max(0, FPageSize) / (Range + Max(0, FPageSize)));

    if ThumbSize < 24 then
      ThumbSize:=24;

    if ThumbSize > Track.Width then
      ThumbSize:=Track.Width;

    Result:=GuiRect(Track.Left + ((Track.Width - ThumbSize) * Ratio), Track.Top, ThumbSize, Track.Height);
  end else
  begin
    ThumbSize:=Track.Height;
    if Range > 0 then
      ThumbSize:=Track.Height * (Max(0, FPageSize) / (Range + Max(0, FPageSize)));

    if ThumbSize < 24 then
      ThumbSize:=24;

    if ThumbSize > Track.Height then
      ThumbSize:=Track.Height;

    Result:=GuiRect(Track.Left, Track.Top + ((Track.Height - ThumbSize) * Ratio), Track.Width, ThumbSize);
  end;
end;

procedure TGuiScrollBar.SetValueFromPoint(const APoint: TGuiPoint);
var
  Track: TGuiRect;
  Thumb: TGuiRect;
  Ratio: TGuiFloat;
  Travel: TGuiFloat;
begin
  Track:=TrackRect;
  Thumb:=ThumbRect;

  if FOrientation = goHorizontal then
  begin
    Travel:=Track.Width - Thumb.Width;
    if Travel <= 0 then
      Exit;

    Ratio:=(APoint.X - Track.Left - FDragOffset) / Travel;
  end else
  begin
    Travel:=Track.Height - Thumb.Height;
    if Travel <= 0 then
      Exit;

    Ratio:=(APoint.Y - Track.Top - FDragOffset) / Travel;
  end;

  if Ratio < 0 then
    Ratio:=0;

  if Ratio > 1 then
    Ratio:=1;

  SetValue(FMinValue + ((FMaxValue - FMinValue) * Ratio));
end;

procedure TGuiScrollBar.PaintSelf(ACanvas: TGuiCanvas);
var
  Track: TGuiRect;
  Thumb: TGuiRect;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);

  if Pressed then
    Include(States, gcvsPressed);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  Track:=TrackRect;
  Thumb:=ThumbRect;
  if NOT ((Style.Background.Kind = gdkBrush) AND (Style.Background.Brush.Kind = gbkColor)) then
    ACanvas.DrawSurface(Style.Background, AbsoluteBounds, Style.CornerRadius);
  PaintScrollBar(ACanvas, Track, Thumb, FOrientation, Pressed);

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

procedure TGuiScrollBar.HandleEvent(var AEvent: TGuiEvent);
var
  Step: TGuiFloat;
  Thumb: TGuiRect;
begin
  inherited HandleEvent(AEvent);

  case AEvent.Kind of
    gekMouseDown:
    begin
      if AEvent.Button <> gmbLeft then Exit;
      Thumb:=ThumbRect;
      if FOrientation = goHorizontal then
      begin
        FDragOffset:=Thumb.Width / 2;
        if GuiRectContains(Thumb, AEvent.Position) then FDragOffset:=AEvent.Position.X - Thumb.Left;
      end else
      begin
        FDragOffset:=Thumb.Height / 2;
        if GuiRectContains(Thumb, AEvent.Position) then FDragOffset:=AEvent.Position.Y - Thumb.Top;
      end;
      SetValueFromPoint(AEvent.Position);
      AEvent.Handled:=True;
    end;

    gekMouseMove:
    begin
      if Pressed then
      begin
        SetValueFromPoint(AEvent.Position);
        AEvent.Handled:=True;
      end;
    end;

    gekMouseWheel:
    begin
      SetValue(FValue - AEvent.Delta.Y);
      AEvent.Handled:=True;
    end;

    gekKeyDown:
    begin
      Step:=1;
      if FPageSize > 1 then
        Step:=FPageSize / 10;

      case AEvent.KeyCode of
        $40000050, $40000052:
        begin
          SetValue(FValue - Step);
          AEvent.Handled:=True;
        end;

        $4000004F, $40000051:
        begin
          SetValue(FValue + Step);
          AEvent.Handled:=True;
        end;

        $4000004A:
        begin
          SetValue(FMinValue);
          AEvent.Handled:=True;
        end;

        $4000004D:
        begin
          SetValue(FMaxValue);
          AEvent.Handled:=True;
        end;
      end;
    end;
  end;
end;

function TGuiRangeSlider.HandleFocusNavigation(AReverse: Boolean): Boolean;
begin
  Result:=((NOT AReverse) AND (ActiveThumb = grtLower)) OR
    (AReverse AND (ActiveThumb = grtUpper));
  if NOT Result then
    Exit;
  if AReverse then
    ActiveThumb:=grtLower
  else
    ActiveThumb:=grtUpper;
end;

procedure TGuiRangeSlider.PrepareFocusNavigation(AReverse: Boolean);
begin
  if AReverse then
    ActiveThumb:=grtUpper
  else
    ActiveThumb:=grtLower;
end;

end.
