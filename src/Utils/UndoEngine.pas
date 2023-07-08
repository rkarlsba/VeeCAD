unit UndoEngine;

interface

uses Classes, Sysutils;


{ **********************************************************************
     UNDO-REDO ENGINE USING MEMENTOS

     Engine is general purpose. Any code, even from unrelated parts of the
     application can create a TunMemento descendant and add operations to a
     single undo list, or an engine can be created when needed for a task.

     All knowledge of how to undo or redo is contained within the Memento. A
     discarded Memento can free itself or return to a store for reissue.

   ********************************************************************}


   { *****************************************************************
                TunMemento

       Create a descendant of TunMemento and override the four abstract
       methods. The Engine will call the abstract methods as needed.

       Your Memento should contain data fields that store the delta or
       before and after values, and an object reference or index to the
       item to be acted upon.

       One Memento should be instantiated for every single object involved
       in a single undo step, and included within a single engine transaction.

       Procedure Undo; Engine calls this when item edit must be undone.
       Memento should revert the item to its previous state.
       If original edit was a deletion, reinstate the item it by adding it back
       to the owner etc. If the edit was an addition, reverse it by removing the
       item from its owner. The Engine continues to hold the Memento, and the
       Memento holds a reference to the item. Undo should leave the Memento
       unaltered, because it is still owned by the engine.

       Procedure Redo; Engine calls this when the item edit that was performed
       and then undone, must now be reinstated. Memento should forward the item
       the state before the undo. If the original edit was a deletion, then
       set things to the deleted state. If the original edit was an addition,
       the set the item back to its owner. Redo should leave the Memento
       unanaltered, because it is still owned by the engine.

      Procedure DiscardUndo; Engine calls this when the Memento is discarded
      from the engine undo list, either because the list capacity has been
      reached, or the engine is being cleared. If the Memento records an edit
      of item deletion, then Memento code should delete the referenced
      item. If the Memento records an edit is item addition, it should leave the
      item alone, since it belongs to the application. Since the Memento is no
      longer owned by the engine, it typically frees itself.

      Procedure DiscardRedo; Engine calls this when the Memento is discarded
      from the engine redo list, either because list capacity is reached, the
      engine is being cleared, or the redo list is being discarded. If the
      Memento edit is item deletion, then it should leave the item alone,
      since it belongs to the application. If the Memento records item
      addition, then Memento code should delete the item. Since the Memento
      is no longer owned by the engine, it typically frees itself.

      ********************************************************************}

// TMemento descendants are the records that are offered by items to
// record editing changes.
type TunMemento = class
  public
  // perform undo
  Procedure Undo; virtual; abstract;
  // perform redo
  Procedure Redo; virtual; abstract;

  // Discard procedures throw away the Memento, freeing any owned objects.
  // Undo engine will not access the Memento after this call, either because it
  // is destroyed, or has returned itself to a pool of Mementos.

  // throw away this Memento from the Undo stack and destroy etc. the Memento
  Procedure DiscardUndo; virtual; abstract;
  // throw away this Memento from the Redo stack and destroy etc. the Memento
  Procedure DiscardRedo; virtual; abstract;
End;


// Undo Engine stores Mementos in TunTransaction Containers
type TunTransaction = class
  protected
    FMementos : TList;
    function GetCount : integer;
    function GetMemento( index : integer ) : TunMemento;
  public
    property Count : integer read GetCount;
    property Mementos[index : integer] : TunMemento read GetMemento;
    procedure AddMemento( Memento : TunMemento );

    procedure Undo;
    procedure Redo;
    procedure DiscardUndo;
    procedure DiscardRedo;
    constructor Create;
    destructor Destroy; override;
end;


type TStage = (stNoTransaction, stEnteredTransaction, stHaveMemento);

// TUndo is the undo-redo engine.
TunUndo = class
protected
  FTransactions : TList;
  LatestTransactionIndex : integer;
  TopTransactionIndex : integer;
  Stage : TStage;

  function LatestTransaction : TunTransaction;
  function PeekNext : TunTransaction;

  // move LatestOperationIndex to right (in Redo direction)
  procedure Next;
  // move LatestOperationndex to left (in Undo direction)
  procedure Previous;

public
  procedure Undo;
  procedure Redo;
  procedure Clear;

  // add an undo step by starting a transaction, adding Mementos, and ending
  // transaction. Engine discards transactions that contain zero mementos -
  // allows code that starts and ends a transaction without knowing whether any
  // changes will actually be made and recorded as Mementos.
  procedure BeginTransaction;
  procedure EndTransaction;
  procedure AddMemento( Memento : TunMemento );

  constructor Create( Capacity : integer );
  destructor Destroy; override;
end;

