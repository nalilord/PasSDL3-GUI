unit PasSDL3.GUI.StateStrings;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses SysUtils, Classes;

type
  { Per-row state is deliberately separate from application-owned Objects. }
  TGuiStateStrings = class(TStringList)
  private
    FStates: array of Integer;
    procedure ValidateIndex(AIndex: Integer);
    function GetState(AIndex: Integer): Integer;
    procedure SetState(AIndex,AValue: Integer);
  protected
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
  public
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1,Index2: Integer); override;
    procedure Move(CurIndex,NewIndex: Integer); override;
    procedure Sort; override;
    procedure CustomSort(Compare: TStringListSortCompare); override;
    property ItemState[Index: Integer]: Integer read GetState write SetState;
  end;

  { Preserves row identity without commandeering application-owned Objects. }
  TGuiIdentityStrings = class(TGuiStateStrings)
  public
    procedure Assign(Source: TPersistent); override;
  end;

implementation

procedure TGuiIdentityStrings.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source = Self then
    Exit;
  BeginUpdate;
  try
    inherited;
    { Assignment replaces rows; do not import another control's private state. }
    for I:=0 to Count - 1 do
      ItemState[I]:=0;
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.Assign(Source: TPersistent);
var I: Integer;
begin
  if Source=Self then Exit;
  BeginUpdate;
  try
    inherited;
    if Source IS TGuiStateStrings then
      for I:=0 to Count-1 do FStates[I]:=TGuiStateStrings(Source).ItemState[I];
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.ValidateIndex(AIndex: Integer);
begin
  if (AIndex<0) OR (AIndex>=Count) then raise EStringListError.Create('Invalid state-list index');
end;

function TGuiStateStrings.GetState(AIndex: Integer): Integer;
begin
  ValidateIndex(AIndex);
  Result:=FStates[AIndex];
end;

procedure TGuiStateStrings.SetState(AIndex,AValue: Integer);
begin
  ValidateIndex(AIndex);
  if FStates[AIndex]=AValue then Exit;
  Changing;
  FStates[AIndex]:=AValue;
  Changed;
end;

procedure TGuiStateStrings.InsertItem(Index: Integer; const S: string; AObject: TObject);
var I: Integer;
begin
  BeginUpdate;
  try
    inherited;
    SetLength(FStates,Count);
    for I:=Count-1 downto Index+1 do FStates[I]:=FStates[I-1];
    FStates[Index]:=0;
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.Clear;
begin
  BeginUpdate;
  try
    inherited;
    SetLength(FStates,0);
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.Delete(Index: Integer);
var I: Integer;
begin
  ValidateIndex(Index);
  BeginUpdate;
  try
    inherited;
    for I:=Index to Count-1 do FStates[I]:=FStates[I+1];
    SetLength(FStates,Count);
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.Exchange(Index1,Index2: Integer);
var State: Integer;
begin
  ValidateIndex(Index1);
  ValidateIndex(Index2);
  if Index1=Index2 then Exit;
  BeginUpdate;
  try
    inherited;
    State:=FStates[Index1];
    FStates[Index1]:=FStates[Index2];
    FStates[Index2]:=State;
  finally
    EndUpdate;
  end;
end;

procedure TGuiStateStrings.Move(CurIndex,NewIndex: Integer);
var Step: Integer;
begin
  ValidateIndex(CurIndex);
  ValidateIndex(NewIndex);
  if CurIndex=NewIndex then Exit;
  if Sorted then raise EStringListError.Create('Cannot move items in a sorted state list');
  if NewIndex>CurIndex then Step:=1 else Step:=-1;
  BeginUpdate;
  try
    while CurIndex<>NewIndex do
    begin
      Exchange(CurIndex,CurIndex+Step);
      Inc(CurIndex,Step);
    end;
  finally
    EndUpdate;
  end;
end;

function StateStringsCompare(List: TStringList; L,R: Integer): Integer;
begin
  {$IFDEF FPC}
  Result:=TGuiStateStrings(List).DoCompareText(List[L],List[R]);
  {$ELSE}
  Result:=TGuiStateStrings(List).CompareStrings(List[L],List[R]);
  {$ENDIF}
end;

procedure TGuiStateStrings.Sort;
begin
  CustomSort(StateStringsCompare);
end;

procedure TGuiStateStrings.CustomSort(Compare: TStringListSortCompare);
var Order,Buffer,Position,Original: array of Integer;
I,J,Old: Integer;
  procedure MergeSort(L,R: Integer);
  var M,A,B,K: Integer;
  begin
    if R-L<2 then Exit;
    M:=(L+R) DIV 2;
    MergeSort(L,M);
    MergeSort(M,R);
    A:=L;
    B:=M;
    for K:=L to R-1 do
    begin
      if (A<M) AND ((B>=R) OR (Compare(Self,Order[A],Order[B])<=0)) then
      begin
        Buffer[K]:=Order[A];
        Inc(A);
      end
      else
      begin
        Buffer[K]:=Order[B];
        Inc(B);
      end;
    end;
    for K:=L to R-1 do Order[K]:=Buffer[K];
  end;
begin
  if Count<2 then Exit;
  if NOT Assigned(Compare) then raise EArgumentException.Create('Missing state-list comparator');
  SetLength(Order,Count);
  SetLength(Buffer,Count);
  SetLength(Position,Count);
  SetLength(Original,Count);
  for I:=0 to Count-1 do
  begin
    Order[I]:=I;
    Position[I]:=I;
    Original[I]:=I;
  end;
  BeginUpdate;
  try
    MergeSort(0,Count);
    for I:=0 to Count-1 do
    begin
      J:=Position[Order[I]];
      if I=J then Continue;
      Exchange(I,J);
      Old:=Original[I];
      Original[I]:=Original[J];
      Original[J]:=Old;
      Position[Original[I]]:=I;
      Position[Original[J]]:=J;
    end;
  finally
    EndUpdate;
  end;
end;

end.
