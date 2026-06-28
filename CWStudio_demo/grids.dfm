object frmGrids: TfrmGrids
  Left = 0
  Top = 0
  Align = alClient
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'frmGrids'
  ClientHeight = 562
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object CWSScrollBox1: TCWSScrollBox
    Left = 0
    Top = 0
    Width = 640
    Height = 562
    ShowBorder = False
    Align = alClient
    TabOrder = 0
    ExplicitHeight = 480
    DesignSize = (
      640
      562)
    object lblTitle1: TLabel
      Left = 24
      Top = 24
      Width = 396
      Height = 25
      Caption = 'CWSStrinGrid - StringGrid with WinUI3 look'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object CWSStringGrid1: TCWSStringGrid
      Left = 24
      Top = 64
      Width = 449
      Height = 475
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goThumbTracking, goFixedRowDefAlign]
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      CornerRadiusF = 6.000000000000000000
    end
    object CWSEdit1: TCWSEdit
      Left = 488
      Top = 64
      Width = 123
      Height = 45
      Cursor = crIBeam
      Text = ''
      LabelText = 'Corner radius'
      CornerRadius = 4.000000000000000000
      OnKeyPress = CWSEdit1KeyPress
      Anchors = [akTop, akRight]
      TabOrder = 4
      TabStop = True
    end
  end
end
