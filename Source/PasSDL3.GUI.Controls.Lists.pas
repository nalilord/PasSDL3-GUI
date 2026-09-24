unit PasSDL3.GUI.Controls.Lists;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Math,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.StateStrings,
  PasSDL3.GUI.Renderer.Canvas,
  PasSDL3.GUI.Core,
  PasSDL3.GUI.Controls.Buttons,
  PasSDL3.GUI.Controls.Text;

type
  TGuiCheckBoxState = PasSDL3.GUI.Controls.Buttons.TGuiCheckBoxState;

  TGuiListBox = class(TGuiControl)
  private type
    PListEventGuard = ^TListEventGuard;
    TListEventGuard = record
    private
      FPrevious: PListEventGuard;
      FAlive: Boolean;
    public
      property Previous: PListEventGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FListEventGuard: PListEventGuard;
    procedure BeginListEvent(var AGuard: TListEventGuard);
    procedure EndListEvent(var AGuard: TListEventGuard);
  private
    FItems: TStringList;
    FSelectedIndex: Integer;
    FItemHeight: TGuiFloat;
    FScrollY, FDragStartY, FDragStartScrollY: TGuiFloat;
    FDraggingScrollBar: Boolean;
    FDragScrollEnabled, FContentPointerDown, FContentDragging: Boolean;
    FContentStartY, FContentStartScrollY: TGuiFloat;
    procedure SetItemHeight(AValue: TGuiFloat);
    procedure SetScrollY(AValue: TGuiFloat);
    function GetMaxScrollY: TGuiFloat;
    function GetContentRect: TGuiRect;
    function GetScrollBarRect: TGuiRect;
    function GetScrollThumbRect: TGuiRect;
    procedure EnsureSelectionVisible;
    procedure SetSelectedIndex(AValue: Integer);
    function ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    FOnSelect: TGuiNotifyEvent;
    function CreateItems: TStringList; virtual;
    procedure ItemsChanged(Sender: TObject); virtual;
    procedure PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect); virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddItem(const AText: String): Integer;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property Items: TStringList read FItems;
    property ItemHeight: TGuiFloat read FItemHeight write SetItemHeight;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
    property ScrollY: TGuiFloat read FScrollY write SetScrollY;
    property MaxScrollY: TGuiFloat read GetMaxScrollY;
    property DragScrollEnabled: Boolean read FDragScrollEnabled write FDragScrollEnabled;
  end;

  TGuiWheelWrapMode = (gwwAuto, gwwEnabled, gwwDisabled);

  TGuiWheelPicker = class(TGuiControl)
  private type
    PWheelEventGuard = ^TWheelEventGuard;
    TWheelEventGuard = record
    private
      FPrevious: PWheelEventGuard;
      FAlive: Boolean;
    public
      property Previous: PWheelEventGuard read FPrevious write FPrevious;
      property Alive: Boolean read FAlive write FAlive;
    end;
  private
    FWheelEventGuard: PWheelEventGuard;
  private
    FAnimating,FFlickEnabled: Boolean;
    FVelocity,FStartVelocity,FStartPosition: Double;
    FDeceleration: TGuiFloat;
    FSampleTime,FMotionStart: UInt64;
    FSettleDuration: Cardinal;
    FMotionRevision: Integer;
    FItems: TStringList;
    FItemIndex,FVisibleItemCount: Integer;
    FWrapMode: TGuiWheelWrapMode;
    FPosition: Double;
    FPointerDown,FDragging: Boolean;
    FDownY,FLastY: TGuiFloat;
    FOnChange: TGuiNotifyEvent;
    procedure ItemsChanged(Sender: TObject);
    procedure SetItemIndex(AValue: Integer);
    procedure SetVisibleItemCount(AValue: Integer);
    procedure SetWrapMode(AValue: TGuiWheelWrapMode);
    procedure SetWrap(AValue: Boolean);
    function GetWrap: Boolean;
    procedure CancelMotion;
    procedure SetPosition(AValue: Double; ASettle: Boolean);
    function RowHeight: TGuiFloat;
    function GetMoving: Boolean;
    procedure SetFlickEnabled(AValue: Boolean);
    procedure SetDeceleration(AValue: TGuiFloat);
    procedure SetSettleDuration(AValue: Cardinal);
    procedure SampleVelocity(ADelta: Double);
    procedure StartMotion;
  protected
    function AnimationTime: UInt64; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
    procedure PaintWheelItem(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
      ADisplacement: TGuiFloat); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddItem(const AText: String): Integer;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure UpdateMotion;
    procedure UpdateInteraction(AStage: TGuiInteractionStage); override;
    property Items: TStringList read FItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property VisibleItemCount: Integer read FVisibleItemCount write SetVisibleItemCount;
    property WrapMode: TGuiWheelWrapMode read FWrapMode write SetWrapMode;
    property Wrap: Boolean read GetWrap write SetWrap;
    property Moving: Boolean read GetMoving;
    property ScrollPosition: Double read FPosition;
    property FlickEnabled: Boolean read FFlickEnabled write SetFlickEnabled;
    property Deceleration: TGuiFloat read FDeceleration write SetDeceleration;
    property SettleDuration: Cardinal read FSettleDuration write SetSettleDuration;
    property OnChange: TGuiNotifyEvent read FOnChange write FOnChange;
  end;

  TGuiRadioGroup = class(TGuiListBox)
  private
    function GetItemIndex: Integer;
    procedure SetItemIndex(AValue: Integer);
  protected
    procedure ItemsChanged(Sender: TObject); override;
    procedure PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property OnChange: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiTreeNode = class
  private
    FText: String;
    FLevel: Integer;
    FExpanded: Boolean;
  public
    property Text: String read FText write FText;
    property Level: Integer read FLevel write FLevel;
    property Expanded: Boolean read FExpanded write FExpanded;
    constructor Create(const AText: String; ALevel: Integer);
  end;

  TGuiTreeView = class(TGuiControl)
  private
    FNodes: TList;
    FSelectedIndex: Integer;
    FItemHeight: TGuiFloat;
    FScrollY: TGuiFloat;
    FDraggingScrollBar: Boolean;
    FDragStartY: TGuiFloat;
    FDragStartScrollY: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    procedure SetScrollY(AValue: TGuiFloat);
    function GetMaxScrollY: TGuiFloat;
    function GetContentRect: TGuiRect;
    function GetScrollBarRect: TGuiRect;
    function GetScrollThumbRect: TGuiRect;
    function ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
    function NodeHasChildren(AIndex: Integer): Boolean;
    function IsNodeVisible(AIndex: Integer): Boolean;
    function VisibleNodeCount: Integer;
    function VisibleIndexToNodeIndex(AVisibleIndex: Integer): Integer;
    function NodeIndexAtPoint(const APoint: TGuiPoint): Integer;
    function GetNode(AIndex: Integer): TGuiTreeNode;
    function GetNodeCount: Integer;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddNode(const AText: String; ALevel: Integer = 0): TGuiTreeNode;
    procedure ClearNodes;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property Nodes[AIndex: Integer]: TGuiTreeNode read GetNode;
    property NodeCount: Integer read GetNodeCount;
    property ItemHeight: TGuiFloat read FItemHeight write FItemHeight;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property ScrollY: TGuiFloat read FScrollY write SetScrollY;
    property MaxScrollY: TGuiFloat read GetMaxScrollY;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiHeaderControl = class(TGuiControl)
  private
    FResizingColumn: Integer;
    FResizeStartX, FResizeStartWidth: TGuiFloat;
    FColumnsResizable: Boolean;
    function ResizeColumnAtPoint(const APoint: TGuiPoint): Integer;
    procedure SetColumnWidth(AIndex: Integer; AValue: TGuiFloat);
    function HandleColumnResize(var AEvent: TGuiEvent): Boolean;
  private
    FCaptions: TStringList;
    FColumnWidths: TList;
    FHoveredIndex: Integer;
    function GetColumnCount: Integer;
    function GetColumnCaption(AIndex: Integer): String;
    function GetColumnWidth(AIndex: Integer): TGuiFloat;
    function ColumnIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddColumn(const ACaption: String; AWidth: TGuiFloat): Integer;
    procedure ClearColumns;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    property ColumnCount: Integer read GetColumnCount;
    property ColumnCaption[AIndex: Integer]: String read GetColumnCaption;
    property ColumnWidth[AIndex: Integer]: TGuiFloat read GetColumnWidth write SetColumnWidth;
    property ColumnsResizable: Boolean read FColumnsResizable write FColumnsResizable;
  end;

  TGuiSortDirection = (gsdAscending, gsdDescending);
  TGuiColumnSortKind = (gcskText, gcskNumber);
  TGuiIndexArray = array of Integer;
  TGuiColumnEvent = procedure(Sender: TGuiControl; AColumn: Integer) of object;
  TGuiCompareRowsEvent = procedure(Sender: TGuiControl;
    ALeft, ARight: TStrings; AColumn: Integer; var AResult: Integer) of object;

  TGuiListView = class(TGuiControl)
  private
    FSelectedRows, FColumnSortKinds: TList;
    FSelectionAnchor: TStringList;
    FMultiSelect, FSortOnHeaderClick: Boolean;
    FSortColumn, FHeaderColumn, FPressedColumn: Integer;
    FSortDirection: TGuiSortDirection;
    FOnColumnClick: TGuiColumnEvent;
    FOnCompareRows: TGuiCompareRowsEvent;
    procedure SetMultiSelect(AValue: Boolean);
    procedure SelectIndex(AIndex: Integer; AExtend, AToggle, AKeep: Boolean);
    procedure EnsureSelectionVisible;
    function GetRowSelected(AIndex: Integer): Boolean;
    procedure SetRowSelected(AIndex: Integer; AValue: Boolean);
    function GetSelectedCount: Integer;
    function GetCellText(ARow, AColumn: Integer): String;
    procedure SetCellText(ARow, AColumn: Integer; const AValue: String);
    function GetColumnSortKind(AColumn: Integer): TGuiColumnSortKind;
    procedure SetColumnSortKind(AColumn: Integer; AValue: TGuiColumnSortKind);
    function HeaderIndexAtPoint(const APoint: TGuiPoint): Integer;
    procedure ActivateColumn(AColumn: Integer);
  private
    FResizingColumn: Integer;
    FResizeStartX, FResizeStartWidth: TGuiFloat;
    FColumnsResizable: Boolean;
    function ResizeColumnAtPoint(const APoint: TGuiPoint): Integer;
    procedure SetColumnWidth(AIndex: Integer; AValue: TGuiFloat);
    function HandleColumnResize(var AEvent: TGuiEvent): Boolean;
  private
    FColumns: TStringList;
    FColumnWidths: TList;
    FRows: TList;
    FSelectedIndex: Integer;
    FRowHeight: TGuiFloat;
    FHeaderHeight: TGuiFloat;
    FScrollY: TGuiFloat;
    FDraggingScrollBar: Boolean;
    FDragStartY: TGuiFloat;
    FDragStartScrollY: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    procedure SetScrollY(AValue: TGuiFloat);
    function GetMaxScrollY: TGuiFloat;
    function GetColumnCount: Integer;
    function GetRowCount: Integer;
    function GetColumnWidth(AIndex: Integer): TGuiFloat;
    function GetContentRect: TGuiRect;
    function GetRowsRect: TGuiRect;
    function GetScrollBarRect: TGuiRect;
    function GetScrollThumbRect: TGuiRect;
    function ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
    function RowIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddColumn(const ACaption: String; AWidth: TGuiFloat): Integer;
    function AddRow(const AValues: array of String): Integer;
    procedure ClearRows;
    procedure ClearColumns;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    procedure SortByColumn(AColumn: Integer; ADirection: TGuiSortDirection = gsdAscending);
    procedure ClearSelection;
    procedure SelectAll;
    function SelectedIndices: TGuiIndexArray;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect;
    property RowSelected[AIndex: Integer]: Boolean read GetRowSelected write SetRowSelected;
    property SelectedCount: Integer read GetSelectedCount;
    property CellText[ARow, AColumn: Integer]: String read GetCellText write SetCellText;
    property ColumnSortKind[AColumn: Integer]: TGuiColumnSortKind read GetColumnSortKind write SetColumnSortKind;
    property SortOnHeaderClick: Boolean read FSortOnHeaderClick write FSortOnHeaderClick;
    property SortColumn: Integer read FSortColumn;
    property SortDirection: TGuiSortDirection read FSortDirection;
    property OnColumnClick: TGuiColumnEvent read FOnColumnClick write FOnColumnClick;
    property OnCompareRows: TGuiCompareRowsEvent read FOnCompareRows write FOnCompareRows;
    property ColumnCount: Integer read GetColumnCount;
    property RowCount: Integer read GetRowCount;
    property ColumnWidth[AIndex: Integer]: TGuiFloat read GetColumnWidth write SetColumnWidth;
    property ColumnsResizable: Boolean read FColumnsResizable write FColumnsResizable;
    property RowHeight: TGuiFloat read FRowHeight write FRowHeight;
    property HeaderHeight: TGuiFloat read FHeaderHeight write FHeaderHeight;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property ScrollY: TGuiFloat read FScrollY write SetScrollY;
    property MaxScrollY: TGuiFloat read GetMaxScrollY;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
  end;

  TGuiItemTemplate = class(TGuiControl)
  private
    FTitle: String;
    FSubtitle: String;
    FDetailText: String;
    FIcon: TGuiDrawable;
    FShowSwatch: Boolean;
    FSwatchColor: TGuiColor;
    FSelected: Boolean;
  public
    property Title: String read FTitle write FTitle;
    property Subtitle: String read FSubtitle write FSubtitle;
    property DetailText: String read FDetailText write FDetailText;
    property Icon: TGuiDrawable read FIcon write FIcon;
    property ShowSwatch: Boolean read FShowSwatch write FShowSwatch;
    property SwatchColor: TGuiColor read FSwatchColor write FSwatchColor;
    property Selected: Boolean read FSelected write FSelected;
    constructor Create; override;
  protected
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  end;

  TGuiItemCheckEvent = procedure(Sender: TGuiControl;
    AIndex: Integer) of object;

  TGuiCheckListBox = class(TGuiListBox)
  private
    FAllowGrayed: Boolean;
    FPendingItem,FItemRevision: Integer;
    FOnCheck: TGuiItemCheckEvent;
    function GetState(AIndex: Integer): TGuiCheckBoxState;
    procedure SetState(AIndex: Integer; AValue: TGuiCheckBoxState);
    function GetChecked(AIndex: Integer): Boolean;
    procedure SetChecked(AIndex: Integer; AValue: Boolean);
    function GetItemEnabled(AIndex: Integer): Boolean;
    procedure SetItemEnabled(AIndex: Integer; AValue: Boolean);
  protected
    function CreateItems: TStringList; override;
    procedure ItemsChanged(Sender: TObject); override;
    function IndicatorSize: TGuiSize; virtual;
    procedure PaintCheckIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect;
      AState: TGuiCheckBoxState; AEnabled: Boolean); virtual;
    procedure PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect); override;
    function NextCheckState(AIndex: Integer): TGuiCheckBoxState; virtual;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    procedure ToggleCheck(AIndex: Integer);
    property Checked[Index: Integer]: Boolean read GetChecked write SetChecked;
    property State[Index: Integer]: TGuiCheckBoxState read GetState write SetState;
    property ItemEnabled[Index: Integer]: Boolean read GetItemEnabled write SetItemEnabled;
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed;
    property OnCheck: TGuiItemCheckEvent read FOnCheck write FOnCheck;
  end;

  TGuiSwitchListBox = class(TGuiCheckListBox)
  private
    FSwitchItem,FPaintItem: Integer;
    FSwitchDragging: Boolean;
    FSwitchStartX,FSwitchStartPosition,FSwitchPosition: TGuiFloat;
    function GetThumbPosition(AIndex: Integer): TGuiFloat;
    function ItemTrackRect(AIndex: Integer): TGuiRect;
  protected
    procedure ItemsChanged(Sender: TObject); override;
    function IndicatorSize: TGuiSize; override;
    function NextCheckState(AIndex: Integer): TGuiCheckBoxState; override;
    procedure PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect); override;
    procedure PaintCheckIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect;
      AState: TGuiCheckBoxState; AEnabled: Boolean); override;
  public
    constructor Create; override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    property ThumbPosition[Index: Integer]: TGuiFloat read GetThumbPosition;
  end;

  TGuiComboBox = class(TGuiEdit)
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
    FSelectionRevision: UInt64;
    FKeyboardHighlight: Boolean;
    FOnAccept: TGuiNotifyEvent;
    FSyncingText,FEditing,FEditingPointer: Boolean;
    FAutoComplete,FSearchCaseSensitive: Boolean;
    FTypeAhead,FSearchComposing: Boolean;
    FSearchPrefix: String;
    FSearchStamp: UInt64;
    FTypeAheadTimeout: Cardinal;
    procedure SetTypeAhead(AValue: Boolean);
    procedure SetTypeAheadTimeout(AValue: Cardinal);
    function TryCompleteText: Boolean;
    function GetEditable: Boolean;
    procedure SetEditable(AValue: Boolean);
    procedure SyncSelectionText;
    procedure MoveHighlight(AIndex: Integer);
    procedure AcceptItem(AIndex: Integer; const ACustomText: String = '');
    procedure EnsureItemVisible(AIndex: Integer);
  private
    FDropDownCount,FPopupRowCount: Integer;
    FPopupLayout: TGuiRect;
    FHasPopupLayout: Boolean;
    procedure SetDropDownCount(AValue: Integer);
    function GetVisibleItemCount: Integer;
    procedure NormalizePopupScroll;
  private
    FSyncingItems: Boolean;
    FItemsCount,FItemsRevision: Integer;
    FSelectionText: String;
    procedure ItemsChanged(Sender: TObject);
    procedure ApplySelection(AIndex: Integer; AIdentityChanged: Boolean;
      const ACustomText: String = ''; APreserveEdit: Boolean = False);
    procedure EnsureSelectionVisible;
    procedure SetDroppedDown(AValue: Boolean);
    procedure SetItemHeight(AValue: TGuiFloat);
  private
    FDraggingPopupBar: Boolean;
    FPopupDragY: TGuiFloat;
    FPopupDragFirst: Integer;
    FFirstVisible: Integer;
    FItems: TStringList;
    FSelectedIndex: Integer;
    FDroppedDown: Boolean;
    FHoveredIndex: Integer;
    FItemHeight: TGuiFloat;
    FOnSelect: TGuiNotifyEvent;
    procedure SetSelectedIndex(AValue: Integer);
    function PopupTrackRect: TGuiRect;
    function PopupThumbRect: TGuiRect;
    function HandlePopupScroll(var AEvent: TGuiEvent): Boolean;
    function DropDownRect: TGuiRect;
    function ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
  protected
    procedure DoChange; override;
    function TextRect: TGuiRect; override;
    procedure ClosePopup; override;
    procedure DoTextInserted; override;
    function SearchTime: UInt64; virtual;
    procedure PaintSelf(ACanvas: TGuiCanvas); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function AddItem(const AText: String): Integer;
    procedure AcceptSelection;
    procedure AcceptText;
    procedure CancelEdit;
    function FindText(const AText: String): Integer;
    function FindPrefix(const AText: String; AStartIndex: Integer = 0): Integer; virtual;
    function CompleteText: Boolean;
    procedure Search(const AText: String);
    procedure ClearSearch;
    function TextInputRect(ACanvas: TGuiCanvas): TGuiRect; override;
    function MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor; override;
    procedure PaintOverlay(ACanvas: TGuiCanvas); override;
    procedure HandleEvent(var AEvent: TGuiEvent); override;
    function HitTest(const APoint: TGuiPoint): TGuiControl; override;
    function HitTestOverlay(const APoint: TGuiPoint): TGuiControl; override;
    property Items: TStringList read FItems;
    property SelectedIndex: Integer read FSelectedIndex write SetSelectedIndex;
    property DroppedDown: Boolean read FDroppedDown write SetDroppedDown;
    property ItemHeight: TGuiFloat read FItemHeight write SetItemHeight;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount;
    property VisibleItemCount: Integer read GetVisibleItemCount;
    property PopupBounds: TGuiRect read DropDownRect;
    property OnSelect: TGuiNotifyEvent read FOnSelect write FOnSelect;
    property HighlightedIndex: Integer read FHoveredIndex;
    property OnAccept: TGuiNotifyEvent read FOnAccept write FOnAccept;
    property Editable: Boolean read GetEditable write SetEditable;
    property Editing: Boolean read FEditing;
    property AutoComplete: Boolean read FAutoComplete write FAutoComplete;
    property SearchCaseSensitive: Boolean read FSearchCaseSensitive write FSearchCaseSensitive;
    property TypeAhead: Boolean read FTypeAhead write SetTypeAhead;
    property TypeAheadTimeout: Cardinal read FTypeAheadTimeout write SetTypeAheadTimeout;
    property SearchPrefix: String read FSearchPrefix;
  end;

