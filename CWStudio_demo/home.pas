unit home;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CWSFluentColorsMulti, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Imaging.pngimage, SVGIconImage,
  CWSLabelColumn;

type
  TfrmHome = class(TForm)
    lblDescription: TLabel;
    imgLogo: TImage;
    CWSLabelColumn1: TCWSLabelColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure ApplyTheme;
  public
    { Public declarations }
  end;

var
  frmHome: TfrmHome;

implementation

{$R *.dfm}

procedure TfrmHome.ApplyTheme;
begin
  self.Color:= flNeutralBackground2;
  lblDescription.Font.Color:= flNeutralForeground1;
  CWSLabelColumn1.LeftFont.Color:= flNeutralForeground1;
  CWSLabelColumn1.RightFont.Color:= flNeutralForeground1;

end;

procedure TfrmHome.FormCreate(Sender: TObject);
begin
  RegisterThemeChange(Self.ApplyTheme);
  FluentApplySystemTheme;
end;

procedure TfrmHome.FormDestroy(Sender: TObject);
begin
  UnregisterThemeChange(Self.ApplyTheme);
end;

procedure TfrmHome.FormShow(Sender: TObject);
begin
 ScaleForPPI(CurrentPPI);
end;

end.

