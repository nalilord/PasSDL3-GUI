program ShopMenu;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SDL3,
  PasSDL3.GUI.Types,
  PasSDL3.GUI.Context,
  PasSDL3.GUI.Controls,
  PasSDL3.GUI.Input.SDL3,
  PasSDL3.GUI.Clipboard.SDL3,
  PasSDL3.GUI.Renderer.SDL3,
  PasSDL3.GUI.Fonts.SDLTTF,
  PasSDL3.GUI.Fonts,
  PasSDL3.GUI.Host.SDL3,
  PasSDL3.GUI.Theme;

type
  TShopHandlers = class
  private
    FStatusLabel: TGuiLabel;
    FCurrencyLabel: TGuiLabel;
    FItemGrid: TGuiGridPanel;
    FScrollBox: TGuiScrollBox;
    FCurrency: Integer;
  public
    constructor Create(AStatusLabel, ACurrencyLabel: TGuiLabel; AItemGrid: TGuiGridPanel; AScrollBox: TGuiScrollBox; ACurrency: Integer);
    procedure BuyClicked(Sender: TGuiControl);
    procedure CategoryClicked(Sender: TGuiControl);
    procedure DetailSelected(Sender: TGuiControl);
  end;

constructor TShopHandlers.Create(AStatusLabel, ACurrencyLabel: TGuiLabel; AItemGrid: TGuiGridPanel; AScrollBox: TGuiScrollBox; ACurrency: Integer);
begin
  inherited Create;
  FStatusLabel:=AStatusLabel;
  FCurrencyLabel:=ACurrencyLabel;
  FItemGrid:=AItemGrid;
  FScrollBox:=AScrollBox;
  FCurrency:=ACurrency;
end;

procedure TShopHandlers.BuyClicked(Sender: TGuiControl);
var
  Price: Integer;
begin
  Price:=StrToIntDef(Sender.StyleClass, 0);

  if Price <= FCurrency then
  begin
    FCurrency:=FCurrency - Price;
    FStatusLabel.Caption:='Purchased ' + Sender.Name;
  end else
    FStatusLabel.Caption:='Not enough coins for ' + Sender.Name;

  FCurrencyLabel.Caption:='Coins: ' + IntToStr(FCurrency);
end;

procedure TShopHandlers.CategoryClicked(Sender: TGuiControl);
var
  I: Integer;
  Control: TGuiControl;
  FilterKind: String;
begin
  FilterKind:=Sender.StyleClass;
  if Assigned(FItemGrid) then
  begin
    for I:=0 to FItemGrid.ChildCount - 1 do
    begin
      Control:=FItemGrid.Children[I];
      Control.Visible:=(FilterKind = 'All') OR (Control.Name = FilterKind);
    end;
  end;

  if Assigned(FScrollBox) then
    FScrollBox.ScrollY:=0;

  FStatusLabel.Caption:='Category: ' + Sender.Caption;
end;

procedure TShopHandlers.DetailSelected(Sender: TGuiControl);
var
  ListBox: TGuiListBox;
begin
  if Sender IS TGuiListBox then
  begin
    ListBox:=TGuiListBox(Sender);
    if (ListBox.SelectedIndex >= 0) AND (ListBox.SelectedIndex < ListBox.Items.Count) then
      FStatusLabel.Caption:='Detail tab: ' + ListBox.Items[ListBox.SelectedIndex];
  end;
end;

function AddLabel(AParent: TGuiControl; const ACaption: String; const ABounds: TGuiRect; const AColor: TGuiColor;
  AHorizontalAlign: TGuiHorizontalTextAlign = ghtaLeft): TGuiLabel;
begin
  Result:=TGuiLabel.Create;
  Result.Bounds:=ABounds;
  Result.Caption:=ACaption;
  Result.TextColor:=AColor;
  Result.TextHorizontalAlign:=AHorizontalAlign;
  AParent.Add(Result);
end;

function AddRoleLabel(AParent: TGuiControl; const ACaption: String; const ABounds: TGuiRect; const AStyleClass: String;
  AHorizontalAlign: TGuiHorizontalTextAlign = ghtaLeft): TGuiLabel;
begin
  Result:=AddLabel(AParent, ACaption, ABounds, GuiColor(255, 255, 255), AHorizontalAlign);
  Result.StyleClass:=AStyleClass;
end;

function AddPanel(AParent: TGuiControl; const ABounds: TGuiRect; const ABackColor, ABorderColor: TGuiColor): TGuiPanel;
begin
  Result:=TGuiPanel.Create;
  Result.Bounds:=ABounds;
  Result.BackgroundColor:=ABackColor;
  Result.BorderColor:=ABorderColor;
  AParent.Add(Result);
