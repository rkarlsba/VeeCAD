object ImportNetForm: TImportNetForm
  Left = 227
  Top = 107
  HelpContext = 230
  BorderIcons = [biSystemMenu]
  Caption = 'Import Netlist'
  ClientHeight = 388
  ClientWidth = 472
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 348
    Width = 472
    Height = 40
    Align = alBottom
    TabOrder = 0
    object ImportTButton: TButton
      Left = 136
      Top = 7
      Width = 75
      Height = 25
      Caption = '&Import'
      Default = True
      TabOrder = 0
      OnClick = ImportTButtonAClick
    end
    object CloseTButton: TButton
      Left = 265
      Top = 7
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'Close'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 121
    Width = 472
    Height = 227
    Align = alClient
    TabOrder = 1
    DesignSize = (
      472
      227)
    object Label3: TLabel
      Left = 16
      Top = 6
      Width = 40
      Height = 13
      Caption = 'Libraries'
    end
    object Panel3: TPanel
      Left = 1
      Top = 185
      Width = 470
      Height = 41
      Align = alBottom
      TabOrder = 0
      DesignSize = (
        470
        41)
      object LibMoveDownTBitBtn: TBitBtn
        Left = 232
        Top = 6
        Width = 27
        Height = 27
        Anchors = [akTop, akRight]
        DoubleBuffered = True
        Glyph.Data = {
          8A010000424D8A01000000000000760000002800000017000000170000000100
          0400000000001401000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFF0FFFFFFFFFFF0FFFF
          FFFFFF000FFFFFFFFFF0FFFFFFFFFF0A0FFFFFFFFFF0FFFFFFFFF0AA0FFFFFFF
          FFF0FFFFFFFFF0AAA0FFFFFFFFF0FFFFFFFF0AAAA0FFFFFFFFF0FFFFFFFF0AAA
          AA0FFFFFFFF0FFFFFFF0AAAAAA0FFFFFFFF0FFFFFFF0AAAAAAA0FFFFFFF0FFFF
          FF0AAAAAAAA0FFFFFFF0FFFFFF0AAAAAAAAA0FFFFFF0FFFFF0AAAAAAAAAA0FFF
          FFF0FFFFF0AAAAAAAAAAA0FFFFF0FFFF0AAAAAAAAAAAA0FFFFF0FFFF0AAAAAAA
          AAAAAA0FFFF0FFF0AAAAAAAAAAAAAA0FFFF0FFF0AAAAAAAAAAAAAAA0FFF0FF0A
          AAAAAAAAAAAAAAA0FFF0FF0000000000000000000FF0FFFFFFFFFFFFFFFFFFFF
          FFF0FFFFFFFFFFFFFFFFFFFFFFF0}
        ParentDoubleBuffered = False
        TabOrder = 0
        OnClick = LibMoveDownTBitBtnAClick
      end
      object LibMoveUpTBitBtn: TBitBtn
        Left = 264
        Top = 6
        Width = 27
        Height = 27
        Anchors = [akTop, akRight]
        DoubleBuffered = True
        Glyph.Data = {
          8A010000424D8A01000000000000760000002800000017000000170000000100
          0400000000001401000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
          FFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFF0FF0000000000000000000FF0FF0A
          AAAAAAAAAAAAAAAA0FF0FF00AAAAAAAAAAAAAAA00FF0FFF0AAAAAAAAAAAAAAA0
          FFF0FFFF0AAAAAAAAAAAAA0FFFF0FFFF0AAAAAAAAAAAAA0FFFF0FFFFF0AAAAAA
          AAAAA0FFFFF0FFFFF0AAAAAAAAAAA0FFFFF0FFFFFF0AAAAAAAAA0FFFFFF0FFFF
          FF0AAAAAAAAA0FFFFFF0FFFFFFF0AAAAAAA0FFFFFFF0FFFFFFF0AAAAAAA0FFFF
          FFF0FFFFFFFF0AAAAA0FFFFFFFF0FFFFFFFF0AAAAA0FFFFFFFF0FFFFFFFFF0AA
          A0FFFFFFFFF0FFFFFFFFF0AAA0FFFFFFFFF0FFFFFFFFF00A0FFFFFFFFFF0FFFF
          FFFFFF0A0FFFFFFFFFF0FFFFFFFFFFF0FFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFF
          FFF0FFFFFFFFFFFFFFFFFFFFFFF0}
        ParentDoubleBuffered = False
        TabOrder = 1
        OnClick = LibMoveUpTBitBtnAClick
      end
      object LibAddTButton: TButton
        Left = 312
        Top = 8
        Width = 57
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Add'
        TabOrder = 2
        OnClick = LibAddTButtonAClick
      end
      object LibDeleteTButton: TButton
        Left = 376
        Top = 8
        Width = 57
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Delete'
        TabOrder = 3
        OnClick = LibDeleteTButtonAClick
      end
    end
    object LibListTCheckListBox: TCheckListBox
      Left = 5
      Top = 25
      Width = 460
      Height = 149
      Margins.Left = 5
      Margins.Top = 25
      Margins.Right = 5
      Margins.Bottom = 10
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemHeight = 13
      Items.Strings = (
        'C:\CAD\Libs\VCadStdLib.per'
        'C:\Project\DIPLib.per')
      TabOrder = 1
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 0
    Width = 472
    Height = 121
    Align = alTop
    TabOrder = 2
    DesignSize = (
      472
      121)
    object Label1: TLabel
      Left = 16
      Top = 5
      Width = 67
      Height = 13
      Caption = 'Netlist Format'
    end
    object Label2: TLabel
      Left = 16
      Top = 67
      Width = 75
      Height = 13
      Caption = 'Netlist Filename'
    end
    object FormatTComboBox: TComboBox
      Left = 16
      Top = 24
      Width = 290
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      OnChange = FormatTComboBoxAChange
      Items.Strings = (
        'Protel'
        'Wirelist')
    end
    object FilenameTEdit: TEdit
      Left = 16
      Top = 86
      Width = 418
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      Text = 'FilenameTEdit'
    end
    object SelectFileNameTButton: TButton
      Left = 440
      Top = 84
      Width = 25
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 2
      OnClick = SelectFileNameTButtonAClick
    end
  end
end
