TinyCAD to Kicad Library Converter
-----------------------------------

// command line params
eg. TinyCad_Kicad.exe c:\myfolder\*.TCLib c:\myfolder\Kicad

// the first command line param defines one of more files.

    // : a single file c:\myfolder\mylib.TCLib
    // : multiple files using a wildcard c:\myfolder\*.TCLib 
    
// the second command line param defines an output directory
    // c:\myfolder\Kicad

After startup, the Memo shows all the input files that have been located. If
no files are located, the Memo shows, "No files found at <path\name>".

The Display Library and Display Kicad buttons operate only on the first file
listed in the memo. 

Display Library reads the TcLIb SQLite file and displays the data for all the 
symbols contained in it.

The Display Kicad button shows the corresponding Kicad (text) file generated
from the TinyCAD library.  

The Convert Batch button causes all TinyCAD library files to be processed, each
one producing a corresponding Kicad .lib file in the output directory.


************ KICAD FORMAT **************

# GENERIC DIP14                          << spaces are OK in this comment string
#
DEF GENERIC_DIP14 U 0 20 Y Y 1 L N       <<- no spaces allowed in "GENERIC DIP14"
F0 "U" -500 1000 50 H V L C
F1 "GENERIC DIP14" -500 900 50 H V L C   <<- name must match DEF line, so no spaces also
F2 "DIP14" 0 0 50 H I C C
$FPLIST
 DIP14
$ENDFPLIST
DRAW
X ~ 1 -500 600 200 R 50 50 1 0 U
X ~ 2 -500 400 200 R 50 50 1 0 U
X ~ 3 -500 200 200 R 50 50 1 0 U
X ~ 4 -500 0 200 R 50 50 1 0 U
X ~ 5 -500 -200 200 R 50 50 1 0 U
X ~ 6 -500 -400 200 R 50 50 1 0 U
X ~ 7 -500 -600 200 R 50 50 1 0 U
X ~ 10 500 -200 200 L 50 50 1 0 U
X ~ 11 500 0 200 L 50 50 1 0 U
X ~ 12 500 200 200 L 50 50 1 0 U
X ~ 13 500 400 200 L 50 50 1 0 U
X ~ 14 500 600 200 L 50 50 1 0 U
X ~ 8 500 -600 200 L 50 50 1 0 U
X ~ 9 500 -400 200 L 50 50 1 0 U
S -300 800 300 -800 0 0 8 N
A 0 800 50 1800 -900 0 0 8 N -50 800 0 750
A 0 800 50 -900 0 0 0 8 N 0 750 50 800
ENDDRAW
ENDDEF
#