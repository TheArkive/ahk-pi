# AHK Portable Installer

## To-Do List

* ~~allow user defined list of parallel versions of AutoHotkey to run used in 1st-line comment match~~
* ~~Ahk_Launcher must follow user defined list of specified parallel AHK versions~~
* ~~make Ahk2Exe Handler tool tips follow main script setting "Disable Tooltips"~~
* change Ahk2Exe Handler to only use Compiler in specified AHK folder
* no longer require renaming of AHK_H exe files

## Intro

[Posted on AutoHotkey.com Forums](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=73056)

Check [releases](https://github.com/TheArkive/ahk-pi/releases) for binaries.

If you need a version of Window Spy for AHK v2 go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) 
on AHK forums.

This is a portable install manager.  This script is meant to be run compiled, and is only meant to work with the `.zip` archives.  It is written in AHKv2.  If you run this as a script, switch to AHK v1, close, and try to reopen the script, it will not work.  For best results, please comipile, or use the included precompiled EXE(s).

Please make sure to use the 64-bit EXE if you are running 64-bit windows.  The uninstall process for 64-bit AHK won't uninstall reg key `HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey` if you use the 32-bit EXE on 64-bit Windows.

<img src="/images/ahk-pi2.png" width="420" align="top"/><img src="/images/ahk-pi10.png" width="420"/>

## Basic Setup

The AHK `base folder` is intended to look something like this:

Example:
```
C:\AutoHotkey    <-- place the base folder anywhere you want
             \ahk version blah\...
             \ahk_h anoterh_version\...
             \etc\...

Folder Name format:
    [name_no_spaces] [version_no_spaces] [additional_info_optional]

Examples:
    AutoHotkey v1.1.32.00
    AutoHotkey v2.0-a108-a2fa0498 extra_info not_used
    AutoHotkey_H v1.2.3.4

Separate name and version with a space.  There should be NO spaces in the NAME or VERSION.
Note that all VERSION info comes from folder name.  The type (ANSI / UNICODE) and bitness
(64/32 bit) comes from the EXE file.
```

NOTE: If you are using AutoHotkey_H, you will need to append the appropriate suffix to the exe file name:

```
AutoHotkey.exe  --->  AutoHotkey_HA32MT.exe   (ANSI)
                      AutoHotkey_HA32.exe
                      AutoHotkey_HU32MT.exe   (Unicode)
                      AutoHotkey_HU32.exe
                      AutoHotkey_HU64MT.exe   (MT = DLL in compiled exe)
                      AutoHotkey_HU64.exe
```

Please choose one of the specific file names above for AutoHotkey_H exe files.  The AutoHotkey.exe file is deleted and the selected EXE is copied to `AutoHotkey.exe`.  As a precaution, any version named `AutoHotkey.exe` is NOT displayed in the program.  This may change in the future for AHK_H since I'm still trying to figure out how `Ahk2Exe` works for AutoHotkey_H.

There is no "installation" for this script/program.  Just download, run, and select your AHK base folder.

In general, each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, `Compiler` folder with `Ahk2Exe` and all necessary support files (like `.bin` files or `mpress.exe` if you want to use it).

There is no need to keep `Installer.ahk` or `Template.ahk` unless you have a need for them.

When you activate an EXE (which writes reg entries for the `.ahk` extension) the template that corresponds to the major version (v1 or v2) will be automatically written to `C:\Windows\ShellNew\Template.ahk` based on the EXE you selected.

You can get a copy of Window Spy for AHK v2 [here](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333&sid=3b87fff7974d5900bc41619869692564).

## What this does...

As a portable installer, based on your selected/activated version, here's what it does:

* Writes registry values to associate the `.ahk` extension.
* Writes registry values to define the default `.bin` file to use with Ahk2Exe compiler.
* Writes registry values to enable `mpress.exe` if present in `Compiler` folder (or disables it if not).
* Writes registry entries to associate `.ahk` extension with AutoHotkey.

If not using the fancy Ahk2Exe Handler (the default), the auto loading of the `.bin` files requires that each AHK folder has it's own Ahk2Exe `Compiler` folder, and that all `.bin` files retain their original names.