const
  gcbUnchecked = PasSDL3.GUI.Controls.Buttons.gcbUnchecked;
  gcbChecked = PasSDL3.GUI.Controls.Buttons.gcbChecked;
  gcbGrayed = PasSDL3.GUI.Controls.Buttons.gcbGrayed;

implementation

constructor TGuiListBox.Create;
begin
  inherited Create;
  FItems:=CreateItems;
  FItems.OnChange:=ItemsChanged;
  FSelectedIndex:=-1;
  FItemHeight:=30;
  CanFocus:=True;
  TabStop:=True;
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
  TextColor:=GuiColor(232, 238, 247);
  Padding:=GuiBox(4);
end;

function TGuiListBox.CreateItems: TStringList;
begin
  Result:=TStringList.Create;
end;

destructor TGuiListBox.Destroy;
var Guard: PListEventGuard;
begin
  Guard:=FListEventGuard;
  while Assigned(Guard) do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  FItems.Free;
  inherited Destroy;
end;

procedure TGuiListBox.BeginListEvent(var AGuard: TListEventGuard);
begin
  AGuard.Previous:=FListEventGuard;
  AGuard.Alive:=True;
  FListEventGuard:=@AGuard;
end;

procedure TGuiListBox.EndListEvent(var AGuard: TListEventGuard);
begin
  FListEventGuard:=AGuard.Previous;
end;

function TGuiListBox.AddItem(const AText: String): Integer;
begin
  Result:=FItems.Add(AText);

  if FSelectedIndex < 0 then
    FSelectedIndex:=0;

  InvalidateLayout;
end;

procedure TGuiListBox.SetSelectedIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue:=-1;

  if AValue >= FItems.Count then
    AValue:=FItems.Count - 1;

  if FSelectedIndex = AValue then
  begin
    EnsureSelectionVisible;
    Exit;
  end;

  FSelectedIndex:=AValue;
  EnsureSelectionVisible;

  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TGuiListBox.SetItemHeight(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) then
    raise EArgumentException.Create('List item height must be finite');
  AValue:=Max(1,AValue);
  if FItemHeight=AValue then Exit;
  FItemHeight:=AValue;
  FDraggingScrollBar:=False;
  FContentPointerDown:=False;
  FContentDragging:=False;
  EnsureSelectionVisible;
  InvalidateLayout;
end;

procedure TGuiListBox.ItemsChanged(Sender: TObject);
begin
  if FSelectedIndex >= FItems.Count then FSelectedIndex:=FItems.Count - 1;
  SetScrollY(FScrollY);
  InvalidateLayout;
end;

function TGuiListBox.GetMaxScrollY: TGuiFloat;
begin
  Result:=Max(0, FItems.Count * Max(1, FItemHeight) - GuiInflateRect(AbsoluteBounds, Padding).Height);
end;

procedure TGuiListBox.SetScrollY(AValue: TGuiFloat);
begin
  FScrollY:=EnsureRange(AValue, 0, MaxScrollY);
end;

function TGuiListBox.GetContentRect: TGuiRect;
begin
  Result:=ScrollContentRect(MaxScrollY > 0);
end;

function TGuiListBox.GetScrollBarRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(AbsoluteBounds, goVertical, Max(8, Style.ScrollBarSize));
end;

function TGuiListBox.GetScrollThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(GetScrollBarRect, GetContentRect.Height,
    FItems.Count * Max(1, FItemHeight), FScrollY);
end;

procedure TGuiListBox.EnsureSelectionVisible;
var Top, Height: TGuiFloat;
begin
  SetScrollY(FScrollY);
  if FSelectedIndex < 0 then Exit;
  Height:=Max(1, FItemHeight);
  Top:=FSelectedIndex * Height;
  if Top < FScrollY then SetScrollY(Top)
  else if Top + Height > FScrollY + GetContentRect.Height then
    SetScrollY(Top + Height - GetContentRect.Height);
end;

function TGuiListBox.ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
begin
  Result:=-1;
  Rect:=FullWidthRowRect(GetContentRect);

  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  Result:=Trunc((APoint.Y - Rect.Top + FScrollY) / Max(1, FItemHeight));

  if (Result < 0) OR (Result >= FItems.Count) then
    Result:=-1;
end;

procedure TGuiListBox.PaintSelf(ACanvas: TGuiCanvas);
var
  I, First, Last: Integer;
  Rect, ItemRect: TGuiRect;
  Height: TGuiFloat;
begin
  SetScrollY(FScrollY);
  inherited PaintSelf(ACanvas);
  Rect:=GetContentRect;
  Height:=Max(1, FItemHeight);
  First:=Max(0, Floor(FScrollY / Height));
  Last:=Min(FItems.Count - 1, Ceil((FScrollY + Rect.Height) / Height) - 1);
  ACanvas.PushClipRect(FullWidthRowRect(Rect));
  try
    for I:=First to Last do
    begin
      ItemRect:=GuiRect(Rect.Left, Rect.Top + I * Height - FScrollY, Rect.Width, Height);
      PaintItemBackground(ACanvas, FullWidthRowRect(ItemRect), I = FSelectedIndex);
      ACanvas.PushClipRect(Rect);
      try
        PaintItemContent(ACanvas,I,ItemRect);
      finally
        ACanvas.PopClipRect;
      end;
    end;
  finally
    ACanvas.PopClipRect;
  end;
  if MaxScrollY > 0 then
    PaintScrollBar(ACanvas, GetScrollBarRect, GetScrollThumbRect, goVertical, FDraggingScrollBar, True);
  if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

procedure TGuiListBox.PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect);
var States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if NOT Enabled then Include(States,gcvsDisabled);
  DrawControlText(ACanvas,FItems[AIndex],GuiInflateRect(ARect,GuiBoxLTRB(8,2,8,2)),
    GuiResolveTextColor(Style,States),ghtaLeft,gvtaCenter);
end;

constructor TGuiRadioGroup.Create;
begin
  inherited Create;
  Bounds:=GuiRect(0,0,240,160);
  ItemHeight:=34;
end;

function TGuiRadioGroup.GetItemIndex: Integer;
begin
  Result:=SelectedIndex;
end;

procedure TGuiRadioGroup.SetItemIndex(AValue: Integer);
begin
  SelectedIndex:=AValue;
end;

procedure TGuiRadioGroup.ItemsChanged(Sender: TObject);
begin
  if (SelectedIndex<0) AND (Items.Count>0) then SelectedIndex:=0
  else SelectedIndex:=SelectedIndex;
  inherited;
end;

procedure TGuiRadioGroup.PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect);
var R: TGuiRect;
Color,TextColor: TGuiColor;
begin
  R:=GuiRect(ARect.Left+8,ARect.Top+(ARect.Height-18)/2,18,18);
  Color:=Style.BorderColor;
  TextColor:=Style.TextColor;
  if AIndex=SelectedIndex then Color:=Style.CheckedBorderColor;
  if NOT Enabled then
  begin
    Color:=Style.DisabledTextColor;
    TextColor:=Color;
  end;
  ACanvas.DrawRoundedBorder(R,9,Max(1,Style.BorderWidth),Color);
  if AIndex=SelectedIndex then ACanvas.FillRoundedRect(GuiInflateRect(R,GuiBox(5)),4,Color);
  DrawControlText(ACanvas,Items[AIndex],GuiInflateRect(ARect,GuiBoxLTRB(34,2,8,2)),TextColor,ghtaLeft,gvtaCenter);
end;

procedure TGuiRadioGroup.HandleEvent(var AEvent: TGuiEvent);
begin
  if Enabled AND (AEvent.Kind=gekKeyDown) then
    case AEvent.KeyCode of
      13,32:
        begin
          if (SelectedIndex<0) AND (Items.Count>0) then SelectedIndex:=0;
          AEvent.Handled:=True;
          Exit;
        end;
      $40000050:
      begin
        SelectedIndex:=Max(0,SelectedIndex-1);
        AEvent.Handled:=True;
        Exit;
      end;
      $4000004F:
      begin
        SelectedIndex:=SelectedIndex+1;
        AEvent.Handled:=True;
        Exit;
      end;
    end;
  inherited;
end;

procedure TGuiListBox.HandleEvent(var AEvent: TGuiEvent);
var
  Index, Page: Integer;
  Thumb, Track: TGuiRect;
  OldY: TGuiFloat;
  Guard: TListEventGuard;
begin
  BeginListEvent(Guard);
  try
  inherited HandleEvent(AEvent);
  if NOT Guard.Alive then Exit;
  if (AEvent.Kind IN [gekCancel,gekBlur]) OR NOT Enabled then
  begin
    FDraggingScrollBar:=False;
    FContentPointerDown:=False;
    FContentDragging:=False;
    Exit;
  end;
  SetScrollY(FScrollY);
  case AEvent.Kind of
    gekMouseWheel:
    begin
      OldY:=FScrollY;
      SetScrollY(FScrollY - AEvent.Delta.Y * Max(1, FItemHeight) * 3);
      AEvent.Handled:=OldY <> FScrollY;
    end;
    gekMouseDown:
    begin
      if AEvent.Button <> gmbLeft then Exit;
      Track:=GetScrollBarRect;
      if (MaxScrollY > 0) AND GuiRectContains(Track, AEvent.Position) then
      begin
        Thumb:=GetScrollThumbRect;
        if NOT GuiRectContains(Thumb, AEvent.Position) then
          SetScrollY(FScrollY + GuiScrollOffsetFromThumbDelta(AEvent.Position.Y - Thumb.Top - Thumb.Height / 2,
            Track.Height, Thumb.Height, MaxScrollY));
        FDraggingScrollBar:=True;
        FDragStartY:=AEvent.Position.Y;
        FDragStartScrollY:=FScrollY;
        AEvent.Handled:=True;
      end else
      begin
        Index:=ItemIndexAtPoint(AEvent.Position);
        if Index >= 0 then
        begin
          if FDragScrollEnabled AND (MaxScrollY > 0) then
          begin
            FContentPointerDown:=True;
            FContentDragging:=False;
            FContentStartY:=AEvent.Position.Y;
            FContentStartScrollY:=FScrollY;
          end else
            SelectedIndex:=Index;
          AEvent.Handled:=True;
        end;
      end;
    end;
    gekMouseMove:
      if FContentPointerDown then
      begin
        if Abs(AEvent.Position.Y - FContentStartY) >= 8 then
          FContentDragging:=True;
        if FContentDragging then
          SetScrollY(FContentStartScrollY + FContentStartY - AEvent.Position.Y);
        AEvent.Handled:=True;
      end else if FDraggingScrollBar then
      begin
        Track:=GetScrollBarRect;
        Thumb:=GetScrollThumbRect;
        SetScrollY(FDragStartScrollY + GuiScrollOffsetFromThumbDelta(AEvent.Position.Y - FDragStartY,
          Track.Height, Thumb.Height, MaxScrollY));
        AEvent.Handled:=True;
      end;
    gekMouseUp:
      if FContentPointerDown then
      begin
        if NOT FContentDragging then
        begin
          Index:=ItemIndexAtPoint(AEvent.Position);
          if Index >= 0 then SelectedIndex:=Index;
        end;
        FContentPointerDown:=False;
        FContentDragging:=False;
        AEvent.Handled:=True;
      end else if FDraggingScrollBar then
      begin
        FDraggingScrollBar:=False;
        AEvent.Handled:=True;
      end;
    gekKeyDown:
    begin
      Page:=Max(1, Floor(GetContentRect.Height / Max(1, FItemHeight)));
      Index:=FSelectedIndex;
      case AEvent.KeyCode of
        $40000052: Index:=Max(0, Index - 1);
        $40000051: Index:=Index + 1;
        $4000004A: Index:=0;
        $4000004D: Index:=FItems.Count - 1;
        $4000004B: Index:=Max(0, Index - Page);
        $4000004E: Index:=Index + Page;
        else Exit;
      end;
      SelectedIndex:=Index;
      AEvent.Handled:=True;
    end;
  end;
  finally
    if Guard.Alive then EndListEvent(Guard);
  end;
end;

constructor TGuiTreeNode.Create(const AText: String; ALevel: Integer);
begin
  inherited Create;
  Text:=AText;
  Level:=ALevel;
  Expanded:=True;
end;

constructor TGuiTreeView.Create;
begin
  inherited Create;
  FNodes:=TList.Create;
  FSelectedIndex:=-1;
  FItemHeight:=26;
  FScrollY:=0;
  FDraggingScrollBar:=False;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBox(4);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
end;

destructor TGuiTreeView.Destroy;
begin
  ClearNodes;
  FNodes.Free;
  inherited Destroy;
end;

function TGuiTreeView.AddNode(const AText: String; ALevel: Integer): TGuiTreeNode;
begin
  Result:=TGuiTreeNode.Create(AText, ALevel);
  FNodes.Add(Result);
  if FSelectedIndex < 0 then
    FSelectedIndex:=0;

  InvalidateLayout;
end;

procedure TGuiTreeView.ClearNodes;
var
  I: Integer;
begin
  for I:=FNodes.Count - 1 downto 0 do
    TObject(FNodes[I]).Free;

  FNodes.Clear;
  FSelectedIndex:=-1;
  SetScrollY(0);
  InvalidateLayout;
end;

function TGuiTreeView.GetNode(AIndex: Integer): TGuiTreeNode;
begin
  Result:=TGuiTreeNode(FNodes[AIndex]);
end;

function TGuiTreeView.GetNodeCount: Integer;
begin
  Result:=FNodes.Count;
end;

