# AHK Portable Installer

<!-- <img src="images/ahk-pi2.png" width="420" align="top"/><img src="/images/ahk-pi10.png" width="420"/> -->

## Intro

[Posted on AutoHotkey.com Forums](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=73056)

Check [releases](https://github.com/TheArkive/ahk-pi/releases) for binaries.

If you need a version of `Window Spy for AHK v2` go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) on AHK forums.

This is a portable install manager.  This script is meant to work with the `.zip` archives of AutoHotkey, NOT the setup EXE versions.  It is written in AHK v2.  I won't support this program as a script.  It is meant to be run compiled.

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

Separate name and version with a space.  There should be NO spaces in the NAME or VERSION.  Note that most
of the version info comes from the folder name, so type out the version as you want it to appear in the
program.  The type (ANSI / UNICODE) and bitness (64/32 bit) comes from the EXE file, or in the case of
AutoHotkey_H, it comes from the subfolder the EXE is in.
```

In general, for best results, each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, and `Compiler` folder with `Ahk2Exe` and all necessary support files (like `.bin` files or `mpress.exe` if you want to use it).

When you click `Activate EXE` this writes registry entries for the `.ahk` extension, context menu entries, and the template that corresponds to the major version (v1 or v2) of AutoHotkey.  The associated template will be automatically written to `C:\Windows\ShellNew\Template.ahk`.

For more info on how to setup multiple compilers with AHK Portable Installer, read more below in the Ahk2Exe section.

## Ahk2Exe Handler

This feature requires the `AHK Launcher` to be enabled.  If the `Ahk2Exe Handler` is enabled, when you click "Compile Script" from the context menu, it reads your script's configured setting for what version of AutoHotkey to run, and then opens the corresponding compiler.

Currently, due to some significantly different behaviors of some versions of `Ahk2Exe`, this feature just opens the `Ahk2Exe` program associated with with script you clicked on, and auto-fills the script to be compiled.  More changes to come to improve automation!

You don't have to use this feature.  You can implement the default action of the "Compile Script" by unchecking the "Ahk2Exe Handler" in the "Extras" tab.  Doing this will only launch the compiler linked to the active version of AutoHotkey.

## AHK Launcher v2

<img src="/images/ahk-pi11.png" />

In the `AHK Launcher` tab, you can configure several (practically unlimited) versions of AutoHotkey and AutoHotkey_H to run side-by-side.  The first line of the script will be parsed for a comment containing a match-string that specifies the version of AutoHotkey to use to run the script.  The user determines what the match-string is, decides to match via exact-match or regex, and decides what EXE to run for each specified match in this tab.

When running a script, if a match is not found, the fallback operation is to launch the installed/activated version of AutoHotkey.

You can change these settings on-the-fly without actually clicking `Activate EXE`.  Just close the GUI after you are done making changes in order for the settings to take effect.

Use the plus/minus buttons to add/remove entries.  Double-click on a list item to edit it.

Key Notes:
* There are 9 default values to allow for running the following versions side by side:
  * AHK v1/2 64/32-bit/ANSI
  * AHK_H v1/2 32/64-bit
  * just specify the EXE to use for each one you intend to use.
* Spacing variations and excluding the "v" for "v1" or "v2" is supported with default regex.

You can change these settings on the fly without selecting another AutoHotkey EXE to reinstall / re-activate.

The default match-strings for AHK versions are regex.  Examples that are valid for default values are:

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

There isn't much to setting up the compiler for normal versions of AutoHotkey.  All versions of AutoHotkey v1 come with a compiler and `.bin` files, and `mpress.exe`.  These versions of `Ahk2Exe` also work for AutoHotkey v2.  Just copy `Ahk2Exe.exe` and `mpress.exe` in the AHK v1 compiler folder to the AHK v2 compiler folder.  Note, it is suggested to not copy over the `.bin` files.

AutoHotkey_H is a different story.  Setting up the compiler for AHK_H is more difficult but not impossible.  Simply copy the version of `AutoHotkey.exe` you want to use to the compiler folder and rename it to `Ahk2Exe.exe`.  If you have a 64-bit OS, then you should usually choose a 64-bit version of `AutoHotkey.exe`.  You will still be able to select to compile 32-bit versions of your script if desired.

After you copy over `AutoHotkey.exe` to the compiler folder, it's necessary to compile `Ahk2Exe` in order to use it with AHK Portable Installer.

MAKE SURE TO CHOOSE A DIFFERENT DESTINATION EXE, NOT AHK2EXE.EXE !!!

After it is compiled, you can delete the current `Ahk2Exe.exe` (that you copied over and renamed), and then rename your newly-compiled version to `Ahk2Exe.exe`.

Currently the latest version of AutoHotkey_H v1 compiler should compile itself fine.  For AutoHotkey_H v2, the latest version that is fully functional is version a108.  Use this version until user HotKeyIt is able to fix up a new stable release.  The latest AHK_H is a110 and has some critical issues.

## What AHK Portable Installer does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with modifying the App list of installed programs.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.
* WILL NOT automatically download new versions (at least for now).

## Troubleshooting

1) It is NOT recommended to run this script along side a normal installation of AutoHotkey with the setup program.

2) If you move your AutoHotkey folder, then you must reinstall / re-activate your chosen AutoHotkey version.

3) If you activate / install AutoHotkey more than once, you may be prompted by Windows to "select a program" to open `.ahk` files.  In most cases this will be the `AhkLauncher.exe`, or some form of `AutoHotkey.exe`.


## To-Do List

* improve some automation options with Ahk2Exe
* allow options to compile one script into multiple versions with minimal clicks

## Other remarks...

This program will NOT circumvent User Account Control settings.  If you leave UAC enabled, then you will likely be prompted when this program tries to write to the registry.  I leave it to the user to decide how to manage their UAC settings.

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.

If you need a version of Window Spy for AHK v2 go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) 
on AHK forums.

