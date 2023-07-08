object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'WarningTLabel'
  ClientHeight = 170
  ClientWidth = 281
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 96
    Top = 24
    Width = 6
    Height = 13
    Caption = 'X'
  end
  object Label2: TLabel
    Left = 160
    Top = 24
    Width = 6
    Height = 13
    Caption = 'Y'
  end
  object Label3: TLabel
    Left = 96
    Top = 64
    Width = 6
    Height = 13
    Caption = 'X'
  end
  object Label4: TLabel
    Left = 160
    Top = 64
    Width = 6
    Height = 13
    Caption = 'Y'
  end
  object Label5: TLabel
    Left = 24
    Top = 24
    Width = 24
    Height = 13
    Caption = 'Start'
  end
  object Label6: TLabel
    Left = 24
    Top = 64
    Width = 27
    Height = 13
    Caption = 'Finish'
  end
  object WarningTLabel: TLabel
    Left = 24
    Top = 101
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
  object StartXTEdit: TEdit
    Left = 108
    Top = 21
    Width = 36
    Height = 21
    TabOrder = 0
    Text = 'StartXTEdit'
  end
  object StartYTEdit: TEdit
    Left = 172
    Top = 21
    Width = 36
    Height = 21
    TabOrder = 1
    Text = 'Edit1'
  end
  object FinishXTEdit: TEdit
    Left = 108
    Top = 61
    Width = 36
    Height = 21
    TabOrder = 2
    Text = 'Edit1'
  end
  object FinishYTEdit: TEdit
    Left = 172
    Top = 61
    Width = 36
    Height = 21
    TabOrder = 3
    Text = 'Edit1'
  end
  object Button1: TButton
    Left = 180
    Top = 134
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
  object Button2: TButton
    Left = 24
    Top = 134
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 5
  end
end