end;

function AddCategoryButton(AParent: TGuiControl; const ACaption, AFilterKind: String; AChecked: Boolean; AHandler: TShopHandlers): TGuiToggleButton;
begin
  Result:=TGuiToggleButton.Create;
  Result.Bounds:=GuiRect(0, 0, 96, 30);
  Result.Caption:=ACaption;
  Result.StyleClass:=AFilterKind;
  Result.Checked:=AChecked;
  Result.GroupName:='ShopCategories';
  Result.OnClick:=AHandler.CategoryClicked;
  AParent.Add(Result);
end;

procedure AddItemCard(AParent: TGuiControl; const AName, AKind, AStats: String; APrice: Integer; ATexture: TGuiTexture; const ATheme: TGuiTheme;
  AHandler: TShopHandlers);
var
  Card: TGuiPanel;
  Icon: TGuiImage;
  Button: TGuiButton;
begin
  Card:=AddPanel(AParent, GuiRect(0, 0, 220, 178), ATheme.CardBackground, ATheme.CardBorder);
  Card.Name:=AKind;
  Card.StyleClass:='Card';

  Icon:=TGuiImage.Create;
  Icon.Bounds:=GuiRect(16, 16, 52, 52);
  Icon.BackgroundColor:=ATheme.PanelBackground;
  Icon.BorderColor:=ATheme.SecondaryAccent;
  Icon.Texture:=ATexture;
  Icon.Padding:=GuiBox(6);
  Card.Add(Icon);

  AddLabel(Card, AName, GuiRect(80, 16, 120, 26), ATheme.Text);
  AddRoleLabel(Card, AKind, GuiRect(80, 43, 120, 24), 'Muted');
  AddRoleLabel(Card, AStats, GuiRect(16, 82, 188, 28), 'Muted');
  AddRoleLabel(Card, IntToStr(APrice) + ' coins', GuiRect(16, 116, 88, 28), 'Price');

  Button:=TGuiButton.Create;
  Button.Bounds:=GuiRect(112, 116, 92, 34);
  Button.Caption:='Buy';
  Button.Name:=AName;
  Button.StyleClass:=IntToStr(APrice);
  Button.OnClick:=AHandler.BuyClicked;
  Card.Add(Button);
end;

function CreateIconTexture(ARenderer: PSDL_Renderer; const ABaseColor, AAccentColor: TGuiColor): PSDL_Texture;
var
  PreviousTarget: PSDL_Texture;
  Rect: TSDL_FRect;
begin
  Result:=SDL_CreateTexture(ARenderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 64, 64);
  if NOT Assigned(Result) then
    Exit;

  SDL_SetTextureBlendMode(Result, SDL_BLENDMODE_BLEND);
  PreviousTarget:=SDL_GetRenderTarget(ARenderer);
  SDL_SetRenderTarget(ARenderer, Result);
  try
    SDL_SetRenderDrawColor(ARenderer, ABaseColor.R, ABaseColor.G, ABaseColor.B, ABaseColor.A);
    SDL_RenderClear(ARenderer);

    SDL_SetRenderDrawColor(ARenderer, AAccentColor.R, AAccentColor.G, AAccentColor.B, AAccentColor.A);
    Rect.x:=12;
    Rect.y:=12;
    Rect.w:=40;
    Rect.h:=40;
    SDL_RenderFillRect(ARenderer, @Rect);

    SDL_SetRenderDrawColor(ARenderer, 248, 250, 252, 180);
    Rect.x:=22;
    Rect.y:=22;
    Rect.w:=20;
    Rect.h:=20;
    SDL_RenderRect(ARenderer, @Rect);
  finally
    SDL_SetRenderTarget(ARenderer, PreviousTarget);
  end;
end;

var
  Window: PSDL_Window;
  Renderer: PSDL_Renderer;
  SdlEvent: TSDL_Event;
  Host: TGuiSDL3Host;
  Context: TGuiContext;
  Canvas: TGuiSDL3Canvas;
  FontRenderer: TGuiSDLTTFFontRenderer;
  Header: TGuiPanel;
  CategoryBar: TGuiStackPanel;
  Content: TGuiPanel;
  ScrollBox: TGuiScrollBox;
  ItemGrid: TGuiGridPanel;
  Details: TGuiPanel;
  DetailsStack: TGuiStackPanel;
  DetailList: TGuiListBox;
  StatusLabel: TGuiLabel;
  CurrencyLabel: TGuiLabel;
  Handler: TShopHandlers;
  Theme: TGuiTheme;
  WeaponIcon: PSDL_Texture;
  ArmorIcon: PSDL_Texture;
  GearIcon: PSDL_Texture;
  PotionIcon: PSDL_Texture;
  RelicIcon: PSDL_Texture;
  ToolIcon: PSDL_Texture;
  Running: Boolean;