procedure TGuiTreeView.SetSelectedIndex(AValue: Integer);
begin
  if AValue < -1 then
    AValue:=-1;

  if AValue >= FNodes.Count then
    AValue:=FNodes.Count - 1;

  if FSelectedIndex = AValue then
    Exit;

  FSelectedIndex:=AValue;

  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TGuiTreeView.SetScrollY(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if AValue > MaxScrollY then
    AValue:=MaxScrollY;

  FScrollY:=AValue;
end;

function TGuiTreeView.GetMaxScrollY: TGuiFloat;
var
  Rect: TGuiRect;
begin
  Rect:=GuiInflateRect(Bounds, Padding);
  Result:=(VisibleNodeCount * FItemHeight) - Rect.Height;

  if Result < 0 then
    Result:=0;
end;

function TGuiTreeView.GetContentRect: TGuiRect;
begin
  Result:=ScrollContentRect(MaxScrollY > 0);
end;

function TGuiTreeView.GetScrollBarRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(AbsoluteBounds, goVertical, Max(8, Style.ScrollBarSize));
end;

function TGuiTreeView.GetScrollThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(GetScrollBarRect, GetContentRect.Height, VisibleNodeCount * FItemHeight, FScrollY);
end;

function TGuiTreeView.ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
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

function TGuiTreeView.NodeHasChildren(AIndex: Integer): Boolean;
var
  Node: TGuiTreeNode;
begin
  Result:=False;

  if (AIndex < 0) OR (AIndex >= FNodes.Count - 1) then
    Exit;

  Node:=TGuiTreeNode(FNodes[AIndex]);
  Result:=TGuiTreeNode(FNodes[AIndex + 1]).Level > Node.Level;
end;

function TGuiTreeView.IsNodeVisible(AIndex: Integer): Boolean;
var
  I: Integer;
  Node: TGuiTreeNode;
  ParentLevel: Integer;
begin
  Result:=False;

  if (AIndex < 0) OR (AIndex >= FNodes.Count) then
    Exit;

  Node:=TGuiTreeNode(FNodes[AIndex]);
  ParentLevel:=Node.Level - 1;

  for I:=AIndex - 1 downto 0 do
  begin
    Node:=TGuiTreeNode(FNodes[I]);
    if Node.Level = ParentLevel then
    begin
      if NOT Node.Expanded then
        Exit;

      Dec(ParentLevel);
      if ParentLevel < 0 then
        Break;
    end;
  end;

  Result:=True;
end;

function TGuiTreeView.VisibleNodeCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to FNodes.Count - 1 do
  begin
    if IsNodeVisible(I) then
      Inc(Result);
  end;
end;

function TGuiTreeView.VisibleIndexToNodeIndex(AVisibleIndex: Integer): Integer;
var
  I: Integer;
  VisibleIndex: Integer;
begin
  Result:=-1;
  VisibleIndex:=0;

  for I:=0 to FNodes.Count - 1 do
  begin
    if NOT IsNodeVisible(I) then
      Continue;

    if VisibleIndex = AVisibleIndex then
    begin
      Result:=I;
      Exit;
    end;

    Inc(VisibleIndex);
  end;
end;

function TGuiTreeView.NodeIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
  VisibleIndex: Integer;
begin
  Result:=-1;
  Rect:=FullWidthRowRect(GetContentRect);

  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  VisibleIndex:=Trunc((APoint.Y - Rect.Top + FScrollY) / FItemHeight);
  Result:=VisibleIndexToNodeIndex(VisibleIndex);
  if (Result < 0) OR (Result >= FNodes.Count) then
    Result:=-1;
end;

procedure TGuiTreeView.PaintSelf(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
  ItemRect: TGuiRect;
  BarRect: TGuiRect;
  ThumbRect: TGuiRect;
  GlyphRect: TGuiRect;
  Node: TGuiTreeNode;
  States: TGuiControlVisualStates;
  VisibleIndex: Integer;
begin
  SetScrollY(FScrollY);
  States:=[gcvsNormal];
  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), AbsoluteBounds, Style.CornerRadius);
  DrawControlBorder(ACanvas, AbsoluteBounds, GuiResolveBorderColor(Style, States));

  Rect:=GetContentRect;
  ACanvas.PushClipRect(FullWidthRowRect(Rect));
  try
    VisibleIndex:=0;
    for I:=0 to FNodes.Count - 1 do
    begin
      if NOT IsNodeVisible(I) then
        Continue;

      Node:=TGuiTreeNode(FNodes[I]);
      ItemRect:=GuiRect(Rect.Left, Rect.Top + (VisibleIndex * FItemHeight) - FScrollY, Rect.Width, FItemHeight);
      Inc(VisibleIndex);

      if (ItemRect.Top + ItemRect.Height < Rect.Top) OR (ItemRect.Top > Rect.Top + Rect.Height) then
        Continue;

      PaintItemBackground(ACanvas, FullWidthRowRect(ItemRect), I = FSelectedIndex);
      ACanvas.PushClipRect(Rect);
      try

      if NodeHasChildren(I) then
      begin
        GlyphRect:=GuiRect(Rect.Left + 4 + (Node.Level * 16), ItemRect.Top + ((FItemHeight - 12) / 2), 12, 12);
        if Node.Expanded then
          ACanvas.DrawChevron(GuiRect(GlyphRect.Left + 2, GlyphRect.Top + 4, 8, 4), GuiResolveTextColor(Style, States))
        else
        begin
          ACanvas.DrawLine(GuiPoint(GlyphRect.Left + 4, GlyphRect.Top + 2),
            GuiPoint(GlyphRect.Left + 8, GlyphRect.Top + 6), 2, GuiResolveTextColor(Style, States));
          ACanvas.DrawLine(GuiPoint(GlyphRect.Left + 8, GlyphRect.Top + 6),
            GuiPoint(GlyphRect.Left + 4, GlyphRect.Top + 10), 2, GuiResolveTextColor(Style, States));
        end;
      end;

      DrawControlText(ACanvas, Node.Text, GuiInflateRect(ItemRect, GuiBoxLTRB(22 + (Node.Level * 16), 2, 8, 2)),
        GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
      finally
        ACanvas.PopClipRect;
      end;
    end;
  finally
    ACanvas.PopClipRect;
  end;

  if MaxScrollY > 0 then
  begin
    BarRect:=GetScrollBarRect;
    ThumbRect:=GetScrollThumbRect;
    PaintScrollBar(ACanvas, BarRect, ThumbRect, goVertical, FDraggingScrollBar, True);
  end;

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

procedure TGuiTreeView.HandleEvent(var AEvent: TGuiEvent);
var
  Index: Integer;
  I: Integer;
  Node: TGuiTreeNode;
  ClickRect: TGuiRect;
  ParentLevel: Integer;
begin
  inherited HandleEvent(AEvent);
  if AEvent.Kind = gekCancel then FDraggingScrollBar:=False;

  case AEvent.Kind of
    gekMouseDown:
    begin
      if (MaxScrollY > 0) AND GuiRectContains(GetScrollBarRect, AEvent.Position) then
      begin
        if NOT GuiRectContains(GetScrollThumbRect, AEvent.Position) then
          SetScrollY(FScrollY + ScrollFromThumbDelta(AEvent.Position.Y - (GetScrollThumbRect.Top + (GetScrollThumbRect.Height / 2))));

        FDraggingScrollBar:=True;
        FDragStartY:=AEvent.Position.Y;
        FDragStartScrollY:=FScrollY;
        AEvent.Handled:=True;
      end else
      begin
        Index:=NodeIndexAtPoint(AEvent.Position);
        if Index >= 0 then
        begin
          Node:=TGuiTreeNode(FNodes[Index]);
          ClickRect:=GetContentRect;
          ClickRect:=GuiRect(ClickRect.Left + 4 + (Node.Level * 16), ClickRect.Top, 16, ClickRect.Height);

          if NodeHasChildren(Index) AND GuiRectContains(ClickRect, AEvent.Position) then
          begin
            Node.Expanded:=NOT Node.Expanded;
            SetScrollY(FScrollY);
          end else
            SelectedIndex:=Index;

          AEvent.Handled:=True;
        end;
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

    gekMouseWheel:
    begin
      SetScrollY(FScrollY - (AEvent.Delta.Y * FItemHeight * 3));
      AEvent.Handled:=True;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        $40000052:
        begin
          for I:=FSelectedIndex - 1 downto 0 do
          begin
            if IsNodeVisible(I) then
            begin
              SelectedIndex:=I;
              Break;
            end;
          end;

          AEvent.Handled:=True;
        end;

        $40000051:
        begin
          for I:=FSelectedIndex + 1 to FNodes.Count - 1 do
          begin
            if IsNodeVisible(I) then
            begin
              SelectedIndex:=I;
              Break;
            end;
          end;

          AEvent.Handled:=True;
        end;

        $4000004F:
        begin
          if (FSelectedIndex >= 0) AND NodeHasChildren(FSelectedIndex) then
          begin
            Node:=TGuiTreeNode(FNodes[FSelectedIndex]);
            if NOT Node.Expanded then
              Node.Expanded:=True;
          end;

          AEvent.Handled:=True;
        end;

        $40000050:
        begin
          if FSelectedIndex >= 0 then
          begin
            Node:=TGuiTreeNode(FNodes[FSelectedIndex]);
            if NodeHasChildren(FSelectedIndex) AND Node.Expanded then
            begin
              Node.Expanded:=False;
              SetScrollY(FScrollY);
            end else
            begin
              ParentLevel:=Node.Level - 1;
              for I:=FSelectedIndex - 1 downto 0 do
              begin
                Node:=TGuiTreeNode(FNodes[I]);
                if Node.Level = ParentLevel then
                begin
                  SelectedIndex:=I;
                  Break;
                end;
              end;
            end;
          end;

          AEvent.Handled:=True;
        end;
      end;
    end;
  end;
end;

constructor TGuiHeaderControl.Create;
begin
  inherited Create;
  FResizingColumn:=-1;
  FColumnsResizable:=True;
  FCaptions:=TStringList.Create;
  FColumnWidths:=TList.Create;
  FHoveredIndex:=-1;
  Padding:=GuiBox(0);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
end;

destructor TGuiHeaderControl.Destroy;
begin
  FColumnWidths.Free;
  FCaptions.Free;
  inherited Destroy;
end;

function TGuiHeaderControl.AddColumn(const ACaption: String; AWidth: TGuiFloat): Integer;
begin
  Result:=FCaptions.Add(ACaption);
  FColumnWidths.Add(Pointer(NativeInt(Round(AWidth))));
  InvalidateLayout;
end;

procedure TGuiHeaderControl.ClearColumns;
begin
  FResizingColumn:=-1;
  FCaptions.Clear;
  FColumnWidths.Clear;
  FHoveredIndex:=-1;
  InvalidateLayout;
end;

function TGuiHeaderControl.GetColumnCount: Integer;
begin
  Result:=FCaptions.Count;
end;

function TGuiHeaderControl.GetColumnCaption(AIndex: Integer): String;
begin
  Result:=FCaptions[AIndex];
end;

function TGuiHeaderControl.GetColumnWidth(AIndex: Integer): TGuiFloat;
begin
  Result:=NativeInt(FColumnWidths[AIndex]);
end;

function TGuiHeaderControl.ColumnIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  I: Integer;
  Rect: TGuiRect;
  ColumnLeft: TGuiFloat;
  Width: TGuiFloat;
begin
  Result:=-1;
  Rect:=AbsoluteBounds;

  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  ColumnLeft:=Rect.Left;
  for I:=0 to FCaptions.Count - 1 do
  begin
    Width:=GetColumnWidth(I);
    if (APoint.X >= ColumnLeft) AND (APoint.X < ColumnLeft + Width) then
    begin
      Result:=I;
      Exit;
    end;

    ColumnLeft:=ColumnLeft + Width;
  end;
end;

procedure TGuiHeaderControl.SetColumnWidth(AIndex: Integer; AValue: TGuiFloat);
begin
  if (AIndex < 0) OR (AIndex >= FColumnWidths.Count) then Exit;
  FColumnWidths[AIndex]:=Pointer(NativeInt(Round(Max(32, AValue))));
  InvalidateLayout;
end;

function TGuiHeaderControl.ResizeColumnAtPoint(const APoint: TGuiPoint): Integer;
var
  I: Integer;
  Edge: TGuiFloat;
  Rect: TGuiRect;
begin
  Result:=-1;
  if NOT FColumnsResizable then Exit;
  Rect:=AbsoluteBounds;

  if NOT GuiRectContains(Rect, APoint) then Exit;
  Edge:=Rect.Left;
  for I:=0 to ColumnCount - 1 do
  begin
    Edge:=Edge + GetColumnWidth(I);
    if (Edge < Rect.Left + Rect.Width - 1) AND (Abs(APoint.X - Edge) <= 4) then
    begin
      Result:=I;
      Exit;
    end;
  end;
end;

function TGuiHeaderControl.HandleColumnResize(var AEvent: TGuiEvent): Boolean;
var
  Index, I: Integer;
  Limit, Width: TGuiFloat;
begin
  Result:=False;
  if (AEvent.Kind = gekCancel) OR (NOT FColumnsResizable) then
    FResizingColumn:=-1;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) then
  begin
    Index:=ResizeColumnAtPoint(AEvent.Position);
    if Index >= 0 then
    begin
      FResizingColumn:=Index;
      FResizeStartX:=AEvent.Position.X;
      FResizeStartWidth:=GetColumnWidth(Index);
      Result:=True;
    end;
  end
  else if (AEvent.Kind = gekMouseMove) AND (FResizingColumn >= 0) then
  begin
    if FResizingColumn >= ColumnCount then
    begin
      FResizingColumn:=-1;
      Exit;
    end;
    Width:=FResizeStartWidth + AEvent.Position.X - FResizeStartX;
    Limit:=Bounds.Width - 2;
    for I:=0 to FResizingColumn - 1 do Limit:=Limit - GetColumnWidth(I);

    SetColumnWidth(FResizingColumn, Min(Width, Max(32, Limit)));
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND
    (FResizingColumn >= 0) then
  begin
    FResizingColumn:=-1;
    Result:=True;
  end;
  if Result then AEvent.Handled:=True;
end;

procedure TGuiHeaderControl.PaintSelf(ACanvas: TGuiCanvas);
var
  I: Integer;
  Rect: TGuiRect;
  ColumnRect: TGuiRect;
  ColumnLeft: TGuiFloat;
  States: TGuiControlVisualStates;
