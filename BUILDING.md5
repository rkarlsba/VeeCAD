What is VeeCAD?
===============
VeeCAD is a Windows Win32 program created with Delphi Pro 2009.

What you need to Build VeeCAD
=============================
Any version of Delphi 2009 or later. The VeeCAD source tree is self contained
and no additional libraries or VCL components need be installed. No database 
functionality is required. Later versions of Delphi may require small changes to
the source code.

Delphi Community Edition
========================
A free Delphi is available from www.embarcadero.com. You register, download,
run the installer and select to install Delphi for Windows. That gives you an 
IDE for building Forms and writing code. It has a good debugger. VeeCAD source 
code is currently maintained compatible with the current Community Edition, but
in future years may fall behind. In that case you may have to research the 
compiler error messages to make minor changes to source code. In the Delphi IDE
menu go "File -> Open Project", browse to "veecad.dpr" and click "Open".  Hit 
the Compile button and the VeeCAD project will build and run.

Other Tools
===========
The CHM help file is edited and compiled with "HelpMaker 7.4.4", a freeware
program that runs in Windows XP and Vista. Recommended to install HelpMaker in
a virtual machine running WinXP.

An icon editor for altering or editing the Windows icons stored in the 
exectuable.

A bitmap editor for graphics shown on buttons within the program.

InnoSetup for creating Windows installers.

Moving to github
================
After pushing this project to https://github.com/rkarlsba/veecad, I found github
doesn't like large files, so the file VeeCAD.sh6, exists as VeeCAD.sh6.xz. To
uncompress it, simply run 'unxz -k VeeCAD.sh6.xz' and remove VeeCAD.sh6 when you
don't need it anymore.

Source Files
============
\src - The Delphi source files.
\help\VeeCAD.sh6 - The HelpMaker project file.
\help\veecad_tmphhp\VeeCAD.chm - Helpmaker outputs the final CHM file here.

Documentation & Design
======================
\nets - netlist formats proposed or selected for import by VeeCAD
\notes - design and implementation of VeeCAD internals.

Installer Files
===============
\install\VCad_Free.iss the InnoSetup script
\install\buildfree.bat inserts an icon containing large image into the EXE.
\install\VeeCAD Install Checklist.doc how to build and distribute VeeCAD
\Output - InnoSetup outputs installer to this folder

End User Files
==============
\sample - VeeCAD and TinyCAD sample files installed for end user learning
\tutorial - VeeCAD and TinyCAD files installed for end user referred to by help file. 
\library - see section on library files below

End User Library Files
======================
**Standard VeeCAD outline lib
\library\*.per - the standard outline libraries for use by VeeCAD.

**Schematic libs that produce netlists compatible with Standard VeeCAD outline lib
\library\TinyCAd - TinyCAD schematic symbols that have package names and pinouts
   compatible with standard VeeCAD libs.
\library\Kicad - Kicad schematic symbols that have package names and pinouts
   compatible with standard VeeCAD libs,
\library\Converter - program to generate Kicad schematic libs from TinyCAD libs so
   only need to maintain TinyCAD libs.

**Special VeeCAD libs to match package libs from various programs
\library\DesignSpark - VeeCAD outline libraries to match DesignSpart basic lib.
\library\Proteus - VeeCAD outline libraries to match Proteus.
\library\XLDesigner - VeeCAD outline libraries to match XL Designer. 

Code Notes
==========
VeeCAD began in Delphi 5 and is an old program that grew and now has too many
interdependencies between units.

The net tracer/connectivity check is tricky since optimised for speed. 

VeeCAD could be ported to Lazarus/Free Pascal for cross-platfrom builds. 

Compiler Settings
=================
The code uses "Typed @ Operator = true". Nothing else is critical. The program
is fast with or without Optimization.

Conditional Defines
===================
In Delphi, search for '$IFDEF" to find where compiler defines are used. Most
defines are $DEFINE-d in the same file where they are used for debugging 
specific details. 

These global defines you can turn on in Delphi compiler settings "Conditional 
Defines": 
$IFDEF DEBUG - displays info on screen or other small useful debug aids.
$IFDEF DEBUGFORM - displays a debug window where Connective.pas can show objects
created during netlist tracing.

