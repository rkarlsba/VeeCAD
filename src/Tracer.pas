unit Tracer;

interface

{***************************************************
  Tracer Class traces connections without a Netlist

  This class finds groups of interconnected strips.
  It does flag a simple error where a pin lies on a
  break - but otherwise it ignores pins and nets.
 **************************************************}

uses Connective;

type TcnScanType = ( stNetScan, stSimpleScan );


type TveTracer = class( TConnectivity )
protected
  FScanType : TcnScanType;
  procedure PropagateConnections;

public
  property ScanType : TcnScanType read FScanType;
  procedure CheckSimple;
  procedure Check;
end;



implementation


procedure TveTracer.PropagateConnections;

    // handle nets at both ends of a link
    // Return True = a strip has had a net change made on this pass.
    // Keep calling for all links until returns False because no futher nets
    // resolved.

    function PropagateLinkConnection( Link : TcnLink ) : boolean;
    var
        StartStripSet, EndStripSet : TcnStripSet;

    begin
        // assume nothing will change
        result := False;

        // if one end of link has no strip, get out - pointers are nil!
        if (Link.StartStrip = nil) or (Link.EndStrip = nil) then begin
            exit;
        end;

        // get local references to stripsets
        StartStripSet := Link.StartStrip.StripSet;
        EndStripSet := Link.EndStrip.StripSet;

        // if both ends of link are in same stripset, don't make a fuss, just
        // let it pass through - stripsets were already combined, or link
        // lies along a strip or between overlapping strips etc.
        if (StartStripSet = EndStripSet) then begin
            exit;
        end;

        // combine the stripsets into one
        AddToStripSet( StartStripSet , EndStripSet );
        result := True;
    end;


    function PropagateWireConnection( WireSet : TcnWireSet ) : boolean;
    var
        i : integer;
        StripSet : TcnStripSet;
        MasterStripSet : TcnStripSet;
    begin
        // default is no new nets propagated
        result := False;

        // wires that do not sit on a strip were not added to WireSets, therefore
        // all Wire.Strip.StripSet is always valid.
        MasterStripSet := WireSet.Wires[0].Strip.StripSet;

        // combine all stripsets which connect via wires (thru this wireset)
        for i := 1 to WireSet.WireCount -1 do begin
            StripSet := WireSet.Wires[i].Strip.StripSet;
            if StripSet <> MasterStripset then begin
                AddToStripSet( MasterStripSet, StripSet );
                // signal that at least one connection made
                result := True;
            end;
        end;
    end;

var
    Changed : boolean;
    i : integer;
begin
    repeat
        Changed := False;

        for i := 0 to FLinks.Count -1 do begin
            Changed := Changed or PropagateLinkConnection( TcnLink(FLinks[i]) );
        end;

        for i := 0 to FWireSets.Count -1 do begin
            Changed := Changed or PropagateWireConnection( TcnWireSet(FWireSets[i]) );
        end;
    until not Changed;
end;


procedure TveTracer.CheckSimple;
begin
    Clear;

{$IFDEF DEBUGFORM}
    if Assigned( FOnDebugStart ) then begin
        FOnDebugStart;
    end;
{$ENDIF}
    // read all pin data into Cells[][]
    BuildPins;

    // mark as error where a break coincides with pin
    CheckBreaksOnPins;

    // copy over striprsets from Board StripGroups. Mark strips that include
    // a break as Broken.
    BuildStrips;

    // rescan Broken stripsets into new stripsets
    RescanBrokenStripSets;

    // build a SegmentSet for each TbrBoard.SegmentGroup
    BuildSegmentSets;

    // connect strips together using segments
    CombineStripsetsBySegments;

    // build an array of link objects, and record on each the start and end
    // strips (or stripsets)
    BuildLinks;

    // group connected wires to form wiresets
    BuildWireSets;

    // follow connections to leave stripsets for each connected strips
    PropagateConnections;

    // Find first pin from left of strip - used to identify unconnected strips
    // since FirstPin.x, FirstPin.y has a Cell with no pins if strip is empty
    FindFirstPins;
end;


procedure TveTracer.Check;
begin
    Netlist := FProject.Netlist;

  // if we don't have a netlist, just follow traces, links and wires
  if Netlist.NodeCount <= 0 then begin
      FScanType := stSimpleScan;
      CheckSimple;
  end
  // we do have a netlist, so full check
  else begin
      FScanType := stNetScan;
      inherited Check;
  end;
end;


end.
