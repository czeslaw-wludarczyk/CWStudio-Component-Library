object frmDemo: TfrmDemo
  Left = 0
  Top = 0
  Caption = 'CWStudio Component Library - Demo'
  ClientHeight = 720
  ClientWidth = 1180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object DimOverlay: TCWSDimOverlay
    Opacity = 140
    Left = 24
    Top = 24
  end
  object AfterShow: TCWSAfterFormShow
    OnAfterShow = AfterShowAfterShow
    Left = 80
    Top = 24
  end
  object AnimTimer: TTimer
    Enabled = False
    Interval = 30
    OnTimer = AnimTimerTimer
    Left = 136
    Top = 24
  end
end