begin
  Window:=nil;
  Renderer:=nil;
  Context:=nil;
  Canvas:=nil;
  Host:=nil;
  FontRenderer:=nil;
  Handler:=nil;
  Theme:=GuiDarkTheme;
  WeaponIcon:=nil;
  ArmorIcon:=nil;
  GearIcon:=nil;
  PotionIcon:=nil;
  RelicIcon:=nil;
  ToolIcon:=nil;

  if NOT SDL_Init(SDL_INIT_VIDEO OR SDL_INIT_GAMEPAD) then
    raise Exception.CreateFmt('SDL_Init failed: %s', [String(SDL_GetError)]);

  try
    Window:=SDL_CreateWindow('PasSDL3-GUI shop menu', 1100, 680, 0);
    if NOT Assigned(Window) then
      raise Exception.CreateFmt('SDL_CreateWindow failed: %s', [String(SDL_GetError)]);

    SDL_StartTextInput(Window);

    Renderer:=SDL_CreateRenderer(Window, nil);
    if NOT Assigned(Renderer) then
      raise Exception.CreateFmt('SDL_CreateRenderer failed: %s', [String(SDL_GetError)]);

    Context:=TGuiContext.Create;
    Context.Resize(1100, 680);
    Host:=TGuiSDL3Host.Create(Renderer, Context);
    Canvas:=Host.Canvas;
    FontRenderer:=TGuiSDLTTFFontRenderer.Create(GuiDefaultFontFile, 18);
    Canvas.FontRenderer:=FontRenderer;

    WeaponIcon:=CreateIconTexture(Renderer, GuiColor(92, 56, 60), GuiColor(235, 118, 96));
    ArmorIcon:=CreateIconTexture(Renderer, GuiColor(55, 70, 88), Theme.SecondaryAccent);
    GearIcon:=CreateIconTexture(Renderer, GuiColor(58, 72, 66), Theme.PrimaryAccent);
    PotionIcon:=CreateIconTexture(Renderer, GuiColor(57, 50, 82), GuiColor(174, 132, 235));
    RelicIcon:=CreateIconTexture(Renderer, GuiColor(78, 68, 42), Theme.PriceText);
    ToolIcon:=CreateIconTexture(Renderer, GuiColor(67, 60, 54), GuiColor(213, 160, 100));

    Header:=AddPanel(Context.Root, GuiRect(32, 28, 1036, 78), Theme.PanelBackground, Theme.PanelBorder);
    AddLabel(Header, 'Armory Shop', GuiRect(22, 12, 240, 34), Theme.Text);

    CurrencyLabel:=AddRoleLabel(Header, 'Coins: 320', GuiRect(830, 22, 180, 34), 'Price', ghtaRight);

    Content:=AddPanel(Context.Root, GuiRect(32, 126, 720, 506), Theme.SurfaceBackground, GuiColor(64, 76, 94));
    Content.StyleClass:='Surface';
    AddLabel(Content, 'Featured Items', GuiRect(20, 16, 220, 30), GuiColor(232, 238, 247));

    ScrollBox:=TGuiScrollBox.Create;
    ScrollBox.Bounds:=GuiRect(16, 56, 688, 430);
    Content.Add(ScrollBox);

    ItemGrid:=TGuiGridPanel.Create;
    ItemGrid.Columns:=3;
    ItemGrid.CellWidth:=220;
    ItemGrid.CellHeight:=178;
    ItemGrid.ColumnSpacing:=10;
    ItemGrid.RowSpacing:=16;
    ItemGrid.Bounds:=GuiRect(4, 0, 680, 0);
    ScrollBox.Add(ItemGrid);

    StatusLabel:=AddLabel(Context.Root, 'Select an item to buy.', GuiRect(790, 570, 240, 34), GuiColor(205, 215, 229));
    Handler:=TShopHandlers.Create(StatusLabel, CurrencyLabel, ItemGrid, ScrollBox, 320);

    CategoryBar:=TGuiStackPanel.Create;
    CategoryBar.Bounds:=GuiRect(22, 42, 420, 30);
    CategoryBar.Orientation:=goHorizontal;
    CategoryBar.Spacing:=8;
    CategoryBar.AutoSizeToContent:=False;
    Header.Add(CategoryBar);
    AddCategoryButton(CategoryBar, 'All', 'All', True, Handler);
    AddCategoryButton(CategoryBar, 'Weapons', 'Weapon', False, Handler);
    AddCategoryButton(CategoryBar, 'Armor', 'Armor', False, Handler);
    AddCategoryButton(CategoryBar, 'Potions', 'Potion', False, Handler);
    AddCategoryButton(CategoryBar, 'Relics', 'Relic', False, Handler);

    AddItemCard(ItemGrid, 'Iron Sword', 'Weapon', '+8 Attack', 90, WeaponIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Oak Shield', 'Armor', '+5 Defense', 75, ArmorIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Swift Boots', 'Gear', '+12 Speed', 130, GearIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Fire Wand', 'Weapon', '+16 Magic', 210, WeaponIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Health Flask', 'Potion', 'Restores 50 HP', 45, PotionIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Moon Charm', 'Relic', '+3 Luck', 160, RelicIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Frost Axe', 'Weapon', '+14 Attack', 185, WeaponIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Guard Helm', 'Armor', '+7 Defense', 110, ArmorIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Star Ring', 'Relic', '+6 Magic', 155, RelicIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Smoke Bomb', 'Tool', 'Escape chance', 65, ToolIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Mana Tonic', 'Potion', 'Restores 40 MP', 55, PotionIcon, Theme, Handler);
    AddItemCard(ItemGrid, 'Hunter Bow', 'Weapon', '+11 Attack', 140, WeaponIcon, Theme, Handler);

    Details:=AddPanel(Context.Root, GuiRect(784, 126, 284, 420), GuiColor(31, 37, 46), GuiColor(78, 92, 112));
    Details.StyleClass:='Surface';
    DetailsStack:=TGuiStackPanel.Create;
    DetailsStack.Bounds:=GuiRect(22, 20, 232, 0);
    DetailsStack.Spacing:=14;
    Details.Add(DetailsStack);

    AddLabel(DetailsStack, 'Item Details', GuiRect(0, 0, 232, 32), Theme.Text);
    AddRoleLabel(DetailsStack, 'Category toggles now filter visible shop cards.', GuiRect(0, 0, 232, 64), 'Muted');
    DetailList:=TGuiListBox.Create;
    DetailList.Bounds:=GuiRect(0, 0, 232, 112);
    DetailList.AddItem('Overview');
    DetailList.AddItem('Stats');
    DetailList.AddItem('Compare');
    DetailList.OnSelect:=Handler.DetailSelected;
    DetailsStack.Add(DetailList);
    AddRoleLabel(DetailsStack, 'The list box is a generic selectable control, not shop-specific.', GuiRect(0, 0, 232, 84), 'Success');
    GuiApplyTheme(Context.Root, Theme);

    Running:=True;
    while Running do
    begin
      while SDL_PollEvent(@SdlEvent) do
      begin
        if TSDL_EventType(SdlEvent.type_) = SDL_EVENT_QUIT then
          Running:=False
        else
          Host.ProcessEvent(SdlEvent);
      end;

      SDL_SetRenderDrawColor(Renderer, Theme.WindowBackground.R, Theme.WindowBackground.G, Theme.WindowBackground.B, Theme.WindowBackground.A);
      SDL_RenderClear(Renderer);
      Host.Render;
      SDL_RenderPresent(Renderer);
      SDL_Delay(16);
      if FindCmdLineSwitch('smoke-test') then Running:=False;
    end;
  finally
    Handler.Free;
    if Assigned(ToolIcon) then
      SDL_DestroyTexture(ToolIcon);

    if Assigned(RelicIcon) then
      SDL_DestroyTexture(RelicIcon);

    if Assigned(PotionIcon) then
      SDL_DestroyTexture(PotionIcon);

    if Assigned(GearIcon) then
      SDL_DestroyTexture(GearIcon);

    if Assigned(ArmorIcon) then
      SDL_DestroyTexture(ArmorIcon);

    if Assigned(WeaponIcon) then
      SDL_DestroyTexture(WeaponIcon);

    FontRenderer.Free;
    Host.Free;
    Context.Free;

    if Assigned(Renderer) then
      SDL_DestroyRenderer(Renderer);

    if Assigned(Window) then
    begin
      SDL_StopTextInput(Window);
      SDL_DestroyWindow(Window);
    end;

    SDL_Quit;
  end;
end.
