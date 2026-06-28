//////////////////////////////////////////////////////////////////////////
//
//   CWStudio Component Library
//   Created by Czesław Włudarczyk 2026 CWStudio
//
//   LICENSE: MIT
//   Free to use, modify and distribute in any project, commercial or
//   non-commercial, provided that the copyright notice and this license
//   text are preserved. See the LICENSE file for the full MIT terms.
//
//   ATTRIBUTION REQUIRED:
//   Any application built using CWStudio components MUST include
//   visible information about the author of the components inside
//   the application (e.g. in the About box, credits screen, or
//   splash screen), for example:
//
//       "Uses CWStudio components by Czesław Włudarczyk"
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
//
//////////////////////////////////////////////////////////////////////////
unit CWStudio_Reg;

interface

procedure Register;

implementation

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.DBGrids,
  ToolsAPI,
  DesignIntf,
  DesignEditors,
  ColnEdit,
  DBColnEd,
  MaskProp,   { TMaskProperty — the VCL "Input Mask Editor" dialog (… button) }
  CWStudio_Version,
  { runtime units with components — the DT package requires CWStudio_ComponentsRT }
  CWSCornerPanel,
  CWSSettingsPanel,
  CWSButton,
  CWSStoreButton,
  CWSMenuButton,
  CWSRadioButton,
  CWSCheckBox,
  CWSSwitch,
  CWSEdit,
  CWSEditMask,
  CWSComboBox,
  CWSMemo,
  CWSDatePicker,
  CWSProgressCircle,
  CWSProgressBar,
  CWSIndicatorLoading,
  CWSPopupMenu,
  CWSScrollBox,
  CWSDimOverlay,
  CWSAfterFormShow,
  CWSListBox,
  CWSStringGrid,
  CWSDBGrid,
  CWSLabelColumn,
  CWSLabelTrend;

{ Resource with the 24×24 splash/About bitmap — compiled from CWStudio_Splash.rc }
{$R CWStudio_Splash.res}

const
  cSplashResName = 'CWSTUDIO_SPLASH';

type
  { Columns property editor for TCWSDBGrid.

    TCWSDBGrid does not descend from TCustomDBGrid, so the IDE does not apply
    the standard DBGrid editor (registered only for TCustomDBGrid) to its
    Columns and falls back to the generic collection editor, which does not
    understand the csDefault/csCustomized state — making a freshly dropped
    component look as if it already had one column. We therefore register the
    same editor as the real DBGrid (TDBGridColumnsEditor): empty after dropping
    the component, a column appears only after "Add", plus "Add all fields" /
    "Restore defaults". }
  TCWSDBGridColumnsProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

procedure TCWSDBGridColumnsProperty.Edit;
begin
  ShowCollectionEditorClass(Designer, TDBGridColumnsEditor,
    GetComponent(0) as TComponent, TDBGridColumns(GetOrdValue), GetName);
end;

function TCWSDBGridColumnsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

{ ──────────────────────────────────────────────────────────────────────────
    Register components on the palette
  ────────────────────────────────────────────────────────────────────────── }
procedure Register;
begin
  RegisterComponents('CWStudio_Panels',
    [TCWSCornerPanel, TCWSSettingsPanel]);
  RegisterComponents('CWStudio_Buttons',
    [TCWSButton, TCWSStoreButton, TCWSMenuButton, TCWSRadioButton, TCWSCheckBox, TCWSSwitch]);
  RegisterComponents('CWStudio_Edits',
    [TCWSEdit, TCWSEditMask, TCWSComboBox, TCWSMemo, TCWSDatePicker]);
  RegisterComponents('CWStudio_ProgressBars',
    [TCWSProgressCircle, TCWSProgressBar, TCWSIndicatorLoading]);
  RegisterComponents('CWStudio_Menus',
    [TCWSPopupMenu]);
  RegisterComponents('CWStudio_ScrollBoxes',
    [TCWSScrollBox]);
  RegisterComponents('CWStudio_Forms',
    [TCWSDimOverlay, TCWSAfterFormShow]);
  RegisterComponents('CWStudio_ListBoxes',
    [TCWSListBox]);
  RegisterComponents('CWStudio_Grids',
    [TCWSStringGrid, TCWSDBGrid]);
  RegisterComponents('CWStudio_Labels',
    [TCWSLabelColumn, TCWSLabelTrend]);

  { The same columns editor as in the real TDBGrid — see TCWSDBGridColumnsProperty }
  RegisterPropertyEditor(TypeInfo(TDBGridColumns), TCWSDBGrid, 'Columns',
    TCWSDBGridColumnsProperty);

  { The same "Input Mask Editor" dialog as the VCL TMaskEdit — the … button on
    the EditMask property opens the mask builder with the predefined mask list. }
  RegisterPropertyEditor(TypeInfo(string), TCWSEditMask, 'EditMask',
    TMaskProperty);
end;

{ ──────────────────────────────────────────────────────────────────────────
    Splash screen + About Box IDE
  ────────────────────────────────────────────────────────────────────────── }
var
  AboutBoxIndex: Integer = -1;
  SplashBitmap: TBitmap = nil;   { kept alive for the About Box }

function LoadSplashBitmap: TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.LoadFromResourceName(HInstance, cSplashResName);
  except
    Result.Free;
    raise;
  end;
end;

procedure RegisterSplashScreen;
var
  Bmp: TBitmap;
begin
  if not Assigned(SplashScreenServices) then
    Exit;
  Bmp := LoadSplashBitmap;
  try
    SplashScreenServices.AddPluginBitmap(
      CWStudioCaption,        { 'CWStudio Component 1.6.1' }
      Bmp.Handle,
      False,                  { not an unregistered version }
      CWStudioVersionLabel);  { 'V1.6.1.0' — status field next to the icon }
  finally
    Bmp.Free;               { splash copy bitmap — can free }
  end;
end;

procedure RegisterAboutBox;
var
  AboutSvc: IOTAAboutBoxServices;
begin
  if not Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutSvc) then
    Exit;
  SplashBitmap := LoadSplashBitmap;
  AboutBoxIndex := AboutSvc.AddPluginInfo(
    CWStudioCaption,
    'CWStudio Component Library ' + CWStudioVersionFull + sLineBreak +
    'Modern Windows 11 / WinUI 3 style VCL components for Delphi.' + sLineBreak +
    CWStudioCopyright,
    SplashBitmap.Handle,
    False,
    CWStudioVersionLabel);
end;

procedure UnregisterAboutBox;
var
  AboutSvc: IOTAAboutBoxServices;
begin
  if (AboutBoxIndex <> -1) and
     Supports(BorlandIDEServices, IOTAAboutBoxServices, AboutSvc) then
    AboutSvc.RemovePluginInfo(AboutBoxIndex);
  AboutBoxIndex := -1;
  FreeAndNil(SplashBitmap);
end;

initialization
  RegisterSplashScreen;
  RegisterAboutBox;

finalization
  UnregisterAboutBox;

end.
