object ColorNetLinkForm: TColorNetLinkForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Colour Nets'
  ClientHeight = 256
  ClientWidth = 236
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 22
    Top = 19
    Width = 6
    Height = 13
    Caption = '1'
  end
  object Shape0: TShape
    Left = 38
    Top = 16
    Width = 25
    Height = 17
    Brush.Color = clAqua
  end
  object Label2: TLabel
    Left = 22
    Top = 45
    Width = 6
    Height = 13
    Caption = '2'
  end
  object Shape1: TShape
    Left = 38
    Top = 43
    Width = 25
    Height = 17
    Brush.Color = clLime
  end
  object Label3: TLabel
    Left = 22
    Top = 72
    Width = 6
    Height = 13
    Caption = '3'
  end
  object Shape2: TShape
    Left = 38
    Top = 70
    Width = 25
    Height = 17
    Brush.Color = 16711808
  end
  object Label4: TLabel
    Left = 22
    Top = 100
    Width = 6
    Height = 13
    Caption = '4'
  end
  object Shape3: TShape
    Left = 38
    Top = 97
    Width = 25
    Height = 19
    Brush.Color = 33023
  end
  object Label5: TLabel
    Left = 22
    Top = 127
    Width = 6
    Height = 13
    Caption = '5'
  end
  object Shape4: TShape
    Left = 38
    Top = 124
    Width = 25
    Height = 19
    Brush.Color = 33023
  end
  object Label6: TLabel
    Left = 22
    Top = 154
    Width = 6
    Height = 13
    Caption = '6'
  end
  object Shape5: TShape
    Left = 38
    Top = 151
    Width = 25
    Height = 19
    Brush.Color = 33023
  end
  object NetTComboBox0: TComboBox
    Left = 69
    Top = 16
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
  end
  object NetTComboBox1: TComboBox
    Left = 69
    Top = 43
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
  end
  object NetTComboBox2: TComboBox
    Left = 69
    Top = 70
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 2
  end
  object NetTComboBox3: TComboBox
    Left = 69
    Top = 97
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 3
  end
  object Panel1: TPanel
    Left = 0
    Top = 215
    Width = 236
    Height = 41
    Align = alBottom
    BevelInner = bvLowered
    Caption = 'Panel1'
    ShowCaption = False
    TabOrder = 4
    object OKTButton: TButton
      Left = 22
      Top = 8
      Width = 75
      Height = 25
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
    end
    object CancelTButton: TButton
      Left = 139
      Top = 8
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object ColorsTButton: TButton
    Left = 22
    Top = 184
    Width = 75
    Height = 25
    Caption = 'Colours...'
    TabOrder = 5
    OnClick = ColorsTButtonClick
  end
  object NetTComboBox4: TComboBox
    Left = 69
    Top = 124
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 6
  end
  object NetTComboBox5: TComboBox
    Left = 69
    Top = 151
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 7
  end
end
