unit PasSDL3.GUI.Controls.Text;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Text,
  PasSDL3.GUI.Grapheme,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Clipboard,
  PasSDL3.GUI.Core;

type
  TGuiLabel = class(TGuiControl)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
  end;

  TGuiLinkLabel = class(TGuiLabel)
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
  end;

  TGuiValueLabel = class(TGuiControl)
  private
    FValueText: String;
    FUnitText: String;
    FValueWidth: TGuiFloat;
    FCaptionColor: TGuiColor;
    FValueColor: TGuiColor;
    FUnitColor: TGuiColor;
  public
    property ValueText: String read FValueText write FValueText;
    property UnitText: String read FUnitText write FUnitText;
    property ValueWidth: TGuiFloat read FValueWidth write FValueWidth;
    property CaptionColor: TGuiColor read FCaptionColor write FCaptionColor;
    property ValueColor: TGuiColor read FValueColor write FValueColor;
    property UnitColor: TGuiColor read FUnitColor write FUnitColor;
    constructor Create; override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiEditState = record
  private
    FText: String;
    FCaret: Integer;
    FAnchor: Integer;
  public
    property Text: String read FText write FText;
    property Caret: Integer read FCaret write FCaret;
    property Anchor: Integer read FAnchor write FAnchor;
  end;

  TGuiEdit = class(TGuiControl)
  private
    FGraphemes: TGuiGraphemeMap;
    FHistory: array of TGuiEditState;
    FHistoryIndex: Integer;
    FRestoringHistory: Boolean;
    FComposition: String;
    FCompositionStart, FCompositionLength: Integer;
    FCompositionCancellationRevision: UInt64;
    FMultiLine: Boolean;
    FText: String;
    FCaretIndex: Integer;
    FPlaceholder: String;
    FPasswordChar: Char;
    FMaxLength: Integer;
    FTextOffsetX: TGuiFloat;
    FMeasuredText: String;
    FMeasuredFont: String;
    FCaretPositions: array of TGuiFloat;
    FSelectionAnchor: Integer;
    FSelectionStart: Integer;
    FSelectionEnd: Integer;
    FReadOnly: Boolean;
    FCaretBlink: Boolean;
    FCaretBlinkInterval: Cardinal;
    FLastCaretBlinkTime: UInt64;
    FCaretBlinkVisible: Boolean;
    FOnChange: TGuiNotifyEvent;
    FOnSubmit: TGuiNotifyEvent;
    procedure MoveCaretFromPoint(const APoint: TGuiPoint; AExtend: Boolean);
    function TextAlignmentOffset: TGuiFloat;
    function AlignmentOffsetForWidth(AWidth: TGuiFloat): TGuiFloat;
    procedure ScrollCaretIntoView(AX: TGuiFloat);
    function CompositionPixelX(ACanvas: TGuiCanvas; AOffset: Integer): TGuiFloat;
    procedure SaveUndoSelection;
    procedure SetComposition(const AEvent: TGuiEvent);
    procedure SetReadOnly(AValue: Boolean);
    function GetCompositionCursor: Integer;
    function GetCompositionSelectionLength: Integer;
    function CompositionInsertionStart: Integer;
    function CompositionTextValue: String;
    procedure SetText(const AValue: String);
    procedure SetCaretIndex(AValue: Integer);
    function DisplayText: String;
    function TextForMeasurement: String;
    procedure UpdateTextMetrics(ACanvas: TGuiCanvas);
    procedure EnsureCaretVisible;
    function CaretPixelX(AIndex: Integer): TGuiFloat;
    function CaretIndexFromPixelX(AX: TGuiFloat): Integer;
    procedure SelectWordAt(AIndex: Integer);
    procedure DeleteSelection;
    function WordStart(AIndex: Integer): Integer;
    function WordEnd(AIndex: Integer): Integer;
    procedure MoveCaret(AIndex: Integer; AExtendSelection: Boolean);
    procedure InsertText(const AText: String);
    procedure DeleteBeforeCaret;
    procedure DeleteAtCaret;
    procedure DeleteWordBeforeCaret;
    procedure DeleteWordAtCaret;
    function PointToCaretIndex(const APoint: TGuiPoint): Integer; virtual;
    procedure DoSubmit;
  protected
    function NormalizeText(const AText: String): String;
    function TextRect: TGuiRect; virtual;
    procedure InvalidateTextMetrics;
    function IsGraphemeBoundary(const AText: String;
      AIndex: Integer): Boolean;
    procedure AssignTextSilently(const AValue: String);
    procedure RecordChange;
    procedure DoChange; virtual;
    procedure DoUserChange; virtual;
    procedure DoTextInserted; virtual;
    procedure HandleControlEvent(var AEvent: TGuiEvent);
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure DetachedFromContext; override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    function HasSelection: Boolean;
    function SelectedText: String;
    procedure ClearSelection;
    procedure SetSelection(AAnchor, ACaret: Integer);
    procedure SelectAll;
    procedure CopySelectionToClipboard;
    procedure CutSelectionToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure Redo;
    { Hosts call before dispatching input when text/font state changed since paint. }
    procedure PrepareTextLayout(ACanvas: TGuiCanvas); virtual;
    function TextInputRect(ACanvas: TGuiCanvas): TGuiRect; virtual;
    property CompositionText: String read FComposition;
    { Native String offsets within CompositionText. }
    property CompositionCursor: Integer read GetCompositionCursor;
    property CompositionSelectionLength: Integer read GetCompositionSelectionLength;
    procedure CancelComposition;
    property CompositionCancellationRevision: UInt64 read FCompositionCancellationRevision;
    property Text: String read FText write SetText;
    property CaretIndex: Integer read FCaretIndex write SetCaretIndex;
    property SelectionStart: Integer read FSelectionStart;
    property SelectionEnd: Integer read FSelectionEnd;
    property Placeholder: String read FPlaceholder write FPlaceholder;
    property PasswordChar: Char read FPasswordChar write FPasswordChar;
    property MaxLength: Integer read FMaxLength write FMaxLength;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property CaretBlink: Boolean read FCaretBlink write FCaretBlink;
    property CaretBlinkInterval: Cardinal read FCaretBlinkInterval write FCaretBlinkInterval;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
    property OnSubmit: TGuiNotifyEvent read FOnSubmit write FOnSubmit;
  end;

  TGuiMemo = class(TGuiEdit)
  private
    FPreviewRows: TGuiTextRows;
    FPreviewText,FPreviewKey: String;
    FPreviewRow,FPreviewStop: Integer;
    procedure UpdateCompositionRows(ACanvas: TGuiCanvas);
    function HasCompositionRows: Boolean;
    function CompositionInputRect: TGuiRect;
    procedure PaintCompositionRows(ACanvas: TGuiCanvas);
  private
    FWordWrap: Boolean;
    FVisualRows: TGuiTextRows;
    FVisualText, FVisualFont: String;
    FVisualWidth, FVisualHeight, FVisualBarSize, FVisualLineHeight: TGuiFloat;
    FVisualWrapped, FVisualValid: Boolean;
    FPreferredRow, FPreferredCaret: Integer;
    FDesiredX: TGuiFloat;
    procedure SetWordWrap(AValue: Boolean);
    procedure UpdateVisualRows(ACanvas: TGuiCanvas);
    function GetVisualLineCount: Integer;
    function VisualCaretRow: Integer;
    function VisualRowX(ARow, AIndex: Integer): TGuiFloat;
    function VisualRowIndex(ARow: Integer; AX: TGuiFloat): Integer;
    function PointToCaretIndex(const APoint: TGuiPoint): Integer; override;
  private
    FSyncLines: Boolean;
    FLastPaintCaret: Integer;
    FLines: TStringList;
    FLineHeight: TGuiFloat;
    FScrollY: TGuiFloat;
    FDraggingScrollBar: Boolean;
    FDragStartY: TGuiFloat;
    FDragStartScrollY: TGuiFloat;
    procedure LinesChanged(Sender: TObject);
    function LineStart(ALine: Integer): Integer;
    function CaretLine: Integer;
    function IndexAtPoint(const APoint: TGuiPoint): Integer;
    procedure SetScrollY(AValue: TGuiFloat);
    function GetMaxScrollY: TGuiFloat;
    function GetContentRect: TGuiRect;
    function GetScrollBarRect: TGuiRect;
    function GetScrollThumbRect: TGuiRect;
    function ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
  protected
    procedure DoChange; override;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddLine(const AText: String): Integer;
    procedure ClearLines;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    procedure PrepareTextLayout(ACanvas: TGuiCanvas); override;
    property Lines: TStringList read FLines;
    property LineHeight: TGuiFloat read FLineHeight write FLineHeight;
    property ScrollY: TGuiFloat read FScrollY write SetScrollY;
    property MaxScrollY: TGuiFloat read GetMaxScrollY;
    property WordWrap: Boolean read FWordWrap write SetWordWrap;
    property VisualLineCount: Integer read GetVisualLineCount;
    function TextInputRect(ACanvas: TGuiCanvas): TGuiRect; override;
  end;

  TGuiSpinEdit = class(TGuiEdit)
  private type
    PNotifyGuard = ^TNotifyGuard;
    TNotifyGuard = record
    private
      FPrevious: PNotifyGuard;
      FAlive: Boolean;
    public
      property Previous: PNotifyGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FNotifyGuard: PNotifyGuard;
    FValueRevision: UInt64;
    FOnValueModified: TGuiNotifyEvent;
    FSyncing,FLive,FEditing,FSteppingPointer: Boolean;
    FAutoRepeat,FRepeatWaiting: Boolean;
    FRepeatDelay,FRepeatInterval: Cardinal;
    FRepeatStamp: UInt64;
    FRepeatDirection,FHotArrow: Integer;
    procedure CancelRepeat;
    procedure SetAutoRepeat(AValue: Boolean);
    procedure SetRepeatDelay(AValue: Cardinal);
    procedure SetRepeatInterval(AValue: Cardinal);
    procedure SetWrap(AValue: Boolean);
    procedure AssignValue(AValue: Integer; AUser: Boolean = False);
    procedure NotifyValueChanged(AUser: Boolean);
    function NextStepValue(ASteps: Integer): Integer;
    function GetEditable: Boolean;
    procedure SetEditable(AValue: Boolean);
    procedure SetLive(AValue: Boolean);
    function GetInputValid: Boolean;
    procedure SyncText;
    procedure UpdateLiveValue(AUser: Boolean = False);
  private
    FWrap: Boolean;
    FMinValue: Integer;
    FMaxValue: Integer;
    FValue: Integer;
    FIncrement: Integer;
    FOnChange: TGuiNotifyEvent;
    procedure SetMinValue(AValue: Integer);
    procedure SetMaxValue(AValue: Integer);
    procedure SetValue(AValue: Integer);
    procedure SetIncrement(AValue: Integer);
    function UpButtonRect: TGuiRect;
    function DownButtonRect: TGuiRect;
  protected
    procedure DoChange; override;
    procedure DoUserChange; override;
    function TextRect: TGuiRect; override;
    function FormatValue(AValue: Integer): String; virtual;
    function TryParseValue(const AText: String; out AValue: Integer): Boolean; virtual;
    function AnimationTime: UInt64; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure StepBy(ASteps: Integer);
    procedure UpdateRepeat;
    procedure UpdateInteraction(AStage: TGuiInteractionStage); override;
    function CommitEdit: Boolean;
    procedure CancelEdit;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    property MinValue: Integer read FMinValue write SetMinValue;
    property MaxValue: Integer read FMaxValue write SetMaxValue;
    property Value: Integer read FValue write SetValue;
    property Increment: Integer read FIncrement write SetIncrement;
    property Wrap: Boolean read FWrap write SetWrap;
    property AutoRepeat: Boolean read FAutoRepeat write SetAutoRepeat;
    property RepeatDelay: Cardinal read FRepeatDelay write SetRepeatDelay;
    property RepeatInterval: Cardinal read FRepeatInterval write SetRepeatInterval;
    property Editable: Boolean read GetEditable write SetEditable;
    property Live: Boolean read FLive write SetLive;
    property Editing: Boolean read FEditing;
    property InputValid: Boolean read GetInputValid;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
    property OnValueModified: TGuiNotifyEvent read FOnValueModified write FOnValueModified;
  end;

