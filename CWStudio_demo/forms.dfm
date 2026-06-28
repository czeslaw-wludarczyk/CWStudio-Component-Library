object frmForms: TfrmForms
  Left = 0
  Top = 0
  Align = alClient
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'Forms'
  ClientHeight = 494
  ClientWidth = 812
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 17
  object scrbForms: TCWSScrollBox
    Left = 0
    Top = 0
    Width = 812
    Height = 494
    ShowBorder = False
    Align = alClient
    TabOrder = 0
    object lblTitle1: TLabel
      Left = 16
      Top = 16
      Width = 504
      Height = 25
      Caption = 'TCWSDimOverlay '#8212' dim the form behind a modal dialog'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object Label1: TLabel
      Left = 16
      Top = 56
      Width = 423
      Height = 68
      Caption = 
        'TCWSDimOverlay is a layered window that paints a semi-transparen' +
        't '#13#10'colour over the form (with Win11-aware rounded corners). It ' +
        'is animated'#13#10'and can block clicks underneath it. Use it to focus' +
        ' the user'#39's attention '#13#10'on a modal dialog '#8212' click the button bel' +
        'ow to see it in action.'
      Transparent = True
    end
    object btnShow: TCWSButton
      Left = 16
      Top = 144
      Width = 185
      Height = 35
      Color = clBtnFace
      TabOrder = 3
      IconFontName = 'Segoe MDL2 Assets'
      BckNormalColor = clWhite
      BckHoverColor = clWhitesmoke
      BckPressedColor = 14737632
      BorderColorNormal = 13750737
      BorderColorHover = 13092807
      BorderColorPressed = 11776947
      Caption = 'Show dim dialog'
      IconColorNormal = 2368548
      IconColorHover = 2368548
      IconColorPressed = 2368548
      CaptionColorNormal = 2368548
      CaptionColorHover = 2368548
      CaptionColorPressed = 2368548
      BckDisabledColor = 15790320
      BorderColorDisabled = 14737632
      CaptionColorDisabled = 12434877
      IconColorDisabled = 12434877
      OnClick = btnShowClick
    end
    object lblTitle2: TLabel
      Left = 16
      Top = 224
      Width = 193
      Height = 25
      Caption = 'TCWSAfterFormShow'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object Label3: TLabel
      Left = 16
      Top = 255
      Width = 728
      Height = 17
      Caption = 
        'Component that fires an OnAfterShow event once the form is fully' +
        ' painted after Show / ShowModal (but not on un-minimize).'
      Transparent = True
    end
  end
end
