//////////////////////////////////////////////////////////////////////////
//
//   CWStudio Component Library — Demo Application
//   Created by Czesław Włudarczyk 2026 CWStudio
//
//   Showcase of all components in the CWStudio package.
//   Icons are rendered using the "Segoe MDL2 Assets" system font.
//
//////////////////////////////////////////////////////////////////////////
program CWStudio_Demo;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  MainForm in 'MainForm.pas' {frmDemo};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CWStudio Component Library — Demo';
  Application.CreateForm(TfrmDemo, frmDemo);
  Application.Run;
end.
