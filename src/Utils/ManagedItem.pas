unit ManagedItem;

interface

uses Classes;

type TManagedItem = class

  public
    // managed items provide a virtual constructor and destructor so they
    // can be created and destroyed by the TManagedList that owns them.
    // Any TManagedItem descendant can be stored in a TManagedList
    constructor Create; virtual;
end;

type TManagedItemClass = class of TManagedItem;

//
type TManagedList = class
  protected
    List : TList;
    FCount : integer;
    function GetItem( Index : integer ) : TManagedItem;
  public
    property Count : integer read FCount;
    property Items[Index : integer] : TManagedItem read GetItem; default;
    function IndexOf( Item : TManagedItem ) : integer;
    procedure Clear;
    function AddNew( ItemClass : TManagedItemClass ) : TManagedItem;
    procedure Delete( Index : integer );
    procedure Sort( Compare: TListSortCompare );
    constructor Create;
    destructor Destroy; override;
end;

implementation

uses SysUtils;

type EManagedItem = class( Exception );


// **************************************
//            TManageditem
// **************************************

constructor TManageditem.Create;
begin
end;


// **************************************
//            TManagedList
// **************************************
{
    TManagedList holds TManagedItem descendants in a list.
    When Clear is called, the list count is set zero (empty), but the list
    objects are not deallocated and can be reused when objects are again wanted
    from the list.  That is why the AddNew method can return a reused object or
    a new one.
}

constructor TManagedList.Create;
begin
    List := TList.Create;
end;

destructor TManagedList.Destroy;
var
    i : integer;
begin
    if assigned( List ) then begin
        for i := List.Count -1 downto 0 do begin
            TObject(List[i]).Free;
        end;
        List.Destroy;
    end;
end;

procedure TManagedList.Clear;
begin
    FCount := 0;
end;


procedure TManagedList.Delete( Index : integer );
begin
    // move to the "in reserve" section at tail of array
    List.Move( Index, List.Count -1);
    // reduce count
    Dec( FCount );
end;


function TManagedList.GetItem( Index : integer ) : TManagedItem;
begin
    if (Index < 0) or (Index >= FCount) then begin
        raise EListError.Create( 'Index out of range' );
    end;
    result := List[Index];
end;

function TManagedList.IndexOf( Item : TManagedItem ) : integer;
begin
    result := List.IndexOf( Item );
    if result >= Count then begin
        result := -1;
    end;
end;

function TManagedList.AddNew( ItemClass : TManagedItemClass ) : TManagedItem;
begin
    if List.Count <= FCount then begin
        result := ItemClass.Create;
        List.Add( result );
    end
    else begin
        result := List[FCount];
    end;
    Inc( FCount );
end;

procedure QuickSort(SortList: PPointerList; L, R: Integer;
  SCompare: TListSortCompare);
var
  I, J: Integer;
  P, T: Pointer;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SCompare(SortList^[I], P) < 0 do
        Inc(I);
      while SCompare(SortList^[J], P) > 0 do
        Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure TManagedList.Sort( Compare: TListSortCompare );
begin
  if (List.List <> nil) and (FCount > 0) then
{$IFDEF VER200}
    QuickSort(List.List, 0, FCount - 1, Compare);
{$ELSE}
    QuickSort(@List.List, 0, FCount - 1, Compare);
{$ENDIF}
end;


end.
