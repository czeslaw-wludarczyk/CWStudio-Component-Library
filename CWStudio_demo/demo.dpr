program demo;

uses
  Vcl.Forms,
  main in 'main.pas' {frmMain},
  home in 'home.pas' {frmHome},
  edits in 'edits.pas' {frmEdits},
  panels in 'panels.pas' {frmPanels},
  forms in 'forms.pas' {frmForms},
  dlg_info in 'dlg_info.pas' {dlgInfo},
  buttons in 'buttons.pas' {frmButtons},
  progress_bars in 'progress_bars.pas' {frmProgressBars},
  scrollboxes in 'scrollboxes.pas' {frmScrollBoxes},
  info in 'info.pas' {frmInfo},
  grids in 'grids.pas' {frmGrids};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmHome, frmHome);
  Application.CreateForm(TfrmEdits, frmEdits);
  Application.CreateForm(TfrmPanels, frmPanels);
  Application.CreateForm(TfrmForms, frmForms);
  Application.CreateForm(TdlgInfo, dlgInfo);
  Application.CreateForm(TfrmButtons, frmButtons);
  Application.CreateForm(TfrmProgressBars, frmProgressBars);
  Application.CreateForm(TfrmScrollBoxes, frmScrollBoxes);
  Application.CreateForm(TfrmInfo, frmInfo);
  Application.CreateForm(TfrmGrids, frmGrids);
  Application.Run;
end.
