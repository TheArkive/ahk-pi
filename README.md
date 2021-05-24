# AHK Portable Installer (now completely portable)

<img src="images/ahk-pi-main.png" width="420" align="top"/>

For details on how to use Fully Portable Mode, skip to that section below.

## Intro

[Posted on AutoHotkey.com Forums](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=73056)

This is a portable install manager and allows multiple versions of AutoHotkey to coexist simultaneously.  This script is meant to work with the portable `.zip` archives of AutoHotkey, NOT the setup `.exe` versions.  It is written in AHK v2.

The main function of AHK Portable Installer is for the user to specify the `base version` of AHK to be used for the system to run scripts.  This is done from the main window's list.

If you use the `AHK Launcher` feature, then the first line of every script is searched for a `first-line version comment` to indicate which version to run.  If there is no match, or there is no `first-line version comment`, then the selected `base version` is run instead.

If you use the `Ahk2Exe Handler` feature, then the same type of dynamic version matching as the `AHK Launcher` is done, but determines which compiler to use.  If there is no match, then the `base version` compiler is used.

If you are upgrading your version of AHK Portable Installer, you should be able to save your `Settings.json` file and copy it to the latest version script directory.  If you encounter problems, please post a comment in the forum post above, or open an issue on this repo.

If you need a version of `Window Spy for AHK v2` go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) on AHK forums.