begin
  Rect:=AbsoluteBounds;
  ACanvas.FillRect(Rect, Style.BackgroundColor);
  DrawControlBorder(ACanvas, Rect, Style.BorderColor);

  ACanvas.PushClipRect(Rect);
  try
  ColumnLeft:=Rect.Left;
  for I:=0 to FCaptions.Count - 1 do
  begin
    States:=[gcvsNormal];
    if I = FHoveredIndex then
      Include(States, gcvsHovered);

    if NOT Enabled then
      Include(States, gcvsDisabled);

    ColumnRect:=GuiRect(ColumnLeft, Rect.Top, GetColumnWidth(I), Rect.Height);
    ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), ColumnRect, Style.CornerRadius);
    ACanvas.FillRect(GuiRect(ColumnRect.Left + ColumnRect.Width - 1, ColumnRect.Top, 1, ColumnRect.Height), Style.BorderColor);
    if (I = FResizingColumn) OR
      (Assigned(Context) AND (Context.HoveredControl = Self) AND
       (I = ResizeColumnAtPoint(Context.MousePosition))) then
      ACanvas.FillRect(GuiRect(ColumnRect.Left + ColumnRect.Width - 2, ColumnRect.Top + 2,
        2, Max(0, ColumnRect.Height - 4)), Style.ScrollPressedColor);
    ACanvas.PushClipRect(GuiInflateRect(ColumnRect, GuiBoxLTRB(1, 1, 1, 1)));
    try
      DrawControlText(ACanvas, FCaptions[I], GuiInflateRect(ColumnRect, GuiBoxLTRB(8, 2, 8, 2)), GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
    finally
      ACanvas.PopClipRect;
    end;
    ColumnLeft:=ColumnLeft + ColumnRect.Width;
  end;
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiHeaderControl.HandleEvent(var AEvent: TGuiEvent);
begin
  inherited HandleEvent(AEvent);
  if HandleColumnResize(AEvent) then Exit;

  case AEvent.Kind of
    gekMouseLeave:
    begin
      FHoveredIndex:=-1;
    end;

    gekMouseMove:
    begin
      FHoveredIndex:=ColumnIndexAtPoint(AEvent.Position);
    end;
  end;
end;

constructor TGuiListView.Create;
begin
  inherited Create;
  FSelectedRows:=TList.Create;
  FColumnSortKinds:=TList.Create;
  FSortColumn:=-1;
  FHeaderColumn:=-1;
  FPressedColumn:=-1;
  FSortOnHeaderClick:=True;
  FResizingColumn:=-1;
  FColumnsResizable:=True;
  FColumns:=TStringList.Create;
  FColumnWidths:=TList.Create;
  FRows:=TList.Create;
  FSelectedIndex:=-1;
  FRowHeight:=28;
  FHeaderHeight:=30;
  FScrollY:=0;
  FDraggingScrollBar:=False;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBox(4);
  BackgroundColor:=GuiColor(31, 37, 46);
  BorderColor:=GuiColor(78, 92, 112);
end;

destructor TGuiListView.Destroy;
begin
  ClearRows;
  FSelectedRows.Free;
  FColumnSortKinds.Free;
  FRows.Free;
  FColumnWidths.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TGuiListView.AddColumn(const ACaption: String; AWidth: TGuiFloat): Integer;
begin
  Result:=FColumns.Add(ACaption);
  FColumnWidths.Add(Pointer(NativeInt(Round(AWidth))));
  FColumnSortKinds.Add(nil);
  if FHeaderColumn < 0 then FHeaderColumn:=0;
  InvalidateLayout;
end;

function TGuiListView.AddRow(const AValues: array of String): Integer;
var
  I: Integer;
  Row: TStringList;
begin
  Row:=TStringList.Create;
  for I:=Low(AValues) to High(AValues) do
    Row.Add(AValues[I]);

  Result:=FRows.Add(Row);
  if FSelectedIndex < 0 then
  begin
    FSelectedIndex:=0;
    FSelectedRows.Add(FRows[0]);
    FSelectionAnchor:=TStringList(FRows[0]);
  end;
  if FSortColumn >= 0 then SortByColumn(FSortColumn, FSortDirection);
  Result:=FRows.IndexOf(Row);

  InvalidateLayout;
end;

procedure TGuiListView.ClearRows;
var
  I: Integer;
begin
  FSelectedRows.Clear;
  FSelectionAnchor:=nil;
  for I:=FRows.Count - 1 downto 0 do
    TObject(FRows[I]).Free;

  FRows.Clear;
  FSelectedIndex:=-1;
  SetScrollY(0);
  InvalidateLayout;
end;

procedure TGuiListView.ClearColumns;
begin
  FColumnSortKinds.Clear;
  FSortColumn:=-1;
  FHeaderColumn:=-1;
  FPressedColumn:=-1;
  FResizingColumn:=-1;
  FColumns.Clear;
  FColumnWidths.Clear;
  InvalidateLayout;
end;

function TGuiListView.GetColumnCount: Integer;
begin
  Result:=FColumns.Count;
end;

function TGuiListView.GetRowCount: Integer;
begin
  Result:=FRows.Count;
end;

function TGuiListView.GetColumnWidth(AIndex: Integer): TGuiFloat;
begin
  Result:=NativeInt(FColumnWidths[AIndex]);
end;

procedure TGuiListView.SetSelectedIndex(AValue: Integer);
begin
  SelectIndex(AValue, False, False, False);
end;

procedure TGuiListView.EnsureSelectionVisible;
var R: TGuiRect;
Y: TGuiFloat;
begin
  if FSelectedIndex < 0 then Exit;
  R:=GetRowsRect;
  Y:=FSelectedIndex * FRowHeight;
  if Y < FScrollY then SetScrollY(Y)
  else if Y + FRowHeight > FScrollY + R.Height then
    SetScrollY(Y + FRowHeight - R.Height);
end;

procedure TGuiListView.SelectIndex(AIndex: Integer; AExtend, AToggle, AKeep: Boolean);
var I, Anchor, OldIndex: Integer;
Old: TGuiIndexArray;
Changed: Boolean;
begin
  AIndex:=Max(-1, Min(AIndex, FRows.Count - 1));
  OldIndex:=FSelectedIndex;
  Old:=SelectedIndices;
  FSelectedIndex:=AIndex;
  if NOT FMultiSelect then
  begin
    AExtend:=False;
    AToggle:=False;
    AKeep:=False;
  end;
  if AIndex < 0 then
  begin
    FSelectedRows.Clear;
    FSelectionAnchor:=nil;
  end
  else if NOT AKeep then
  begin
    if AExtend then
    begin
      Anchor:=FRows.IndexOf(FSelectionAnchor);
      if Anchor < 0 then Anchor:=Max(0, OldIndex);
      FSelectionAnchor:=TStringList(FRows[Anchor]);
      if NOT AToggle then FSelectedRows.Clear;
      for I:=Min(Anchor, AIndex) to Max(Anchor, AIndex) do
        if FSelectedRows.IndexOf(FRows[I]) < 0 then FSelectedRows.Add(FRows[I]);
    end else
    begin
      if AToggle then
      begin
        I:=FSelectedRows.IndexOf(FRows[AIndex]);
        if I >= 0 then FSelectedRows.Delete(I) else FSelectedRows.Add(FRows[AIndex]);
      end else
      begin
        FSelectedRows.Clear;
        FSelectedRows.Add(FRows[AIndex]);
      end;
      FSelectionAnchor:=TStringList(FRows[AIndex]);
    end;
  end;
  EnsureSelectionVisible;
  Changed:=(OldIndex <> FSelectedIndex) OR (Length(Old) <> FSelectedRows.Count);
  if NOT Changed then
    for I:=0 to High(Old) do
      if NOT GetRowSelected(Old[I]) then
      begin
        Changed:=True;
        Break;
      end;
  if Changed AND Assigned(FOnSelect) then FOnSelect(Self);
end;

function TGuiListView.GetRowSelected(AIndex: Integer): Boolean;
begin
  Result:=False;
  if (AIndex >= 0) AND (AIndex < FRows.Count) then
    Result:=FSelectedRows.IndexOf(FRows[AIndex]) >= 0;
end;

procedure TGuiListView.SetRowSelected(AIndex: Integer; AValue: Boolean);
begin
  if (AIndex < 0) OR (AIndex >= FRows.Count) then Exit;
  if GetRowSelected(AIndex) = AValue then Exit;
  if FMultiSelect then SelectIndex(AIndex, False, True, False)
  else if AValue then SelectedIndex:=AIndex else ClearSelection;
end;

function TGuiListView.GetSelectedCount: Integer;
begin
  Result:=FSelectedRows.Count;
end;

function TGuiListView.SelectedIndices: TGuiIndexArray;
var I, N: Integer;
begin
  Result:=nil;
  SetLength(Result, FSelectedRows.Count);
  N:=0;
  for I:=0 to FRows.Count - 1 do
    if GetRowSelected(I) then
    begin
      Result[N]:=I;
      Inc(N);
    end;
end;

procedure TGuiListView.SetMultiSelect(AValue: Boolean);
begin
  if FMultiSelect = AValue then Exit;
  FMultiSelect:=AValue;
  if NOT AValue then SelectedIndex:=FSelectedIndex;
end;

procedure TGuiListView.ClearSelection;
begin
  SelectedIndex:=-1;
end;

procedure TGuiListView.SelectAll;
begin
  if NOT FMultiSelect then
  begin
    if (FSelectedIndex < 0) AND (FRows.Count > 0) then SelectedIndex:=0;
    Exit;
  end;
  if FRows.Count = 0 then Exit;
  FSelectionAnchor:=TStringList(FRows[0]);
  SelectIndex(FRows.Count - 1, True, False, False);
end;

function TGuiListView.GetCellText(ARow, AColumn: Integer): String;
begin
  Result:='';
  if (ARow < 0) OR (ARow >= FRows.Count) OR (AColumn < 0) then Exit;
  if AColumn < TStringList(FRows[ARow]).Count then Result:=TStringList(FRows[ARow])[AColumn];
end;

procedure TGuiListView.SetCellText(ARow, AColumn: Integer; const AValue: String);
var Row: TStringList;
begin
  if (ARow < 0) OR (ARow >= FRows.Count) OR (AColumn < 0) OR (AColumn >= ColumnCount) then Exit;
  Row:=TStringList(FRows[ARow]);
  while Row.Count <= AColumn do Row.Add('');
  Row[AColumn]:=AValue;
  if FSortColumn = AColumn then SortByColumn(FSortColumn, FSortDirection);
end;

function TGuiListView.GetColumnSortKind(AColumn: Integer): TGuiColumnSortKind;
begin
  Result:=gcskText;
  if (AColumn >= 0) AND (AColumn < FColumnSortKinds.Count) then
    Result:=TGuiColumnSortKind(NativeInt(FColumnSortKinds[AColumn]));
end;

procedure TGuiListView.SetColumnSortKind(AColumn: Integer; AValue: TGuiColumnSortKind);
begin
  if (AColumn < 0) OR (AColumn >= FColumnSortKinds.Count) then Exit;
  FColumnSortKinds[AColumn]:=Pointer(NativeInt(Ord(AValue)));
  if FSortColumn = AColumn then SortByColumn(AColumn, FSortDirection);
end;

procedure TGuiListView.SortByColumn(AColumn: Integer; ADirection: TGuiSortDirection);
var Rows, Temp: array of Pointer;
FocusRow: Pointer;
I: Integer;
  function Compare(L, R: TStringList): Integer;
  var LS, RS: String;
  LN, RN: Extended;
  LC, RC: Integer;
  begin
    LS:='';
    RS:='';
    if AColumn < L.Count then LS:=L[AColumn];
    if AColumn < R.Count then RS:=R[AColumn];
    Result:=CompareText(LS, RS);
    if GetColumnSortKind(AColumn) = gcskNumber then
    begin
      Val(Trim(LS), LN, LC);
      Val(Trim(RS), RN, RC);
      if (LC = 0) AND (RC = 0) then
      begin
        Result:=0;
        if LN < RN then Result:=-1 else if LN > RN then Result:=1;
      end
      else if LC = 0 then Result:=-1 else if RC = 0 then Result:=1;
    end;
    if Assigned(FOnCompareRows) then FOnCompareRows(Self, L, R, AColumn, Result);
    if Result < 0 then Result:=-1 else if Result > 0 then Result:=1;
    if ADirection = gsdDescending then Result:=-Result;
  end;
  procedure MergeSort(Lo, Hi: Integer);
  var Mid, L, R, K: Integer;
  begin
    if Lo >= Hi then Exit;
    Mid:=Lo + (Hi - Lo) DIV 2;
    MergeSort(Lo, Mid);
    MergeSort(Mid + 1, Hi);
    L:=Lo;
    R:=Mid + 1;
    for K:=Lo to Hi do
    begin
      if L > Mid then
      begin
        Temp[K]:=Rows[R];
        Inc(R);
      end
      else if R > Hi then
      begin
        Temp[K]:=Rows[L];
        Inc(L);
      end
      else if Compare(TStringList(Rows[L]), TStringList(Rows[R])) <= 0 then
      begin
        Temp[K]:=Rows[L];
        Inc(L);
      end
      else
      begin
        Temp[K]:=Rows[R];
        Inc(R);
      end;
    end;
    for K:=Lo to Hi do Rows[K]:=Temp[K];
  end;
begin
  if (AColumn < 0) OR (AColumn >= ColumnCount) then Exit;
  FocusRow:=nil;
  if FSelectedIndex >= 0 then FocusRow:=FRows[FSelectedIndex];
  SetLength(Rows, FRows.Count);
  SetLength(Temp, FRows.Count);
  for I:=0 to FRows.Count - 1 do Rows[I]:=FRows[I];
  MergeSort(0, High(Rows));
  for I:=0 to High(Rows) do FRows[I]:=Rows[I];
  FSortColumn:=AColumn;
  FSortDirection:=ADirection;
  FHeaderColumn:=AColumn;
  FSelectedIndex:=FRows.IndexOf(FocusRow);
  EnsureSelectionVisible;
end;

function TGuiListView.HeaderIndexAtPoint(const APoint: TGuiPoint): Integer;
var R: TGuiRect;
I: Integer;
X, W: TGuiFloat;
begin
  Result:=-1;
  if FHeaderHeight <= 0 then Exit;
  R:=GetContentRect;
  if (APoint.Y < AbsoluteBounds.Top + 1) OR (APoint.Y >= R.Top + FHeaderHeight) then Exit;
  X:=R.Left;
  for I:=0 to ColumnCount - 1 do
  begin
    W:=GetColumnWidth(I);
    if I = ColumnCount - 1 then W:=AbsoluteBounds.Left + AbsoluteBounds.Width - 1 - X;
    if (APoint.X >= X) AND (APoint.X < Min(X + W, AbsoluteBounds.Left + AbsoluteBounds.Width - 1)) then
    begin
      Result:=I;
      Exit;
    end;
    X:=X + W;
  end;
end;

procedure TGuiListView.ActivateColumn(AColumn: Integer);
var Direction: TGuiSortDirection;
begin
  if (AColumn < 0) OR (AColumn >= ColumnCount) then Exit;
  FHeaderColumn:=AColumn;
  if FSortOnHeaderClick then
  begin
    Direction:=gsdAscending;
    if (FSortColumn = AColumn) AND (FSortDirection = gsdAscending) then Direction:=gsdDescending;
    SortByColumn(AColumn, Direction);
  end;
  if Assigned(FOnColumnClick) then FOnColumnClick(Self, AColumn);
end;

procedure TGuiListView.SetScrollY(AValue: TGuiFloat);
begin
  if AValue < 0 then
    AValue:=0;

  if AValue > MaxScrollY then
    AValue:=MaxScrollY;

  FScrollY:=AValue;
end;

function TGuiListView.GetMaxScrollY: TGuiFloat;
var
  Rect: TGuiRect;
begin
  Rect:=GuiInflateRect(Bounds, Padding);
  Rect.Height:=Max(0, Rect.Height - FHeaderHeight);
  Result:=(FRows.Count * FRowHeight) - Rect.Height;

  if Result < 0 then
    Result:=0;
end;

function TGuiListView.GetContentRect: TGuiRect;
begin
  Result:=ScrollContentRect(MaxScrollY > 0);
end;

function TGuiListView.GetRowsRect: TGuiRect;
begin
  Result:=GetContentRect;
  Result.Top:=Result.Top + FHeaderHeight;
  Result.Height:=Result.Height - FHeaderHeight;

  if Result.Height < 0 then
    Result.Height:=0;
end;

function TGuiListView.GetScrollBarRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(AbsoluteBounds, goVertical, Max(8, Style.ScrollBarSize), Max(4, Padding.Top + FHeaderHeight));
end;

function TGuiListView.GetScrollThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(GetScrollBarRect, GetRowsRect.Height, FRows.Count * FRowHeight, FScrollY);
end;

function TGuiListView.ScrollFromThumbDelta(ADeltaY: TGuiFloat): TGuiFloat;
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

function TGuiListView.RowIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
begin
  Result:=-1;
  Rect:=FullWidthRowRect(GetRowsRect);

  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  Result:=Trunc((APoint.Y - Rect.Top + FScrollY) / FRowHeight);
  if (Result < 0) OR (Result >= FRows.Count) then
    Result:=-1;
end;

procedure TGuiListView.SetColumnWidth(AIndex: Integer; AValue: TGuiFloat);
begin
  if (AIndex < 0) OR (AIndex >= FColumnWidths.Count) then Exit;
  FColumnWidths[AIndex]:=Pointer(NativeInt(Round(Max(32, AValue))));
  InvalidateLayout;
end;

function TGuiListView.ResizeColumnAtPoint(const APoint: TGuiPoint): Integer;
var
  I: Integer;
  Edge: TGuiFloat;
  Rect: TGuiRect;
begin
  Result:=-1;
  if NOT FColumnsResizable then Exit;
  Rect:=AbsoluteBounds;
  Rect.Height:=Max(0, Padding.Top + FHeaderHeight);
  if FHeaderHeight <= 0 then Exit;
  if NOT GuiRectContains(Rect, APoint) then Exit;
  Edge:=Rect.Left + Padding.Left;
  for I:=0 to ColumnCount - 2 do
  begin
    Edge:=Edge + GetColumnWidth(I);
    if (Edge < Rect.Left + Rect.Width - 1) AND (Abs(APoint.X - Edge) <= 4) then
    begin
      Result:=I;
      Exit;
    end;
  end;
end;

function TGuiListView.HandleColumnResize(var AEvent: TGuiEvent): Boolean;
var
  Index, I: Integer;
  Limit, Width: TGuiFloat;
begin
  Result:=False;
  if (AEvent.Kind = gekCancel) OR (NOT FColumnsResizable) then
    FResizingColumn:=-1;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) then
  begin
    Index:=ResizeColumnAtPoint(AEvent.Position);
    if Index >= 0 then
    begin
      FResizingColumn:=Index;
      FResizeStartX:=AEvent.Position.X;
      FResizeStartWidth:=GetColumnWidth(Index);
      Result:=True;
    end;
  end
  else if (AEvent.Kind = gekMouseMove) AND (FResizingColumn >= 0) then
  begin
    if FResizingColumn >= ColumnCount then
    begin
      FResizingColumn:=-1;
      Exit;
    end;
    Width:=FResizeStartWidth + AEvent.Position.X - FResizeStartX;
    Limit:=Bounds.Width - 2 - Padding.Left - 32;
    for I:=0 to FResizingColumn - 1 do Limit:=Limit - GetColumnWidth(I);
    for I:=FResizingColumn + 1 to ColumnCount - 2 do Limit:=Limit - GetColumnWidth(I);
    SetColumnWidth(FResizingColumn, Min(Width, Max(32, Limit)));
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND
    (FResizingColumn >= 0) then
  begin
    FResizingColumn:=-1;
    Result:=True;
  end;
  if Result then AEvent.Handled:=True;
end;

procedure TGuiListView.PaintSelf(ACanvas: TGuiCanvas);
var
  CaptionRect: TGuiRect;
  ArrowX, ArrowY, ArrowSign: TGuiFloat;
  I: Integer;
  Column: Integer;
  ColumnLeft: TGuiFloat;
  Rect: TGuiRect;
  HeaderRect, HeaderSurface: TGuiRect;
  HeaderRadius: TGuiFloat;
  ColumnRect: TGuiRect;
  RowsRect: TGuiRect;
  RowRect: TGuiRect;
  BarRect: TGuiRect;
  ThumbRect: TGuiRect;
  Row: TStringList;
  TextValue: String;
  States: TGuiControlVisualStates;
