program ListsCompatibilityTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Controls.Lists;

var
  CoreControl: PasSDL3.GUI.Controls.TGuiControl;
  ListBox: PasSDL3.GUI.Controls.Lists.TGuiListBox;
  Wheel: PasSDL3.GUI.Controls.Lists.TGuiWheelPicker;
  Radio: PasSDL3.GUI.Controls.Lists.TGuiRadioGroup;
  Tree: PasSDL3.GUI.Controls.Lists.TGuiTreeView;
  Header: PasSDL3.GUI.Controls.Lists.TGuiHeaderControl;
  ListView: PasSDL3.GUI.Controls.Lists.TGuiListView;
  Item: PasSDL3.GUI.Controls.Lists.TGuiItemTemplate;
  CheckList: PasSDL3.GUI.Controls.Lists.TGuiCheckListBox;
  SwitchList: PasSDL3.GUI.Controls.Lists.TGuiSwitchListBox;
  Combo: PasSDL3.GUI.Controls.Lists.TGuiComboBox;
  Node: PasSDL3.GUI.Controls.Lists.TGuiTreeNode;
  CoreNode: PasSDL3.GUI.Controls.TGuiTreeNode;
  CoreWrap: PasSDL3.GUI.Controls.TGuiWheelWrapMode;
  WrapMode: PasSDL3.GUI.Controls.Lists.TGuiWheelWrapMode;
  CoreSort: PasSDL3.GUI.Controls.TGuiSortDirection;
  SortDirection: PasSDL3.GUI.Controls.Lists.TGuiSortDirection;
  CoreKind: PasSDL3.GUI.Controls.TGuiColumnSortKind;
  SortKind: PasSDL3.GUI.Controls.Lists.TGuiColumnSortKind;

begin
  ListBox:=PasSDL3.GUI.Controls.Lists.TGuiListBox.Create;
  Wheel:=PasSDL3.GUI.Controls.Lists.TGuiWheelPicker.Create;
  Radio:=PasSDL3.GUI.Controls.Lists.TGuiRadioGroup.Create;
  Tree:=PasSDL3.GUI.Controls.Lists.TGuiTreeView.Create;
  Header:=PasSDL3.GUI.Controls.Lists.TGuiHeaderControl.Create;
  ListView:=PasSDL3.GUI.Controls.Lists.TGuiListView.Create;
  Item:=PasSDL3.GUI.Controls.Lists.TGuiItemTemplate.Create;
  CheckList:=PasSDL3.GUI.Controls.Lists.TGuiCheckListBox.Create;
  SwitchList:=PasSDL3.GUI.Controls.Lists.TGuiSwitchListBox.Create;
  Combo:=PasSDL3.GUI.Controls.Lists.TGuiComboBox.Create;
  Node:=PasSDL3.GUI.Controls.Lists.TGuiTreeNode.Create('node', 0);
  try
    CoreControl:=ListBox;
    CoreControl:=Wheel;
    CoreControl:=Radio;
    CoreControl:=Tree;
    CoreControl:=Header;
    CoreControl:=ListView;
    CoreControl:=Item;
    CoreControl:=CheckList;
    CoreControl:=SwitchList;
    CoreControl:=Combo;
    CoreNode:=Node;
    CoreWrap:=PasSDL3.GUI.Controls.Lists.gwwDisabled;
    WrapMode:=CoreWrap;
    CoreSort:=PasSDL3.GUI.Controls.Lists.gsdDescending;
    SortDirection:=CoreSort;
    CoreKind:=PasSDL3.GUI.Controls.Lists.gcskNumber;
    SortKind:=CoreKind;
    if (CoreControl <> Combo) OR (CoreNode <> Node) OR
      (WrapMode <> PasSDL3.GUI.Controls.Lists.gwwDisabled) OR
      (SortDirection <> PasSDL3.GUI.Controls.Lists.gsdDescending) OR
      (SortKind <> PasSDL3.GUI.Controls.Lists.gcskNumber) then
      Halt(1);
  finally
    Node.Free;
    Combo.Free;
    SwitchList.Free;
    CheckList.Free;
    Item.Free;
    ListView.Free;
    Header.Free;
    Tree.Free;
    Radio.Free;
    Wheel.Free;
    ListBox.Free;
  end;
  WriteLn('PASS: aggregate list compatibility aliases preserve exact type identity');
end.
