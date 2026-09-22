program ListsImportTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  CategoryImportSupport,
  PasSDL3.GUI.Controls.Lists;

var
  WrapMode: TGuiWheelWrapMode;
  SortDirection: TGuiSortDirection;
  SortKind: TGuiColumnSortKind;
  Indices: TGuiIndexArray;
  ColumnEvent: TGuiColumnEvent;
  CompareEvent: TGuiCompareRowsEvent;
  ItemCheckEvent: TGuiItemCheckEvent;

begin
  WrapMode:=gwwDisabled;
  SortDirection:=gsdDescending;
  SortKind:=gcskNumber;
  SetLength(Indices, 0);
  ColumnEvent:=nil;
  CompareEvent:=nil;
  ItemCheckEvent:=nil;
  if (Ord(WrapMode) <> 2) OR (Ord(SortDirection) <> 1) OR
      (Ord(SortKind) <> 1) OR Assigned(ColumnEvent) OR
      Assigned(CompareEvent) OR Assigned(ItemCheckEvent) OR
      (Length(Indices) <> 0) then
    Halt(1);
  CheckControlClass(TGuiListBox);
  CheckControlClass(TGuiWheelPicker);
  CheckControlClass(TGuiRadioGroup);
  CheckControlClass(TGuiTreeView);
  CheckControlClass(TGuiHeaderControl);
  CheckControlClass(TGuiListView);
  CheckControlClass(TGuiItemTemplate);
  CheckControlClass(TGuiCheckListBox);
  CheckControlClass(TGuiSwitchListBox);
  CheckControlClass(TGuiComboBox);
  Pass('Lists');
end.