// Undo engine throws this type of exception
type EUndo = class(Exception);


implementation

// **************************************************
//                TunTransaction
// **************************************************

// Each Transaction stores the Mementos that describe
// all the changes for a single Undo Transaction

function TunTransaction.GetCount : integer;
begin
     result := FMementos.Count;
end;

function TunTransaction.GetMemento( index : integer ) : TunMemento;
begin
     result := TunMemento(FMementos[index]);
end;

procedure TunTransaction.AddMemento( Memento : TunMemento );
begin
     FMementos.Add(Memento);
end;

procedure TunTransaction.Undo;
var
    i : integer;
begin
     for i:=0 to FMementos.Count -1 do begin
       TunMemento(FMementos[i]).Undo;
     end;
end;

procedure TunTransaction.Redo;
var
    i : integer;
begin
  for i:=0 to FMementos.Count -1 do begin
    TunMemento(FMementos[i]).Redo;
  end;
end;

procedure TunTransaction.DiscardUndo;
var
    i : integer;
begin
  for i:=0 to FMementos.Count -1 do begin
    TunMemento(FMementos[i]).DiscardUndo;
  end;
  // we never free memory, but leave it for when Transaction is re-used
  FMementos.Count := 0;
end;

procedure TunTransaction.DiscardRedo;
var
    i : integer;
begin
  for i:=0 to FMementos.Count -1 do begin
    TunMemento(FMementos[i]).DiscardRedo;
  end;
  FMementos.Count := 0;
end;

constructor TunTransaction.Create;
begin
  FMementos := TList.Create;
end;

destructor TunTransaction.Destroy;
begin
  // Any Mementos in list are lost - should have been discarded through
  // calls to DiscardUndo() or DicardRedo() by the TunUndo that owns this
  // TunTransaction
  FMementos.Free;
end;


// **************************************************
//            TunUndo - THE UNDO ENGINE
// **************************************************
{
    HOW UNDO-REDO OPERATIONS ARE STORED

    TOperation : An object which stores each Move, Delete, etc, and references
        to all objects concerned.
    TUndoList : Stores an array of refs to TOperation and creates, destroys,
        reuses the TOperation obejcts.

    FOperations is a TList which holds Memento references. Each Memento can
    perform Undo-Redo operations on something that gets edited via the user GUI.

    Have two indexes into the Transactions[] array:

      CurrentTransaction : index of the Transaction that is currently being
      recorded, or which was last recorded. Set to -1 if no Transaction is
      has been allocated.

      TopTransaction : index of the highest Transaction that has been allocated.
      When we record an edit, TopTranscation == CurrentTransaction. For every
      Undo, CurrentTransaction decreases below TopTransaction.

    when no Transactions are recorded
      O O O O O O O O O O O O O O O O
    ^
    TopOperation = -1
    ^
    LatestOperation = -1


    after one Memento is recorded
      O O O O O O O O O O O O O O O 0
      ^
      TopOperation
      ^
      LatestOperation


    when array is filled with Transactions
      O O O O O O O O O O O O O O O O
                                    ^
                                    TopTransaction
                                    ^
                                    LatestTransaction

    after one more Transactions is stored : oldest Transaction has been discarded.
    Other Transactions are all shifted one left in te array. Oldest Transcation
    is reused by placing it at top of the array.
     ____________<_________________
    |                             |
    O O O O O O O O O O O O O O O O
                                  ^
                                  TopTransaction
                                  ^
                                  LatestTransaction


    after some Undo commands.  Array same, but LatestTransaction is next one
    for undo.  Higher in array are Transactions ready for Redo.
    LatestTransactionIndex decreases and increases as Undo-Redo are performed.
    O O O O O O O O O O O O O O O O
                                  ^
                                  TopTransaction
                        ^
                        LatestTransaction

    As previous state, but a further editing transaction has been stored. All
    Redo has been thrown away and further redo is impossible.  Further Undo is
    possible, into earlier stored transactions.
    O O O O O O O O O O O O O O O O
                          ^
                          TopTransaction
                          ^
                          LatestTransaction
}


constructor TunUndo.Create( Capacity : integer );
var
  i : integer;
begin
  FTransactions := TList.Create;
  FTransactions.Capacity := Capacity;
  // fill FTransactions with TunTransactions objects
  for i := 0 to FTransactions.Capacity -1 do begin
      FTransactions.Add( TunTransaction.Create );
  end;

  // no undo or redos are presently stored
  LatestTransactionIndex := -1;
  TopTransactionIndex := -1;

  // no transaction in progress
  Stage := stNoTransaction;
end;

destructor TunUndo.Destroy;
var
  i : integer;