This program also:

* Checks for updates when prompted, or does so automatially if enabled.
* Displays the latest versions of AHK v1 and v2 (with internet connection of course).
* Displays currently active version of AHK.
* Easy access to edit templates for new AutoHotkey.ahk files with Context Menu > New > ...
* Provides links to AHK v1 and v2 download pages / version archives.
* Allows you to invoke `WindowSpy.ahk`, `help file`, and opt to Uninstall all traces of AHK in the registry.
* Allows running AHK v1 and v2 side-by-side with minimal modification (see AHK Launcher below).

Please make sure to use the 64-bit EXE if you are running 64-bit windows.  The uninstall process for 64-bit AHK won't uninstall reg key `HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey` if you use the 32-bit EXE on 64-bit Windows.

## fancy Ahk2Exe Handler

If you don't use the fancy Ahk2Exe Handler (default) then each AHK folder should have its own `Compiler` folder with `.bin` files and `mpress.exe` if you need it (and of course `Ahk2Exe.exe`).  Otherwise you can place Ahk2Exe in a single folder and not have it copied into every AHK folder.  If you do this, and you want to combine AHK v1 and v2 `.bin` files, be sure to rename the `.bin` files to add " v1" or " v2" as needed, except for `AutoHotkeySC.bin`.  Otherwise if you only use `.bin` files from a particular version of AHK, then you don't need to rename them.

See directly below for an example renaming the bin files.  When you use the context menu and click `Compile`, a small selection window will open.

<table width="100%">
  <tr>
    <th>Rename example</th>
    <th>fancy AHK Handler</th>
  </tr>
  <tr>
    <td width="200"><img src="/images/ahk-pi5.png" /></td>
    <td width="200"><img src="/images/ahk-pi7.png" /></td>
  </tr>
</table>
Filter 32-bit, 64-bit, or all with the drop-down menu.  The filter remembers your last selection.  Double-click the list to move quickly, or single-click to customize the output EXE in the edit box below.

After you have made your selection, the Ahk2Exe window will open up with all selected options pre-filled.  Also, if you have an `.ico` file named the same as your `.ahk` script, then the icon selection will be auto-filled as well.

Options to Auto-Start and Auto-Close the compiler are in the main GUI > Extras tab.

![](/images/ahk-pi8.png)

## AHK Launcher v2

Now you can run several (practically unlimited) versions of AutoHotkey side-by-side.  I've designed the AhkLauncher.exe to look for the following info to determine the AHK version of the script:

* support for appending AHK version to the end of the file name has been removed
* add AHK version as first comment:
    * ; AHK v1 32-bit
    * ; AHK_H v2 64-bit
* in the main window > Extras tab, you can define as many versios of AHK as desired with regex
* default values allow for specifying the following versions as first-line comment:
  * AHK v1 64-bit
  * AHK v1 32-bit
  * AHK v2 64-bit
  * AHK v2 32-bit
  * AHK_H v1/2 32/64-bit ... 8 versions total in default settings
* spacing variations accounted for in the regex
* specify the EXE you want to associate with each entry in the Extras tab and get started!
* more specific regex match allows you to specify any major/minor/type/bitness version of AHK

You can also specify entries to differentiate between MT versions of AHK_H and non-MT versions.  If you need help with that regex just add an issue and I'll respond.

## What this does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with installing or uninstalling.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.
* WILL NOT automatically download new versions.

If you install/activate AutoHotkey, and then move your AHK folder, then you may be prompted to specify a program to associate before everything works nicely.  This shouldn't happen.  Just click the uninstall button, and then reinstall/activate your desired version of AutoHotkey.

Some of these features may change or be added in the future.

This program will NOT circumvent User Account Control settings.  If you leave UAC enabled, then you will likely be prompted when this program tries to write to the registry.  I leave it to the user to decide how to manage their UAC settings.

I may take some hints from the `Installer.ahk` and attempt to work around this, but this program does enough in the registry (for my preference).

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.

If you need a version of Window Spy for AHK v2 go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) 
on AHK forums.