If you want the latest version of `Ahk2Exe`, you can get it from the latest official AHK v1 zip, or from [here](https://github.com/AutoHotkey/Ahk2Exe).

For the latest test build of `Ahk2Exe` that conforms to the latest features/requirements of AHK v2 a136+ go [here](https://github.com/AutoHotkey/Ahk2Exe/commit/5fff25e5542d4ebdc5f7eba0024e53efff33a8f8).  For notes on this test release of Ahk2Exe, see [this post](https://www.autohotkey.com/boards/viewtopic.php?p=398771#p398771).

The latest versions of AutoHotkey_H v1 and v2 have an updated `Ahk2Exe.exe` included as well.

This script is now supported uncompiled, since McAffee has decided that some of the key (previously compiled) exe files are supposedly viruses (a false positive of course).  Running this as a script should mitigate this issue.

The following hotkeys are active while the script is running.

|Hotkey         |Description                                           |
| -------------:| ---------------------------------------------------- |
|MButton        |Runs selected script files (you can select multiple). |
|Shift + MButton|Open script file in specified text editor.            |
|Ctrl + MButton |Open the compiler with the selected script pre-filled.|

## Features
* Fully Portable Mode.  See the `Fully Portable Mode` section below.
* Associate the `.ahk` extension with any version of AHK on double-click.  (not in portable mode)
* Selectively choose which context-menu items appear in the context menu.  (not in portable mode)
* Associate any text editor with "Edit Script" in context menu easily.  (use SHIFT + MButton in portable mode)
* Define as many versions of AHK as you want to run in parallel.
* Checks for updates when prompted, or does so automatically if enabled.
* Displays the latest versions of AHK v1 and v2 (with internet connection only).
* Displays currently active version of AHK.
* Provides links to AHK v1 and v2 download pages / version archives.
* Easily invoke `WindowSpy.ahk`, `help file`, and the `Ahk2Exe` compiler for the selected `base version`.
* Edit templates for new AutoHotkey.ahk files from GUI.  (not in portable mode)

## Basic Setup

Grab the latest copy of AHK v2 alpha (currently a136), copy the desired version of `AutoHotkey32/64.exe` into the script dir and rename it to `AHK Portable Installer.exe`.  Always run this EXE file to launch the script.

File version info is now taken directly from the EXE file.  So the directory structure is less strict than before.

The AutoHotkey `base folder` is generally intended to look something like this:

Example:
```
C:\AutoHotkey    <-- place the base folder anywhere you want
             \_OLD_\old_versions_here...   <-- AHK folders here will not be parsed/listed
             \ahk version blah\...         <-- AHK folders for each version
             \ahk_h another_version\...    <-- AHK folders for each version
             \and_so_on\...                <-- AHK folders for each version

Folder Name format (suggested):
    [name_no_spaces] [version_no_spaces] [additional_info_optional]
                    ^                   ^
                  space               space

Examples:
    AutoHotkey v1.1.32.00
    AutoHotkey v2.0-a108-a2fa0498
    AutoHotkey_H v1.2.3.4
```

Don't modify the original structure of the `.zip` archives for any of the versions of AHK you intend to use.  Just unzip the contents to a folder, and rename it if you wish, otherwise you can use the default name (the `.zip` file name) for the folder.

Each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, and `Compiler` folder with `Ahk2Exe` and all necessary support files (like `.bin` files, `mpress.exe`, and/or `upx.exe` if you want to use it).

In general, for the best ease of use, you should always maintain a copy of the latest version of AutoHotkey v2 to run this script.  Then setup your other versions of AutoHotkey as you wish.  This will simplify your basic setup.

In non-portable mode, when you click `Activate EXE`, or double-click on a version in the list, this sets the `base version` and writes registry entries for the `.ahk` extension, context menu entries, and the template that corresponds to the major version (v1 or v2).  The associated template file will also be automatically copied (and overwritten) to `C:\Windows\ShellNew\Template.ahk`.

When using Fully Portable Mode, `Activate EXE` will not modify the registry at all.  It simply sets the `base version`.  Of course, you must leave the script running in the background when using Fully Portable Mode.

## AHK Launcher

If the `Use AHK Launcher` checkbox in the `Basics` tab is not checked, then none of the settings in the `AHK Launcher` tab apply.  With `AHK Launcher` disabled, every script you run will be run with the `base version` you selected in the main list.  If you want more flexibility with less effort to manage multiple versions of AutoHotkey for your scripts, then it is suggested to enable the `AHK Launcher`.

These settings allow the user to define a `first-line version comment` that corresponds to a particular AutoHotkey EXE version.  When a `first-line version comment` is added as the first line in a script, it identifies the AHK version that should be used.  When a script is run, the first line is checked for a match.  If no match is found, then the `base version` selected by the user is used to run the script.  This functionality is present in portable and non-portable mode.

Click the `+` and `-` buttons to add and remove entries.  Double-click on a list item to edit.  When adding an entry, give it a display name, specify the match type (regex or exact), the match string, and the `AutoHotkey.exe` file to be used to run the script when a match is made.

You can configure several (practically unlimited) versions of AutoHotkey and AutoHotkey_H to run side-by-side.  Once your settings are set, you won't have to change them again, unless you add/change a version of AHK for use.  Just don't forget to add the `first-line version comment` to your scripts!

Changing these settings can be done at any time.  When in non-portable mode, simply close the GUI after you are done making changes in the `AHK Launcher` tab in order for the changes to take effect.  In portable mode, (and when using the hotkeys listed above) the settings take effect immediately.

There are 9 default values to allow for running the following versions side by side:
* AHK v1/2 64/32-bit/ANSI
* AHK_H v1/2 32/64-bit
* The default match string type is regex.

You will need to specify a `AutoHotkey.exe` variant for each entry you intend to use (like `AutoHotkeyU32.exe`, etc).  Because regex is the default, spacing variations and optionally excluding the "v" for "v1" or "v2" is supported, and uppercase/lowercase does not matter.  You can remove the entries you don't need.

Examples of default match strings to use as your `first-line version comment` in your scripts are listed directly below.

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

You can of course modify these match settings and change the `first-line version comment` to be whatever you want for each version of `AutoHotkey.exe` you use.  You can even specify a very precise version number, or a special name, or a silly catch phrase, and then specify the corresponding version of AutoHotkey you desire.

## Ahk2Exe Handler and Compiling Scripts

If you select to enable the `Ahk2Exe Handler` from the `Basics` tab, then the `first-line version comment` will be parsed to find a match.  If a match is found, then the corresponding compiler for that version is launched.  If the `Ahk2Exe Handler` is disabled, then only the compiler that corresponds to the selected `base version` is launched.  This applies when using the context menu, and when using the CTRL + MButton hotkey.

For extra flexibility when compiling AutoHotkey scripts please look at the [Script Compiler Directives help docs for Ahk2Exe](https://www.autohotkey.com/docs/misc/Ahk2ExeDirectives.htm).

## Setting up Ahk2Exe

All versions of AutoHotkey v1 come with a compiler (Ahk2Exe), `.bin` files, and `mpress.exe`.  These versions of `Ahk2Exe` also work for AutoHotkey v2.  Just copy `Ahk2Exe.exe` and `mpress.exe` from the AHK v1 compiler folder to the AHK v2 compiler folder.  DO NOT copy the `.bin` files, unless you know what you are doing.

The latest versions of AutoHotkey_H v1 and v2, as of the updating of this document (2021/04/16), both have their own separate updated compilers which contain `Ahk2Exe.exe`.

So if you were to run all versions of AutoHotkey in parallel (in theory) your compiler setup for each version of AutoHotkey in your base folder should follow these general guidelines:

* All AutoHotkey v1 and v2 folders should have the same latest release of Ahk2Exe, but the `.bin` files will be different.
* All AutoHotkey_H v1 folders should have the same version compiler.  Just replace the older compiler with the newer one.
* All AutoHotkey_H v2 folders should have the same version compiler.  Just replace the older compiler with the newer one.

This setup will allow you to properly compile any version of AutoHotkey you wish to setup on your system.

## Fully Portable Mode

To enable Fully Portable Mode, check the checkbox in the Options tab.  No admin rights are required in this mode.  In this mode, AHK Portable Installer must remain running.  You can minimize to the taskbar or to the tray.  See the Options tab for settings you can use.

Enabling this mode has the following effects:

* Selecting a new `base version` will not modify the registry, and the `.ahk` extension is not registered.
* The options to show context menu items have no effect.

Note that whlie AHK Portable Installer is running the following hotkeys are active:

* MButton:  Run script (you can select multiple, then click MButton)
* SHIFT + MButton:  Edit Script, opens in your specified text editor.
* CTRL + MButton:  Compile Script, opens Ahk2Exe with the selected script file pre-filled in the Source field.

You can use these hotkeys with files on the desktop, or in any Explorer file browser window.

If you want AHK Portable Installer to run on startup, then check the `Run on system startup` checkbox in the Options tab.

## What AHK Portable Installer does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with modifying the App list of installed programs.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.
* WILL NOT automatically download new versions (at least for now).

## Troubleshooting and avoiding problems

1) It is NOT recommended to run this script along side a normal installation of AutoHotkey with the setup program, it is however theoretically possible.  But this script will override the proper install with its own settings in the registry.

2) If you move your AutoHotkey folder, then you must "re-activate" your chosen AutoHotkey `base version`  Simply click `Activate EXE` or double-click an item in the list.

3) Every version folder of AutoHotkey should have its own `help file`, `WindowSpy.ahk`, and `Compiler` folder.

4) You should generally always use the latest Ahk2Exe.  Remember there are 3 different Ahk2Exe's:
* AutoHotkey v1 and v2 all use the same version.
* AutoHotkey_H v1 has it's own compiler.  The latest one will work for all verions, just replace the olders ones with the latest.
* AutoHotkey_H v2 has it's own compiler.  The latest one will work for all verions, just replace the olders ones with the latest.

## To-Do List

* allow options to compile one script into multiple versions with minimal clicks (maybe)

## Other remarks...

This program will NOT circumvent User Account Control settings.  If you leave UAC enabled, then you will likely be prompted when this program performs certain actions, and certainly when write to the registry.  I leave it to the user to decide how to manage their UAC settings.

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.