begin
  SetScrollY(FScrollY);
  States:=[gcvsNormal];
  if Focused then
    Include(States, gcvsFocused);

  if NOT Enabled then
    Include(States, gcvsDisabled);

  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), AbsoluteBounds, Style.CornerRadius);

  Rect:=GetContentRect;
  HeaderRect:=FullWidthRowRect(GuiRect(Rect.Left, Rect.Top, Rect.Width, FHeaderHeight));
  { Attach the header to the frame, not to the padded row viewport.
    Preserve its bottom edge so row and scrollbar geometry stay aligned. }
  HeaderRect.Top:=AbsoluteBounds.Top + 1;
  HeaderRect.Height:=Max(0, Rect.Top + FHeaderHeight - HeaderRect.Top);
  if FHeaderHeight <= 0 then HeaderRect.Height:=0;
  ACanvas.PushClipRect(HeaderRect);
  try
  HeaderRadius:=Max(0, Min(Style.CornerRadius,
    Min(AbsoluteBounds.Width, AbsoluteBounds.Height) / 2) - 1);
  HeaderSurface:=HeaderRect;
  { Clip off the lower rounding: the header shares only the frame's top corners. }
  HeaderSurface.Height:=HeaderSurface.Height + HeaderRadius * 2;
  ACanvas.DrawSurface(Style.HoverBackground, HeaderSurface, HeaderRadius);
  if HeaderRect.Height > 0 then
    ACanvas.FillRect(GuiRect(HeaderRect.Left, HeaderRect.Top + HeaderRect.Height - 1,
      HeaderRect.Width, 1), Style.BorderColor);

  ColumnLeft:=Rect.Left;
  for Column:=0 to FColumns.Count - 1 do
  begin
    ColumnRect:=GuiRect(ColumnLeft, HeaderRect.Top, GetColumnWidth(Column), HeaderRect.Height);
    if Column = FColumns.Count - 1 then
      ColumnRect.Width:=Max(0, HeaderRect.Left + HeaderRect.Width - ColumnLeft)
    else
      ColumnRect.Width:=Max(0, Min(ColumnRect.Width, HeaderRect.Left + HeaderRect.Width - ColumnLeft));
    if ColumnRect.Width <= 0 then Break;
    if (Column < FColumns.Count - 1) AND
      (ColumnRect.Left + ColumnRect.Width < HeaderRect.Left + HeaderRect.Width) then
      ACanvas.FillRect(GuiRect(ColumnRect.Left + ColumnRect.Width - 1, ColumnRect.Top, 1, ColumnRect.Height), Style.BorderColor);
    if (Column = FResizingColumn) OR
      (Assigned(Context) AND (Context.HoveredControl = Self) AND
       (Column = ResizeColumnAtPoint(Context.MousePosition))) then
      ACanvas.FillRect(GuiRect(ColumnRect.Left + ColumnRect.Width - 2, ColumnRect.Top + 2,
        2, Max(0, ColumnRect.Height - 4)), Style.ScrollPressedColor);
    ACanvas.PushClipRect(GuiInflateRect(ColumnRect, GuiBoxLTRB(1, 1, 1, 1)));
    try
      CaptionRect:=GuiInflateRect(ColumnRect, GuiBoxLTRB(8, 2, 8, 2));
      if Column = FSortColumn then
      begin
        CaptionRect.Width:=Max(0, CaptionRect.Width - 16);
        ArrowX:=ColumnRect.Left + ColumnRect.Width - 13;
        ArrowY:=ColumnRect.Top + ColumnRect.Height / 2;
        ArrowSign:=1;
        if FSortDirection = gsdDescending then ArrowSign:=-1;
        ACanvas.DrawLine(GuiPoint(ArrowX - 3, ArrowY + 2 * ArrowSign),
          GuiPoint(ArrowX, ArrowY - 2 * ArrowSign), 1.5, Style.TextColor);
        ACanvas.DrawLine(GuiPoint(ArrowX, ArrowY - 2 * ArrowSign),
          GuiPoint(ArrowX + 3, ArrowY + 2 * ArrowSign), 1.5, Style.TextColor);
      end;
      if Focused AND FocusVisible AND (Column = FHeaderColumn) then
        ACanvas.FillRect(GuiRect(ColumnRect.Left + 5, ColumnRect.Top + ColumnRect.Height - 3,
          Max(0, ColumnRect.Width - 10), 2), Style.ScrollPressedColor);
      DrawControlText(ACanvas, FColumns[Column], CaptionRect, Style.TextColor, ghtaLeft, gvtaCenter);
    finally
      ACanvas.PopClipRect;
    end;
    ColumnLeft:=ColumnLeft + ColumnRect.Width;
  end;

  finally
    ACanvas.PopClipRect;
  end;

  RowsRect:=GetRowsRect;
  ACanvas.PushClipRect(FullWidthRowRect(RowsRect));
  try
    for I:=0 to FRows.Count - 1 do
    begin
      RowRect:=GuiRect(RowsRect.Left, RowsRect.Top + (I * FRowHeight) - FScrollY, RowsRect.Width, FRowHeight);
      if (RowRect.Top + RowRect.Height < RowsRect.Top) OR (RowRect.Top > RowsRect.Top + RowsRect.Height) then
        Continue;

      PaintItemBackground(ACanvas, FullWidthRowRect(RowRect), GetRowSelected(I));
      if (I = FSelectedIndex) AND Focused AND FocusVisible then
        GuiPaintFocusIndicator(ACanvas, FullWidthRowRect(RowRect), Style);
      ACanvas.PushClipRect(RowsRect);
      try

      Row:=TStringList(FRows[I]);
      ColumnLeft:=RowsRect.Left;
      for Column:=0 to FColumns.Count - 1 do
      begin
        ColumnRect:=GuiRect(ColumnLeft, RowRect.Top, GetColumnWidth(Column), RowRect.Height);
        if Column = FColumns.Count - 1 then
          ColumnRect.Width:=Max(0, RowsRect.Left + RowsRect.Width - ColumnLeft)
        else
          ACanvas.FillRect(GuiRect(ColumnRect.Left + ColumnRect.Width - 1, ColumnRect.Top, 1, ColumnRect.Height), Style.BorderColor);
        TextValue:='';
        if Column < Row.Count then
          TextValue:=Row[Column];

        ACanvas.PushClipRect(GuiInflateRect(ColumnRect, GuiBoxLTRB(1, 1, 1, 1)));
        try
          DrawControlText(ACanvas, TextValue, GuiInflateRect(ColumnRect, GuiBoxLTRB(8, 2, 8, 2)), GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
        finally
          ACanvas.PopClipRect;
        end;
        ColumnLeft:=ColumnLeft + ColumnRect.Width;
      end;
      finally
        ACanvas.PopClipRect;
      end;
    end;
  finally
    ACanvas.PopClipRect;
  end;

  if MaxScrollY > 0 then
  begin
    BarRect:=GetScrollBarRect;
    ThumbRect:=GetScrollThumbRect;
    PaintScrollBar(ACanvas, BarRect, ThumbRect, goVertical, FDraggingScrollBar, True);
  end;

  DrawControlBorder(ACanvas, AbsoluteBounds, GuiResolveBorderColor(Style, States));

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, AbsoluteBounds, Style);
end;

procedure TGuiListView.HandleEvent(var AEvent: TGuiEvent);
var
  Index, Step: Integer;
  PreviousScroll: TGuiFloat;
begin
  inherited HandleEvent(AEvent);
  if HandleColumnResize(AEvent) then Exit;
  if AEvent.Kind = gekCancel then
  begin
    FDraggingScrollBar:=False;
    FPressedColumn:=-1;
  end;

  case AEvent.Kind of
    gekMouseDown:
    begin
      if AEvent.Button <> gmbLeft then Exit;
      FPressedColumn:=HeaderIndexAtPoint(AEvent.Position);
      if FPressedColumn >= 0 then
      begin
        AEvent.Handled:=True;
        Exit;
      end;
      if (MaxScrollY > 0) AND GuiRectContains(GetScrollBarRect, AEvent.Position) then
      begin
        if NOT GuiRectContains(GetScrollThumbRect, AEvent.Position) then
          SetScrollY(FScrollY + ScrollFromThumbDelta(AEvent.Position.Y - (GetScrollThumbRect.Top + (GetScrollThumbRect.Height / 2))));

        FDraggingScrollBar:=True;
        FDragStartY:=AEvent.Position.Y;
        FDragStartScrollY:=FScrollY;
        AEvent.Handled:=True;
      end else
      begin
        Index:=RowIndexAtPoint(AEvent.Position);
        if Index >= 0 then
        begin
          SelectIndex(Index, gemShift IN AEvent.Modifiers, gemCtrl IN AEvent.Modifiers, False);
          AEvent.Handled:=True;
        end;
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
      if AEvent.Button <> gmbLeft then Exit;
      if FPressedColumn >= 0 then
      begin
        Index:=FPressedColumn;
        FPressedColumn:=-1;
        AEvent.Handled:=True;
        if HeaderIndexAtPoint(AEvent.Position) = Index then ActivateColumn(Index);
        Exit;
      end;
      if FDraggingScrollBar then
      begin
        FDraggingScrollBar:=False;
        AEvent.Handled:=True;
      end;
    end;

    gekMouseWheel:
    begin
      PreviousScroll:=FScrollY;
      SetScrollY(FScrollY - (AEvent.Delta.Y * FRowHeight * 3));
      AEvent.Handled:=PreviousScroll <> FScrollY;
    end;

    gekKeyDown:
    begin
      if gemAlt IN AEvent.Modifiers then
      begin
        case AEvent.KeyCode of
          $40000050: FHeaderColumn:=Max(0, FHeaderColumn - 1);
          $4000004F: FHeaderColumn:=Min(ColumnCount - 1, FHeaderColumn + 1);
          $40000052: SortByColumn(FHeaderColumn, gsdAscending);
          $40000051: SortByColumn(FHeaderColumn, gsdDescending);
          13: ActivateColumn(FHeaderColumn);
        else Exit;
        end;
        AEvent.Handled:=True;
        Exit;
      end;
      if (gemCtrl IN AEvent.Modifiers) AND (AEvent.KeyCode IN [65, 97]) AND FMultiSelect then
      begin
        AEvent.Handled:=True;
        SelectAll;
        Exit;
      end;
      Index:=FSelectedIndex;
      Step:=Max(1, Floor(GetRowsRect.Height / Max(1, FRowHeight)));
      case AEvent.KeyCode of
        $40000052: Index:=Max(0, Index - 1);
        $40000051: Index:=Min(FRows.Count - 1, Index + 1);
        $4000004A: Index:=0;
        $4000004D: Index:=FRows.Count - 1;
        $4000004B: Index:=Max(0, Index - Step);
        $4000004E: Index:=Min(FRows.Count - 1, Index + Step);
        32: ;
      else Exit;
      end;
      AEvent.Handled:=True;
      SelectIndex(Index, gemShift IN AEvent.Modifiers,
        (gemCtrl IN AEvent.Modifiers) AND
          ((AEvent.KeyCode = 32) OR (gemShift IN AEvent.Modifiers)),
        (gemCtrl IN AEvent.Modifiers) AND NOT (gemShift IN AEvent.Modifiers) AND
          (AEvent.KeyCode <> 32));
    end;
  end;
end;

constructor TGuiItemTemplate.Create;
begin
  inherited Create;
  Title:='';
  Subtitle:='';
  DetailText:='';
  Icon:=GuiEmptyDrawable;
  ShowSwatch:=False;
  SwatchColor:=GuiColor(118, 214, 180);
  Selected:=False;
  Padding:=GuiBoxLTRB(8, 6, 8, 6);
end;

procedure TGuiItemTemplate.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  ContentRect: TGuiRect;
  IconRect: TGuiRect;
  TextLeft: TGuiFloat;
  States: TGuiControlVisualStates;
begin
  States:=[gcvsNormal];
  if Hovered then
    Include(States, gcvsHovered);
  if Pressed then
    Include(States, gcvsPressed);
  if Selected then
    Include(States, gcvsChecked);
  if NOT Enabled then
    Include(States, gcvsDisabled);

  Rect:=AbsoluteBounds;
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));

  ContentRect:=GuiInflateRect(Rect, Padding);
  TextLeft:=ContentRect.Left;

  if ShowSwatch then
  begin
    ACanvas.FillRect(GuiRect(ContentRect.Left, ContentRect.Top + 4, 14, 14), SwatchColor);
    TextLeft:=TextLeft + 22;
  end else
  if Icon.Kind <> gdkNone then
  begin
    IconRect:=GuiRect(ContentRect.Left, ContentRect.Top + ((ContentRect.Height - 28) / 2), 28, 28);
    ACanvas.DrawDrawable(Icon, IconRect);
    TextLeft:=TextLeft + 36;
  end;

  DrawControlText(ACanvas, Title, GuiRect(TextLeft, ContentRect.Top, ContentRect.Width - (TextLeft - ContentRect.Left) - 78, 20),
    GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);

  if Subtitle <> '' then
    DrawControlText(ACanvas, Subtitle, GuiRect(TextLeft, ContentRect.Top + 20, ContentRect.Width - (TextLeft - ContentRect.Left) - 78, 18),
      Style.DisabledTextColor, ghtaLeft, gvtaCenter);

  if DetailText <> '' then
    DrawControlText(ACanvas, DetailText, GuiRect(ContentRect.Left + ContentRect.Width - 76, ContentRect.Top, 76, ContentRect.Height),
      GuiResolveTextColor(Style, States), ghtaRight, gvtaCenter);
end;

constructor TGuiCheckListBox.Create;
begin
  inherited;
  FPendingItem:=-1;
  Bounds:=GuiRect(0,0,240,180);
end;

function TGuiCheckListBox.CreateItems: TStringList;
begin
  Result:=TGuiStateStrings.Create;
end;

procedure TGuiCheckListBox.ItemsChanged(Sender: TObject);
begin
  Inc(FItemRevision);
  FPendingItem:=-1;
  inherited;
end;

function TGuiCheckListBox.GetState(AIndex: Integer): TGuiCheckBoxState;
begin
  Result:=TGuiCheckBoxState(TGuiStateStrings(Items).ItemState[AIndex] AND 3);
end;

procedure TGuiCheckListBox.SetState(AIndex: Integer; AValue: TGuiCheckBoxState);
var Flags: Integer;
begin
  if (Ord(AValue)<0) OR (Ord(AValue)>Ord(gcbGrayed)) then raise EArgumentException.Create('Invalid row check state');
  Flags:=TGuiStateStrings(Items).ItemState[AIndex];
  if (Flags AND 3)=Ord(AValue) then Exit;
  TGuiStateStrings(Items).ItemState[AIndex]:=(Flags AND NOT 3) OR Ord(AValue);
  if Assigned(FOnCheck) then FOnCheck(Self,AIndex);
end;

function TGuiCheckListBox.GetChecked(AIndex: Integer): Boolean;
begin
  Result:=State[AIndex]=gcbChecked;
end;

procedure TGuiCheckListBox.SetChecked(AIndex: Integer; AValue: Boolean);
begin
  if AValue then State[AIndex]:=gcbChecked else State[AIndex]:=gcbUnchecked;
end;

function TGuiCheckListBox.GetItemEnabled(AIndex: Integer): Boolean;
begin
  Result:=(TGuiStateStrings(Items).ItemState[AIndex] AND 4)=0;
end;

procedure TGuiCheckListBox.SetItemEnabled(AIndex: Integer; AValue: Boolean);
var Flags: Integer;
begin
  Flags:=TGuiStateStrings(Items).ItemState[AIndex];
  if AValue then Flags:=Flags AND NOT 4 else Flags:=Flags OR 4;
  TGuiStateStrings(Items).ItemState[AIndex]:=Flags;
end;

function TGuiCheckListBox.NextCheckState(AIndex: Integer): TGuiCheckBoxState;
begin
  case State[AIndex] of
    gcbChecked: Result:=gcbUnchecked;
    gcbGrayed: Result:=gcbChecked;
    else if AllowGrayed then Result:=gcbGrayed else Result:=gcbChecked;
  end;
end;

procedure TGuiCheckListBox.ToggleCheck(AIndex: Integer);
begin
  if Enabled AND ItemEnabled[AIndex] then State[AIndex]:=NextCheckState(AIndex);
end;

function TGuiCheckListBox.IndicatorSize: TGuiSize;
begin
  Result:=GuiSize(18,18);
end;

procedure TGuiCheckListBox.PaintCheckIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect;
  AState: TGuiCheckBoxState; AEnabled: Boolean);
var Color: TGuiColor;
begin
  Color:=Style.BorderColor;
  if AState<>gcbUnchecked then Color:=Style.CheckedBorderColor;
  if NOT AEnabled then Color:=Style.DisabledTextColor;
  ACanvas.DrawRoundedBorder(ARect,Min(4,Style.CornerRadius),Max(1,Style.BorderWidth),Color);
  if AState=gcbChecked then ACanvas.DrawCheckMark(GuiInflateRect(ARect,GuiBox(4)),Color)
  else if AState=gcbGrayed then
    ACanvas.FillRoundedRect(GuiRect(ARect.Left+4,ARect.Top+8,10,2),1,Color);
end;

procedure TGuiCheckListBox.PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect);
var Size: TGuiSize;
R: TGuiRect;
Active: Boolean;
Color: TGuiColor;
begin
  Size:=IndicatorSize;
  Active:=Enabled AND ItemEnabled[AIndex];
  R:=GuiRect(ARect.Left+8,ARect.Top+(ARect.Height-Size.Height)/2,Size.Width,Size.Height);
  PaintCheckIndicator(ACanvas,R,State[AIndex],Active);
  Color:=Style.TextColor;
  if NOT Active then Color:=Style.DisabledTextColor;
  DrawControlText(ACanvas,Items[AIndex],GuiInflateRect(ARect,GuiBoxLTRB(Size.Width+16,2,8,2)),Color,ghtaLeft,gvtaCenter);
end;

procedure TGuiCheckListBox.HandleEvent(var AEvent: TGuiEvent);
var Index,Revision: Integer;
  Guard: TListEventGuard;
