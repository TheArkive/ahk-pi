# AHK Portable Installer

<!-- <img src="images/ahk-pi2.png" width="420" align="top"/><img src="/images/ahk-pi10.png" width="420"/> -->

## Intro

[Posted on AutoHotkey.com Forums](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=73056)

Check [releases](https://github.com/TheArkive/ahk-pi/releases) for binaries.

If you need a version of `Window Spy for AHK v2` go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) on AHK forums.

This is a portable install manager.  This script is meant to work with the portable `.zip` archives of AutoHotkey, NOT the setup `.exe` versions.  It is written in AHK v2.

I am now going to support this script uncompiled, since McAffee has decided that some of the key exe files are supposedly viruses.  Running this as a script should mitigate this issue, but this introduces one key change to how this is meant to run:

<b><font color="red">
If you run this as a script (not compiled), you MUST select ONLY one of the AHK v2 versions (currently only alphas - and do NOT pick AHK_H v2) to install as your primary base install for AutoHotkey.

DO NOT select any other version of AHK other than AHK v2 (non-AHK_H) as your base install.  If you restart the script after selecting an AHK v1 base version, this script WILL NOT WORK.  I have not yet tested this script with AHK_H v2.

If you want to compile this script, you must compile 3 files:

* AHK Portable Installer.ahk  <-- main script
* Ahk2Exe_Handler.ahk         <-- support element
* AhkLauncher.ahk             <-- support element

If you run this script compiled, then you can choose any AHK version as your base version, and you can change the base installed version at will.
</font></b>

I'll create a detailed setup tutorial for this script soon.  For now please see "Basic Setup" below.  I have made a few updates to try and clarify the key options that govern how this script runs and how it allows you to run all version of AHK with minimal effort.

## Features
* Associate the .ahk extension with any version of AHK on double-click.
* Selectively choose which context-menu items appear in the context menu.
* Associate any text editor with "Edit Script" in context menu easily.
* Define as many versions of AHK as you want to run in parallel.
* Automatically launch the appropriate compiler from "Compile Script" context menu.
* Checks for updates when prompted, or does so automatically if enabled.
* Displays the latest versions of AHK v1 and v2 (with internet connection of course).
* Displays currently active version of AHK.
* Provides links to AHK v1 and v2 download pages / version archives.
* Allows you to invoke `WindowSpy.ahk` and `help file` for active AHK version from GUI.
* Easy access to edit templates for new AutoHotkey.ahk files from GUI.

## Basic Setup

The AHK `base folder` is intended to look something like this:

Example:
```
C:\AutoHotkey    <-- place the base folder anywhere you want
             \ahk version blah\...
             \ahk_h another_version\...
             \etc\...

Folder Name format:
    [name_no_spaces] [version_no_spaces] [additional_info_optional]

Examples:
    AutoHotkey v1.1.32.00
    AutoHotkey v2.0-a108-a2fa0498 extra_info not_used
    AutoHotkey_H v1.2.3.4
```

Separate name and version with a space.  There should be NO spaces in the NAME or VERSION in the folder name.  Note that most of the version info comes from the folder name, so type out the version as you want it to appear in the program.  The type (ANSI / UNICODE) and bitness (64/32 bit) comes from the EXE file, or in the case of AutoHotkey_H, it comes from the subfolder the EXE is in.  Don't modify the original structure of the `.zip` archives for any of the versions of AHK you intend to use.

In general, for best results, each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, and `Compiler` folder with `Ahk2Exe` and all necessary support files (like `.bin` files or `mpress.exe` if you want to use it).

When you click `Activate EXE` this writes registry entries for the `.ahk` extension, context menu entries, and the template that corresponds to the major version (v1 or v2) of AutoHotkey.  The associated template will be automatically written to `C:\Windows\ShellNew\Template.ahk`.  The AHK_Launcher.exe (or .ahk) is used to dynamically launch the appropriate version of AHK based on your config settings in the <font color="red">AHK Launcher</font> tab.

For more info on how to setup multiple compilers with AHK Portable Installer, read more below in the <font color="red">Setting Up Ahk2Exe</font> section.

## Ahk2Exe Handler

This feature is currently under construction.  Currently it will only open the Ahk2Exe window with the script name and icon pre filled.

## AHK Launcher Tab

<img src="images/ahk-pi-ahk2exe.png" />

