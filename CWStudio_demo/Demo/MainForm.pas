//////////////////////////////////////////////////////////////////////////
//
//   CWStudio Component Library — Demo Application
//   Created by Czesław Włudarczyk 2026 CWStudio
//
//   This unit builds the entire demo UI programmatically so that the
//   source itself documents how each CWStudio component is used.
//
//   All icons are rendered using the "Segoe MDL2 Assets" font (built
//   into Windows 10/11). Glyph codepoints belong to the Unicode
//   Private Use Area (U+E000–U+F8FF).
//
//   Every control is themed dynamically — the form walks its own
//   control tree on every theme change and recolours every label,
//   panel, button and input from the active Fluent palette.
//
//   Label theming "role" is encoded into TLabel.Tag:
//       0 = primary text          (flNeutralForeground1)
//       1 = secondary text        (flNeutralForeground2)
//       2 = muted / tertiary text (flNeutralForeground3)
//      90 = icon label — custom color, do NOT override
//      99 = theme-locked control  (no re-theming at all)
//
//////////////////////////////////////////////////////////////////////////
unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.UITypes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  CWSFluentColorsMulti,
  CWSCornerPanel, CWSButton, CWSMenuButton, CWSStoreButton,
  CWSEdit, CWSComboBox, CWSMemo, CWSDatePicker,
  CWSProgressCircle, CWSScrollBox, CWSSettingsPanel,
  CWSDimOverlay, CWSAfterFormShow;

type
  TfrmDemo = class(TForm)
    DimOverlay: TCWSDimOverlay;
    AfterShow: TCWSAfterFormShow;
    AnimTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure AfterShowAfterShow(Sender: TObject);
    procedure AnimTimerTimer(Sender: TObject);
  strict private
    FSidebar:        TPanel;
    FSidebarSplit:   TPanel;          // 1-px vertical separator
    FContent:        TPanel;
    FHeader:         TPanel;
    // TCWSButton's color setters intentionally flip ButtonStyle to bsCustom
    // (for the IDE designer). At runtime that destroys the original style
    // after the first re-theme, so we remember it here before the first
    // ApplyTheme and look it up during every subsequent re-theme.
    FButtonStyles:   TDictionary<TCWSButton, TCWSButtonStyle>;
    FLblTitle:       TLabel;
    FLblSubtitle:    TLabel;
    FNavButtons:     array of TCWSMenuButton;
    FPages:          array of TCWSScrollBox;
    FCurrentPage:    Integer;
    FThemeButton:    TCWSButton;
    FProgressCircle: TCWSProgressCircle;
    FProgressDir:    Integer;
    FDemoDialog:     TForm;

    // --- building -------------------------------------------------------
    procedure BuildLayout;
    procedure BuildSidebar;
    procedure BuildPages;

    procedure BuildHomePage      (APage: TWinControl);
    procedure BuildButtonsPage   (APage: TWinControl);
    procedure BuildInputsPage    (APage: TWinControl);
    procedure BuildPickersPage   (APage: TWinControl);
    procedure BuildProgressPage  (APage: TWinControl);
    procedure BuildContainersPage(APage: TWinControl);
    procedure BuildOverlayPage   (APage: TWinControl);
    procedure BuildAboutPage     (APage: TWinControl);

    procedure ShowPage(AIndex: Integer);

    // --- theming --------------------------------------------------------
    procedure HandleThemeChange;
    procedure ApplyTheme;
    procedure RethemeControl(C: TControl);
    function  ParentBgColor    (C: TControl): TColor;
    procedure RememberButtonStyles;
    procedure RethemeButton     (B: TCWSButton);
    procedure RethemeMenuButton (B: TCWSMenuButton);
    procedure RethemeStoreButton(B: TCWSStoreButton);
    procedure RethemeEdit       (E: TCWSEdit);
    procedure RethemeMemo       (M: TCWSMemo);
    procedure RethemeComboBox   (C: TCWSComboBox);
    procedure RethemeDatePicker (D: TCWSDatePicker);
    procedure RethemeProgress   (P: TCWSProgressCircle);
    procedure UpdateThemeButton;

    // --- event handlers -------------------------------------------------
    procedure NavClick(Sender: TObject);
    procedure ThemeClick(Sender: TObject);
    procedure ShowDimDialogClick(Sender: TObject);
    procedure CloseDimDialog(Sender: TObject);
    procedure FavoriteClick(Sender: TObject);
    procedure DonateClick(Sender: TObject);

    // --- factories ------------------------------------------------------
    function AddNav(AParent: TWinControl; ATop: Integer;
      const AGlyph, AGlyphSelected, ACaption: string;
      AGroupIndex, AIndex: Integer): TCWSMenuButton;
    function AddSection(AParent: TWinControl; ATop, AHeight: Integer;
      const ATitle: string): TCWSCornerPanel;
    function AddSectionLabel(AParent: TWinControl; const ATitle: string): TLabel;
    function AddBodyLabel(AParent: TWinControl; AX, AY, AW, AH: Integer;
      const AText: string; ASize: Integer = 10; ARole: Integer = 0): TLabel;
    function AddIconLabel(AParent: TWinControl; AX, AY, ASize: Integer;
      const AGlyph: string; AColor: TColor): TLabel;
    function AddButton(AParent: TWinControl; AX, AY: Integer;
      const ACaption, AGlyph: string;
      AStyle: TCWSButtonStyle = bsNeutral;
      AWidth: Integer = 150): TCWSButton;
  public
  end;

var
  frmDemo: TfrmDemo;

implementation

{$R *.dfm}

const
  // ─── Segoe MDL2 Assets glyphs (Private Use Area) ──────────────────────
  // outline / regular
  ICON_HOME       = #$E80F;
  ICON_BUTTONS    = #$E7C4;
  ICON_INPUTS     = #$E932;
  ICON_PICKERS    = #$E787;
  ICON_PROGRESS   = #$E9F5;
  ICON_CONTAINERS = #$E80A;
  ICON_OVERLAY    = #$E78B;
  ICON_ABOUT      = #$E946;
  ICON_USER       = #$E77B;
  ICON_MAIL       = #$E715;
  ICON_PHONE      = #$E717;
  ICON_LOCK       = #$E72E;
  ICON_DELETE     = #$E74D;
  ICON_DOWNLOAD   = #$E896;
  ICON_FAVORITE   = #$E734;
  ICON_PALETTE    = #$E790;
  ICON_GLOBE      = #$E774;
  ICON_WARNING    = #$E7BA;
  ICON_HEART      = #$EB51;
  ICON_SEARCH     = #$E721;
  ICON_CLEAR      = #$E894;
  ICON_SAVE       = #$E74E;
  ICON_OK         = #$E73E;
  ICON_CANCEL     = #$E711;
  ICON_ADD        = #$E710;
  ICON_REFRESH    = #$E72C;
  ICON_SETTINGS   = #$E713;
  ICON_SUN        = #$E706;
  ICON_MOON       = #$E708;

  // solid / selected variants (where a clean filled glyph exists in MDL2)
  ICON_HOME_S     = #$EA8A; // HomeSolid
  ICON_BUTTONS_S  = #$E7C4; // (no solid variant — keep)
  ICON_INPUTS_S   = #$E932; // (no solid variant — keep)
  ICON_PICKERS_S  = #$EA89; // CalendarSolid
  ICON_PROGRESS_S = #$E9F5; // (no solid variant — keep)
  ICON_CONTAINERS_S = #$E80A; // (no solid variant — keep)
  ICON_OVERLAY_S  = #$E78B; // (no solid variant — keep)
  ICON_ABOUT_S    = #$F167; // InfoSolid
  ICON_USER_S     = #$EA8C; // ContactSolid
  ICON_MAIL_S     = #$E8A5; // ReadingMode → use this as a "selected" mail
  ICON_SETTINGS_S = #$E713; // (no solid — keep)
  ICON_DELETE_S   = #$E74D; // (no solid — keep)
  ICON_FAVORITE_F = #$E735; // FavoriteStarFill
  ICON_HEART_F    = #$EB52; // HeartFill

  // ─── Layout constants ────────────────────────────────────────────────
  SIDEBAR_W = 240;
  HEADER_H  = 90;

  PAGE_TITLES: array[0..7] of string = (
    'Home',
    'Buttons',
    'Input Controls',
    'Pickers',
    'Progress',
    'Containers',
    'Dim Overlay & Dialog',
    'About'
  );
  PAGE_SUBTITLES: array[0..7] of string = (
    'Welcome to the CWStudio component showcase',
    'TCWSButton, TCWSMenuButton, TCWSStoreButton',
    'TCWSEdit and TCWSMemo',
    'TCWSComboBox and TCWSDatePicker',
    'TCWSProgressCircle with live animation',
    'TCWSCornerPanel, TCWSSettingsPanel, TCWSScrollBox',
    'TCWSDimOverlay — modal dimming made easy',
    'About the CWStudio library'
  );

  // Tag values denoting label "role" — see unit header.
  TAG_PRIMARY   = 0;
  TAG_SECONDARY = 1;
  TAG_MUTED     = 2;
  TAG_ICON      = 90;
  TAG_LOCKED    = 99;