implementation

function GuiEditIsWordChar(AChar: Char): Boolean;
begin
  Result:=((AChar >= 'A') AND (AChar <= 'Z')) OR
    ((AChar >= 'a') AND (AChar <= 'z')) OR
    ((AChar >= '0') AND (AChar <= '9')) OR (AChar = '_');
end;

constructor TGuiLabel.Create;
begin
  inherited Create;
  Enabled:=False;
  TextColor:=GuiColor(222, 226, 232);
end;

procedure TGuiLabel.PaintSelf(ACanvas: TGuiCanvas);
begin
  inherited PaintSelf(ACanvas);
  DrawControlText(ACanvas, Caption, GuiInflateRect(AbsoluteBounds, Padding), TextColor, TextHorizontalAlign, TextVerticalAlign);
end;

constructor TGuiLinkLabel.Create;
begin
  inherited Create;
  Enabled:=True;
  CanFocus:=True;
  TabStop:=True;
  TextColor:=GuiColor(139, 176, 220);
end;

procedure TGuiLinkLabel.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  LineRect: TGuiRect;
  DrawColor: TGuiColor;
  TextSize: TGuiSize;
  TextLeft: TGuiFloat;
begin
  DrawColor:=TextColor;
  if Hovered OR Focused then
    DrawColor:=Style.CheckedBorderColor;

  if BackgroundColor.A > 0 then
    ACanvas.FillRect(AbsoluteBounds, BackgroundColor);

  if BorderColor.A > 0 then
    DrawControlBorder(ACanvas, AbsoluteBounds, BorderColor);

  Rect:=GuiInflateRect(AbsoluteBounds, Padding);
  DrawControlText(ACanvas, Caption, Rect, DrawColor, TextHorizontalAlign, TextVerticalAlign);

  TextSize:=ACanvas.MeasureText(Caption);
  TextLeft:=Rect.Left;
  case TextHorizontalAlign of
    ghtaCenter: TextLeft:=Rect.Left + ((Rect.Width - TextSize.Width) / 2);
    ghtaRight: TextLeft:=Rect.Left + Rect.Width - TextSize.Width;
  end;

  if TextSize.Width > Rect.Width then
    TextSize.Width:=Rect.Width;

  LineRect:=GuiRect(TextLeft, Rect.Top + Rect.Height - 4, TextSize.Width, 1);
  ACanvas.FillRect(LineRect, DrawColor);

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

constructor TGuiValueLabel.Create;
begin
  inherited Create;
  ValueText:='';
  UnitText:='';
  ValueWidth:=70;
  CaptionColor:=GuiColor(0, 0, 0, 0);
  ValueColor:=GuiColor(0, 0, 0, 0);
  UnitColor:=GuiColor(0, 0, 0, 0);
  Padding:=GuiBox(0);
end;

procedure TGuiValueLabel.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  CaptionRect: TGuiRect;
  ValueRect: TGuiRect;
  UnitRect: TGuiRect;
  CaptionDrawColor: TGuiColor;
  ValueDrawColor: TGuiColor;
  UnitDrawColor: TGuiColor;
begin
  inherited PaintSelf(ACanvas);
  Rect:=GuiInflateRect(AbsoluteBounds, Padding);
  CaptionDrawColor:=CaptionColor;
  ValueDrawColor:=ValueColor;
  UnitDrawColor:=UnitColor;

  if CaptionDrawColor.A = 0 then
    CaptionDrawColor:=TextColor;
  if ValueDrawColor.A = 0 then
    ValueDrawColor:=Style.TextColor;
  if UnitDrawColor.A = 0 then
    UnitDrawColor:=Style.DisabledTextColor;

  ValueRect:=GuiRect(Rect.Left + Rect.Width - ValueWidth, Rect.Top, ValueWidth, Rect.Height);
  UnitRect:=GuiRect(ValueRect.Left + ValueRect.Width - 36, Rect.Top, 36, Rect.Height);
  CaptionRect:=GuiRect(Rect.Left, Rect.Top, Rect.Width - ValueWidth - 6, Rect.Height);

  DrawControlText(ACanvas, Caption, CaptionRect, CaptionDrawColor, ghtaLeft, gvtaCenter);
  DrawControlText(ACanvas, ValueText, ValueRect, ValueDrawColor, ghtaRight, gvtaCenter);
  if UnitText <> '' then
    DrawControlText(ACanvas, UnitText, UnitRect, UnitDrawColor, ghtaRight, gvtaCenter);
end;

constructor TGuiEdit.Create;
begin
  inherited Create;
  CanFocus:=True;
  TabStop:=True;
  FText:='';
  FCaretIndex:=0;
  FPlaceholder:='';
  FPasswordChar:=#0;
  FMaxLength:=0;
  FTextOffsetX:=0;
  FMeasuredText:='';
  FSelectionAnchor:=0;
  FSelectionStart:=0;
  FSelectionEnd:=0;
  FReadOnly:=False;
  FCaretBlink:=True;
  FCaretBlinkInterval:=500;
  FLastCaretBlinkTime:=TThread.GetTickCount64;
  FCaretBlinkVisible:=True;
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
  TextColor:=GuiColor(232, 238, 247);
  Padding:=GuiBoxLTRB(8, 4, 8, 4);
  TextHorizontalAlign:=ghtaLeft;
  TextVerticalAlign:=gvtaCenter;
  SetLength(FHistory, 1);
end;

procedure TGuiEdit.SetText(const AValue: String);
begin
  if FText = AValue then
    Exit;

  CancelComposition;
  SaveUndoSelection;
  FText:=NormalizeText(AValue);

  if (FMaxLength > 0) AND (Length(FText) > FMaxLength) then
    FText:=Copy(FText, 1, FGraphemes.Boundary(FText, FMaxLength));

  SetCaretIndex(FCaretIndex);
  ClearSelection;
  InvalidateTextMetrics;
  InvalidateLayout;
  FLastCaretBlinkTime:=TThread.GetTickCount64;
  FCaretBlinkVisible:=True;
  DoChange;
end;

procedure TGuiEdit.PrepareTextLayout(ACanvas: TGuiCanvas);
var
  PreviousFont: String;
begin
  PreviousFont:=ACanvas.FontName;
  ACanvas.FontName:=FontName;
  try
    UpdateTextMetrics(ACanvas);
    EnsureCaretVisible;
  finally
    ACanvas.FontName:=PreviousFont;
  end;
end;

function TGuiEdit.TextAlignmentOffset: TGuiFloat;
begin
  Result:=0;
  if Length(FCaretPositions)>0 then
    Result:=AlignmentOffsetForWidth(FCaretPositions[High(FCaretPositions)]);
end;

function TGuiEdit.AlignmentOffsetForWidth(AWidth: TGuiFloat): TGuiFloat;
begin
  Result:=0;
  case TextHorizontalAlign of
    ghtaCenter: Result:=Max(0,(TextRect.Width-AWidth)/2);
    ghtaRight: Result:=Max(0,TextRect.Width-AWidth);
  end;
  Result:=Result+Style.TextOffset.X+TextOffset.X;
end;

function TGuiEdit.CompositionPixelX(ACanvas: TGuiCanvas; AOffset: Integer): TGuiFloat;
var Value: String;
begin
  Value:=CompositionTextValue;
  AOffset:=FGraphemes.Boundary(Value,AOffset);
  Result:=ACanvas.MeasureText(Copy(Value,1,AOffset)).Width+
    AlignmentOffsetForWidth(ACanvas.MeasureText(Value).Width);
end;

function TGuiEdit.CompositionInsertionStart: Integer;
begin
  Result:=FCaretIndex;
  if HasSelection then Result:=FSelectionStart;
end;

function TGuiEdit.CompositionTextValue: String;
var Stop: Integer;
begin
  if FComposition='' then Exit(FText);
  Stop:=FCaretIndex;
  if HasSelection then Stop:=FSelectionEnd;
  Result:=Copy(FText,1,CompositionInsertionStart)+FComposition+Copy(FText,Stop+1,MaxInt);
end;

function TGuiEdit.GetCompositionCursor: Integer;
begin
  if FComposition='' then Result:=0 else Result:=FCompositionStart;
end;

procedure TGuiEdit.CancelComposition;
begin
  if FComposition='' then Exit;
  FComposition:='';
  FCompositionStart:=0;
  FCompositionLength:=0;
  Inc(FCompositionCancellationRevision);
end;

procedure TGuiEdit.SetReadOnly(AValue: Boolean);
begin
  if FReadOnly=AValue then Exit;
  FReadOnly:=AValue;
  if AValue then CancelComposition;
end;

function TGuiEdit.GetCompositionSelectionLength: Integer;
begin
  if FComposition='' then Result:=0 else Result:=FCompositionLength;
end;

procedure TGuiEdit.SetComposition(const AEvent: TGuiEvent);
var Raw: String;
Decoded: TGuiDecodedText;
Start,Stop,N: Integer;
begin
  Raw:=String(AEvent.Text);
  Decoded:=GuiDecodeText(Raw);
  N:=Length(Decoded.Scalars);
  Start:=N;
  if AEvent.HasCompositionRange AND (AEvent.CompositionStart>=0) then
    Start:=Min(N,AEvent.CompositionStart);
  Stop:=Start;
  if AEvent.HasCompositionRange AND (AEvent.CompositionLength>0) then
    Inc(Stop,Min(N-Start,AEvent.CompositionLength));
  FComposition:=NormalizeText(Raw);
  FCompositionStart:=Min(Length(FComposition),Length(NormalizeText(Copy(Raw,1,Decoded.Offsets[Start]))));
  FCompositionLength:=Max(0,Min(Length(FComposition),
    Length(NormalizeText(Copy(Raw,1,Decoded.Offsets[Stop]))))-FCompositionStart);
