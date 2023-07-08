object MaterialsForm: TMaterialsForm
  Left = 693
  Top = 181
  HelpContext = 40
  BorderIcons = [biSystemMenu]
  Caption = 'Materials'
  ClientHeight = 446
  ClientWidth = 556
  Color = clBtnFace
  Constraints.MinWidth = 450
  ParentFont = True
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 409
    Width = 556
    Height = 37
    Align = alBottom
    TabOrder = 0
    ExplicitWidth = 463
    object CloseTButton: TButton
      Left = 14
      Top = 6
      Width = 75
      Height = 25
      Hint = 'Close window'
      Cancel = True
      Caption = 'Close'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = CloseTButtonClick
    end
    object RefreshTButton: TButton
      Left = 198
      Top = 6
      Width = 75
      Height = 25
      Hint = 'Update display'
      Caption = 'Refresh'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = RefreshTButtonClick
    end
    object CopyTButton: TButton
      Left = 279
      Top = 6
      Width = 75
      Height = 25
      Hint = 'Copy to clipboard'
      Caption = 'Copy'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = CopyTButtonClick
    end
    object PrintTButton: TButton
      Left = 360
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Print...'
      TabOrder = 3
      OnClick = PrintTButtonClick
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 556
    Height = 409
    ActivePage = TabSheet3
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 463
    object TabSheet1: TTabSheet
      Caption = 'Components'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object ComponentsTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'B.O.M.'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object BOMTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Links'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object LinksTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Wires'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object WiresTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
    object TabSheet6: TTabSheet
      Caption = 'Breaks'
      ImageIndex = 5
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object BreaksTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Statistics'
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 455
      ExplicitHeight = 0
      object StatisticsTMemo: TMemo
        Left = 0
        Top = 0
        Width = 548
        Height = 381
        Align = alClient
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        WordWrap = False
        ExplicitWidth = 455
      end
    end
  end
end
