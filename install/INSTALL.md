# Kicad install checklist

## Kicad Library Files Checklist  (Once per full & free version release set.)
- Run “library\MakeInstalledKicadLibrary.bat” to create Kicad library files in installed Kicad folder under “C:\Program Files”.
- Run Kicad and check new library files.
- Run “library\converter\MakeKicadLibrary.bat” to create a set of Kicad library files at library\Kicad.

## VeeCAD Full Open Source Version Install Checklist

### Delphi
- Project -> Options -> Delphi Compiler -> Conditional Defines set to blank
- Set Version Info
- Build All
- Run and Check.
- Run BuildFree.bat which places Vista icon into EXE

### InnoSetup
- Use InnoSetup script VCad_Free.iss
- Set version number (2 places)
- Save script
- Run
- Perform test installation

### Files
- Rename Setup.exe
- Zip renamed file
- Rename ZIP

## VeeCAD Release Checklist

### Menus
- Perform basic and netlist import tutorials
- Menus look correct (not greyed wrongly)
- Check project save then load round trip.
- Check Copy Graphic

### Upload Free Version to Website Checklist
- Upload free version installer zip file ( eg. VeeCAD_Free_2_28_2_0.zip to public_html
- Edit public_html/.htaccess file to redirect free version downloads to new zip file
- Edit public_html/updatefree.php to have new version numbers and file name.
- Start VeeCAD free and go Help | Check for Updates to test.
- Edit public_html/free.html to show any new features.
- Post on forum “V2.27.0.0 Free Version Released”