begin
  BeginListEvent(Guard);
  try
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur,gekKeyDown,gekMouseWheel]) then FPendingItem:=-1;
  if Enabled AND (AEvent.Kind=gekKeyDown) AND ((AEvent.KeyCode=32) OR (AEvent.KeyCode=13)) then
  begin
    FPendingItem:=-1;
    if SelectedIndex>=0 then ToggleCheck(SelectedIndex);
    AEvent.Handled:=True;
    Exit;
  end;
  if Enabled AND (AEvent.Kind=gekMouseDown) AND (AEvent.Button=gmbLeft) then
  begin
    Index:=ItemIndexAtPoint(AEvent.Position);
    Revision:=FItemRevision;
    FPendingItem:=-1;
    inherited;
    if NOT Guard.Alive then Exit;
    if NOT FDraggingScrollBar AND (Revision=FItemRevision) AND (Index>=0) then FPendingItem:=Index;
    Exit;
  end;
  if (AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft) then
  begin
    Index:=FPendingItem;
    Revision:=FItemRevision;
    FPendingItem:=-1;
    inherited;
    if NOT Guard.Alive then Exit;
    if Enabled AND (Revision=FItemRevision) AND (Index>=0) AND (Index<Items.Count) AND
      (ItemIndexAtPoint(AEvent.Position)=Index) AND
      NOT ((MaxScrollY>0) AND GuiRectContains(GetScrollBarRect,AEvent.Position)) then
    begin
      ToggleCheck(Index);
      AEvent.Handled:=True;
    end;
    Exit;
  end;
  inherited;
    if NOT Guard.Alive then Exit;
  finally
    if Guard.Alive then EndListEvent(Guard);
  end;
end;

constructor TGuiSwitchListBox.Create;
begin
  inherited;
  FSwitchItem:=-1;
  FPaintItem:=-1;
end;

procedure TGuiSwitchListBox.ItemsChanged(Sender: TObject);
begin
  FSwitchItem:=-1;
  FSwitchDragging:=False;
  inherited;
end;

function TGuiSwitchListBox.IndicatorSize: TGuiSize;
begin
  Result:=GuiSize(40,20);
end;

function TGuiSwitchListBox.NextCheckState(AIndex: Integer): TGuiCheckBoxState;
begin
  if Checked[AIndex] then Result:=gcbUnchecked else Result:=gcbChecked;
end;

function TGuiSwitchListBox.GetThumbPosition(AIndex: Integer): TGuiFloat;
begin
  if State[AIndex]=gcbGrayed then Result:=0.5 else Result:=Ord(Checked[AIndex]);
  if (AIndex=FSwitchItem) AND FSwitchDragging AND Enabled then Result:=FSwitchPosition;
end;

function TGuiSwitchListBox.ItemTrackRect(AIndex: Integer): TGuiRect;
var R: TGuiRect;
S: TGuiSize;
begin
  R:=GetContentRect;
  S:=IndicatorSize;
  Result:=GuiRect(R.Left+8,R.Top+AIndex*Max(1,ItemHeight)-ScrollY+
    (Max(1,ItemHeight)-S.Height)/2,S.Width,S.Height);
end;

procedure TGuiSwitchListBox.PaintItemContent(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect);
begin
  FPaintItem:=AIndex;
  try
    inherited;
  finally
    FPaintItem:=-1;
  end;
end;

procedure TGuiSwitchListBox.PaintCheckIndicator(ACanvas: TGuiCanvas; const ARect: TGuiRect;
  AState: TGuiCheckBoxState; AEnabled: Boolean);
var States: TGuiControlVisualStates;
Thumb: TGuiRect;
Diameter: TGuiFloat;
begin
  States:=[gcvsNormal];
  if AState<>gcbUnchecked then Include(States,gcvsChecked);
  if NOT AEnabled then Include(States,gcvsDisabled);
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style,States),ARect,ARect.Height/2);
  ACanvas.DrawRoundedBorder(ARect,ARect.Height/2,Max(1,Style.BorderWidth),GuiResolveBorderColor(Style,States));
  Diameter:=Max(0,ARect.Height-6);
  Thumb:=GuiRect(ARect.Left+3+GetThumbPosition(FPaintItem)*(ARect.Width-ARect.Height),
    ARect.Top+3,Diameter,Diameter);
  ACanvas.FillRoundedRect(Thumb,Diameter/2,GuiResolveTextColor(Style,States));
end;

procedure TGuiSwitchListBox.HandleEvent(var AEvent: TGuiEvent);
var Index,Revision: Integer;
Position: TGuiFloat;
R: TGuiRect;
  Guard: TListEventGuard;
begin
  BeginListEvent(Guard);
  try
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur,gekKeyDown,gekMouseWheel]) then
  begin
    FSwitchItem:=-1;
    FSwitchDragging:=False;
  end;
  if Enabled AND (AEvent.Kind=gekKeyDown) AND
    ((AEvent.KeyCode=$40000050) OR (AEvent.KeyCode=$4000004F)) then
  begin
    FPendingItem:=-1;
    if (SelectedIndex>=0) AND ItemEnabled[SelectedIndex] then Checked[SelectedIndex]:=AEvent.KeyCode=$4000004F;
    AEvent.Handled:=True;
    Exit;
  end;
  if (AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft) AND FSwitchDragging AND (FSwitchItem>=0) then
  begin
    Index:=FSwitchItem;
    Revision:=FItemRevision;
    R:=ItemTrackRect(Index);
    Position:=EnsureRange(FSwitchStartPosition+(AEvent.Position.X-FSwitchStartX)/Max(1,R.Width-R.Height),0,1);
    FPendingItem:=-1;
    FSwitchItem:=-1;
    FSwitchDragging:=False;
    inherited;
    if NOT Guard.Alive then Exit;
    if Enabled AND (Revision=FItemRevision) AND (Index<Items.Count) AND ItemEnabled[Index] then Checked[Index]:=Position>=0.5;
    AEvent.Handled:=True;
    Exit;
  end;
  inherited;
    if NOT Guard.Alive then Exit;
  if NOT Enabled then Exit;
  if (AEvent.Kind=gekMouseDown) AND (AEvent.Button=gmbLeft) then
  begin
    FSwitchItem:=-1;
    FSwitchDragging:=False;
    Index:=FPendingItem;
    if (Index>=0) AND ItemEnabled[Index] AND GuiRectContains(ItemTrackRect(Index),AEvent.Position) then
    begin
      FSwitchStartPosition:=GetThumbPosition(Index);
      FSwitchItem:=Index;
      FSwitchStartX:=AEvent.Position.X;
    end;
  end
  else if (AEvent.Kind=gekMouseMove) AND (FSwitchItem>=0) then
  begin
    if Abs(AEvent.Position.X-FSwitchStartX)>3 then FSwitchDragging:=True;
    if FSwitchDragging then
    begin
      R:=ItemTrackRect(FSwitchItem);
      FSwitchPosition:=EnsureRange(FSwitchStartPosition+(AEvent.Position.X-FSwitchStartX)/Max(1,R.Width-R.Height),0,1);
      AEvent.Handled:=True;
    end;
  end
  else if (AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft) then
  begin
    FSwitchItem:=-1;
    FSwitchDragging:=False;
  end;
  finally
    if Guard.Alive then EndListEvent(Guard);
  end;
end;

constructor TGuiWheelPicker.Create;
begin
  inherited;
  CanFocus:=True;
  TabStop:=True;
  Bounds:=GuiRect(0,0,160,180);
  Padding:=GuiBox(4);
  FFlickEnabled:=True;
  FDeceleration:=20;
  FSettleDuration:=150;
  FVisibleItemCount:=5;
  FItemIndex:=-1;
  FItems:=TStringList.Create;
  FItems.OnChange:=ItemsChanged;
end;

destructor TGuiWheelPicker.Destroy;
var Guard: PWheelEventGuard;
begin
  Guard:=FWheelEventGuard;
  while Guard<>nil do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  FItems.Free;
  inherited;
end;

function TGuiWheelPicker.AddItem(const AText: String): Integer;
begin
  Result:=FItems.Add(AText);
end;

procedure TGuiWheelPicker.CancelMotion;
begin
  Inc(FMotionRevision);
  FAnimating:=False;
  FVelocity:=0;
  FPointerDown:=False;
  FDragging:=False;
  Pressed:=False;
  FPosition:=Max(0,FItemIndex);
end;

function TGuiWheelPicker.AnimationTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

function TGuiWheelPicker.GetMoving: Boolean;
begin
  Result:=FDragging OR FAnimating;
end;

procedure TGuiWheelPicker.SetFlickEnabled(AValue: Boolean);
begin
  CancelMotion;
  FFlickEnabled:=AValue;
end;

procedure TGuiWheelPicker.SetDeceleration(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<=0) then
    raise EArgumentException.Create('Wheel deceleration must be finite and positive');
  CancelMotion;
  FDeceleration:=AValue;
end;

procedure TGuiWheelPicker.SetSettleDuration(AValue: Cardinal);
begin
  CancelMotion;
  FSettleDuration:=AValue;
end;

procedure TGuiWheelPicker.SampleVelocity(ADelta: Double);
var NowValue,Elapsed: UInt64;
begin
  NowValue:=AnimationTime;
  if NowValue<FSampleTime then FVelocity:=0
  else
  begin
    Elapsed:=NowValue-FSampleTime;
    if Elapsed>120 then FVelocity:=0
    else if (Elapsed>0) AND (ADelta<>0) then FVelocity:=EnsureRange(ADelta*1000/Elapsed,-60,60);
  end;
  if ADelta<>0 then FSampleTime:=NowValue;
end;

procedure TGuiWheelPicker.StartMotion;
begin
  if NOT FFlickEnabled OR (Abs(FVelocity)<0.2) then FVelocity:=0;
  FStartPosition:=FPosition;
  FStartVelocity:=FVelocity;
  FMotionStart:=AnimationTime;
  FAnimating:=(FStartVelocity<>0) OR (Abs(FPosition-Floor(FPosition+0.5))>0.0001);
  if FAnimating then UpdateMotion;
end;

procedure TGuiWheelPicker.UpdateMotion;
var Ancestor: TGuiControl;
NowValue: UInt64;
  Elapsed,StopTime,Time,Distance,NewPosition,StoppedPosition,Fraction,Direction: Double;
  Finished: Boolean;
begin
  if NOT FAnimating then Exit;
  Ancestor:=Self;
  while Assigned(Ancestor) do
  begin
    if NOT Ancestor.Enabled OR NOT Ancestor.Visible then
    begin
      CancelMotion;
      Exit;
    end;
    Ancestor:=Ancestor.Parent;
  end;
  if Assigned(Context) AND Assigned(Context.ModalControl) AND
    NOT Context.ControlContains(Context.ModalControl,Self) then
    begin
      CancelMotion;
      Exit;
    end;
  NowValue:=AnimationTime;
  if NowValue<FMotionStart then
  begin
    CancelMotion;
    Exit;
  end;
  Elapsed:=(NowValue-FMotionStart)/1000;
  StopTime:=Abs(FStartVelocity)/FDeceleration;
  Direction:=1;
  if FStartVelocity<0 then Direction:=-1;
  Time:=Min(Elapsed,StopTime);
  Distance:=Abs(FStartVelocity)*Time-FDeceleration*Time*Time/2;
  NewPosition:=FStartPosition+Direction*Distance;
  Finished:=False;
  if NOT Wrap AND ((NewPosition<0) OR (NewPosition>FItems.Count-1)) then Finished:=True
  else if Elapsed>=StopTime then
  begin
    StoppedPosition:=NewPosition;
    if FSettleDuration=0 then Fraction:=1 else Fraction:=Min(1,(Elapsed-StopTime)*1000/FSettleDuration);
    Finished:=Fraction>=1;
    { Ease-out settling is analytic, so frame rate does not alter the final row. }
    Fraction:=1-Sqr(1-Fraction)*(1-Fraction);
    NewPosition:=StoppedPosition+(Floor(StoppedPosition+0.5)-StoppedPosition)*Fraction;
  end;
  FAnimating:=NOT Finished;
  SetPosition(NewPosition,Finished);
end;

procedure TGuiWheelPicker.ItemsChanged(Sender: TObject);
var OldIndex: Integer;
begin
  OldIndex:=FItemIndex;
  if FItems.Count=0 then FItemIndex:=-1 else FItemIndex:=EnsureRange(FItemIndex,0,FItems.Count-1);
  CancelMotion;
  if (OldIndex<>FItemIndex) AND Assigned(FOnChange) then FOnChange(Self);
end;

procedure TGuiWheelPicker.SetItemIndex(AValue: Integer);
var OldIndex: Integer;
begin
  OldIndex:=FItemIndex;
  if FItems.Count=0 then FItemIndex:=-1 else FItemIndex:=EnsureRange(AValue,0,FItems.Count-1);
  CancelMotion;
  if (OldIndex<>FItemIndex) AND Assigned(FOnChange) then FOnChange(Self);
end;

procedure TGuiWheelPicker.SetVisibleItemCount(AValue: Integer);
begin
  if (AValue<1) OR (AValue>101) OR (AValue MOD 2=0) then
    raise EArgumentException.Create('Visible wheel item count must be odd and between 1 and 101');
  CancelMotion;
  FVisibleItemCount:=AValue;
end;

procedure TGuiWheelPicker.SetWrapMode(AValue: TGuiWheelWrapMode);
begin
  if (Ord(AValue)<Ord(Low(TGuiWheelWrapMode))) OR (Ord(AValue)>Ord(High(TGuiWheelWrapMode))) then
    raise EArgumentException.Create('Invalid wheel wrap mode');
  CancelMotion;
  FWrapMode:=AValue;
end;

procedure TGuiWheelPicker.SetWrap(AValue: Boolean);
begin
  if AValue then WrapMode:=gwwEnabled else WrapMode:=gwwDisabled;
end;

function TGuiWheelPicker.GetWrap: Boolean;
begin
  Result:=(FItems.Count>1) AND ((FWrapMode=gwwEnabled) OR
    ((FWrapMode=gwwAuto) AND (FItems.Count>FVisibleItemCount)));
end;

function TGuiWheelPicker.RowHeight: TGuiFloat;
begin
  Result:=Max(1,GuiInflateRect(AbsoluteBounds,Padding).Height/FVisibleItemCount);
end;

procedure TGuiWheelPicker.SetPosition(AValue: Double; ASettle: Boolean);
var OldIndex: Integer;
begin
  if FItems.Count=0 then Exit;
  if Wrap then
  begin
    AValue:=AValue-Int(AValue/FItems.Count)*FItems.Count;
    if AValue<0 then AValue:=AValue+FItems.Count;
  end
  else AValue:=EnsureRange(AValue,0,FItems.Count-1);
  OldIndex:=FItemIndex;
  FPosition:=AValue;
  FItemIndex:=Floor(AValue+0.5);
  if Wrap then FItemIndex:=FItemIndex MOD FItems.Count else FItemIndex:=Min(FItemIndex,FItems.Count-1);
  if ASettle then FPosition:=FItemIndex;
  if (OldIndex<>FItemIndex) AND Assigned(FOnChange) then FOnChange(Self);
end;

procedure TGuiWheelPicker.PaintWheelItem(ACanvas: TGuiCanvas; AIndex: Integer; const ARect: TGuiRect;
  ADisplacement: TGuiFloat);
var Color: TGuiColor;
Fade: TGuiFloat;
begin
  if Enabled then Color:=Style.TextColor else Color:=Style.DisabledTextColor;
  Fade:=Max(0.15,1-Abs(ADisplacement)/(FVisibleItemCount/2+0.5));
  Color.A:=Round(Color.A*Fade);
  DrawControlText(ACanvas,FItems[AIndex],GuiInflateRect(ARect,GuiBoxLTRB(6,0,6,0)),Color,ghtaCenter,gvtaCenter);
end;

procedure TGuiWheelPicker.PaintSelf(ACanvas: TGuiCanvas);
var R,Row: TGuiRect;
Height,Center,Displacement: TGuiFloat;
Base,Offset,Index: Integer;
begin
  R:=AbsoluteBounds;
  ACanvas.DrawSurface(Style.Background,R,Style.CornerRadius);
  DrawControlBorder(ACanvas,R,Style.BorderColor);
  R:=GuiInflateRect(R,Padding);
  Height:=RowHeight;
  Center:=R.Top+R.Height/2;
  ACanvas.PushClipRect(R);
  try
    if FItems.Count>0 then
    begin
      Row:=GuiRect(R.Left,Center-Height/2,R.Width,Height);
      PaintItemBackground(ACanvas,Row,True);
      Base:=Floor(FPosition);
      for Offset:=-(FVisibleItemCount DIV 2)-1 to FVisibleItemCount DIV 2+1 do
      begin
        Index:=Base+Offset;
        if Wrap then Index:=((Index MOD FItems.Count)+FItems.Count) MOD FItems.Count;
        if (Index<0) OR (Index>=FItems.Count) then Continue;
        Displacement:=Base+Offset-FPosition;
        Row:=GuiRect(R.Left,Center+(Displacement-0.5)*Height,R.Width,Height);
        if (Abs(Displacement)<(FVisibleItemCount+1)/2) AND
          (Row.Top+Row.Height>R.Top) AND (Row.Top<R.Top+R.Height) then
          PaintWheelItem(ACanvas,Index,Row,Displacement);
      end;
    end;
  finally
    ACanvas.PopClipRect;
  end;
  if Focused AND FocusVisible then GuiPaintFocusIndicator(ACanvas,AbsoluteBounds,Style);
end;

procedure TGuiWheelPicker.HandleEvent(var AEvent: TGuiEvent);
var NewPosition,Delta: Double;
OldIndex,Step,Revision: Integer;
R: TGuiRect;
WasDragging: Boolean;
  Guard: TWheelEventGuard;