begin
  // discard stored Mementos
  Clear;

  // free Transactions
  for i := 0 to FTransactions.Count -1 do begin
      TunMemento(FTransactions[i]).Free;
  end;

  // delete list holding referenes to Transactions
  FTransactions.Free;

  inherited;
end;

function TunUndo.LatestTransaction : TunTransaction;
begin
  if LatestTransactionIndex < 0 then begin
      result := nil;
  end
  else begin
      result := TunTransaction(FTransactions[LatestTransactionIndex]);
  end;
end;

function TunUndo.PeekNext : TunTransaction;
begin
  // look to redo section of the queue
  if LatestTransactionIndex < TopTransactionIndex then begin
      result := TunTransaction(FTransactions[LatestTransactionIndex +1]);
  end
  else begin
      result := nil;
  end;
end;

// move LatestTransactionIndex to right (in Redo direction)
procedure TunUndo.Next;
begin
  if LatestTransactionIndex >= TopTransactionIndex then begin
      raise EUndo.Create( 'Call of Next beyond end' );
  end;
  inc( LatestTransactionIndex );
end;

// move LatestOperationndex to left (in Undo direction)
procedure TunUndo.Previous;
begin
  if LatestTransactionIndex < 0 then begin
      raise EUndo.Create( 'Call of Previous beyond beginning' );
  end;
  dec( LatestTransactionIndex );
end;


procedure TunUndo.Undo;
var
  Transaction : TunTransaction;
begin
  // undo latest transaction
  Transaction := LatestTransaction;

  // end of undo list
  if Transaction = nil then begin
      exit;
  end;

  Transaction.Undo;

  // now previous Operation is the Current Operation
  Previous;
end;

procedure TunUndo.Redo;
var
  Transaction : TunTransaction;
begin
  // Next List Operation is the one to redo
  Transaction := PeekNext;

  // nothing to redo
  if Transaction = nil then begin
      exit;
  end;

  Transaction.Redo;

  // now next Operation is Current Operation
  Next;
end;

procedure TunUndo.Clear;
var
  i : integer;
begin
  // clear all Undoes
  for i := 0 to LatestTransactionIndex do begin
      TunTransaction(FTransactions[i]).DiscardUndo;
  end;

  // clear all Redoes
  for i := LatestTransactionIndex +1 to TopTransactionIndex do begin
      TunTransaction(FTransactions[i]).DiscardRedo;
  end;

  LatestTransactionIndex := -1;
  TopTransactionIndex := -1;
  Stage := stNoTransaction;
end;

procedure TunUndo.BeginTransaction;
var
    i : integer;
begin
  // throw away any Redos
  for i := LatestTransactionIndex +1 to TopTransactionIndex do begin
      TunTransaction(FTransactions[i]).DiscardRedo;
  end;

  TopTransactionIndex := LatestTransactionIndex;

  Stage := stEnteredTransaction;

  // Add a Begin Transaction Memento here
//  AddMemento(

end;

procedure TunUndo.AddMemento( Memento : TunMemento );
var
    i : integer;
    OldestTransaction : TunTransaction;
begin
  // must be inside a transaction
  if not (Stage in [stEnteredTransaction, stHaveMemento]) then begin
    raise EUndo.Create( 'Adding Memento without transaction.' );
  end;

  // if this is first Memento in the current transaction
  if Stage = stEnteredTransaction then begin

    // if we have room, allocate the next empty operation location
    if TopTransactionIndex < FTransactions.Count -1 then begin
        Inc( TopTransactionIndex );
        Inc( LatestTransactionIndex )
    end

    // we don't have room, so move queue along
    else begin
        // free up oldest transaction location,
        OldestTransaction := TunTransaction( FTransactions[0] );
        OldestTransaction.DiscardUndo;

        // slide all operations down to bottom of list
        for i := 1 to FTransactions.Count -1 do begin
            FTransactions[i-1] := FTransactions[i];
        end;

        // leaving a vacated location at top of list
        LatestTransactionIndex := FTransactions.Count -1;
        TopTransactionIndex := LatestTransactionIndex;

        // reuse the oldest transaction by moving it to top of list
        FTransactions[LatestTransactionIndex] := OldestTransaction;
    end;

    // move move unto system to next state
     Stage := stHaveMemento;
  end;

  // put our Memento into the current Transaction
  LatestTransaction.AddMemento( Memento );
end;

procedure TunUndo.EndTransaction;
begin
  if not (Stage in [stEnteredTransaction, stHaveMemento]) then begin
      raise EUndo.Create( 'EndTransaction without BeginTransaction' );
  end;

  // if Stage = stEnteredTransaction, then no TunMemento's were stored and no
  // TunTransaction was allocated. Thus the entire transaction was not entered
  // into the Undo system.

  // end of Transaction
  Stage := stNoTransaction;
end;

end.