In the `AHK Launcher` tab, you can configure several (practically unlimited) versions of AutoHotkey and AutoHotkey_H to run side-by-side.  This works by parsing the first line of the script for a comment containing a match-string that specifies the version of AutoHotkey to use to run the script.  The user determines what the match-string is, decides to match via exact-match or regex, and decides what EXE to run for each specified match in this tab.  Once your settings are set, you won't have to change them again, unless you add/change a version of AHK for use.

When running a script, if a first line match is not found, the fallback operation is to launch the installed/activated version of AutoHotkey.

Changing these settings can be done on-the-fly.  Just close the GUI after you are done making changes in the <font color="red">AHK Launcher Tab</font> in order for the changes to take effect.

Use the plus/minus buttons to add/remove entries.  Double-click on a list item to edit it.

Key Notes:
* There are 9 default values to allow for running the following versions side by side:
  * AHK v1/2 64/32-bit/ANSI
  * AHK_H v1/2 32/64-bit
  * just specify the EXE to use for each one you intend to use.
* Spacing variations and optionally excluding the "v" for "v1" or "v2" is supported with default regex.

The default match-strings for AHK versions are regex.  Valid match strings to use as your first-line comment in your scripts are listed directly below.  Any space in the match can actually be multiple spaces if desired, and the "v" (as in "v1" or "v2") is optional.

```
; AHK v1            <-- for 64-bit, optionally include "64-bit"
; AHK v1 32-bit
; AHK v1 ANSI
; AHK v2            <-- for 64-bit, optionally include "64-bit"
; AHK v2 32-bit
; AHK_H v1          <-- for 64-bit
; AHK_H v1 32-bit
; AHK_H v2          <-- for 64-bit
; AHK_H v2 32-bit
```

## Setting up Ahk2Exe

Remember, each version of AutoHotkey you configure to use with AHK Portable Installer should have its own compiler folder with `Ahk2Exe.exe` in it.

There isn't much to setting up the compiler for normal versions of AutoHotkey.  All versions of AutoHotkey v1 come with a compiler and `.bin` files, and `mpress.exe`.  These versions of `Ahk2Exe` also work for AutoHotkey v2.  Just copy `Ahk2Exe.exe` and `mpress.exe` in the AHK v1 compiler folder to the AHK v2 compiler folder.  Note, it is suggested to not copy over the `.bin` files from AHK v1 to AHK v2 folders.  Copy `Ahk2Exe.exe` only for best/easiest results.

AutoHotkey_H is a different story.  Setting up the compiler for AHK_H is more difficult but not impossible.  Simply copy the version of `AutoHotkey.exe` you want to use to the compiler folder and rename it to `Ahk2Exe.exe`.  If you have a 64-bit OS, then you should usually choose a 64-bit version of `AutoHotkey.exe`.  You will still be able to select to compile 32-bit versions of your script if desired.

After you copy over `AutoHotkey.exe` to the compiler folder (and renamed it to `Ahk2Exe.exe`), it's necessary to compile `Ahk2Exe` in order to use it with AHK Portable Installer.

MAKE SURE TO CHOOSE A DIFFERENT DESTINATION EXE, NOT AHK2EXE.EXE !!!

After it is compiled, you can delete the current `Ahk2Exe.exe` (the `AutoHotkey.exe` binary that you copied over and renamed), and then rename your newly-compiled version to `Ahk2Exe.exe`.

Currently the latest version of AutoHotkey_H v1 compiler should compile itself fine.  For AutoHotkey_H v2, the latest version I have tested that is fully functional is version a108.  AHK_H v2 has been updated recently (2020-12-31), and I will be integrating/testing it soon.

## What AHK Portable Installer does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with modifying the App list of installed programs.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.
* WILL NOT automatically download new versions (at least for now).

## Troubleshooting

1) It is NOT recommended to run this script along side a normal installation of AutoHotkey with the setup program, it is however theoretically possible.  But this script will override the proper install with its own settings.

2) If you move your AutoHotkey folder, then you must reinstall / re-activate your chosen AutoHotkey version.  If you don't re-activate / re-install then you will likely be prompted to "select an application" when running scripts.

## To-Do List

* improve some automation options with Ahk2Exe
* allow options to compile one script into multiple versions with minimal clicks

## Other remarks...

This program will NOT circumvent User Account Control settings.  If you leave UAC enabled, then you will likely be prompted when this program tries to write to the registry.  I leave it to the user to decide how to manage their UAC settings.

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.

If you need a version of Window Spy for AHK v2 go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) 
on AHK forums.