{ ════════════════════════════════════════════════════════════════════════
                              Form lifecycle
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.FormCreate(Sender: TObject);
begin
  Caption        := 'CWStudio Component Library - Demo';
  Width          := 1180;
  Height         := 760;
  Position       := poScreenCenter;
  Font.Name      := 'Segoe UI';
  Font.Size      := 9;
  DoubleBuffered := True;

  FButtonStyles := TDictionary<TCWSButton, TCWSButtonStyle>.Create;

  FluentApplySystemTheme;
  RegisterThemeChange(HandleThemeChange);

  BuildLayout;
  BuildSidebar;
  BuildPages;
  ShowPage(0);

  RememberButtonStyles;   // snapshot every button's style before re-theming
  ApplyTheme;
end;

procedure TfrmDemo.FormDestroy(Sender: TObject);
begin
  UnregisterThemeChange(HandleThemeChange);
  FButtonStyles.Free;
end;

procedure TfrmDemo.RememberButtonStyles;

  procedure Walk(C: TControl);
  var
    I: Integer;
    WC: TWinControl;
  begin
    if C is TCWSButton then
      FButtonStyles.AddOrSetValue(TCWSButton(C), TCWSButton(C).ButtonStyle);
    if C is TWinControl then
    begin
      WC := TWinControl(C);
      for I := 0 to WC.ControlCount - 1 do
        Walk(WC.Controls[I]);
    end;
  end;

var
  I: Integer;
begin
  FButtonStyles.Clear;
  for I := 0 to ControlCount - 1 do
    Walk(Controls[I]);
end;

procedure TfrmDemo.FormResize(Sender: TObject);
var
  I: Integer;
begin
  if Assigned(FHeader) then
  begin
    if Assigned(FLblTitle) then
      FLblTitle.Width := FHeader.ClientWidth - 40;
    if Assigned(FLblSubtitle) then
      FLblSubtitle.Width := FHeader.ClientWidth - 40;
  end;
  for I := 0 to High(FPages) do
    if Assigned(FPages[I]) then
    begin
      FPages[I].Width  := ClientWidth - SIDEBAR_W;
      FPages[I].Height := ClientHeight - HEADER_H;
    end;
end;

procedure TfrmDemo.AfterShowAfterShow(Sender: TObject);
begin
  AnimTimer.Enabled := True;
end;

{ ════════════════════════════════════════════════════════════════════════
                                Theming
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.ThemeClick(Sender: TObject);
begin
  if FluentThemeMode = ftmLight then
    FluentSetDarkMode(True)
  else
    FluentSetDarkMode(False);
end;

procedure TfrmDemo.HandleThemeChange;
begin
  ApplyTheme;
end;

procedure TfrmDemo.ApplyTheme;
var
  I: Integer;
begin
  // Top-level surfaces ------------------------------------------------
  Color := flNeutralBackground1;

  // The sidebar uses the SAME color as the form. Any control sitting on
  // the sidebar (menubuttons, theme button) can therefore safely set
  // `Color := flNeutralBackground1` and have its rounded-shape corners
  // blend perfectly. The two surfaces are visually separated by a
  // 1-pixel vertical line (FSidebarSplit) rather than a colour change.
  if Assigned(FSidebar) then
  begin
    FSidebar.Color       := flNeutralBackground1;
    FSidebar.ParentColor := False;
  end;
  if Assigned(FSidebarSplit) then
  begin
    FSidebarSplit.Color       := flNeutralStroke2;
    FSidebarSplit.ParentColor := False;
  end;
  if Assigned(FHeader) then
  begin
    FHeader.Color       := flNeutralBackground1;
    FHeader.ParentColor := False;
  end;
  if Assigned(FContent) then
  begin
    FContent.Color       := flNeutralBackground1;
    FContent.ParentColor := False;
  end;

  for I := 0 to High(FPages) do
    if Assigned(FPages[I]) then
    begin
      FPages[I].BackgroundColor := flNeutralBackground1;
      FPages[I].ShowBorder      := False;
      FPages[I].ScrollThumbColor      := flNeutralStroke1;
      FPages[I].ScrollThumbHoverColor := flBrandBackground;
    end;

  // Walk the entire form recursively and recolour every component -----
  for I := 0 to ControlCount - 1 do
    RethemeControl(Controls[I]);

  UpdateThemeButton;
  Invalidate;
end;

procedure TfrmDemo.RethemeControl(C: TControl);
var
  I: Integer;
  WC: TWinControl;
begin
  if C.Tag = TAG_LOCKED then
    Exit;

  // Labels — coloured by role tag
  if C is TLabel then
  begin
    case C.Tag of
      TAG_PRIMARY:   TLabel(C).Font.Color := flNeutralForeground1;
      TAG_SECONDARY: TLabel(C).Font.Color := flNeutralForeground2;
      TAG_MUTED:     TLabel(C).Font.Color := flNeutralForeground3;
      TAG_ICON:      ; // keep its custom colour
    end;
  end

  // TCWSCornerPanel — used as "section card" everywhere
  else if C is TCWSCornerPanel then
  begin
    TCWSCornerPanel(C).Color           := flNeutralCardBackground;
    TCWSCornerPanel(C).CornerColor     := flNeutralStroke1;
    TCWSCornerPanel(C).ParentBackground := False;
  end

  else if C is TCWSSettingsPanel then
  begin
    TCWSSettingsPanel(C).FillColor   := flNeutralCardBackground;
    TCWSSettingsPanel(C).BorderColor := flNeutralStroke1;
  end

  else if C is TCWSButton      then begin RethemeButton     (TCWSButton(C));      Exit; end
  else if C is TCWSMenuButton  then begin RethemeMenuButton (TCWSMenuButton(C));  Exit; end
  else if C is TCWSStoreButton then begin RethemeStoreButton(TCWSStoreButton(C)); Exit; end
  else if C is TCWSEdit        then begin RethemeEdit       (TCWSEdit(C));        Exit; end
  else if C is TCWSMemo        then begin RethemeMemo       (TCWSMemo(C));        Exit; end
  else if C is TCWSComboBox    then begin RethemeComboBox   (TCWSComboBox(C));    Exit; end
  else if C is TCWSDatePicker  then begin RethemeDatePicker (TCWSDatePicker(C));  Exit; end
  else if C is TCWSProgressCircle then begin RethemeProgress(TCWSProgressCircle(C)); Exit; end
  else if (C is TPanel) and (C <> FSidebar) and (C <> FHeader) and (C <> FContent) then
  begin
    TPanel(C).Color       := flNeutralBackground1;
    TPanel(C).ParentColor := False;
  end;

  // Recurse into children — but NEVER into our own components, otherwise we
  // would touch their private TLabel/TEdit children (e.g. TCWSButton's
  // FLabelCaption) and overwrite the color the component set up itself.
  if C is TWinControl then
  begin
    WC := TWinControl(C);
    for I := 0 to WC.ControlCount - 1 do
      RethemeControl(WC.Controls[I]);
  end;
end;

procedure TfrmDemo.RethemeButton(B: TCWSButton);
var
  OriginalStyle: TCWSButtonStyle;
begin
  // Outer Color (TCustomControl bg around the rounded shape) — match parent
  B.Color := ParentBgColor(B);

  // Read the style from our dictionary, NOT from B.ButtonStyle — every
  // color setter in TCWSButton intentionally flips FButtonStyle to
  // bsCustom (for the IDE designer), so after the first re-theme the
  // button's runtime ButtonStyle no longer matches what we created it as.
  if not FButtonStyles.TryGetValue(B, OriginalStyle) then
    OriginalStyle := B.ButtonStyle;

  if OriginalStyle = bsPrimary then
  begin
    B.BckNormalColor      := flBrandBackground;
    B.BckHoverColor       := flBrandBackgroundHover;
    B.BckPressedColor     := flBrandBackgroundPressed;
    B.BorderColorNormal   := flBrandBackground;
    B.BorderColorHover    := flBrandBackgroundHover;
    B.BorderColorPressed  := flBrandBackgroundPressed;
    B.CaptionColorNormal  := clWhite;
    B.CaptionColorHover   := clWhite;
    B.CaptionColorPressed := clWhite;
    B.IconColorNormal     := clWhite;
    B.IconColorHover      := clWhite;
    B.IconColorPressed    := clWhite;
  end
  else
  begin
    B.BckNormalColor      := flNeutralCardBackground;
    B.BckHoverColor       := flSubtleBackgroundHover;
    B.BckPressedColor     := flSubtleBackgroundPressed;
    B.BorderColorNormal   := flNeutralStroke1;
    B.BorderColorHover    := flNeutralStroke1;
    B.BorderColorPressed  := flNeutralStroke2;
    B.CaptionColorNormal  := flNeutralForeground1;
    B.CaptionColorHover   := flNeutralForeground1;
    B.CaptionColorPressed := flNeutralForeground1;
    B.IconColorNormal     := flNeutralForeground1;
    B.IconColorHover      := flNeutralForeground1;
    B.IconColorPressed    := flNeutralForeground1;
  end;
  B.BckDisabledColor     := flNeutralBackground3;
  B.BorderColorDisabled  := flNeutralStroke2;
  B.CaptionColorDisabled := flNeutralForeground4;
  B.IconColorDisabled    := flNeutralForeground4;
end;

function TfrmDemo.ParentBgColor(C: TControl): TColor;
begin
  if (C = nil) or (C.Parent = nil) then
    Exit(flNeutralBackground1);
  // Sidebar shares the form colour, so anything on the sidebar uses the
  // same neutral background — rounded-shape corners blend cleanly.
  if C.Parent = FSidebar then
    Result := flNeutralBackground1
  else if C.Parent is TCWSCornerPanel then
    Result := flNeutralCardBackground
  else if C.Parent is TCWSSettingsPanel then
    Result := flNeutralCardBackground
  else if C.Parent is TPanel then
    Result := TPanel(C.Parent).Color
  else
    Result := flNeutralBackground1;
end;

procedure TfrmDemo.RethemeMenuButton(B: TCWSMenuButton);
var
  Bg: TColor;
begin
  Bg      := ParentBgColor(B);
  B.Color := Bg;
  // Nav-style buttons blend with whatever surface they sit on at rest.
  B.BckNormalColor       := Bg;
  // Hover & selected colours that contrast clearly in BOTH light and dark
  // modes — flSubtleBackgroundHover equals the sidebar background in
  // light mode (both #F5F5F5), so it would be invisible there.
  B.BckHoverColor        := flSubtleBackgroundPressed;   // L #E0E0E0 / D #2E2E2E
  B.BckPressedColor      := flSubtleBackgroundSelected;  // L #EBEBEB / D #333333
  B.CursorColor          := flBrandBackground;
  B.CursorHeight         := 20;
  B.IconColorNormal      := flNeutralForeground2;
  B.IconColorHover       := flNeutralForeground1;
  B.IconColorPressed     := flBrandForegroundLink;
  B.MenuColorTextNormal  := flNeutralForeground2;
  B.MenuColorTextHover   := flNeutralForeground1;
  B.MenuColorTextPressed := flNeutralForeground1;
end;

procedure TfrmDemo.RethemeStoreButton(B: TCWSStoreButton);
begin
  B.Color                       := ParentBgColor(B);
  B.BckNormalColor              := flNeutralCardBackground;
  B.BckHoverColor               := flNeutralCardBackgroundHover;
  B.BckPressedColor             := flNeutralCardBackgroundSelected;
  B.CursorColor                 := flBrandBackground;
  B.IconColorNormal             := flNeutralForeground2;
  B.IconColorHover              := flNeutralForeground1;
  B.IconColorPressed            := flBrandForegroundLink;
  B.DescriptionColorNormal      := flNeutralForeground2;
  B.DescriptionColorHover       := flNeutralForeground1;
  B.DescriptionColorPressed     := flNeutralForeground1;
end;

procedure TfrmDemo.RethemeEdit(E: TCWSEdit);
begin
  E.BackgroundColor      := flNeutralCardBackground;
  E.BackgroundHoverColor := flNeutralBackground2;
  E.BackgroundFocusColor := flNeutralCardBackground;
  E.BorderColor          := flNeutralStroke1;
  E.DisabledColor        := flNeutralBackground3;
  E.DisabledBorderColor  := flNeutralStroke2;
  E.LabelColor           := flNeutralForeground2;
  E.AccentColor          := flBrandBackground;
  E.ButtonIconColor      := flNeutralForeground2;
  E.ButtonHoverColor     := flSubtleBackgroundHover;
  E.Font.Color           := flNeutralForeground1;
end;

procedure TfrmDemo.RethemeMemo(M: TCWSMemo);
begin
  M.BackgroundColor       := flNeutralCardBackground;
  M.BackgroundHoverColor  := flNeutralBackground2;
  M.BackgroundFocusColor  := flNeutralCardBackground;
  M.BorderColor           := flNeutralStroke1;
  M.LabelColor            := flNeutralForeground2;
  M.AccentColor           := flBrandBackground;
  M.ScrollThumbColor      := flNeutralStroke1;
  M.ScrollThumbHoverColor := flBrandBackground;
  M.Font.Color            := flNeutralForeground1;
end;

procedure TfrmDemo.RethemeComboBox(C: TCWSComboBox);
begin
  C.BackgroundColor                  := flNeutralCardBackground;
  C.BackgroundHoverColor             := flNeutralBackground2;
  C.BorderColor                      := flNeutralStroke1;
  C.DisabledColor                    := flNeutralBackground3;
  C.DisabledBorderColor              := flNeutralStroke2;
  C.TextColor                        := flNeutralForeground1;
  C.DisabledTextColor                := flNeutralForeground4;
  C.AccentColor                      := flBrandBackground;
  C.DropdownBackColor                := flNeutralCardBackground;
  C.DropdownBorderColor              := flNeutralStroke1;
  C.ItemHighlightColor               := flSubtleBackgroundHover;
  C.ItemHighlightPressedColor        := flSubtleBackgroundPressed;
  C.ItemHighlightTextColor           := flNeutralForeground1;
  C.ItemNormalTextColor              := flNeutralForeground1;
  C.ScrollbarThumbColor              := flNeutralStroke1;
  C.ScrollbarThumbHoverColor         := flBrandBackground;
end;

procedure TfrmDemo.RethemeDatePicker(D: TCWSDatePicker);
begin
  D.BackgroundColor      := flNeutralCardBackground;
  D.BackgroundHoverColor := flNeutralBackground2;
  D.BorderColor          := flNeutralStroke1;
  D.DisabledColor        := flNeutralBackground3;
  D.DisabledBorderColor  := flNeutralStroke2;
  D.TextColor            := flNeutralForeground1;
  D.DisabledTextColor    := flNeutralForeground4;
  D.AccentColor          := flBrandBackground;
  D.DropdownBackColor    := flNeutralCardBackground;
  D.TodayBorderColor     := flBrandBackground;
  D.SelectedDayColor     := flBrandBackground;
  D.SelectedDayTextColor := clWhite;
  D.HoverColor           := flSubtleBackgroundHover;
end;

procedure TfrmDemo.RethemeProgress(P: TCWSProgressCircle);
begin
  // The constructor hard-codes Color := clWhite (CWSProgressCircle.pas:139)
  // and the Paint routine fills the bitmap with Self.Color before drawing
  // the ring (lines 430–431). Without resetting Color the control would
  // always show a white square on dark themes, and white TextColor would
  // then disappear against it.
  P.Color      := ParentBgColor(P);
  P.TrackColor := flNeutralStroke2;
  P.TextColor  := flNeutralForeground1;
end;

procedure TfrmDemo.UpdateThemeButton;
begin
  if not Assigned(FThemeButton) then
    Exit;
  if FluentThemeMode = ftmLight then
  begin
    FThemeButton.Caption   := 'Dark mode';
    FThemeButton.IconGlyph := ICON_MOON;
  end
  else
  begin
    FThemeButton.Caption   := 'Light mode';
    FThemeButton.IconGlyph := ICON_SUN;
  end;
  FThemeButton.IconGlyphPressed := FThemeButton.IconGlyph;
end;

{ ════════════════════════════════════════════════════════════════════════
                            Layout building
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildLayout;
begin
  FSidebar := TPanel.Create(Self);
  FSidebar.Parent     := Self;
  FSidebar.Align      := alLeft;
  FSidebar.Width      := SIDEBAR_W;
  FSidebar.BevelOuter := bvNone;

  // 1-pixel vertical line that separates the sidebar from the content
  // area without changing the background colour.
  FSidebarSplit := TPanel.Create(Self);
  FSidebarSplit.Parent     := Self;
  FSidebarSplit.Align      := alLeft;
  FSidebarSplit.Width      := 1;
  FSidebarSplit.BevelOuter := bvNone;

  FContent := TPanel.Create(Self);
  FContent.Parent     := Self;
  FContent.Align      := alClient;
  FContent.BevelOuter := bvNone;

  FHeader := TPanel.Create(Self);
  FHeader.Parent     := FContent;
  FHeader.Align      := alTop;
  FHeader.Height     := HEADER_H;
  FHeader.BevelOuter := bvNone;

  FLblTitle := TLabel.Create(Self);
  FLblTitle.Parent     := FHeader;
  FLblTitle.SetBounds(24, 18, 800, 32);
  FLblTitle.Caption    := PAGE_TITLES[0];
  FLblTitle.Font.Name  := 'Segoe UI';
  FLblTitle.Font.Size  := 22;
  FLblTitle.Font.Style := [fsBold];
  FLblTitle.Tag        := TAG_PRIMARY;
  FLblTitle.Transparent := True;

  FLblSubtitle := TLabel.Create(Self);
  FLblSubtitle.Parent     := FHeader;
  FLblSubtitle.SetBounds(24, 56, 800, 20);
  FLblSubtitle.Caption    := PAGE_SUBTITLES[0];
  FLblSubtitle.Font.Name  := 'Segoe UI';
  FLblSubtitle.Font.Size  := 10;
  FLblSubtitle.Tag        := TAG_SECONDARY;
  FLblSubtitle.Transparent := True;
end;

procedure TfrmDemo.BuildSidebar;
var
  AppLabel: TLabel;
  Subtitle: TLabel;
begin
  AppLabel := TLabel.Create(Self);
  AppLabel.Parent      := FSidebar;
  AppLabel.SetBounds(20, 22, 200, 28);
  AppLabel.Caption     := 'CWStudio';
  AppLabel.Font.Name   := 'Segoe UI';
  AppLabel.Font.Size   := 17;
  AppLabel.Font.Style  := [fsBold];
  AppLabel.Tag         := TAG_PRIMARY;
  AppLabel.Transparent := True;

  Subtitle := TLabel.Create(Self);
  Subtitle.Parent      := FSidebar;
  Subtitle.SetBounds(20, 52, 200, 18);
  Subtitle.Caption     := 'Component Library';
  Subtitle.Font.Name   := 'Segoe UI';
  Subtitle.Font.Size   := 9;
  Subtitle.Tag         := TAG_MUTED;
  Subtitle.Transparent := True;

  SetLength(FNavButtons, 8);
  FNavButtons[0] := AddNav(FSidebar,  96, ICON_HOME,       ICON_HOME_S,       'Home',         1, 0);
  FNavButtons[1] := AddNav(FSidebar, 140, ICON_BUTTONS,    ICON_BUTTONS_S,    'Buttons',      1, 1);
  FNavButtons[2] := AddNav(FSidebar, 184, ICON_INPUTS,     ICON_INPUTS_S,     'Inputs',       1, 2);
  FNavButtons[3] := AddNav(FSidebar, 228, ICON_PICKERS,    ICON_PICKERS_S,    'Pickers',      1, 3);
  FNavButtons[4] := AddNav(FSidebar, 272, ICON_PROGRESS,   ICON_PROGRESS_S,   'Progress',     1, 4);
  FNavButtons[5] := AddNav(FSidebar, 316, ICON_CONTAINERS, ICON_CONTAINERS_S, 'Containers',   1, 5);
  FNavButtons[6] := AddNav(FSidebar, 360, ICON_OVERLAY,    ICON_OVERLAY_S,    'Dim Overlay',  1, 6);
  FNavButtons[7] := AddNav(FSidebar, 404, ICON_ABOUT,      ICON_ABOUT_S,      'About',        1, 7);
  FNavButtons[0].Pressed := True;

  FThemeButton := TCWSButton.Create(Self);
  FThemeButton.Parent       := FSidebar;
  FThemeButton.SetBounds(20, ClientHeight - 80, SIDEBAR_W - 40, 36);
  FThemeButton.Anchors      := [akLeft, akBottom];
  FThemeButton.ButtonStyle  := bsNeutral;
  FThemeButton.IconFontName := 'Segoe MDL2 Assets';
  FThemeButton.IconFontSize := 14;
  FThemeButton.IconSpacing  := 10;
  FThemeButton.CornerRadius := 6;
  FThemeButton.OnClick      := ThemeClick;
end;

function TfrmDemo.AddNav(AParent: TWinControl; ATop: Integer;
  const AGlyph, AGlyphSelected, ACaption: string;
  AGroupIndex, AIndex: Integer): TCWSMenuButton;
begin
  Result := TCWSMenuButton.Create(Self);
  Result.Parent           := AParent;
  Result.SetBounds(12, ATop, SIDEBAR_W - 24, 38);
  Result.IconFontName     := 'Segoe MDL2 Assets';
  Result.IconFontSize     := 14;
  Result.IconGlyph        := AGlyph;
  Result.IconGlyphPressed := AGlyphSelected;
  Result.MenuText         := ACaption;
  Result.GroupIndex       := AGroupIndex;
  Result.Tag              := AIndex;
  Result.CursorHeight     := 18;
  Result.OnClick          := NavClick;
end;

procedure TfrmDemo.NavClick(Sender: TObject);
begin
  ShowPage(TCWSMenuButton(Sender).Tag);
end;

procedure TfrmDemo.BuildPages;
var
  I: Integer;

  function NewPage: TCWSScrollBox;
  begin
    Result := TCWSScrollBox.Create(Self);
    Result.Parent     := FContent;
    Result.SetBounds(0, HEADER_H, ClientWidth - SIDEBAR_W, ClientHeight - HEADER_H);
    Result.Anchors    := [akLeft, akTop, akRight, akBottom];
    Result.ShowBorder := False;
    Result.Visible    := False;
  end;

begin
  SetLength(FPages, 8);
  for I := 0 to High(FPages) do
    FPages[I] := NewPage;

  BuildHomePage      (FPages[0].ContentPanel);
  BuildButtonsPage   (FPages[1].ContentPanel);
  BuildInputsPage    (FPages[2].ContentPanel);
  BuildPickersPage   (FPages[3].ContentPanel);
  BuildProgressPage  (FPages[4].ContentPanel);
  BuildContainersPage(FPages[5].ContentPanel);
  BuildOverlayPage   (FPages[6].ContentPanel);
  BuildAboutPage     (FPages[7].ContentPanel);
end;

procedure TfrmDemo.ShowPage(AIndex: Integer);
var
  I: Integer;
begin
  if (AIndex < 0) or (AIndex > High(FPages)) then
    Exit;
  for I := 0 to High(FPages) do
    FPages[I].Visible := (I = AIndex);
  FCurrentPage := AIndex;
  FLblTitle.Caption    := PAGE_TITLES[AIndex];
  FLblSubtitle.Caption := PAGE_SUBTITLES[AIndex];
end;

{ ════════════════════════════════════════════════════════════════════════
                          Helper builders
  ════════════════════════════════════════════════════════════════════════ }

function TfrmDemo.AddSectionLabel(AParent: TWinControl;
  const ATitle: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent      := AParent;
  Result.Caption     := ATitle;
  Result.Font.Name   := 'Segoe UI';
  Result.Font.Size   := 12;
  Result.Font.Style  := [fsBold];
  Result.Tag         := TAG_PRIMARY;
  Result.Transparent := True;
end;

function TfrmDemo.AddBodyLabel(AParent: TWinControl; AX, AY, AW, AH: Integer;
  const AText: string; ASize: Integer; ARole: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent      := AParent;
  Result.SetBounds(AX, AY, AW, AH);
  Result.AutoSize    := False;
  Result.WordWrap    := True;
  Result.Caption     := AText;
  Result.Font.Name   := 'Segoe UI';
  Result.Font.Size   := ASize;
  Result.Tag         := ARole;
  Result.Transparent := True;
end;

function TfrmDemo.AddIconLabel(AParent: TWinControl; AX, AY, ASize: Integer;
  const AGlyph: string; AColor: TColor): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent       := AParent;
  Result.SetBounds(AX, AY, ASize + 10, ASize + 10);
  Result.AutoSize     := False;
  Result.Alignment    := taCenter;
  Result.Layout       := tlCenter;
  Result.Font.Name    := 'Segoe MDL2 Assets';
  Result.Font.Size    := ASize;
  Result.Font.Color   := AColor;
  Result.Caption      := AGlyph;
  Result.Tag          := TAG_ICON;
  Result.Transparent  := True;
end;

function TfrmDemo.AddSection(AParent: TWinControl; ATop, AHeight: Integer;
  const ATitle: string): TCWSCornerPanel;
var
  Lbl: TLabel;
begin
  Lbl := AddSectionLabel(AParent, ATitle);
  Lbl.SetBounds(20, ATop, 800, 22);

  Result := TCWSCornerPanel.Create(Self);
  Result.Parent           := AParent;
  Result.SetBounds(20, ATop + 30, 860, AHeight);
  Result.CornerSize       := 16;
  Result.CornerLineWidth  := 1;
  Result.ParentBackground := False;
end;

function TfrmDemo.AddButton(AParent: TWinControl; AX, AY: Integer;
  const ACaption, AGlyph: string; AStyle: TCWSButtonStyle;
  AWidth: Integer): TCWSButton;
begin
  Result := TCWSButton.Create(Self);
  Result.Parent           := AParent;
  Result.SetBounds(AX, AY, AWidth, 36);
  Result.ButtonStyle      := AStyle;
  Result.Caption          := ACaption;
  Result.IconFontName     := 'Segoe MDL2 Assets';
  Result.IconFontSize     := 13;
  Result.IconGlyph        := AGlyph;
  Result.IconGlyphPressed := AGlyph;
  Result.IconSpacing      := 8;
  Result.CornerRadius     := 6;
end;

{ ════════════════════════════════════════════════════════════════════════
                                HOME page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildHomePage(APage: TWinControl);
var
  StoreA, StoreB, StoreC: TCWSStoreButton;
  Lbl: TLabel;
begin
  AddBodyLabel(APage, 20, 20, 860, 80,
    'Welcome! This demo showcases the components shipped in the CWStudio package.' + sLineBreak +
    'All controls are styled to match Windows 11 / WinUI 3 and react automatically' + sLineBreak +
    'to the Light / Dark theme — try the switch at the bottom of the sidebar.',
    11, TAG_PRIMARY);

  Lbl := AddSectionLabel(APage, 'TCWSStoreButton — pick a feature to explore');
  Lbl.SetBounds(20, 120, 800, 22);

  StoreA := TCWSStoreButton.Create(Self);
  StoreA.Parent             := APage;
  StoreA.SetBounds(20, 150, 270, 120);
  StoreA.IconFontName       := 'Segoe MDL2 Assets';
  StoreA.IconFontSize       := 28;
  StoreA.IconGlyph          := ICON_PALETTE;
  StoreA.IconGlyphPressed   := ICON_PALETTE;
  StoreA.DescriptionText    := 'Fluent palette';
  StoreA.GroupIndex         := 10;
  StoreA.CursorHeight       := 28;
  StoreA.Pressed            := True;

  StoreB := TCWSStoreButton.Create(Self);
  StoreB.Parent             := APage;
  StoreB.SetBounds(305, 150, 270, 120);
  StoreB.IconFontName       := 'Segoe MDL2 Assets';
  StoreB.IconFontSize       := 28;
  StoreB.IconGlyph          := ICON_BUTTONS;
  StoreB.IconGlyphPressed   := ICON_BUTTONS;
  StoreB.DescriptionText    := 'Rich button set with icon glyphs';
  StoreB.GroupIndex         := 10;
  StoreB.CursorHeight       := 28;

  StoreC := TCWSStoreButton.Create(Self);
  StoreC.Parent             := APage;
  StoreC.SetBounds(590, 150, 270, 120);
  StoreC.IconFontName       := 'Segoe MDL2 Assets';
  StoreC.IconFontSize       := 28;
  StoreC.IconGlyph          := ICON_GLOBE;
  StoreC.IconGlyphPressed   := ICON_GLOBE;
  StoreC.DescriptionText    := 'Open Source. Free for any project';
  StoreC.GroupIndex         := 10;
  StoreC.CursorHeight       := 28;
end;

{ ════════════════════════════════════════════════════════════════════════
                              BUTTONS page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildButtonsPage(APage: TWinControl);
var
  Sec1, Sec2, Sec3: TCWSCornerPanel;
  TopBtn, RightBtn, BottomBtn: TCWSButton;
  FavBtn, DisBtn: TCWSButton;
  Mb: TCWSMenuButton;
begin
  // --- Section 1: styles -------------------------------------------------
  Sec1 := AddSection(APage, 20, 100, 'Styles');
  AddButton(Sec1, 20,  30, 'Primary',  ICON_OK,   bsPrimary);
  AddButton(Sec1, 190, 30, 'Neutral',  ICON_SAVE, bsNeutral);
  DisBtn := AddButton(Sec1, 360, 30, 'Disabled', ICON_LOCK, bsNeutral);
  DisBtn.Enabled := False;

  FavBtn := AddButton(Sec1, 530, 30, 'Favorite', ICON_FAVORITE, bsPrimary, 150);
  FavBtn.IconGlyphPressed := ICON_FAVORITE_F;
  FavBtn.OnClick := FavoriteClick;
  FavBtn.Tag := 0;

  // --- Section 2: icon positions ----------------------------------------
  Sec2 := AddSection(APage, 160, 140, 'Icon position');
  AddButton(Sec2, 20,  30, 'Left',  ICON_DOWNLOAD).IconPosition := ipLeft;

  RightBtn := AddButton(Sec2, 190, 30, 'Right', ICON_REFRESH);
  RightBtn.IconPosition := ipRight;

  TopBtn := AddButton(Sec2, 360, 20, 'Top', ICON_USER, bsNeutral, 110);
  TopBtn.IconPosition := ipTop;
  TopBtn.Height       := 80;
  TopBtn.IconFontSize := 22;
  TopBtn.IconGlyphPressed := ICON_USER_S;

  BottomBtn := AddButton(Sec2, 480, 20, 'Bottom', ICON_MAIL, bsNeutral, 110);
  BottomBtn.IconPosition := ipBottom;
  BottomBtn.Height       := 80;
  BottomBtn.IconFontSize := 22;
  BottomBtn.IconGlyphPressed := ICON_MAIL_S;

  // --- Section 3: TCWSMenuButton (radio behaviour via GroupIndex) -------
  Sec3 := AddSection(APage, 320, 220, 'TCWSMenuButton (selected glyph via IconGlyphPressed)');

  Mb := TCWSMenuButton.Create(Self);
  Mb.Parent           := Sec3;
  Mb.SetBounds(20, 20, 260, 38);
  Mb.IconFontName     := 'Segoe MDL2 Assets';
  Mb.IconFontSize     := 14;
  Mb.IconGlyph        := ICON_HOME;
  Mb.IconGlyphPressed := ICON_HOME_S;
  Mb.MenuText         := 'Dashboard';
  Mb.GroupIndex       := 20;
  Mb.Pressed          := True;

  Mb := TCWSMenuButton.Create(Self);
  Mb.Parent           := Sec3;
  Mb.SetBounds(20, 64, 260, 38);
  Mb.IconFontName     := 'Segoe MDL2 Assets';
  Mb.IconFontSize     := 14;
  Mb.IconGlyph        := ICON_MAIL;
  Mb.IconGlyphPressed := ICON_MAIL_S;
  Mb.MenuText         := 'Inbox';
  Mb.GroupIndex       := 20;

  Mb := TCWSMenuButton.Create(Self);
  Mb.Parent           := Sec3;
  Mb.SetBounds(20, 108, 260, 38);
  Mb.IconFontName     := 'Segoe MDL2 Assets';
  Mb.IconFontSize     := 14;
  Mb.IconGlyph        := ICON_SETTINGS;
  Mb.IconGlyphPressed := ICON_SETTINGS_S;
  Mb.MenuText         := 'Settings';
  Mb.GroupIndex       := 20;

  Mb := TCWSMenuButton.Create(Self);
  Mb.Parent           := Sec3;
  Mb.SetBounds(20, 152, 260, 38);
  Mb.IconFontName     := 'Segoe MDL2 Assets';
  Mb.IconFontSize     := 14;
  Mb.IconGlyph        := ICON_DELETE;
  Mb.IconGlyphPressed := ICON_DELETE_S;
  Mb.MenuText         := 'Trash';
  Mb.GroupIndex       := 20;

  APage.Height := 580;
end;

procedure TfrmDemo.FavoriteClick(Sender: TObject);
var
  Btn: TCWSButton;
begin
  Btn := TCWSButton(Sender);
  Btn.Tag := 1 - Btn.Tag;
  if Btn.Tag = 1 then
  begin
    Btn.IconGlyph := ICON_FAVORITE_F;
    Btn.Caption   := 'Favorited';
  end
  else
  begin
    Btn.IconGlyph := ICON_FAVORITE;
    Btn.Caption   := 'Favorite';
  end;
end;

{ ════════════════════════════════════════════════════════════════════════
                              INPUTS page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildInputsPage(APage: TWinControl);
var
  Sec1, Sec2, Sec3: TCWSCornerPanel;
  Ed1, Ed2, Ed3, Ed4: TCWSEdit;
  Memo: TCWSMemo;
begin
  Sec1 := AddSection(APage, 20, 170, 'TCWSEdit — clear / search / password / plain');

  Ed1 := TCWSEdit.Create(Self);
  Ed1.Parent      := Sec1;
  Ed1.SetBounds(20, 25, 380, 56);
  Ed1.LabelText   := 'Full name';
  Ed1.TextHint    := 'Enter your name...';
  Ed1.ButtonStyle := ebsClear;

  Ed2 := TCWSEdit.Create(Self);
  Ed2.Parent      := Sec1;
  Ed2.SetBounds(420, 25, 380, 56);
  Ed2.LabelText   := 'Search';
  Ed2.TextHint    := 'Type a query...';
  Ed2.ButtonStyle := ebsSearch;

  Ed3 := TCWSEdit.Create(Self);
  Ed3.Parent      := Sec1;
  Ed3.SetBounds(20, 90, 380, 56);
  Ed3.LabelText   := 'Password';
  Ed3.TextHint    := '••••••••';
  Ed3.ButtonStyle := ebsPassword;

  Ed4 := TCWSEdit.Create(Self);
  Ed4.Parent      := Sec1;
  Ed4.SetBounds(420, 90, 380, 56);
  Ed4.LabelText   := 'E-mail';
  Ed4.TextHint    := 'user@example.com';

  Sec2 := AddSection(APage, 240, 100, 'Modifiers');

  Ed1 := TCWSEdit.Create(Self);
  Ed1.Parent      := Sec2;
  Ed1.SetBounds(20, 25, 250, 56);
  Ed1.LabelText   := 'Numbers only';
  Ed1.NumbersOnly := True;
  Ed1.TextHint    := '0';

  Ed2 := TCWSEdit.Create(Self);
  Ed2.Parent      := Sec2;
  Ed2.SetBounds(290, 25, 250, 56);
  Ed2.LabelText   := 'Read-only';
  Ed2.ReadOnly    := True;
  Ed2.Text        := 'Cannot edit this';

  Ed3 := TCWSEdit.Create(Self);
  Ed3.Parent      := Sec2;
  Ed3.SetBounds(560, 25, 250, 56);
  Ed3.LabelText   := 'Disabled';
  Ed3.Enabled     := False;
  Ed3.Text        := 'Inactive';

  Sec3 := AddSection(APage, 390, 220, 'TCWSMemo — with Fluent overlay scrollbar');
  Memo := TCWSMemo.Create(Self);
  Memo.Parent    := Sec3;
  Memo.SetBounds(20, 20, 820, 180);
  Memo.LabelText := 'Notes';
  Memo.WordWrap  := True;
  Memo.Lines.Add('CWStudio components feel native on Windows 11.');
  Memo.Lines.Add('');
  Memo.Lines.Add('- The scrollbar appears only on hover.');
  Memo.Lines.Add('- Text rendering uses native VCL — but the frame is GDI+.');
  Memo.Lines.Add('- Try resizing the form to see how everything reflows.');
  Memo.Lines.Add('');
  Memo.Lines.Add('Add a few more lines so the scrollbar has something to do...');
  Memo.Lines.Add('Lorem ipsum dolor sit amet, consectetur adipiscing elit.');
  Memo.Lines.Add('Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.');
  Memo.Lines.Add('Ut enim ad minim veniam, quis nostrud exercitation ullamco.');
  Memo.Lines.Add('Laboris nisi ut aliquip ex ea commodo consequat.');

  APage.Height := 640;
end;

{ ════════════════════════════════════════════════════════════════════════
                              PICKERS page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildPickersPage(APage: TWinControl);
var
  Sec1, Sec2: TCWSCornerPanel;
  Combo1, Combo2: TCWSComboBox;
  DP1, DP2: TCWSDatePicker;
  Lbl: TLabel;
begin
  Sec1 := AddSection(APage, 20, 160, 'TCWSComboBox');

  Lbl := AddBodyLabel(Sec1, 20, 22, 240, 18, 'Drop-down list (selection only)', 9, TAG_SECONDARY);
  Lbl.WordWrap := False;

  Combo1 := TCWSComboBox.Create(Self);
  Combo1.Parent := Sec1;
  Combo1.SetBounds(20, 46, 380, 32);
  Combo1.Style  := csDropDownList;
  Combo1.Items.Add('Apples');
  Combo1.Items.Add('Bananas');
  Combo1.Items.Add('Cherries');
  Combo1.Items.Add('Dragon fruit');
  Combo1.Items.Add('Elderberries');
  Combo1.Items.Add('Figs');
  Combo1.Items.Add('Grapes');
  Combo1.Items.Add('Honeydew melon');
  Combo1.ItemIndex := 0;

  Lbl := AddBodyLabel(Sec1, 420, 22, 240, 18, 'Editable (csDropDown)', 9, TAG_SECONDARY);
  Lbl.WordWrap := False;

  Combo2 := TCWSComboBox.Create(Self);
  Combo2.Parent  := Sec1;
  Combo2.SetBounds(420, 46, 380, 32);
  Combo2.Style   := csDropDown;
  Combo2.TextHint := 'Type or pick a city...';
  Combo2.Items.Add('Warsaw');
  Combo2.Items.Add('Cracow');
  Combo2.Items.Add('Gdansk');
  Combo2.Items.Add('Wroclaw');
  Combo2.Items.Add('Poznan');
  Combo2.Items.Add('Lodz');

  Sec2 := AddSection(APage, 230, 160, 'TCWSDatePicker — WinUI 3 calendar popup');

  Lbl := AddBodyLabel(Sec2, 20, 22, 240, 18, 'Default format', 9, TAG_SECONDARY);
  Lbl.WordWrap := False;

  DP1 := TCWSDatePicker.Create(Self);
  DP1.Parent := Sec2;
  DP1.SetBounds(20, 46, 240, 32);
  DP1.Date := Now;

  Lbl := AddBodyLabel(Sec2, 280, 22, 240, 18, 'Custom day-shape (circle)', 9, TAG_SECONDARY);
  Lbl.WordWrap := False;

  DP2 := TCWSDatePicker.Create(Self);
  DP2.Parent     := Sec2;
  DP2.SetBounds(280, 46, 240, 32);
  DP2.Date       := Now + 7;
  DP2.DayShape   := dsCircle;

  APage.Height := 420;
end;

{ ════════════════════════════════════════════════════════════════════════
                              PROGRESS page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildProgressPage(APage: TWinControl);
var
  Sec: TCWSCornerPanel;
  Pc: TCWSProgressCircle;
begin
  Sec := AddSection(APage, 20, 320, 'TCWSProgressCircle — animated GDI+ progress ring');

  FProgressCircle := TCWSProgressCircle.Create(Self);
  FProgressCircle.Parent        := Sec;
  FProgressCircle.SetBounds(40, 30, 240, 240);
  FProgressCircle.MinValue      := 0;
  FProgressCircle.MaxValue      := 100;
  FProgressCircle.Value         := 0;
  FProgressCircle.LineWidth     := 14;
  FProgressCircle.ShowPercent   := True;
  FProgressCircle.ProgressColor := $00B86314;
  FProgressCircle.Font.Size     := 24;
  FProgressCircle.Font.Style    := [fsBold];
  FProgressDir := 1;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(320, 40, 110, 110);
  Pc.Value := 25;
  Pc.LineWidth := 8;
  Pc.ProgressColor := $00C04040;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(450, 40, 110, 110);
  Pc.Value := 60;
  Pc.LineWidth := 8;
  Pc.ProgressColor := $00E0A040;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(580, 40, 110, 110);
  Pc.Value := 90;
  Pc.LineWidth := 8;
  Pc.ProgressColor := $004CAF50;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(320, 170, 110, 110);
  Pc.Value := 100;
  Pc.LineWidth := 8;
  Pc.ProgressColor := $00B86314;
  Pc.ShowPercent := False;
  Pc.CustomText := 'Done';
  Pc.Font.Size := 11;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(450, 170, 110, 110);
  Pc.Value := 45;
  Pc.LineWidth := 8;
  Pc.StartAngle := -90;
  Pc.ProgressColor := $0080468C;

  Pc := TCWSProgressCircle.Create(Self);
  Pc.Parent := Sec;
  Pc.SetBounds(580, 170, 110, 110);
  Pc.Value := 75;
  Pc.LineWidth := 8;
  Pc.RoundCaps := False;
  Pc.ProgressColor := $00606060;

  APage.Height := 400;
end;

procedure TfrmDemo.AnimTimerTimer(Sender: TObject);
var
  V: Double;
begin
  if not Assigned(FProgressCircle) then
    Exit;
  V := FProgressCircle.Value + (FProgressDir * 1);
  if V >= 100 then
  begin
    V := 100;
    FProgressDir := -1;
  end
  else if V <= 0 then
  begin
    V := 0;
    FProgressDir := 1;
  end;
  FProgressCircle.Value := V;
end;

{ ════════════════════════════════════════════════════════════════════════
                            CONTAINERS page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildContainersPage(APage: TWinControl);
var
  Sec1, Sec2: TCWSCornerPanel;
  Sp: TCWSSettingsPanel;
  Title, Desc: TLabel;
  I: Integer;
  IconColor: TColor;
  IconGlyph: string;
  TitleTxt, DescTxt: string;
begin
  Sec1 := AddSection(APage, 20, 110, 'TCWSCornerPanel — the "section card" you see everywhere here');
  AddBodyLabel(Sec1, 20, 20, 800, 70,
    'Each panel below holding controls IS a TCWSCornerPanel. It is themed automatically' + sLineBreak +
    'from flNeutralCardBackground / flNeutralStroke1, so it always sits cleanly on top of' + sLineBreak +
    'the form background in both Light and Dark modes.', 10, TAG_PRIMARY);

  Sec2 := AddSection(APage, 160, 220, 'TCWSSettingsPanel — clickable settings cards');

  for I := 0 to 2 do
  begin
    Sp := TCWSSettingsPanel.Create(Self);
    Sp.Parent := Sec2;
    Sp.SetBounds(20 + I * 270, 25, 240, 80);

    case I of
      0: begin IconGlyph := ICON_PALETTE;  IconColor := $00B86314; TitleTxt := 'Appearance';        DescTxt := 'Themes, colors, font sizes'; end;
      1: begin IconGlyph := ICON_GLOBE;    IconColor := $004B9CD3; TitleTxt := 'Language & region'; DescTxt := 'Date format, locale, units'; end;
    else      begin IconGlyph := ICON_SETTINGS;IconColor := $00388E3C; TitleTxt := 'Advanced';          DescTxt := 'Developer options'; end;
    end;

    AddIconLabel(Sp, 14, 18, 22, IconGlyph, IconColor);

    Title        := TLabel.Create(Self);
    Title.Parent := Sp;
    Title.SetBounds(60, 14, 170, 22);
    Title.Font.Name   := 'Segoe UI';
    Title.Font.Style  := [fsBold];
    Title.Font.Size   := 10;
    Title.Transparent := True;
    Title.Caption     := TitleTxt;
    Title.Tag         := TAG_PRIMARY;

    Desc := AddBodyLabel(Sp, 60, 38, 170, 32, DescTxt, 8, TAG_MUTED);
  end;

  AddBodyLabel(Sec2, 20, 130, 700, 60,
    'Hover any card to see the rounded highlight. TCWSSettingsPanel inherits ' +
    'TCustomControl, so any VCL child controls (TLabels, icons, even other ' +
    'CWStudio components) can be dropped onto it freely.', 9, TAG_MUTED);

  APage.Height := 420;
end;

{ ════════════════════════════════════════════════════════════════════════
                            OVERLAY page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildOverlayPage(APage: TWinControl);
var
  Sec: TCWSCornerPanel;
  ShowBtn: TCWSButton;
begin
  Sec := AddSection(APage, 20, 220, 'TCWSDimOverlay — dim the form behind a modal dialog');

  AddBodyLabel(Sec, 20, 20, 800, 90,
    'TCWSDimOverlay is a layered window that paints a semi-transparent ' +
    'colour over the form (with Win11-aware rounded corners). It is animated ' +
    'and can block clicks underneath it. Use it to focus the user''s attention ' +
    'on a modal dialog — click the button below to see it in action.',
    10, TAG_PRIMARY);

  ShowBtn := AddButton(Sec, 20, 130, 'Show dim dialog', ICON_WARNING, bsPrimary, 220);
  ShowBtn.OnClick := ShowDimDialogClick;

  APage.Height := 380;
end;

procedure TfrmDemo.ShowDimDialogClick(Sender: TObject);
var
  OkBtn, CancelBtn: TCWSButton;
  Title, Body: TLabel;
begin
  FDemoDialog             := TForm.Create(Self);
  FDemoDialog.BorderStyle := bsNone;
  FDemoDialog.Position    := poOwnerFormCenter;
  FDemoDialog.Width       := 460;
  FDemoDialog.Height      := 240;
  FDemoDialog.Color       := flNeutralCardBackground;
  FDemoDialog.PopupMode   := pmExplicit;
  FDemoDialog.PopupParent := Self;
  FDemoDialog.Font.Name   := 'Segoe UI';
  FDemoDialog.Font.Size   := 9;

  AddIconLabel(FDemoDialog, 28, 28, 28, ICON_ABOUT_S, flBrandBackground);

  Title             := TLabel.Create(FDemoDialog);
  Title.Parent      := FDemoDialog;
  Title.SetBounds(80, 28, 360, 30);
  Title.Caption     := 'Dim overlay demo';
  Title.Font.Name   := 'Segoe UI';
  Title.Font.Size   := 14;
  Title.Font.Style  := [fsBold];
  Title.Font.Color  := flNeutralForeground1;
  Title.Transparent := True;

  Body              := TLabel.Create(FDemoDialog);
  Body.Parent       := FDemoDialog;
  Body.SetBounds(80, 68, 360, 80);
  Body.AutoSize     := False;
  Body.WordWrap     := True;
  Body.Caption      :=
    'The main window behind this dialog is dimmed by a TCWSDimOverlay ' +
    'component. Close this dialog to fade the overlay back out.';
  Body.Font.Name    := 'Segoe UI';
  Body.Font.Size    := 10;
  Body.Font.Color   := flNeutralForeground2;
  Body.Transparent  := True;

  CancelBtn := AddButton(FDemoDialog, 240, 175, 'Cancel', ICON_CANCEL, bsNeutral, 100);
  CancelBtn.OnClick := CloseDimDialog;
  RethemeButton(CancelBtn);

  OkBtn := AddButton(FDemoDialog, 350, 175, 'OK', ICON_OK, bsPrimary, 100);
  OkBtn.OnClick   := CloseDimDialog;
  OkBtn.IsDefault := True;
  RethemeButton(OkBtn);

  DimOverlay.Visible := True;
  try
    FDemoDialog.ShowModal;
  finally
    DimOverlay.Visible := False;
    FDemoDialog.Free;
    FDemoDialog := nil;
  end;
end;

procedure TfrmDemo.CloseDimDialog(Sender: TObject);
begin
  if Assigned(FDemoDialog) then
    FDemoDialog.Close;
end;

{ ════════════════════════════════════════════════════════════════════════
                              ABOUT page
  ════════════════════════════════════════════════════════════════════════ }

procedure TfrmDemo.BuildAboutPage(APage: TWinControl);
var
  Sec: TCWSCornerPanel;
  Lbl, TitleLbl: TLabel;
  DonateBtn: TCWSButton;
begin
  Sec := AddSection(APage, 20, 360, 'CWStudio Component Library');

  AddIconLabel(Sec, 20, 25, 36, ICON_HEART_F, $00C04060);

  TitleLbl             := TLabel.Create(Self);
  TitleLbl.Parent      := Sec;
  TitleLbl.SetBounds(90, 30, 700, 30);
  TitleLbl.Caption     := 'CWStudio Component Library';
  TitleLbl.Font.Name   := 'Segoe UI';
  TitleLbl.Font.Size   := 16;
  TitleLbl.Font.Style  := [fsBold];
  TitleLbl.Transparent := True;
  TitleLbl.Tag         := TAG_PRIMARY;

  Lbl := AddBodyLabel(Sec, 90, 62, 700, 22,
    'Modern VCL components in Windows 11 / WinUI 3 style', 10, TAG_MUTED);
  Lbl.WordWrap := False;

  AddBodyLabel(Sec, 20, 110, 820, 160,
    'Author:        Czeslaw Wludarczyk' + sLineBreak +
    'License:       Full Open Source — free for any project' + sLineBreak +
    'Attribution:   please include "Uses CWStudio components by Czeslaw Wludarczyk"' + sLineBreak +
    '               in your application''s About box.' + sLineBreak + sLineBreak +
    'Third-party dependencies:' + sLineBreak +
    '   - SVGIconImageList  by Carlo Barazzetta             (Apache 2.0)' + sLineBreak +
    '   - EsVclComponents   by Peter Sokolov / ErrorSoft    (MIT or GPLv2)',
    10, TAG_PRIMARY);

  DonateBtn := AddButton(Sec, 20, 300, 'Donate via PayPal', ICON_HEART_F, bsPrimary, 220);
  DonateBtn.OnClick := DonateClick;

  APage.Height := 460;
end;

procedure TfrmDemo.DonateClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar('https://paypal.me/czeslaw80'), nil, nil, SW_SHOWNORMAL);
end;

end.