end;

function TGuiEdit.TextInputRect(ACanvas: TGuiCanvas): TGuiRect;
var X: TGuiFloat;
PreviousFont: String;
begin
  PreviousFont:=ACanvas.FontName;
  ACanvas.FontName:=FontName;
  try
    UpdateTextMetrics(ACanvas);
    X:=CaretPixelX(FCaretIndex);
    if (FComposition<>'') AND (FPasswordChar=#0) then
      X:=CompositionPixelX(ACanvas,CompositionInsertionStart+CompositionCursor);
    ScrollCaretIntoView(X);
    Result:=TextRect;
    Result.Left:=Result.Left+EnsureRange(X-FTextOffsetX,0,Max(0,Result.Width-1));
    Result.Width:=1;
  finally
    ACanvas.FontName:=PreviousFont;
  end;
end;

procedure TGuiEdit.SetCaretIndex(AValue: Integer);
begin
  CancelComposition;
  if AValue < 0 then
    AValue:=0;

  if AValue > Length(FText) then
    AValue:=Length(FText);

  FCaretIndex:=FGraphemes.Boundary(FText, AValue);
end;

function TGuiEdit.DisplayText: String;
var
  I: Integer;
begin
  if FPasswordChar = #0 then
  begin
    Result:=FText;
    Exit;
  end;

  Result:='';
  I:=0;
  while I < Length(FText) do
  begin
    Result:=Result + FPasswordChar;
    I:=FGraphemes.Next(FText, I);
  end;
end;

function TGuiEdit.TextRect: TGuiRect;
begin
  Result:=GuiInflateRect(AbsoluteBounds, Padding);
end;

function TGuiEdit.TextForMeasurement: String;
begin
  Result:=DisplayText;
end;

procedure TGuiEdit.InvalidateTextMetrics;
begin
  FMeasuredText:=#1;
end;

procedure TGuiEdit.UpdateTextMetrics(ACanvas: TGuiCanvas);
var I: Integer;
TextValue,Prefix: String;
begin
  TextValue:=TextForMeasurement;
  if (FMeasuredText=TextValue+#0+FText) AND (FMeasuredFont=ACanvas.TextMetricsKey) then Exit;
  FMeasuredText:=TextValue+#0+FText;
  FMeasuredFont:=ACanvas.TextMetricsKey;
  SetLength(FCaretPositions,Length(FText)+1);
  FCaretPositions[0]:=0;
  Prefix:='';
  for I:=1 to Length(FText) do
    if FGraphemes.Boundary(FText,I)=I then
    begin
      if FPasswordChar<>#0 then Prefix:=Prefix+FPasswordChar else Prefix:=Copy(TextValue,1,I);
      FCaretPositions[I]:=ACanvas.MeasureText(Prefix).Width;
    end
    else FCaretPositions[I]:=FCaretPositions[I-1];
end;

procedure TGuiEdit.EnsureCaretVisible;
begin
  ScrollCaretIntoView(CaretPixelX(FCaretIndex));
end;

procedure TGuiEdit.ScrollCaretIntoView(AX: TGuiFloat);
var
  Rect: TGuiRect;
  CaretX: TGuiFloat;
begin
  Rect:=TextRect;
  CaretX:=AX;

  if CaretX - FTextOffsetX > Rect.Width - 2 then
    FTextOffsetX:=CaretX - Rect.Width + 2;

  if CaretX - FTextOffsetX < 0 then
    FTextOffsetX:=CaretX;

  if FTextOffsetX < 0 then
    FTextOffsetX:=0;
  { A shorter replacement must not retain the old horizontal scroll. Composition
    has its own preview extent, and multiline controls manage their own rows. }
  if NOT FMultiLine AND (FComposition='') AND (Length(FCaretPositions)>0) then
    FTextOffsetX:=Min(FTextOffsetX,Max(0,TextAlignmentOffset+
      FCaretPositions[High(FCaretPositions)]-Max(0,Rect.Width-2)));
end;

function TGuiEdit.CaretPixelX(AIndex: Integer): TGuiFloat;
begin
  AIndex:=EnsureRange(AIndex,0,Length(FText));
  Result:=TextAlignmentOffset;
  if AIndex<Length(FCaretPositions) then Result:=Result+FCaretPositions[AIndex];
end;

function TGuiEdit.CaretIndexFromPixelX(AX: TGuiFloat): Integer;
var
  I: Integer;
  MidPoint: TGuiFloat;
begin
  Result:=Length(FText);

  for I:=0 to Length(FText) - 1 do
  begin
    if FGraphemes.Boundary(FText, I) <> I then
      Continue;
    MidPoint:=(CaretPixelX(I) + CaretPixelX(FGraphemes.Next(FText, I))) / 2;
    if AX < MidPoint then
    begin
      Result:=I;
      Exit;
    end;
  end;
end;

function TGuiEdit.HasSelection: Boolean;
begin
  Result:=FSelectionStart <> FSelectionEnd;
end;

function TGuiEdit.SelectedText: String;
begin
  Result:='';

  if HasSelection then
    Result:=Copy(FText, FSelectionStart + 1, FSelectionEnd - FSelectionStart);
end;

procedure TGuiEdit.ClearSelection;
begin
  SetCaretIndex(FCaretIndex);
  FSelectionAnchor:=FCaretIndex;
  FSelectionStart:=FCaretIndex;
  FSelectionEnd:=FCaretIndex;
end;

procedure TGuiEdit.SetSelection(AAnchor, ACaret: Integer);
begin
  SetCaretIndex(ACaret);
  FSelectionAnchor:=FGraphemes.Boundary(FText, AAnchor);

  if FSelectionAnchor < 0 then
    FSelectionAnchor:=0;

  if FSelectionAnchor > Length(FText) then
    FSelectionAnchor:=Length(FText);

  if FSelectionAnchor < FCaretIndex then
  begin
    FSelectionStart:=FSelectionAnchor;
    FSelectionEnd:=FCaretIndex;
  end else
  begin
    FSelectionStart:=FCaretIndex;
    FSelectionEnd:=FSelectionAnchor;
  end;
end;

procedure TGuiEdit.SelectAll;
begin
  SetSelection(0, Length(FText));
end;

procedure TGuiEdit.SelectWordAt(AIndex: Integer);
begin
  SetSelection(WordStart(AIndex), WordEnd(AIndex));
end;

procedure TGuiEdit.DeleteSelection;
begin
  if FReadOnly then
    Exit;

  if NOT HasSelection then
    Exit;

  SaveUndoSelection;
  FText:=Copy(FText, 1, FSelectionStart) + Copy(FText, FSelectionEnd + 1, MaxInt);
  FCaretIndex:=FSelectionStart;
  ClearSelection;
  InvalidateTextMetrics;
  DoUserChange;
end;

function TGuiEdit.WordStart(AIndex: Integer): Integer;
begin
  AIndex:=FGraphemes.Boundary(FText, AIndex);
  while (AIndex > 0) AND NOT GuiEditIsWordChar(FText[FGraphemes.Previous(FText, AIndex) + 1]) do
    AIndex:=FGraphemes.Previous(FText, AIndex);
  while (AIndex > 0) AND GuiEditIsWordChar(FText[FGraphemes.Previous(FText, AIndex) + 1]) do
    AIndex:=FGraphemes.Previous(FText, AIndex);
  Result:=AIndex;
end;

function TGuiEdit.WordEnd(AIndex: Integer): Integer;
begin
  AIndex:=FGraphemes.Boundary(FText, AIndex);
  while (AIndex < Length(FText)) AND NOT GuiEditIsWordChar(FText[AIndex + 1]) do
    AIndex:=FGraphemes.Next(FText, AIndex);
  while (AIndex < Length(FText)) AND GuiEditIsWordChar(FText[AIndex + 1]) do
    AIndex:=FGraphemes.Next(FText, AIndex);
  Result:=AIndex;
end;

procedure TGuiEdit.MoveCaret(AIndex: Integer; AExtendSelection: Boolean);
begin
  if AExtendSelection then
    SetSelection(FSelectionAnchor, AIndex)
  else
  begin
    CaretIndex:=AIndex;
    ClearSelection;
  end;
end;

procedure TGuiEdit.MoveCaretFromPoint(const APoint: TGuiPoint; AExtend: Boolean);
begin
  MoveCaret(PointToCaretIndex(APoint),AExtend);
end;

procedure TGuiEdit.InsertText(const AText: String);
var
  InsertMap: TGuiGraphemeMap;
  TextToInsert: String;
  StartIndex, EndIndex, Available: Integer;
begin
  if FReadOnly then
    Exit;

  if AText = '' then
    Exit;

  StartIndex:=FCaretIndex;
  EndIndex:=FCaretIndex;
  if HasSelection then
  begin
    StartIndex:=FSelectionStart;
    EndIndex:=FSelectionEnd;
  end;
  TextToInsert:=NormalizeText(AText);
  Available:=FMaxLength - (Length(FText) - (EndIndex - StartIndex));
  if (FMaxLength > 0) AND (Length(TextToInsert) > Available) then
    TextToInsert:=Copy(TextToInsert, 1, InsertMap.Boundary(TextToInsert, Available));

  if TextToInsert = '' then
    Exit;

  SaveUndoSelection;
  FText:=Copy(FText, 1, StartIndex) + TextToInsert + Copy(FText, EndIndex + 1, MaxInt);
  FCaretIndex:=StartIndex + Length(TextToInsert);
  if FGraphemes.Boundary(FText, FCaretIndex) <> FCaretIndex then
    FCaretIndex:=FGraphemes.Next(FText, FCaretIndex);
  ClearSelection;
  InvalidateTextMetrics;
  DoTextInserted;
end;

procedure TGuiEdit.DeleteBeforeCaret;
var
  Previous: Integer;
begin
  if FReadOnly then
    Exit;

  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;

  if FCaretIndex <= 0 then
    Exit;

  Previous:=FGraphemes.Previous(FText, FCaretIndex);
  FText:=Copy(FText, 1, Previous) + Copy(FText, FCaretIndex + 1, MaxInt);
  FCaretIndex:=Previous;
  ClearSelection;
  InvalidateTextMetrics;
  DoUserChange;
end;

procedure TGuiEdit.DeleteAtCaret;
begin
  if FReadOnly then
    Exit;

  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;

  if FCaretIndex >= Length(FText) then
    Exit;

  FText:=Copy(FText, 1, FCaretIndex) + Copy(FText, FGraphemes.Next(FText, FCaretIndex) + 1, MaxInt);
  ClearSelection;
  InvalidateTextMetrics;
  DoUserChange;
end;

procedure TGuiEdit.DeleteWordBeforeCaret;
var
  NewCaretIndex: Integer;
begin
  if FReadOnly then
    Exit;

  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;

  if FCaretIndex <= 0 then
    Exit;

  NewCaretIndex:=WordStart(FCaretIndex);
  FText:=Copy(FText, 1, NewCaretIndex) + Copy(FText, FCaretIndex + 1, MaxInt);
  FCaretIndex:=NewCaretIndex;
  ClearSelection;
  InvalidateTextMetrics;
  DoUserChange;
end;

procedure TGuiEdit.DeleteWordAtCaret;
var
  NewCaretIndex: Integer;
begin
  if FReadOnly then
    Exit;

  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;

  if FCaretIndex >= Length(FText) then
    Exit;

  NewCaretIndex:=WordEnd(FCaretIndex);
  FText:=Copy(FText, 1, FCaretIndex) + Copy(FText, NewCaretIndex + 1, MaxInt);
  ClearSelection;
  InvalidateTextMetrics;
  DoUserChange;
end;

procedure TGuiEdit.CopySelectionToClipboard;
begin
  if (FPasswordChar <> #0) OR (NOT HasSelection) then
    Exit;

  GuiClipboardSetText(SelectedText);
end;

procedure TGuiEdit.CutSelectionToClipboard;
begin
  if FReadOnly OR (FPasswordChar <> #0) OR (NOT HasSelection) then
    Exit;

  GuiClipboardSetText(SelectedText);
  DeleteSelection;
end;

procedure TGuiEdit.PasteFromClipboard;
begin
  if FReadOnly then
    Exit;

  InsertText(GuiClipboardGetText);
end;

function TGuiEdit.PointToCaretIndex(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
  LocalX: TGuiFloat;
begin
  Rect:=TextRect;
  LocalX:=APoint.X - Rect.Left + FTextOffsetX;
  Result:=CaretIndexFromPixelX(LocalX);
end;

procedure TGuiEdit.DoUserChange;
begin
  DoChange;
end;

procedure TGuiEdit.DoTextInserted;
begin
  DoUserChange;
end;

procedure TGuiEdit.RecordChange;
var
  I: Integer;
begin
  if NOT FRestoringHistory then
  begin
    if (Length(FHistory) = 0) OR (FHistory[FHistoryIndex].Text <> FText) then
    begin
      if Length(FHistory) = 0 then FHistoryIndex:=-1;
      Inc(FHistoryIndex);
      SetLength(FHistory, FHistoryIndex + 1);
      FHistory[FHistoryIndex].Text:=FText;
      FHistory[FHistoryIndex].Caret:=FCaretIndex;
      FHistory[FHistoryIndex].Anchor:=FSelectionAnchor;
      if Length(FHistory) > 128 then
      begin
        for I:=1 to High(FHistory) do FHistory[I - 1]:=FHistory[I];
        SetLength(FHistory, 128);
        Dec(FHistoryIndex);
      end;
    end;
  end;
end;

procedure TGuiEdit.DoChange;
begin
  RecordChange;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TGuiEdit.NormalizeText(const AText: String): String;
var D: TGuiDecodedText;
I: Integer;
SingleLine: String;
begin
  Result:=StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  Result:=StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result:=StringReplace(Result,#0,'',[rfReplaceAll]);
  if NOT FMultiLine then
  begin
    D:=GuiDecodeText(Result);
    SingleLine:='';
    for I:=0 to High(D.Scalars) do
      if (D.Scalars[I]<>$0A) AND (D.Scalars[I]<>$0D) AND
        (D.Scalars[I]<>$1C) AND (D.Scalars[I]<>$1D) AND (D.Scalars[I]<>$1E) AND
        (D.Scalars[I]<>$85) AND (D.Scalars[I]<>$2028) AND (D.Scalars[I]<>$2029) then
        SingleLine:=SingleLine+Copy(Result,D.Offsets[I]+1,D.Offsets[I+1]-D.Offsets[I]);
    Result:=SingleLine;
  end;
end;

function TGuiEdit.IsGraphemeBoundary(const AText: String;
  AIndex: Integer): Boolean;
begin
  Result:=FGraphemes.Boundary(AText, AIndex) = AIndex;
end;

procedure TGuiEdit.AssignTextSilently(const AValue: String);
begin
  FText:=AValue;
  InvalidateTextMetrics;
  InvalidateLayout;
end;

procedure TGuiEdit.SaveUndoSelection;
begin
  if (Length(FHistory) > 0) AND (FHistory[FHistoryIndex].Text = FText) then
  begin
    FHistory[FHistoryIndex].Caret:=FCaretIndex;
    FHistory[FHistoryIndex].Anchor:=FSelectionAnchor;
  end;
end;

procedure TGuiEdit.Undo;
begin
  CancelComposition;
  if FReadOnly OR (FHistoryIndex <= 0) then Exit;
  Dec(FHistoryIndex);
  FRestoringHistory:=True;
  try
    FText:=FHistory[FHistoryIndex].Text;
    SetSelection(FHistory[FHistoryIndex].Anchor, FHistory[FHistoryIndex].Caret);
    FComposition:='';
    InvalidateTextMetrics;
  finally
    FRestoringHistory:=False;
  end;
  { The restored history entry already matches FText. Notify only after all
    state is settled, so a handler can replace the text or remove the editor. }
  DoUserChange;
end;

procedure TGuiEdit.Redo;
begin
  CancelComposition;
  if FReadOnly OR (FHistoryIndex >= High(FHistory)) then Exit;
  Inc(FHistoryIndex);
  FRestoringHistory:=True;
  try
    FText:=FHistory[FHistoryIndex].Text;
    SetSelection(FHistory[FHistoryIndex].Anchor, FHistory[FHistoryIndex].Caret);
    FComposition:='';
    InvalidateTextMetrics;
  finally
    FRestoringHistory:=False;
  end;
  DoUserChange;
end;

procedure TGuiEdit.DoSubmit;
begin
  if Assigned(FOnSubmit) then
    FOnSubmit(Self);
end;

procedure TGuiEdit.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  InnerRect: TGuiRect;
  DrawColor: TGuiColor;
  TextToDraw: String;
  CaretLeft: TGuiFloat;
  DrawRect: TGuiRect;
  SelectionLeft: TGuiFloat;
  SelectionRight: TGuiFloat;
  States: TGuiControlVisualStates;
  NowTime: UInt64;
  CompositionLeft,CompositionRight: TGuiFloat;
  PaintCaretX: TGuiFloat;
begin
  Rect:=AbsoluteBounds;
  InnerRect:=TextRect;
  UpdateTextMetrics(ACanvas);
  EnsureCaretVisible;
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));

  TextToDraw:=DisplayText;
  if (FComposition <> '') AND (FPasswordChar = #0) then
    TextToDraw:=CompositionTextValue;
  DrawColor:=GuiResolveTextColor(Style, States);
  if (TextToDraw = '') AND (FPlaceholder <> '') then
  begin
    TextToDraw:=FPlaceholder;
    DrawColor:=Style.DisabledTextColor;
  end;

  PaintCaretX:=CaretPixelX(FCaretIndex);
  if (FComposition<>'') AND (FPasswordChar=#0) then
    PaintCaretX:=CompositionPixelX(ACanvas,CompositionInsertionStart+CompositionCursor);
  ScrollCaretIntoView(PaintCaretX);

  ACanvas.PushClipRect(InnerRect);
  try
    if HasSelection AND ((FComposition='') OR (FPasswordChar<>#0)) then
    begin
      SelectionLeft:=InnerRect.Left+CaretPixelX(FSelectionStart)-FTextOffsetX;
      SelectionRight:=InnerRect.Left+CaretPixelX(FSelectionEnd)-FTextOffsetX;
      ACanvas.DrawDrawable(Style.Selection,GuiRect(SelectionLeft,InnerRect.Top+3,
        SelectionRight-SelectionLeft,InnerRect.Height-6));
    end;

    DrawRect:=InnerRect;
    DrawRect.Left:=DrawRect.Left-FTextOffsetX+
      AlignmentOffsetForWidth(ACanvas.MeasureText(TextToDraw).Width);
    DrawRect.Top:=DrawRect.Top+Style.TextOffset.Y+TextOffset.Y;
    DrawRect.Width:=Max(DrawRect.Width,ACanvas.MeasureText(TextToDraw).Width);
    ACanvas.DrawText(TextToDraw,DrawRect,DrawColor,ghtaLeft,TextVerticalAlign);
    if (FComposition<>'') AND (FPasswordChar=#0) then
    begin
      CompositionLeft:=CompositionPixelX(ACanvas,CompositionInsertionStart);
      CompositionRight:=CompositionPixelX(ACanvas,CompositionInsertionStart+Length(FComposition));
      ACanvas.FillRect(GuiRect(InnerRect.Left+CompositionLeft-FTextOffsetX,
        InnerRect.Top+InnerRect.Height-3,Max(0,CompositionRight-CompositionLeft),1),Style.TextColor);
      if CompositionSelectionLength>0 then
      begin
        CompositionLeft:=CompositionPixelX(ACanvas,CompositionInsertionStart+CompositionCursor);
        CompositionRight:=CompositionPixelX(ACanvas,CompositionInsertionStart+CompositionCursor+CompositionSelectionLength);
        ACanvas.FillRect(GuiRect(InnerRect.Left+CompositionLeft-FTextOffsetX,
          InnerRect.Top+InnerRect.Height-4,Max(0,CompositionRight-CompositionLeft),2),Style.TextColor);
      end;
    end;

    if Focused AND Enabled then
    begin
      if FCaretBlink then
      begin
        NowTime:=TThread.GetTickCount64;
        if NowTime - FLastCaretBlinkTime >= FCaretBlinkInterval then
        begin
          FCaretBlinkVisible:=NOT FCaretBlinkVisible;
          FLastCaretBlinkTime:=NowTime;
        end;
      end else
        FCaretBlinkVisible:=True;

      CaretLeft:=InnerRect.Left + PaintCaretX - FTextOffsetX;

      if CaretLeft > InnerRect.Left + InnerRect.Width - 1 then
        CaretLeft:=InnerRect.Left + InnerRect.Width - 1;

      if FCaretBlinkVisible then
        ACanvas.FillRect(GuiRect(CaretLeft, InnerRect.Top + 5, 1, InnerRect.Height - 10), Style.TextColor);
    end;
  finally
    ACanvas.PopClipRect;
  end;

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
end;

procedure TGuiEdit.HandleControlEvent(var AEvent: TGuiEvent);
begin
  inherited HandleEvent(AEvent);
end;

procedure TGuiEdit.HandleEvent(var AEvent: TGuiEvent);
var
  Rect: TGuiRect;
begin
  inherited HandleEvent(AEvent);
  if NOT Enabled then Exit;
  if (FComposition<>'') AND (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode<>27) then
  begin
    AEvent.Handled:=True;
    Exit;
  end;
  if AEvent.Kind=gekMouseDown then CancelComposition;
  if AEvent.Kind IN [gekKeyDown, gekTextInput] then SaveUndoSelection;

  case AEvent.Kind of
    gekBlur, gekCancel: CancelComposition;
    gekTextEditing:
    begin
      if NOT FReadOnly then SetComposition(AEvent);
      AEvent.Handled:=True;
    end;
    gekMouseDown:
    begin
      FLastCaretBlinkTime:=TThread.GetTickCount64;
      FCaretBlinkVisible:=True;
      if AEvent.Button <> gmbLeft then Exit;
      if gemShift IN AEvent.Modifiers then MoveCaretFromPoint(AEvent.Position,True)
      else
      begin
        MoveCaretFromPoint(AEvent.Position,False);
        FSelectionAnchor:=FCaretIndex;
      end;
      if AEvent.Clicks >= 2 then
        SelectWordAt(FCaretIndex);

      AEvent.Handled:=True;
    end;

    gekMouseMove:
    begin
      if Pressed then
      begin
        Rect:=TextRect;
        MoveCaretFromPoint(AEvent.Position,True);
        AEvent.Handled:=True;
      end;
    end;

    gekTextInput:
    begin
      FComposition:='';
      InsertText(String(AEvent.Text));
      AEvent.Handled:=True;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        90, 122:
          if gemCtrl IN AEvent.Modifiers then
          begin
            if gemShift IN AEvent.Modifiers then Redo else Undo;
            AEvent.Handled:=True;
          end;
        89, 121:
          if gemCtrl IN AEvent.Modifiers then
          begin
            Redo;
            AEvent.Handled:=True;
          end;
        8:
        begin
          if gemCtrl IN AEvent.Modifiers then
            DeleteWordBeforeCaret
          else
            DeleteBeforeCaret;

          AEvent.Handled:=True;
        end;

        13:
        begin
          DoSubmit;
          AEvent.Handled:=True;
        end;

        32:
        begin
          AEvent.Handled:=True;
        end;

        127:
        begin
          if gemCtrl IN AEvent.Modifiers then
            DeleteWordAtCaret
          else
            DeleteAtCaret;

          AEvent.Handled:=True;
        end;

        27:
        begin
          if FComposition<>'' then CancelComposition else ClearSelection;
          AEvent.Handled:=True;
        end;

        65, 97:
        begin
          if gemCtrl IN AEvent.Modifiers then
          begin
            SelectAll;
            AEvent.Handled:=True;
          end;
        end;

        67, 99:
        begin
          if gemCtrl IN AEvent.Modifiers then
          begin
            CopySelectionToClipboard;
            AEvent.Handled:=True;
          end;
        end;

        86, 118:
        begin
          if gemCtrl IN AEvent.Modifiers then
          begin
            PasteFromClipboard;
            AEvent.Handled:=True;
          end;
        end;

        88, 120:
        begin
          if gemCtrl IN AEvent.Modifiers then
          begin
            CutSelectionToClipboard;
            AEvent.Handled:=True;
          end;
        end;

        $4000004A:
        begin
          MoveCaret(0, gemShift IN AEvent.Modifiers);
          AEvent.Handled:=True;
        end;

        $4000004D:
        begin
          MoveCaret(Length(FText), gemShift IN AEvent.Modifiers);
          AEvent.Handled:=True;
        end;

        $4000004F:
        begin
          if gemCtrl IN AEvent.Modifiers then
            MoveCaret(WordEnd(FCaretIndex), gemShift IN AEvent.Modifiers)
          else if HasSelection AND NOT (gemShift IN AEvent.Modifiers) then
            MoveCaret(FSelectionEnd,False)
          else
            MoveCaret(FGraphemes.Next(FText, FCaretIndex), gemShift IN AEvent.Modifiers);

          AEvent.Handled:=True;
        end;

        $40000050:
        begin
          if gemCtrl IN AEvent.Modifiers then
            MoveCaret(WordStart(FCaretIndex), gemShift IN AEvent.Modifiers)
          else if HasSelection AND NOT (gemShift IN AEvent.Modifiers) then
            MoveCaret(FSelectionStart,False)
          else
            MoveCaret(FGraphemes.Previous(FText, FCaretIndex), gemShift IN AEvent.Modifiers);

          AEvent.Handled:=True;
        end;
      end;
    end;
  end;
end;

constructor TGuiMemo.Create;
begin
  inherited Create;
  FPreferredRow:=-1;
  FPreferredCaret:=-1;
  FDesiredX:=-1;
  FMultiLine:=True;
  FLines:=TStringList.Create;
  FLines.OnChange:=LinesChanged;
  FLastPaintCaret:=-1;
  FLineHeight:=24;
  FScrollY:=0;
  FDraggingScrollBar:=False;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBox(6);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
end;

procedure TGuiMemo.LinesChanged(Sender: TObject);
var
  Value: String;
begin
  if FSyncLines then Exit;
  Value:=StringReplace(FLines.Text, #13#10, #10, [rfReplaceAll]);
  if (Value <> '') AND (Value[Length(Value)] = #10) then Delete(Value, Length(Value), 1);
  FSyncLines:=True;
  try
    Text:=Value;
  finally
    FSyncLines:=False;
  end;
end;

procedure TGuiMemo.DoChange;
begin
  if Assigned(FLines) AND (NOT FSyncLines) then
  begin
    FSyncLines:=True;
    try
      FLines.Text:=FText;
      if (FText <> '') AND (FText[Length(FText)] = #10) then FLines.Add('');
    finally
      FSyncLines:=False;
    end;
  end;
  inherited DoChange;
end;

function TGuiMemo.LineStart(ALine: Integer): Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to Min(ALine, FLines.Count) - 1 do Inc(Result, Length(FLines[I]) + 1);
  Result:=Min(Result, Length(FText));
end;

function TGuiMemo.CaretLine: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=1 to FCaretIndex do
    if FText[I] = #10 then Inc(Result);
end;

procedure TGuiMemo.SetWordWrap(AValue: Boolean);
begin
  if FWordWrap = AValue then Exit;
  FWordWrap:=AValue;
  FVisualValid:=False;
  FPreferredRow:=-1;
  FTextOffsetX:=0;
  FLastPaintCaret:=-1;
  InvalidateLayout;
end;

procedure TGuiMemo.UpdateVisualRows(ACanvas: TGuiCanvas);
var R: TGuiRect;
FontKey: String;
I,J: Integer;
begin
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  FontKey:=FVisualFont;
  if Assigned(ACanvas) then FontKey:=ACanvas.TextMetricsKey;
  if FVisualValid AND (FVisualText=FText) AND (FVisualFont=FontKey) AND
    (FVisualWidth=R.Width) AND (FVisualHeight=R.Height) AND
    (FVisualBarSize=Style.ScrollBarSize) AND (FVisualLineHeight=FLineHeight) AND
    (FVisualWrapped=FWordWrap) then Exit;
  FVisualRows:=GuiLayoutText(ACanvas,FText,Max(1,R.Width-1),FWordWrap);
  if FWordWrap AND (Length(FVisualRows)*Max(1,FLineHeight)>R.Height) then
    FVisualRows:=GuiLayoutText(ACanvas,FText,Max(1,ScrollContentRect(True).Width-1),True);
  FVisualText:=FText;
  FVisualFont:='';
  if Assigned(ACanvas) then FVisualFont:=FontKey;
  FVisualWidth:=R.Width;
  FVisualHeight:=R.Height;
  FVisualBarSize:=Style.ScrollBarSize;
  FVisualLineHeight:=FLineHeight;
  FVisualWrapped:=FWordWrap;
  FVisualValid:=True;
  FLastPaintCaret:=-1;
  SetLength(FCaretPositions,Length(FText)+1);
  for I:=0 to High(FVisualRows) do
    for J:=0 to FVisualRows[I].TextLength do
      FCaretPositions[FVisualRows[I].StartIndex+J]:=FVisualRows[I].CaretX[J];
  FPreferredRow:=-1;
  if FWordWrap then FTextOffsetX:=0;
end;

function TGuiMemo.HasCompositionRows: Boolean;
begin
  Result:=(FComposition<>'') AND (Length(FPreviewRows)>0) AND
    (FPreviewText=CompositionTextValue);
end;

procedure TGuiMemo.UpdateCompositionRows(ACanvas: TGuiCanvas);
var TextValue,Key: String;
R: TGuiRect;
I,Caret: Integer;
begin
  if (FComposition='') OR (FPasswordChar<>#0) then
  begin
    if Length(FPreviewRows)>0 then FLastPaintCaret:=-1;
    FPreviewRows:=nil;
    FPreviewText:='';
    FPreviewKey:='';
    Exit;
  end;
  TextValue:=CompositionTextValue;
  R:=GuiInflateRect(AbsoluteBounds,Padding);
  Key:=ACanvas.TextMetricsKey+'|'+FloatToStr(R.Width)+'|'+FloatToStr(R.Height)+'|'+
    FloatToStr(FLineHeight)+'|'+FloatToStr(Style.ScrollBarSize)+'|'+IntToStr(Ord(FWordWrap));
  if (FPreviewText<>TextValue) OR (FPreviewKey<>Key) OR (Length(FPreviewRows)=0) then
  begin
    FPreviewRows:=GuiLayoutText(ACanvas,TextValue,Max(1,R.Width-1),FWordWrap);
    if FWordWrap AND (Length(FPreviewRows)*Max(1,FLineHeight)>R.Height) then
      FPreviewRows:=GuiLayoutText(ACanvas,TextValue,Max(1,ScrollContentRect(True).Width-1),True);
    FPreviewText:=TextValue;
    FPreviewKey:=Key;
  end;
  Caret:=FGraphemes.Boundary(TextValue,CompositionInsertionStart+CompositionCursor);
  FPreviewRow:=0;
  for I:=1 to High(FPreviewRows) do
    if FPreviewRows[I].StartIndex<=Caret then FPreviewRow:=I else Break;
  if (CompositionCursor=Length(FComposition)) AND (FPreviewRow>0) AND
    (FPreviewRows[FPreviewRow-1].StartIndex+FPreviewRows[FPreviewRow-1].TextLength=Caret) then
    Dec(FPreviewRow);
  FPreviewStop:=EnsureRange(Caret-FPreviewRows[FPreviewRow].StartIndex,0,FPreviewRows[FPreviewRow].TextLength);
end;

procedure TGuiMemo.PrepareTextLayout(ACanvas: TGuiCanvas);
var
  PreviousFont: String;
begin
  PreviousFont:=ACanvas.FontName;
  ACanvas.FontName:=FontName;
  try
    UpdateVisualRows(ACanvas);
    UpdateCompositionRows(ACanvas);
  finally
    ACanvas.FontName:=PreviousFont;
  end;
end;

function TGuiMemo.CompositionInputRect: TGuiRect;
var R: TGuiRect;
X,H: TGuiFloat;
begin
  R:=GetContentRect;
  H:=Max(1,FLineHeight);
  X:=FPreviewRows[FPreviewRow].CaretX[FPreviewStop]+Style.TextOffset.X+TextOffset.X;
  if FPreviewRow*H<FScrollY then SetScrollY(FPreviewRow*H);
  if (FPreviewRow+1)*H>FScrollY+R.Height then SetScrollY((FPreviewRow+1)*H-R.Height);
  if FWordWrap then FTextOffsetX:=0 else
  begin
    if X<FTextOffsetX then FTextOffsetX:=X;
    if X>FTextOffsetX+Max(0,R.Width-1) then FTextOffsetX:=Max(0,X-R.Width+1);
  end;
  Result:=GuiRect(R.Left+EnsureRange(X-FTextOffsetX,0,Max(0,R.Width-1)),
    R.Top+EnsureRange(FPreviewRow*H-FScrollY,0,Max(0,R.Height-H)),1,Min(H,R.Height));
end;

procedure TGuiMemo.PaintCompositionRows(ACanvas: TGuiCanvas);
var R,LineRect,CaretRect: TGuiRect;
States: TGuiControlVisualStates;
I: Integer;
H: TGuiFloat;
  procedure Underline(AStart,AStop: Integer; AHeight: TGuiFloat);
  var L,E: Integer;
  begin
    L:=Max(AStart,FPreviewRows[I].StartIndex);
    E:=Min(AStop,FPreviewRows[I].StartIndex+FPreviewRows[I].TextLength);
    if E<=L then Exit;
    Dec(L,FPreviewRows[I].StartIndex);
    Dec(E,FPreviewRows[I].StartIndex);
    ACanvas.FillRect(GuiRect(LineRect.Left+FPreviewRows[I].CaretX[L],
      LineRect.Top+H-1-AHeight,FPreviewRows[I].CaretX[E]-FPreviewRows[I].CaretX[L],AHeight),Style.TextColor);
  end;
begin
  CaretRect:=CompositionInputRect;
  R:=GetContentRect;
  H:=Max(1,FLineHeight);
  States:=[gcvsNormal];
  if Focused then Include(States,gcvsFocused);
  if NOT Enabled then Include(States,gcvsDisabled);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),AbsoluteBounds,Style.CornerRadius);
  DrawControlBorder(ACanvas,AbsoluteBounds,GuiResolveBorderColor(Style,States));
  ACanvas.PushClipRect(R);
  try
    for I:=0 to High(FPreviewRows) do
    begin
      LineRect:=GuiRect(R.Left-FTextOffsetX+Style.TextOffset.X+TextOffset.X,
        R.Top+I*H-FScrollY+Style.TextOffset.Y+TextOffset.Y,R.Width+FTextOffsetX,H);
      if (LineRect.Top+H<R.Top) OR (LineRect.Top>R.Top+R.Height) then Continue;
      ACanvas.DrawText(Copy(FPreviewText,FPreviewRows[I].StartIndex+1,FPreviewRows[I].TextLength),
        LineRect,GuiResolveTextColor(Style,States),ghtaLeft,gvtaCenter);
      Underline(CompositionInsertionStart,CompositionInsertionStart+Length(FComposition),1);
      Underline(CompositionInsertionStart+CompositionCursor,
        CompositionInsertionStart+CompositionCursor+CompositionSelectionLength,2);
    end;
    if Focused AND Enabled then ACanvas.FillRect(CaretRect,Style.TextColor);
  finally
    ACanvas.PopClipRect;
  end;
  if MaxScrollY>0 then PaintScrollBar(ACanvas,GetScrollBarRect,GetScrollThumbRect,goVertical,FDraggingScrollBar);
  if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas,AbsoluteBounds,Style);
end;

function TGuiMemo.TextInputRect(ACanvas: TGuiCanvas): TGuiRect;
var Row: Integer;
R: TGuiRect;
X,Height: TGuiFloat;
begin
  PrepareTextLayout(ACanvas);
  if HasCompositionRows then Exit(CompositionInputRect);
  Row:=VisualCaretRow;
  R:=GetContentRect;
  Height:=Max(1,FLineHeight);
  X:=VisualRowX(Row,FCaretIndex);
  if FLastPaintCaret<>FCaretIndex then
  begin
    if Row*Height<FScrollY then SetScrollY(Row*Height);
    if (Row+1)*Height>FScrollY+R.Height then SetScrollY((Row+1)*Height-R.Height);
    if NOT FWordWrap then
    begin
      if X<FTextOffsetX then FTextOffsetX:=X;
      if X>FTextOffsetX+Max(0,R.Width-1) then FTextOffsetX:=Max(0,X-R.Width+1);
    end;
  end;
  Result:=GuiRect(R.Left+EnsureRange(X-FTextOffsetX,0,Max(0,R.Width-1)),
    R.Top+EnsureRange(Row*Height-FScrollY,0,Max(0,R.Height-Height)),1,Min(Height,R.Height));
end;

function TGuiMemo.GetVisualLineCount: Integer;
begin
  UpdateVisualRows(nil);
  if HasCompositionRows then Result:=Length(FPreviewRows) else Result:=Length(FVisualRows);
end;

function TGuiMemo.VisualCaretRow: Integer;
var I: Integer;
begin
  UpdateVisualRows(nil);
  Result:=0;
  if (FPreferredCaret = FCaretIndex) AND (FPreferredRow >= 0) AND
    (FPreferredRow < Length(FVisualRows)) AND
    (FCaretIndex >= FVisualRows[FPreferredRow].StartIndex) AND
    (FCaretIndex <= FVisualRows[FPreferredRow].StartIndex + FVisualRows[FPreferredRow].TextLength) then
  begin
    Result:=FPreferredRow;
    Exit;
  end;
  for I:=1 to High(FVisualRows) do
    if FVisualRows[I].StartIndex <= FCaretIndex then Result:=I else Break;
end;

function TGuiMemo.VisualRowX(ARow, AIndex: Integer): TGuiFloat;
begin
  ARow:=EnsureRange(ARow,0,High(FVisualRows));
  Result:=FVisualRows[ARow].CaretX[EnsureRange(AIndex-FVisualRows[ARow].StartIndex,
    0,FVisualRows[ARow].TextLength)]+Style.TextOffset.X+TextOffset.X;
end;

function TGuiMemo.VisualRowIndex(ARow: Integer; AX: TGuiFloat): Integer;
var NextIndex, StopIndex: Integer;
begin
  ARow:=EnsureRange(ARow, 0, High(FVisualRows));
  Result:=FVisualRows[ARow].StartIndex;
  StopIndex:=Result + FVisualRows[ARow].TextLength;
  while Result < StopIndex do
  begin
    NextIndex:=FGraphemes.Next(FText, Result);
    if AX < (VisualRowX(ARow, Result) + VisualRowX(ARow, NextIndex)) / 2 then Exit;
    Result:=NextIndex;
  end;
end;

function TGuiMemo.PointToCaretIndex(const APoint: TGuiPoint): Integer;
begin
  Result:=IndexAtPoint(APoint);
end;

function TGuiMemo.IndexAtPoint(const APoint: TGuiPoint): Integer;
var Row: Integer;
X: TGuiFloat;
begin
  UpdateVisualRows(nil);
  Row:=EnsureRange(Floor((APoint.Y - GetContentRect.Top + FScrollY) / Max(1, FLineHeight)), 0, High(FVisualRows));
  X:=APoint.X - GetContentRect.Left;
  if NOT FWordWrap then X:=X + FTextOffsetX;
  Result:=VisualRowIndex(Row, X);
  FPreferredRow:=Row;
  FPreferredCaret:=Result;
end;

destructor TGuiMemo.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TGuiMemo.AddLine(const AText: String): Integer;
begin
  Result:=FLines.Add(AText);
  InvalidateLayout;
end;

procedure TGuiMemo.ClearLines;
begin
  FLines.Clear;
  SetScrollY(0);
  InvalidateLayout;
end;

procedure TGuiMemo.SetScrollY(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if AValue > MaxScrollY then
    AValue:=MaxScrollY;

  FScrollY:=AValue;
end;

function TGuiMemo.GetMaxScrollY: TGuiFloat;
var
  Rect: TGuiRect;
begin
  UpdateVisualRows(nil);
  Rect:=GuiInflateRect(Bounds, Padding);
  if HasCompositionRows then Result:=Length(FPreviewRows)*Max(1,FLineHeight)-Rect.Height
  else Result:=(Length(FVisualRows) * Max(1, FLineHeight)) - Rect.Height;
  if (FText = '') AND NOT HasCompositionRows then Result:=0;

  if Result < 0 then
    Result:=0;
end;

function TGuiMemo.GetContentRect: TGuiRect;
begin
  Result:=ScrollContentRect(MaxScrollY > 0);
end;

function TGuiMemo.GetScrollBarRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(AbsoluteBounds, goVertical, Max(8, Style.ScrollBarSize));
end;

function TGuiMemo.GetScrollThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(GetScrollBarRect, GetContentRect.Height, VisualLineCount * Max(1, FLineHeight), FScrollY);
end;

function TGuiMemo.ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
var
  BarRect: TGuiRect;
  ThumbRect: TGuiRect;
  TrackHeight: TGuiFloat;
begin
  Result:=0;

  if MaxScrollY <= 0 then
    Exit;

  BarRect:=GetScrollBarRect;
  ThumbRect:=GetScrollThumbRect;
  TrackHeight:=BarRect.Height;
  Result:=GuiScrollOffsetFromThumbDelta(ADeltaY, TrackHeight, ThumbRect.Height, MaxScrollY);
end;

procedure TGuiMemo.PaintSelf(ACanvas: TGuiCanvas);
var
  I, StartIndex, StopIndex, Row: Integer;
  LeftValue, RightValue, Height: TGuiFloat;
  Rect, LineRect: TGuiRect;
  States: TGuiControlVisualStates;
begin
  UpdateVisualRows(ACanvas);
  UpdateCompositionRows(ACanvas);
  SetScrollY(FScrollY);
  if HasCompositionRows then
  begin
    PaintCompositionRows(ACanvas);
    Exit;
  end;
  Height:=Max(1, FLineHeight);
  Rect:=GetContentRect;
  Row:=VisualCaretRow;
  if FWordWrap then FTextOffsetX:=0;
  if Focused AND (FLastPaintCaret <> FCaretIndex) then
  begin
    if Row * Height < FScrollY then SetScrollY(Row * Height);
    if (Row + 1) * Height > FScrollY + Rect.Height then SetScrollY((Row + 1) * Height - Rect.Height);
    if NOT FWordWrap then
    begin
      LeftValue:=VisualRowX(Row, FCaretIndex);
      if LeftValue < FTextOffsetX then FTextOffsetX:=LeftValue;
      if LeftValue > FTextOffsetX + Max(0, Rect.Width - 1) then
        FTextOffsetX:=Max(0, LeftValue - Rect.Width + 1);
    end;
    FLastPaintCaret:=FCaretIndex;
  end;
  States:=[gcvsNormal];
  if Focused then Include(States, gcvsFocused);
  if NOT Enabled then Include(States, gcvsDisabled);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), AbsoluteBounds, Style.CornerRadius);
  DrawControlBorder(ACanvas, AbsoluteBounds, GuiResolveBorderColor(Style, States));
  ACanvas.PushClipRect(Rect);
  try
    for I:=0 to High(FVisualRows) do
    begin
      LineRect:=GuiRect(Rect.Left - FTextOffsetX, Rect.Top + I * Height - FScrollY, Rect.Width + FTextOffsetX, Height);
      if (LineRect.Top + Height < Rect.Top) OR (LineRect.Top > Rect.Top + Rect.Height) then Continue;
      StartIndex:=FVisualRows[I].StartIndex;
      StopIndex:=StartIndex + FVisualRows[I].TextLength;
      if HasSelection AND (FSelectionEnd > StartIndex) AND (FSelectionStart <= StopIndex) then
      begin
        LeftValue:=VisualRowX(I, Max(StartIndex, FSelectionStart));
        RightValue:=VisualRowX(I, Min(StopIndex, FSelectionEnd));
        if (FSelectionEnd > StopIndex) AND (StopIndex < Length(FText)) AND (FText[StopIndex + 1] = #10) then
          RightValue:=RightValue + 5;
        ACanvas.DrawDrawable(Style.Selection, GuiRect(LineRect.Left + LeftValue, LineRect.Top, Max(0, RightValue - LeftValue), Height));
      end;
        DrawControlText(ACanvas, Copy(FText, StartIndex + 1, FVisualRows[I].TextLength), LineRect,
          GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
    end;
    if Focused AND Enabled then
    begin
      LeftValue:=Rect.Left + VisualRowX(Row, FCaretIndex) - FTextOffsetX;
      ACanvas.FillRect(GuiRect(LeftValue, Rect.Top + Row * Height - FScrollY, 1, Height), Style.TextColor);
      if FComposition <> '' then
        DrawControlText(ACanvas, FComposition, GuiRect(LeftValue, Rect.Top + Row * Height - FScrollY,
          Max(0, Rect.Left + Rect.Width - LeftValue), Height), Style.TextColor);
    end;
  finally
    ACanvas.PopClipRect;
  end;
  if MaxScrollY > 0 then PaintScrollBar(ACanvas, GetScrollBarRect, GetScrollThumbRect, goVertical, FDraggingScrollBar);
  if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

procedure TGuiMemo.HandleEvent(var AEvent: TGuiEvent);
var Row, Index, Page: Integer;
Height, OldScroll: TGuiFloat;
begin
  if NOT Enabled then Exit;
  if (FComposition<>'') AND (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode<>27) then
  begin
    AEvent.Handled:=True;
    Exit;
  end;
  if AEvent.Kind=gekMouseDown then CancelComposition;
  UpdateVisualRows(nil);
  Height:=Max(1, FLineHeight);
  if AEvent.Kind = gekCancel then FDraggingScrollBar:=False;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) AND
    (MaxScrollY > 0) AND GuiRectContains(GetScrollBarRect, AEvent.Position) then
  begin
    if NOT GuiRectContains(GetScrollThumbRect, AEvent.Position) then
      SetScrollY(FScrollY + ScrollFromThumbDelta(AEvent.Position.Y - GetScrollThumbRect.Top - GetScrollThumbRect.Height / 2));
    FDraggingScrollBar:=True;
    Pressed:=True;
    FDragStartY:=AEvent.Position.Y;
    FDragStartScrollY:=FScrollY;
    AEvent.Handled:=True;
    DoMouseDown(AEvent);
    Exit;
  end;
  if (AEvent.Kind = gekMouseMove) AND FDraggingScrollBar then
  begin
    SetScrollY(FDragStartScrollY + ScrollFromThumbDelta(AEvent.Position.Y - FDragStartY));
    AEvent.Handled:=True;
    DoMouseMove(AEvent);
    Exit;
  end;
  if (AEvent.Kind = gekMouseUp) AND FDraggingScrollBar then
  begin
    FDraggingScrollBar:=False;
    Pressed:=False;
    AEvent.Handled:=True;
    DoMouseUp(AEvent);
    Exit;
  end;
  if AEvent.Kind = gekMouseWheel then
  begin
    OldScroll:=FScrollY;
    SetScrollY(FScrollY - AEvent.Delta.Y * Height * 3);
    AEvent.Handled:=OldScroll <> FScrollY;
    Exit;
  end;
  if AEvent.Kind = gekKeyDown then
  begin
    SaveUndoSelection;
    Row:=VisualCaretRow;
    Page:=Max(1, Floor(GetContentRect.Height / Height));
    case AEvent.KeyCode of
      13:
      begin
        InsertText(#10);
        FDesiredX:=-1;
        AEvent.Handled:=True;
        Exit;
      end;
      $40000051, $40000052, $4000004A, $4000004D, $4000004B, $4000004E:
      begin
        if FDesiredX < 0 then FDesiredX:=VisualRowX(Row, FCaretIndex);
        case AEvent.KeyCode of
          $40000051: Row:=Min(High(FVisualRows), Row + 1);
          $40000052: Row:=Max(0, Row - 1);
          $4000004B: Row:=Max(0, Row - Page);
          $4000004E: Row:=Min(High(FVisualRows), Row + Page);
        end;
        Index:=VisualRowIndex(Row, FDesiredX);
        if AEvent.KeyCode = $4000004A then
        begin
          Index:=FVisualRows[Row].StartIndex;
          if gemCtrl IN AEvent.Modifiers then
          begin
            Index:=0;
            Row:=0;
          end;
          FDesiredX:=-1;
        end;
        if AEvent.KeyCode = $4000004D then
        begin
          Index:=FVisualRows[Row].StartIndex + FVisualRows[Row].TextLength;
          if gemCtrl IN AEvent.Modifiers then
          begin
            Index:=Length(FText);
            Row:=High(FVisualRows);
          end;
          FDesiredX:=-1;
        end;
        MoveCaret(Index, gemShift IN AEvent.Modifiers);
        FPreferredCaret:=FCaretIndex;
        FPreferredRow:=Row;
        FLastPaintCaret:=-1;
        if FWordWrap then FTextOffsetX:=0;
        AEvent.Handled:=True;
        Exit;
      end;
    end;
  end;
  if AEvent.Kind IN [gekKeyDown, gekTextInput, gekMouseDown] then
  begin
    FDesiredX:=-1;
    FPreferredRow:=-1;
  end;
  inherited HandleEvent(AEvent);
  if FWordWrap then FTextOffsetX:=0;
end;

constructor TGuiSpinEdit.Create;
begin
  inherited Create;
  CanFocus:=True;
  TabStop:=True;
  FMinValue:=0;
  FMaxValue:=100;
  FValue:=0;
  FIncrement:=1;
  FAutoRepeat:=True;
  FRepeatDelay:=400;
  FRepeatInterval:=75;
  Padding:=GuiBoxLTRB(8, 4, 28, 4);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
  TextHorizontalAlign:=ghtaLeft;
  TextVerticalAlign:=gvtaCenter;
  SyncText;
end;

function TGuiSpinEdit.GetEditable: Boolean;
begin
  Result:=NOT ReadOnly;
end;

destructor TGuiSpinEdit.Destroy;
var Guard: PNotifyGuard;
begin
  Guard:=FNotifyGuard;
  while Assigned(Guard) do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  inherited Destroy;
end;

procedure TGuiSpinEdit.NotifyValueChanged(AUser: Boolean);
var Guard: TNotifyGuard;
Revision: UInt64;
begin
  Guard.Previous:=FNotifyGuard;
  Guard.Alive:=True;
  FNotifyGuard:=@Guard;
  Revision:=FValueRevision;
  try
    if Assigned(FOnChange) then FOnChange(Self);
    if NOT Guard.Alive then Exit;
    { Do not report a stale user value after a reentrant assignment/configuration
      change. Both events observe committed state; the general event comes first. }
    if AUser AND (Revision=FValueRevision) AND Assigned(FOnValueModified) then FOnValueModified(Self);
  finally
    if Guard.Alive then FNotifyGuard:=Guard.Previous;
  end;
end;

procedure TGuiSpinEdit.SetEditable(AValue: Boolean);
begin
  CancelEdit;
  ReadOnly:=NOT AValue;
end;

procedure TGuiSpinEdit.SetLive(AValue: Boolean);
begin
  CancelRepeat;
  FLive:=AValue;
  if FLive then UpdateLiveValue;
end;

function TGuiSpinEdit.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

procedure TGuiSpinEdit.CancelRepeat;
begin
  Inc(FValueRevision);
  FRepeatDirection:=0;
end;

procedure TGuiSpinEdit.SetAutoRepeat(AValue: Boolean);
begin
  CancelRepeat;
  FAutoRepeat:=AValue;
end;

procedure TGuiSpinEdit.SetRepeatDelay(AValue: Cardinal);
begin
  CancelRepeat;
  FRepeatDelay:=AValue;
end;

procedure TGuiSpinEdit.SetRepeatInterval(AValue: Cardinal);
begin
  if AValue=0 then raise EArgumentException.Create('Spin repeat interval must be positive');
  CancelRepeat;
  FRepeatInterval:=AValue;
end;

procedure TGuiSpinEdit.SetWrap(AValue: Boolean);
begin
  CancelRepeat;
  FWrap:=AValue;
end;

procedure TGuiSpinEdit.UpdateRepeat;
var Ancestor: TGuiControl;
NowValue: UInt64;
WaitValue: Cardinal;
begin
  if (FRepeatDirection=0) OR NOT FAutoRepeat then Exit;
  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      CancelRepeat;
      Exit;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if (CompositionText<>'') OR (Assigned(Context) AND Assigned(Context.ModalControl) AND
    NOT Context.ControlContains(Context.ModalControl,Self)) then
    begin
      CancelRepeat;
      Exit;
    end;
  NowValue:=AnimationTime;
  if NowValue<FRepeatStamp then
  begin
    CancelRepeat;
    Exit;
  end;
  if FRepeatWaiting then WaitValue:=FRepeatDelay else WaitValue:=FRepeatInterval;
  if NowValue-FRepeatStamp<WaitValue then Exit;
  { At most one step per update: a stalled frame must not replay a burst of clicks.
    Store timing before notification; callbacks may cancel or remove this control. }
  FRepeatWaiting:=False;
  FRepeatStamp:=NowValue;
  StepBy(FRepeatDirection);
end;

function TGuiSpinEdit.FormatValue(AValue: Integer): String;
begin
  Result:=IntToStr(AValue);
end;

function TGuiSpinEdit.TryParseValue(const AText: String; out AValue: Integer): Boolean;
var S: String;
I,Start: Integer;
begin
  S:=Trim(AText);
  Result:=False;
  AValue:=0;
  if S='' then Exit;
  Start:=1;
  if (S[1]='+') OR (S[1]='-') then Start:=2;
  if Start>Length(S) then Exit;
  for I:=Start to Length(S) do if NOT (S[I] IN ['0'..'9']) then Exit;
  Result:=TryStrToInt(S,AValue);
end;

function TGuiSpinEdit.GetInputValid: Boolean;
var Parsed: Integer;
begin
  Result:=TryParseValue(Text,Parsed) AND (Parsed>=FMinValue) AND (Parsed<=FMaxValue);
end;

procedure TGuiSpinEdit.SyncText;
begin
  FSyncing:=True;
  try
    Text:=FormatValue(FValue);
  finally
    FSyncing:=False;
  end;
  FEditing:=False;
end;

procedure TGuiSpinEdit.UpdateLiveValue(AUser: Boolean);
var Parsed: Integer;
begin
  if NOT FLive OR FSyncing OR NOT TryParseValue(Text,Parsed) then Exit;
  if (Parsed<FMinValue) OR (Parsed>FMaxValue) OR (Parsed=FValue) then Exit;
  FValue:=Parsed;
  Inc(FValueRevision);
  NotifyValueChanged(AUser);
end;

procedure TGuiSpinEdit.DoChange;
begin
  inherited;
  if FSyncing then Exit;
  CancelRepeat;
  FEditing:=True;
  UpdateLiveValue;
end;

procedure TGuiSpinEdit.DoUserChange;
begin
  inherited DoChange;
  if FSyncing then Exit;
  CancelRepeat;
  FEditing:=True;
  UpdateLiveValue(True);
end;

function TGuiSpinEdit.CommitEdit: Boolean;
var Parsed: Integer;
begin
  if CompositionText<>'' then
  begin
    Result:=False;
    Exit;
  end;
  Result:=TryParseValue(Text,Parsed);
  CancelRepeat;
  if Result then AssignValue(Parsed,True) else CancelEdit;
end;

procedure TGuiSpinEdit.CancelEdit;
begin
  CancelRepeat;
  CancelComposition;
  SyncText;
end;

function TGuiSpinEdit.TextRect: TGuiRect;
begin
  Result:=inherited TextRect;
  Result.Width:=Max(0,Min(Result.Width,UpButtonRect.Left-4-Result.Left));
end;

function TGuiSpinEdit.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  if GuiRectContains(UpButtonRect,APoint) OR GuiRectContains(DownButtonRect,APoint) then Result:=gmcArrow
  else Result:=inherited MouseCursorAt(APoint);
end;

procedure TGuiSpinEdit.SetMinValue(AValue: Integer);
begin
  FMinValue:=AValue;
  if FMaxValue < FMinValue then
    FMaxValue:=FMinValue;

  SetValue(FValue);
end;

procedure TGuiSpinEdit.SetMaxValue(AValue: Integer);
begin
  FMaxValue:=AValue;
  if FMinValue > FMaxValue then
    FMinValue:=FMaxValue;

  SetValue(FValue);
end;

procedure TGuiSpinEdit.SetValue(AValue: Integer);
begin
  CancelRepeat;
  AssignValue(AValue);
end;

procedure TGuiSpinEdit.AssignValue(AValue: Integer; AUser: Boolean);
var Changed: Boolean;
begin
  if AValue < FMinValue then
    AValue:=FMinValue;

  if AValue > FMaxValue then
    AValue:=FMaxValue;

  Changed:=FValue<>AValue;
  FValue:=AValue;
  Inc(FValueRevision);
  SyncText;
  if Changed then NotifyValueChanged(AUser);
end;

procedure TGuiSpinEdit.SetIncrement(AValue: Integer);
begin
  if AValue<=0 then raise EArgumentException.Create('Spin increment must be positive');
  CancelRepeat;
  FIncrement:=AValue;
end;

function TGuiSpinEdit.NextStepValue(ASteps: Integer): Integer;
var NextValue: Int64;
Parsed: Integer;
begin
  NextValue:=FValue;
  if FEditing AND TryParseValue(Text,Parsed) then NextValue:=EnsureRange(Parsed,FMinValue,FMaxValue);
  NextValue:=NextValue+Int64(ASteps)*FIncrement;
  if NextValue>FMaxValue then
    if FWrap then NextValue:=FMinValue else NextValue:=FMaxValue
  else if NextValue<FMinValue then
    if FWrap then NextValue:=FMaxValue else NextValue:=FMinValue;
  Result:=Integer(NextValue);
end;

procedure TGuiSpinEdit.StepBy(ASteps: Integer);
begin
  if NOT Enabled OR (ASteps=0) OR (CompositionText<>'') then Exit;
  AssignValue(NextStepValue(ASteps),True);
end;

function TGuiSpinEdit.UpButtonRect: TGuiRect;
var
  Rect: TGuiRect;
  Width,Inset: TGuiFloat;
begin
  Rect:=AbsoluteBounds;
  Inset:=Min(1,Max(0,Rect.Width)/2);
  Width:=Min(23,Max(0,Rect.Width-2*Inset));
  Result:=GuiRect(Rect.Left+Max(0,Rect.Width)-Inset-Width,
    Rect.Top+Min(1,Max(0,Rect.Height)/2),Width,Max(0,Rect.Height-2)/2);
end;

function TGuiSpinEdit.DownButtonRect: TGuiRect;
begin
  Result:=UpButtonRect;
  Result.Top:=Result.Top+Result.Height;
end;

procedure TGuiSpinEdit.PaintSelf(ACanvas: TGuiCanvas);
var
  BoundsRect: TGuiRect;
  UpRect: TGuiRect;
  DownRect: TGuiRect;
  GlyphRect: TGuiRect;
  States: TGuiControlVisualStates;
  ArrowStates: TGuiControlVisualStates;
  procedure PaintArrow(const ARect: TGuiRect; ADirection: Integer);
  begin
    ArrowStates:=States-[gcvsHovered,gcvsFocused];
    if FHotArrow=ADirection then Include(ArrowStates,gcvsHovered);
    if FRepeatDirection=ADirection then Include(ArrowStates,gcvsPressed);
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,ArrowStates),ARect,Style.CornerRadius);
    DrawControlBorder(ACanvas,ARect,GuiResolveBorderColor(Style,ArrowStates));
  end;
begin
  BoundsRect:=AbsoluteBounds;
  if (BoundsRect.Width<=0) OR (BoundsRect.Height<=0) then Exit;
  ACanvas.PushClipRect(BoundsRect);
  try
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);

  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  UpRect:=UpButtonRect;
  DownRect:=DownButtonRect;

  inherited PaintSelf(ACanvas);
  PaintArrow(UpRect,1);
  PaintArrow(DownRect,-1);

  GlyphRect:=GuiRect(UpRect.Left + (UpRect.Width / 2) - 4, UpRect.Top + (UpRect.Height / 2) - 2, 8, 4);
  ACanvas.DrawChevron(GlyphRect, GuiResolveTextColor(Style, States), True);
  GlyphRect:=GuiRect(DownRect.Left + (DownRect.Width / 2) - 4, DownRect.Top + (DownRect.Height / 2) - 2, 8, 4);
  ACanvas.DrawChevron(GlyphRect, GuiResolveTextColor(Style, States));
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiSpinEdit.HandleEvent(var AEvent: TGuiEvent);
var Steps: Integer;
begin
  if AEvent.Kind=gekCancel then
  begin
    FSteppingPointer:=False;
    FHotArrow:=0;
    CancelEdit;
    inherited;
    Exit;
  end;
  if AEvent.Kind=gekBlur then
  begin
    CancelRepeat;
    FSteppingPointer:=False;
    inherited;
    if Enabled then CommitEdit else CancelEdit;
    Exit;
  end;
  if AEvent.Kind=gekMouseLeave then
  begin
    FHotArrow:=0;
    CancelRepeat;
  end;
  if (AEvent.Kind=gekMouseMove) OR ((AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft)) then
  begin
    FHotArrow:=0;
    if GuiRectContains(UpButtonRect,AEvent.Position) then FHotArrow:=1
    else if GuiRectContains(DownButtonRect,AEvent.Position) then FHotArrow:=-1;
    if FHotArrow<>FRepeatDirection then CancelRepeat;
  end;
  if NOT Enabled then Exit;
  if (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27) then
  begin
    CancelRepeat;
    if CompositionText<>'' then CancelComposition else CancelEdit;
    AEvent.Handled:=True;
    Exit;
  end;
  if CompositionText<>'' then
  begin
    inherited;
    Exit;
  end;
  if FSteppingPointer AND (AEvent.Kind=gekMouseMove) then
  begin
    AEvent.Handled:=True;
    Exit;
  end;
  if FSteppingPointer AND (AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft) then
  begin
    CancelRepeat;
    FSteppingPointer:=False;
    Pressed:=False;
    AEvent.Handled:=True;
    Exit;
  end;

  case AEvent.Kind of
    gekMouseDown:
    begin
      if AEvent.Button<>gmbLeft then Exit;
      FSteppingPointer:=False;
      CancelRepeat;
      if GuiRectContains(UpButtonRect, AEvent.Position) then
      begin
        FSteppingPointer:=True;
        Pressed:=False;
        FRepeatDirection:=1;
        FHotArrow:=1;
        FRepeatWaiting:=True;
        FRepeatStamp:=AnimationTime;
        AEvent.Handled:=True;
        StepBy(1);
        Exit;
      end else
      if GuiRectContains(DownButtonRect, AEvent.Position) then
      begin
        FSteppingPointer:=True;
        Pressed:=False;
        FRepeatDirection:=-1;
        FHotArrow:=-1;
        FRepeatWaiting:=True;
        FRepeatStamp:=AnimationTime;
        AEvent.Handled:=True;
        StepBy(-1);
        Exit;
      end;
    end;

    gekMouseWheel:
    begin
      Steps:=0;
      if AEvent.Delta.Y>0 then Steps:=1 else if AEvent.Delta.Y<0 then Steps:=-1;
      if Steps=0 then Exit;
      AEvent.Handled:=NextStepValue(Steps)<>FValue;
      StepBy(Steps);
      Exit;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        $40000052:
        begin
          AEvent.Handled:=True;
          StepBy(1);
          Exit;
        end;

        $40000051:
        begin
          AEvent.Handled:=True;
          StepBy(-1);
          Exit;
        end;

        $4000004A:
        if NOT Editable then
        begin
          AEvent.Handled:=True;
          CancelRepeat;
          AssignValue(FMinValue,True);
          Exit;
        end;

        $4000004D:
        if NOT Editable then
        begin
          AEvent.Handled:=True;
          CancelRepeat;
          AssignValue(FMaxValue,True);
          Exit;
        end;
        13:
        begin
          AEvent.Handled:=True;
          CommitEdit;
          Exit;
        end;
      end;
    end;
  end;
  inherited HandleEvent(AEvent);
end;

function TGuiLinkLabel.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if Enabled AND (Cursor = gmcAuto) then
    Result:=gmcHand;
end;

procedure TGuiEdit.DetachedFromContext;
begin
  CancelComposition;
end;

function TGuiEdit.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if Enabled AND (Cursor = gmcAuto) then
    Result:=gmcText;
end;

function TGuiMemo.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if Enabled AND (Cursor = gmcAuto) AND (MaxScrollY > 0) AND
    (FDraggingScrollBar OR GuiRectContains(GetScrollBarRect, APoint)) then
    Result:=gmcArrow;
end;

procedure TGuiSpinEdit.UpdateInteraction(AStage: TGuiInteractionStage);
begin
  if AStage = gisSecondaryRepeat then
    UpdateRepeat;
end;

end.
