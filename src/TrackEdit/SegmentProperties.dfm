object SegmentPropertiesForm: TSegmentPropertiesForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Segment Properties'
  ClientHeight = 149
  ClientWidth = 271
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 96
    Top = 32
    Width = 6
    Height = 13
    Caption = 'X'
  end
  object Label2: TLabel
    Left = 176
    Top = 32
    Width = 6
    Height = 13
    Caption = 'Y'
  end
  object Label3: TLabel
    Left = 96
    Top = 54
    Width = 6
    Height = 13
    Caption = 'X'
  end
  object Label4: TLabel
    Left = 176
    Top = 54
    Width = 6
    Height = 13
    Caption = 'Y'
  end
  object Label5: TLabel
    Left = 24
    Top = 32
    Width = 24
    Height = 13
    Caption = 'Start'
  end
  object Label6: TLabel
    Left = 25
    Top = 54
    Width = 27
    Height = 13
    Caption = 'Finish'
  end
  object WarningTLabel: TLabel
    Left = 27
    Top = 100
    Width = 223
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'WarningTLabel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label7: TLabel
    Left = 24
    Top = 76
    Width = 28
    Height = 13
    Caption = 'Width'
  end
  object Label8: TLabel
    Left = 24
    Top = 6
    Width = 133
    Height = 13
    Caption = 'All values in 1/1000 of a cell'
  end
  object StartXTEdit: TEdit
    Left = 108
    Top = 29
    Width = 49
    Height = 21
    TabOrder = 0
    Text = 'StartXTEdit'
  end
  object StartYTEdit: TEdit
    Left = 188
    Top = 29
    Width = 53
    Height = 21
    TabOrder = 1
    Text = 'Edit1'
  end
  object FinishXTEdit: TEdit
    Left = 108
    Top = 51
    Width = 49
    Height = 21
    TabOrder = 2
    Text = 'Edit1'
  end
  object FinishYTEdit: TEdit
    Left = 188
    Top = 51
    Width = 53
    Height = 21
    TabOrder = 3
    Text = 'Edit1'
  end
  object Button1: TButton
    Left = 166
    Top = 119
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
  object Button2: TButton
    Left = 27
    Top = 119
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object WidthTEdit: TEdit
    Left = 108
    Top = 73
    Width = 49
    Height = 21
    TabOrder = 6
    Text = 'WidthTEdit'
  end
end