begin
  Guard.Previous:=FWheelEventGuard;
  Guard.Alive:=True;
  FWheelEventGuard:=@Guard;
  try
  inherited;
  if NOT Guard.Alive then Exit;
  if NOT Enabled OR (AEvent.Kind IN [gekCancel,gekBlur]) then
  begin
    CancelMotion;
    Exit;
  end;
  if (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=27) then
  begin
    CancelMotion;
    AEvent.Handled:=True;
    Exit;
  end;
  if FItems.Count=0 then Exit;
  case AEvent.Kind of
    gekMouseDown:
      if AEvent.Button=gmbLeft then
      begin
        NewPosition:=FPosition;
        CancelMotion;
        FPosition:=NewPosition;
        FPointerDown:=True;
        Pressed:=True;
        FDownY:=AEvent.Position.Y;
        FLastY:=FDownY;
        FSampleTime:=AnimationTime;
        AEvent.Handled:=True;
        end;
    gekMouseMove:
      if FPointerDown then
      begin
        if Abs(AEvent.Position.Y-FDownY)>3 then FDragging:=True;
        if FDragging then
        begin
          Delta:=(FLastY-AEvent.Position.Y)/RowHeight;
          SampleVelocity(Delta);
          NewPosition:=FPosition+Delta;
          FLastY:=AEvent.Position.Y;
          AEvent.Handled:=True;
          SetPosition(NewPosition,False);
        end;
      end;
    gekMouseUp:
      if (AEvent.Button=gmbLeft) AND FPointerDown then
      begin
        NewPosition:=FPosition;
        WasDragging:=FDragging;
        if FDragging then
        begin
          Delta:=(FLastY-AEvent.Position.Y)/RowHeight;
          SampleVelocity(Delta);
          NewPosition:=NewPosition+Delta;
        end
        else
        begin
          if NOT GuiRectContains(AbsoluteBounds,AEvent.Position) then
          begin
            CancelMotion;
            Exit;
          end;
          R:=GuiInflateRect(AbsoluteBounds,Padding);
          NewPosition:=FItemIndex+Floor((AEvent.Position.Y-R.Top-R.Height/2)/RowHeight+0.5);
        end;
        FPointerDown:=False;
        FDragging:=False;
        Pressed:=False;
        AEvent.Handled:=True;
        Revision:=FMotionRevision;
        SetPosition(NewPosition,NOT WasDragging);
        if NOT Guard.Alive then Exit;
        if NOT Enabled then
        begin
          CancelMotion;
          Exit;
        end;
        if WasDragging AND (Revision=FMotionRevision) then StartMotion;
      end;
    gekKeyDown,gekMouseWheel:
      begin
        CancelMotion;
        OldIndex:=FItemIndex;
        Step:=0;
        if AEvent.Kind=gekMouseWheel then
        begin
          if AEvent.Delta.Y>0 then Step:=-1 else if AEvent.Delta.Y<0 then Step:=1;
        end
        else case AEvent.KeyCode of
          $40000052,$40000050: Step:=-1;
          $40000051,$4000004F: Step:=1;
          $4000004B: Step:=-FVisibleItemCount;
          $4000004E: Step:=FVisibleItemCount;
          $4000004A: Step:=-FItemIndex;
          $4000004D: Step:=FItems.Count-1-FItemIndex;
          else Exit;
        end;
        NewPosition:=FItemIndex;
        NewPosition:=NewPosition+Step;
        if Wrap then NewPosition:=((Trunc(NewPosition) MOD FItems.Count)+FItems.Count) MOD FItems.Count
        else NewPosition:=EnsureRange(NewPosition,0,FItems.Count-1);
        AEvent.Handled:=(AEvent.Kind=gekKeyDown) OR (OldIndex<>NewPosition);
        SetPosition(NewPosition,True);
      end;
  end;
  finally
    if Guard.Alive then FWheelEventGuard:=Guard.Previous;
  end;
end;

constructor TGuiComboBox.Create;
begin
  inherited Create;
  ReadOnly:=True;
  FTypeAhead:=True;
  FTypeAheadTimeout:=1000;
  FItems:=TGuiIdentityStrings.Create;
  FItems.OnChange:=ItemsChanged;
  FSelectedIndex:=-1;
  FDroppedDown:=False;
  FHoveredIndex:=-1;
  FItemHeight:=30;
  FDropDownCount:=6;
  FPopupRowCount:=6;
  CanFocus:=True;
  TabStop:=True;
  Padding:=GuiBoxLTRB(8, 4, 28, 4);
end;

destructor TGuiComboBox.Destroy;
var Guard: PNotifyGuard;
begin
  Guard:=FNotifyGuard;
  while Assigned(Guard) do
  begin
    Guard^.Alive:=False;
    Guard:=Guard^.Previous;
  end;
  FItems.Free;
  inherited Destroy;
end;

function TGuiComboBox.GetEditable: Boolean;
begin
  Result:=NOT ReadOnly;
end;

function TGuiComboBox.SearchTime: UInt64;
begin
  Result:=TThread.GetTickCount64;
end;

procedure TGuiComboBox.ClearSearch;
begin
  FSearchPrefix:='';
  FSearchStamp:=0;
  if FSearchComposing then CancelComposition;
  FSearchComposing:=False;
end;

procedure TGuiComboBox.SetTypeAhead(AValue: Boolean);
begin
  ClearSearch;
  FTypeAhead:=AValue;
end;

procedure TGuiComboBox.SetTypeAheadTimeout(AValue: Cardinal);
begin
  if AValue=0 then raise EArgumentException.Create('Combo type-ahead timeout must be positive');
  ClearSearch;
  FTypeAheadTimeout:=AValue;
end;

function TGuiComboBox.TextInputRect(ACanvas: TGuiCanvas): TGuiRect;
begin
  if Editable then Result:=inherited TextInputRect(ACanvas)
  else
  begin
    Result:=TextRect;
    Result.Width:=1;
  end;
end;

procedure TGuiComboBox.Search(const AText: String);
var Input,Query: String;
NowValue: UInt64;
Start,Index,Current: Integer;
Fresh,Cycle: Boolean;
  function FindWrapped(const Prefix: String; FromIndex: Integer): Integer;
  begin
    Result:=FindPrefix(Prefix,FromIndex);
    if Result<0 then Result:=FindPrefix(Prefix,0);
  end;
begin
  if NOT FTypeAhead OR Editable OR NOT Enabled OR NOT Visible then Exit;
  Input:=NormalizeText(AText);
  if Input='' then Exit;
  NowValue:=SearchTime;
  Fresh:=(FSearchPrefix='') OR (NowValue<FSearchStamp);
  if NOT Fresh then Fresh:=NowValue-FSearchStamp>=FTypeAheadTimeout;
  Cycle:=NOT Fresh AND ((FSearchCaseSensitive AND (FSearchPrefix=Input)) OR
    (NOT FSearchCaseSensitive AND SameText(FSearchPrefix,Input)));
  if FDroppedDown then Current:=FHoveredIndex else Current:=FSelectedIndex;
  if Fresh OR Cycle then
  begin
    Query:=Input;
    Start:=Current+1;
  end
  else
  begin
    Query:=FSearchPrefix+Input;
    Start:=Max(0,Current);
  end;
  Index:=FindWrapped(Query,Start);
  if (Index<0) AND NOT Fresh AND NOT Cycle then
  begin
    Query:=Input;
    Index:=FindWrapped(Query,Current+1);
  end;
  FSearchPrefix:=Query;
  FSearchStamp:=NowValue;
  if (Index<0) OR (Index>=FItems.Count) then Exit;
  if FDroppedDown then MoveHighlight(Index) else ApplySelection(Index,False);
end;

procedure TGuiComboBox.SetEditable(AValue: Boolean);
begin
  ClosePopup;
  CancelEdit;
  ReadOnly:=NOT AValue;
end;

procedure TGuiComboBox.SyncSelectionText;
begin
  FSyncingText:=True;
  try
    CancelComposition;
    Text:=FSelectionText;
  finally
    FSyncingText:=False;
  end;
  FEditing:=False;
end;

procedure TGuiComboBox.CancelEdit;
begin
  SyncSelectionText;
end;

procedure TGuiComboBox.DoChange;
begin
  if FSyncingText then
  begin
    RecordChange;
    Exit;
  end;
  Inc(FSelectionRevision);
  FEditing:=True;
  ClosePopup;
  inherited;
end;

function TGuiComboBox.TextRect: TGuiRect;
begin
  Result:=inherited TextRect;
  Result.Width:=Max(0,Min(Result.Width,AbsoluteBounds.Left+AbsoluteBounds.Width-30-Result.Left));
end;

function TGuiComboBox.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  if Editable AND GuiRectContains(AbsoluteBounds,APoint) AND
    (APoint.X<AbsoluteBounds.Left+AbsoluteBounds.Width-26) then Result:=gmcText else Result:=gmcArrow;
end;

function TGuiComboBox.FindText(const AText: String): Integer;
var I: Integer;
begin
  for I:=0 to FItems.Count-1 do if FItems[I]=AText then Exit(I);
  Result:=-1;
end;

function TGuiComboBox.FindPrefix(const AText: String; AStartIndex: Integer): Integer;
var I: Integer;
Prefix: String;
begin
  Result:=-1;
  if AText='' then Exit;
  for I:=Max(0,AStartIndex) to FItems.Count-1 do
  begin
    Prefix:=Copy(FItems[I],1,Length(AText));
    if (FSearchCaseSensitive AND (Prefix=AText)) OR
      (NOT FSearchCaseSensitive AND SameText(Prefix,AText)) then Exit(I);
  end;
end;

function TGuiComboBox.TryCompleteText: Boolean;
var Index,PrefixLength: Integer;
Candidate: String;
begin
  Result:=False;
  if NOT Editable OR NOT Enabled OR (CompositionText<>'') OR HasSelection OR
    (CaretIndex<>Length(Text)) then Exit;
  Index:=FindPrefix(Text);
  if (Index<0) OR (Index>=Items.Count) then Exit;
  Candidate:=Items[Index];
  PrefixLength:=Length(Text);
  if (Length(Candidate)<PrefixLength) OR (Candidate=Text) OR ((MaxLength>0) AND (Length(Candidate)>MaxLength)) OR
    (NormalizeText(Candidate)<>Candidate) then Exit;
  { The completion selection must not split a grapheme shared with the prefix. }
  if NOT IsGraphemeBoundary(Candidate, PrefixLength) then Exit;
  AssignTextSilently(Candidate);
  SetSelection(PrefixLength,Length(Candidate));
  Result:=True;
end;

procedure TGuiComboBox.DoTextInserted;
begin
  if FAutoComplete then TryCompleteText;
  inherited;
end;

function TGuiComboBox.CompleteText: Boolean;
begin
  Result:=TryCompleteText;
  if Result then DoUserChange;
end;

procedure TGuiComboBox.AcceptText;
begin
  if NOT Editable OR NOT Enabled OR (CompositionText<>'') then Exit;
  AcceptItem(FindText(Text),Text);
end;

function TGuiComboBox.AddItem(const AText: String): Integer;
begin
  Result:=FItems.Add(AText);
end;

procedure TGuiComboBox.SetSelectedIndex(AValue: Integer);
begin
  ClearSearch;
  ApplySelection(AValue,False);
end;

procedure TGuiComboBox.EnsureSelectionVisible;
begin
  EnsureItemVisible(FSelectedIndex);
end;

procedure TGuiComboBox.EnsureItemVisible(AIndex: Integer);
var Rows: Integer;
begin
  Rows:=Max(1,GetVisibleItemCount);
  if AIndex < FFirstVisible then
    FFirstVisible:=Max(0, AIndex);
  if AIndex >= FFirstVisible + Rows then
    FFirstVisible:=AIndex - Rows + 1;
  FFirstVisible:=EnsureRange(FFirstVisible,0,Max(0,FItems.Count-Rows));
end;

procedure TGuiComboBox.MoveHighlight(AIndex: Integer);
begin
  if FItems.Count=0 then Exit;
  FHoveredIndex:=EnsureRange(AIndex,0,FItems.Count-1);
  FKeyboardHighlight:=True;
  FDraggingPopupBar:=False;
  EnsureItemVisible(FHoveredIndex);
end;

procedure TGuiComboBox.AcceptSelection;
begin
  if FDroppedDown then
  begin
    if FHoveredIndex<0 then
      ClosePopup
    else
      AcceptItem(FHoveredIndex);
  end
  else if Editable then
    AcceptText
  else
    AcceptItem(FSelectedIndex);
end;

procedure TGuiComboBox.AcceptItem(AIndex: Integer; const ACustomText: String);
var Guard: TNotifyGuard;
Revision: UInt64;
begin
  if NOT Enabled OR NOT Visible OR (AIndex< -1) OR ((AIndex=-1) AND NOT Editable) OR
    (AIndex>=FItems.Count) OR (CompositionText<>'') then Exit;
  ClosePopup;
  Guard.Previous:=FNotifyGuard;
  Guard.Alive:=True;
  FNotifyGuard:=@Guard;
  Revision:=FSelectionRevision+1;
  try
    ApplySelection(AIndex,False,ACustomText);
    if NOT Guard.Alive then Exit;
    if (Revision=FSelectionRevision) AND Assigned(FOnAccept) then FOnAccept(Self);
  finally
    if Guard.Alive then FNotifyGuard:=Guard.Previous;
  end;
end;

procedure TGuiComboBox.SetDropDownCount(AValue: Integer);
begin
  if AValue<=0 then raise EArgumentException.Create('Combo dropdown count must be positive');
  FDropDownCount:=AValue;
  FDraggingPopupBar:=False;
  FHoveredIndex:=-1;
  NormalizePopupScroll;
  InvalidateLayout;
end;

function TGuiComboBox.GetVisibleItemCount: Integer;
var R: TGuiRect;
begin
  R:=DropDownRect;
  if (R.Width<=0) OR (R.Height<=0) OR (FItems.Count=0) then Exit(0);
  Result:=Min(Min(FDropDownCount,FItems.Count),Max(1,Floor(R.Height/FItemHeight+0.00001)));
end;

procedure TGuiComboBox.NormalizePopupScroll;
var Rows: Integer;
R: TGuiRect;
begin
  R:=DropDownRect;
  if NOT FHasPopupLayout OR (R.Left<>FPopupLayout.Left) OR (R.Top<>FPopupLayout.Top) OR
    (R.Width<>FPopupLayout.Width) OR (R.Height<>FPopupLayout.Height) then
  begin
    FPopupLayout:=R;
    FHasPopupLayout:=True;
    FDraggingPopupBar:=False;
    if NOT FKeyboardHighlight then FHoveredIndex:=-1;
  end;
  Rows:=GetVisibleItemCount;
  if Rows<>FPopupRowCount then
  begin
    FPopupRowCount:=Rows;
    FDraggingPopupBar:=False;
    if FKeyboardHighlight then EnsureItemVisible(FHoveredIndex)
    else
    begin
      FHoveredIndex:=-1;
      EnsureSelectionVisible;
    end;
  end;
  FFirstVisible:=EnsureRange(FFirstVisible,0,Max(0,FItems.Count-Max(1,Rows)));
end;

procedure TGuiComboBox.ApplySelection(AIndex: Integer; AIdentityChanged: Boolean;
  const ACustomText: String; APreserveEdit: Boolean);
var I: Integer;
NewText: String;
Changed,Preserve: Boolean;
begin
  Inc(FSelectionRevision);
  AIndex:=EnsureRange(AIndex,-1,FItems.Count-1);
  NewText:=ACustomText;
  if AIndex>=0 then NewText:=FItems[AIndex];
  Changed:=AIdentityChanged OR (AIndex<>FSelectedIndex) OR (NewText<>FSelectionText);
  Preserve:=APreserveEdit AND Editable AND FEditing AND NOT AIdentityChanged AND (NewText=FSelectionText);
  FSelectedIndex:=AIndex;
  FSelectionText:=NewText;
  if FDroppedDown then
  begin
    FHoveredIndex:=AIndex;
    FKeyboardHighlight:=False;
  end;
  FSyncingItems:=True;
  try
    for I:=0 to FItems.Count-1 do TGuiStateStrings(FItems).ItemState[I]:=Ord(I=AIndex);
  finally
    FSyncingItems:=False;
  end;
  EnsureSelectionVisible;
  if NOT Preserve then SyncSelectionText;
  if Changed AND Assigned(FOnSelect) then FOnSelect(Self);
end;

procedure TGuiComboBox.ItemsChanged(Sender: TObject);
var I,NewIndex: Integer;
Replaced: Boolean;
begin
  if FSyncingItems then Exit;
  ClearSearch;
  NewIndex:=-1;
  for I:=0 to FItems.Count-1 do
    if TGuiStateStrings(FItems).ItemState[I]=1 then
    begin
      NewIndex:=I;
      Break;
    end;
  Replaced:=(FSelectedIndex>=0) AND (NewIndex<0);
  if NewIndex<0 then
  begin
    NewIndex:=Min(FSelectedIndex,FItems.Count-1);
    if (FItemsCount=0) AND (FItems.Count>0) AND
      NOT (Editable AND (FEditing OR (FSelectionText<>''))) then NewIndex:=0;
  end;
  FItemsCount:=FItems.Count;
  Inc(FItemsRevision);
  FDraggingPopupBar:=False;
  FHoveredIndex:=-1;
  if FItems.Count=0 then ClosePopup;
  InvalidateLayout;
  if (NewIndex<0) AND Editable AND NOT Replaced then ApplySelection(NewIndex,False,FSelectionText,True)
  else ApplySelection(NewIndex,Replaced,'',True);
end;

procedure TGuiComboBox.SetDroppedDown(AValue: Boolean);
begin
  ClearSearch;
  if NOT AValue then
  begin
    ClosePopup;
    Exit;
  end;
  if NOT Enabled OR NOT Visible OR (FItems.Count=0) then
  begin
    ClosePopup;
    Exit;
  end;
  FDraggingPopupBar:=False;
  FHoveredIndex:=-1;
  NormalizePopupScroll;
  if NOT Assigned(Context) OR (GetVisibleItemCount>0) then
  begin
    FDroppedDown:=True;
    FHoveredIndex:=FSelectedIndex;
    FKeyboardHighlight:=False;
  end
  else ClosePopup;
end;

procedure TGuiComboBox.SetItemHeight(AValue: TGuiFloat);
begin
  if IsNan(AValue) OR IsInfinite(AValue) OR (AValue<=0) then
    raise EArgumentException.Create('Combo item height must be positive and finite');
  FDraggingPopupBar:=False;
  FHoveredIndex:=-1;
  FItemHeight:=AValue;
  NormalizePopupScroll;
  InvalidateLayout;
end;

function TGuiComboBox.PopupTrackRect: TGuiRect;
begin
  Result:=GuiScrollTrackRect(DropDownRect, goVertical, Max(8, Style.ScrollBarSize));
end;

function TGuiComboBox.PopupThumbRect: TGuiRect;
begin
  Result:=GuiVerticalScrollThumbRect(PopupTrackRect, GetVisibleItemCount, FItems.Count, FFirstVisible);
end;

function TGuiComboBox.HandlePopupScroll(var AEvent: TGuiEvent): Boolean;
var
  Track, Thumb: TGuiRect;
  Limit: Integer;
begin
  Result:=False;
  NormalizePopupScroll;
  Limit:=Max(0, FItems.Count - Max(1,GetVisibleItemCount));
  FFirstVisible:=EnsureRange(FFirstVisible, 0, Limit);
  if (NOT FDroppedDown) OR (Limit = 0) OR
    (AEvent.Kind IN [gekCancel, gekBlur]) then FDraggingPopupBar:=False;
  if NOT FDroppedDown then Exit;
  Track:=PopupTrackRect;
  Thumb:=PopupThumbRect;
  if (AEvent.Kind = gekMouseDown) AND (AEvent.Button = gmbLeft) AND
    (Limit > 0) AND GuiRectContains(Track, AEvent.Position) then
  begin
    if NOT GuiRectContains(Thumb, AEvent.Position) then
      FFirstVisible:=EnsureRange(FFirstVisible + Round(GuiScrollOffsetFromThumbDelta(
        AEvent.Position.Y - Thumb.Top - Thumb.Height / 2,
        Track.Height, Thumb.Height, Limit)), 0, Limit);
    FDraggingPopupBar:=True;
    FPopupDragY:=AEvent.Position.Y;
    FPopupDragFirst:=FFirstVisible;
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseMove) AND FDraggingPopupBar then
  begin
    FFirstVisible:=EnsureRange(FPopupDragFirst + Round(GuiScrollOffsetFromThumbDelta(
      AEvent.Position.Y - FPopupDragY, Track.Height, Thumb.Height, Limit)), 0, Limit);
    Result:=True;
  end
  else if (AEvent.Kind = gekMouseUp) AND (AEvent.Button = gmbLeft) AND FDraggingPopupBar then
  begin
    FDraggingPopupBar:=False;
    Result:=True;
  end;
  if Result then
  begin
    FHoveredIndex:=-1;
    FKeyboardHighlight:=False;
    AEvent.Handled:=True;
  end;
end;

function TGuiComboBox.DropDownRect: TGuiRect;
var
  Rect,Screen: TGuiRect;
  Below,Above,Space: TGuiFloat;
  Desired: Double;
  OpenAbove: Boolean;
begin
  Rect:=AbsoluteBounds;
  Desired:=FItemHeight;
  Desired:=Desired*Min(FDropDownCount,FItems.Count);
  Result:=GuiRect(Rect.Left,Rect.Top+Rect.Height,Max(0,Rect.Width),Min(Desired,MaxSingle));
  if NOT Assigned(Context) then Exit;
  Screen:=Context.Root.AbsoluteBounds;
  Screen.Width:=Max(0,Screen.Width);
  Screen.Height:=Max(0,Screen.Height);
  Result.Width:=Min(Result.Width,Screen.Width);
  Result.Left:=EnsureRange(Result.Left,Screen.Left,Screen.Left+Screen.Width-Result.Width);
  Below:=Screen.Top+Screen.Height-EnsureRange(Rect.Top+Rect.Height,Screen.Top,Screen.Top+Screen.Height);
  Above:=EnsureRange(Rect.Top,Screen.Top,Screen.Top+Screen.Height)-Screen.Top;
  OpenAbove:=(Desired>Below) AND (Above>Below);
  if OpenAbove then Space:=Above else Space:=Below;
  { Prefer complete rows. If even one cannot fit, show a clipped row; if the
    anchor fills the viewport, use the viewport itself so choices remain usable. }
  if Space<=0 then Space:=Screen.Height;
  if Desired<=Space then Result.Height:=Desired
  else if Space>=FItemHeight then
    Result.Height:=Min(Desired,Floor(Space/FItemHeight)*FItemHeight)
  else Result.Height:=Min(Desired,Space);
  if OpenAbove then Result.Top:=Rect.Top-Result.Height;
  Result.Top:=EnsureRange(Result.Top,Screen.Top,Screen.Top+Screen.Height-Result.Height);
end;

function TGuiComboBox.ItemIndexAtPoint(const APoint: TGuiPoint): Integer;
var
  Rect: TGuiRect;
begin
  Result:=-1;
  Rect:=DropDownRect;
  if NOT GuiRectContains(Rect, APoint) then
    Exit;

  if FItemHeight <= 0 then Exit;
  Result:=FFirstVisible + Trunc((APoint.Y - Rect.Top) / FItemHeight);
  if (Result < 0) OR (Result >= FItems.Count) then
    Result:=-1;
end;

procedure TGuiComboBox.PaintSelf(ACanvas: TGuiCanvas);
var
  Rect: TGuiRect;
  States: TGuiControlVisualStates;
  TextValue: String;
begin
  Rect:=AbsoluteBounds;
  if (Rect.Width<=0) OR (Rect.Height<=0) then Exit;
  ACanvas.PushClipRect(Rect);
  try
  if Editable then
  begin
    inherited PaintSelf(ACanvas);
    States:=[gcvsNormal];
    if NOT Enabled then Include(States,gcvsDisabled);
    Rect:=AbsoluteBounds;
    ACanvas.DrawChevron(GuiRect(Rect.Left+Rect.Width-20,Rect.Top+Rect.Height/2-2,8,4),GuiResolveTextColor(Style,States));
    Exit;
  end;
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
  ACanvas.DrawSurface(GuiResolveBackgroundDrawable(Style, States), Rect, Style.CornerRadius);
  DrawControlBorder(ACanvas, Rect, GuiResolveBorderColor(Style, States));

  TextValue:='';
  if (FSelectedIndex >= 0) AND (FSelectedIndex < FItems.Count) then
    TextValue:=FItems[FSelectedIndex];

  DrawControlText(ACanvas, TextValue, GuiInflateRect(Rect,
    GuiBoxLTRB(Padding.Left, Padding.Top, Max(Padding.Right, 30), Padding.Bottom)),
    GuiResolveTextColor(Style, States), ghtaLeft, gvtaCenter);
  ACanvas.DrawChevron(GuiRect(Rect.Left + Rect.Width - 20, Rect.Top + (Rect.Height / 2) - 2, 8, 4), GuiResolveTextColor(Style, States));

  if Focused AND FocusVisible then
    GuiPaintFocusIndicator(ACanvas, Rect, Style);
  finally
    ACanvas.PopClipRect;
  end;
end;

procedure TGuiComboBox.ClosePopup;
begin
  ClearSearch;
  FKeyboardHighlight:=False;
  FDraggingPopupBar:=False;
  FDroppedDown:=False;
  FHoveredIndex:=-1;
end;

procedure TGuiComboBox.PaintOverlay(ACanvas: TGuiCanvas);
var
  DropRect: TGuiRect;
  ItemsRect: TGuiRect;
  ItemRect, TextRect: TGuiRect;
  I,Rows: Integer;
begin
  if NOT Enabled OR NOT Visible OR (GetVisibleItemCount=0) then ClosePopup;
  if FDroppedDown then
  begin
    NormalizePopupScroll;
    Rows:=GetVisibleItemCount;
    DropRect:=DropDownRect;
    ACanvas.DrawSurface(Style.Background, DropRect, Style.CornerRadius);
    DrawControlBorder(ACanvas, DropRect, Style.BorderColor);
    ItemsRect:=GuiInflateRect(DropRect, GuiBox(1));
    ACanvas.PushClipRect(ItemsRect);
    try
      for I:=FFirstVisible to Min(FItems.Count - 1, FFirstVisible + Rows - 1) do
      begin
        ItemRect:=GuiRect(ItemsRect.Left, DropRect.Top + ((I - FFirstVisible) * FItemHeight), ItemsRect.Width, FItemHeight);
        PaintItemBackground(ACanvas, ItemRect, I = FSelectedIndex);
        if (I=FHoveredIndex) AND (I<>FSelectedIndex) then
          ACanvas.DrawSurface(Style.HoverBackground,ItemRect,0);
        if (I=FHoveredIndex) AND FKeyboardHighlight then
          GuiPaintFocusIndicator(ACanvas,ItemRect,Style);

        TextRect:=ItemRect;
        if FItems.Count > Rows then
          TextRect.Width:=Max(0, PopupTrackRect.Left - 4 - TextRect.Left);
        ACanvas.PushClipRect(TextRect);
        try
          DrawControlText(ACanvas, FItems[I], GuiInflateRect(TextRect, GuiBoxLTRB(8, 2, 8, 2)), Style.TextColor, ghtaLeft, gvtaCenter);
        finally
          ACanvas.PopClipRect;
        end;
      end;
    finally
      ACanvas.PopClipRect;
    end;
    if FItems.Count > Rows then
      PaintScrollBar(ACanvas, PopupTrackRect, PopupThumbRect, goVertical, FDraggingPopupBar, True);
  end;

  inherited PaintOverlay(ACanvas);
end;

procedure TGuiComboBox.HandleEvent(var AEvent: TGuiEvent);
var
  Index,Revision: Integer;
  NowValue: UInt64;
begin
  if AEvent.Kind IN [gekCancel,gekBlur] then
  begin
    FEditingPointer:=False;
    ClosePopup;
    if AEvent.Kind=gekCancel then CancelEdit;
    inherited;
    Exit;
  end;
  if NOT Enabled then
  begin
    ClosePopup;
    Exit;
  end;
  if NOT Editable AND FTypeAhead then
  begin
    if AEvent.Kind=gekTextEditing then
    begin
      FSearchComposing:=AEvent.Text<>'';
      AEvent.Handled:=True;
      Exit;
    end;
    if AEvent.Kind=gekTextInput then
    begin
      FSearchComposing:=False;
      AEvent.Handled:=True;
      Search(String(AEvent.Text));
      Exit;
    end;
    if FSearchComposing AND (AEvent.Kind=gekKeyDown) then
    begin
      if AEvent.KeyCode=27 then ClearSearch;
      AEvent.Handled:=True;
      Exit;
    end;
    if (AEvent.Kind=gekKeyDown) AND (AEvent.KeyCode=32) AND (FSearchPrefix<>'') then
    begin
      NowValue:=SearchTime;
      if NowValue>=FSearchStamp then
        if NowValue-FSearchStamp<FTypeAheadTimeout then
        begin
          AEvent.Handled:=True;
          Exit;
        end;
    end;
  end;
  if AEvent.Kind IN [gekMouseDown,gekMouseWheel] then ClearSearch;
  if AEvent.Kind=gekKeyDown then
    case AEvent.KeyCode of
      13,27,32,$40000052,$40000051,$4000004A,$4000004D,$4000004B,$4000004E,$4000003D: ClearSearch;
    end;
  if Editable then
  begin
    if (CompositionText<>'') AND (AEvent.Kind IN [gekKeyDown,gekTextInput,gekTextEditing]) then
    begin
      inherited;
      Exit;
    end;
    if AEvent.Kind IN [gekTextInput,gekTextEditing] then
    begin
      inherited;
      Exit;
    end;
    if (AEvent.Kind=gekMouseDown) AND (AEvent.Button=gmbLeft) AND GuiRectContains(AbsoluteBounds,AEvent.Position) AND
      (AEvent.Position.X<AbsoluteBounds.Left+AbsoluteBounds.Width-26) then
    begin
      ClosePopup;
      FEditingPointer:=True;
      inherited;
      Exit;
    end;
    if FEditingPointer AND (AEvent.Kind IN [gekMouseMove,gekMouseUp]) then
    begin
      if (AEvent.Kind=gekMouseUp) AND (AEvent.Button=gmbLeft) then FEditingPointer:=False;
      inherited;
      Exit;
    end;
    if AEvent.Kind=gekKeyDown then
    begin
      case AEvent.KeyCode of
        13,27,$40000052,$40000051,$4000004B,$4000004E,$4000003D: ;
        $4000004A,$4000004D: if NOT FDroppedDown then
        begin
          inherited;
          Exit;
        end;
      else inherited;
      Exit;
      end;
    end;
  end;
  if (AEvent.Kind IN [gekMouseDown,gekMouseUp]) AND (AEvent.Button<>gmbLeft) then Exit;
  if Editable AND (AEvent.Kind=gekMouseDown) then CancelComposition;
  if HandlePopupScroll(AEvent) then Exit;
  Revision:=FItemsRevision;
  HandleControlEvent(AEvent);
  if Revision<>FItemsRevision then
  begin
    AEvent.Handled:=True;
    Exit;
  end;

  case AEvent.Kind of
    gekMouseWheel:
    begin
      if FDroppedDown then
      begin
        FFirstVisible:=EnsureRange(FFirstVisible - Round(AEvent.Delta.Y), 0, Max(0, FItems.Count - Max(1,GetVisibleItemCount)));
        FHoveredIndex:=-1;
        FKeyboardHighlight:=False;
        AEvent.Handled:=True;
      end;
    end;
    gekBlur:
    begin
      FDroppedDown:=False;
      FHoveredIndex:=-1;
    end;

    gekMouseLeave:
    begin
      if NOT FKeyboardHighlight then FHoveredIndex:=-1;
    end;

    gekMouseMove:
    begin
      if FDroppedDown then
      begin
        Index:=ItemIndexAtPoint(AEvent.Position);
        if Index>=0 then
        begin
          FHoveredIndex:=Index;
          FKeyboardHighlight:=False;
        end
        else if NOT FKeyboardHighlight then FHoveredIndex:=-1;
        AEvent.Handled:=True;
      end;
    end;

    gekMouseDown:
    begin
      if FDroppedDown then
      begin
        Index:=ItemIndexAtPoint(AEvent.Position);
        if Index >= 0 then
        begin
          AEvent.Handled:=True;
          AcceptItem(Index);
          Exit;
        end else
        begin
          ClosePopup;
        end;
      end else
      begin
        if GuiRectContains(AbsoluteBounds,AEvent.Position) then SetDroppedDown(True);
      end;

      AEvent.Handled:=True;
    end;

    gekKeyDown:
    begin
      case AEvent.KeyCode of
        13, 32:
        begin
          AEvent.Handled:=True;
          if AEvent.KeyRepeat then Exit;
          if FDroppedDown then
          begin
            AcceptSelection;
            Exit;
          end;
          if Editable then
          begin
            AcceptText;
            Exit;
          end;
          SetDroppedDown(True);
        end;

        27:
        begin
          if FDroppedDown then ClosePopup else if Editable then CancelEdit;
          AEvent.Handled:=True;
        end;

        $40000052:
        begin
          AEvent.Handled:=True;
          if FDroppedDown then MoveHighlight(FHoveredIndex-1)
          else if FItems.Count>0 then SelectedIndex:=Max(0,FSelectedIndex - 1);
        end;

        $40000051:
        begin
          AEvent.Handled:=True;
          if FDroppedDown then MoveHighlight(FHoveredIndex+1) else SelectedIndex:=FSelectedIndex + 1;
        end;
        $4000004A:
        begin
          AEvent.Handled:=True;
          if FDroppedDown then MoveHighlight(0) else if FItems.Count>0 then SelectedIndex:=0;
        end;
        $4000004D:
        begin
          AEvent.Handled:=True;
          if FDroppedDown then MoveHighlight(FItems.Count-1) else SelectedIndex:=FItems.Count-1;
        end;
        $4000004B,$4000004E:
        begin
          AEvent.Handled:=True;
          Index:=Max(1,GetVisibleItemCount);
          if AEvent.KeyCode=$4000004B then Index:=-Index;
          if FDroppedDown then MoveHighlight(FHoveredIndex+Index)
          else SelectedIndex:=Max(0,FSelectedIndex+Index);
        end;
        $4000003D:
        begin
          AEvent.Handled:=True;
          if NOT AEvent.KeyRepeat then SetDroppedDown(NOT FDroppedDown);
        end;
      end;
    end;
  end;
end;

function TGuiComboBox.HitTest(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=inherited HitTest(APoint);
end;

function TGuiComboBox.HitTestOverlay(const APoint: TGuiPoint): TGuiControl;
begin
  Result:=inherited HitTestOverlay(APoint);

  if Assigned(Result) then
    Exit;

  if FDroppedDown AND Visible AND Enabled AND GuiRectContains(DropDownRect, APoint) then
    Result:=Self;
end;

function TGuiHeaderControl.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if Enabled AND (Cursor = gmcAuto) AND
    ((FResizingColumn >= 0) OR (ResizeColumnAtPoint(APoint) >= 0)) then
    Result:=gmcSizeWE;
end;

function TGuiListView.MouseCursorAt(const APoint: TGuiPoint): TGuiMouseCursor;
begin
  Result:=inherited MouseCursorAt(APoint);
  if Enabled AND (Cursor = gmcAuto) AND
    ((FResizingColumn >= 0) OR (ResizeColumnAtPoint(APoint) >= 0)) then
    Result:=gmcSizeWE;
end;

procedure TGuiWheelPicker.UpdateInteraction(AStage: TGuiInteractionStage);
begin
  if AStage = gisMotion then
    UpdateMotion;
end;

end.
