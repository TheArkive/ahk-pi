# AHK Portable Installer (now completely portable)

<img src="images/ahk-pi-main.png" width="420" align="top"/>

For details on how to use Fully Portable Mode, skip to that section below.

Latest updates:

* AHK Launcher has been replaced by usage of the #REQUIRES directive (thanks to vvhitevvizard and lexikos for inspiration).
* Downloading is now possible through the UI.
* The default `Base Folder` is now the script directory.
* Installs to HKCU by default.  Can be changed to HKLM in `Settings > Basics tab`.
* Minor bug fixes, and small adjustments.
* Reworked some code to be less redundant.

If you need a version of `Window Spy for AHK v2` go to [this thread](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333) on AHK forums.

If you want the latest version of `Ahk2Exe`, you can get it from the latest official AHK v1 zip, or from [here](https://github.com/AutoHotkey/Ahk2Exe).

For the latest test build of `Ahk2Exe` that conforms to the latest features/requirements of AHK v2 a136+ go [here](https://github.com/AutoHotkey/Ahk2Exe/commit/5fff25e5542d4ebdc5f7eba0024e53efff33a8f8).
For notes on this test release of Ahk2Exe, see [this post](https://www.autohotkey.com/boards/viewtopic.php?p=398771#p398771).

## Intro

[Posted on AutoHotkey.com Forums](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=73056)

This is a portable install manager and allows multiple versions of AutoHotkey to coexist simultaneously.  <font color="red">This script is meant to work with the portable `.zip` archives of AutoHotkey, NOT the setup `.exe` versions.</font>  It is written in AHK v2.

You can use this program in 1 of 2 ways:
1) Change the active AHK version when desired to run different scripts according to selected version.
2) Use the #REQUIRES directive in your scripts to specify a version to use.  This program will parse choose the EXE based on that criteria.

This program can be run as an installer, or as a portable program.  As an installer, registry entries are written to the system to implement the `.ahk` file type association.  In Fully Portable mode, the program must remain running in the background.  Use the hotkes below when using Fully Portable mode.

## Features
* Download/remove AHK versions directly from the UI.
* Fully Portable Mode.  See the `Fully Portable Mode` section below.
* Associate the `.ahk` extension with any version of AHK.  (not in portable mode)
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

Grab the latest copy of AHK v2 alpha (currently a138), copy the desired version of `AutoHotkey32/64.exe` into the script dir and rename it to `AHK Portable Installer.exe`.  Always run this EXE file to launch the script.

Now you can download AutoHotkey through the UI.  Just click `Settings`, pick a major version from the DropDownList, then select/downlad your desired version(s).  To remove a version of AHK, right click on an entry in the main list, and select `Remove this version` from the context menu.

The AutoHotkey `base folder` is now located in the script directory by default.  As usual, it can be moved to another location if desired.  The structure of the `base folder` is described below.  All downloads are cached.  You can open the `base folder` and `temp folder` from the Download tab.

Example:
```
C:\AutoHotkey\   <-- base folder -> place this anywhere you want, or leave it in the script folder
             \_OLD_\old_versions_here...   <-- AHK folders here will not be parsed/listed
             \ahk version blah\...         <-- AHK folders for each version
             \ahk_h another_version\...    <-- AHK folders for each version
             \and_so_on\...                <-- AHK folders for each version
```

Each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, and `Compiler` folder with `Ahk2Exe` and all necessary support files (like `.bin` files, `mpress.exe`, and/or `upx.exe` if you want to use it).  The only exception to this is AHK v2.  Currently there is no official compiler or WindowSpy for the latest v2 alpha.  See the links above to acquire these.  For the time being the compiler and WindowSpy must be added to AHK v2 alphas manually.

Now you need to decide how you want to use this program:
1) Change the version as needed to run different scripts.
2) Use the #REQUIRE directive in your scripts (recommended).  You will need to make small changes to your scripts, but you will be able to run any script of any version at any time.  Read more below.
3) You also need to decide if you want to use this program as an installer (registers the `.ahk` extension on the system) or if you want to run in Fully Portable mode.

## Installer Mode

This is the default mode.  Simply leave `Fully Portable Mode` unchecked.  When installing, by default method is for the `Current User`.  You can optionally install for `All Users`, but you need to run this program as Admin.  To change the install mode, click `Settings > Basics tab`.

In this mode, when you click `Install` the `base version` is set and the script writes registry entries for the `.ahk` extension, and context menu entries (Right-Click > New).

After you have selected / installed your preferred version, close the program for the settings to take effect.

## Fully Portable Mode

Go to Settings > Options tab and check the `Fully Portable Mode` checkbox.  In this mode no registry entries are written.  You can use the hotkeys below to run and edit scripts.  After you select your desired version click the `Select` button to change the selected base version.

Hotkeys for Fully Portable mode:

|Hotkey         |Description                                           |
| -------------:| ---------------------------------------------------- |
|MButton        |Runs SELECTED script files.                           |
|Shift + MButton|Open script file in specified text editor.            |
|Ctrl + MButton |Open the compiler with the selected script pre-filled.|

If you want to use Fully Portable Mode, then you will also want to consider the following settings in the Options tab:

* Hide Tray Icon
* Close to Tray
* Minimize on Startup
* Run on System Startup

## Using the #REQUIRES directive

The old `AHK Launcher` is dead.  Now you use the #REQUIRES directive to run scripts.

Example:
```
    SYNTAX:  #Requires [product] [version] [; options are optional]

#Requires AutoHotkey 2.0-a136                   <-- Uses a136, with system bitness.
#Requires AutoHotkey 2.0-a ; 32-bit             <-- Uses the latest v2 alpha on the system
                                                    and uses only 32-bit.
#Requires AutoHotkey 2.0-a138 ; 64-bit admin    <-- Uses only v2 alpha a138, uses 64-bit
                                                    and runs script as admin.
; #Requires AutoHotkey 1.1.33 ; 32-bit          <-- For versions of AutoHotkey that don't have
                                                    the #Requires directive, simply comment
                                                    out the directive but format it the same.
```

At a minimum specify the product and the version.  For the most part, how the script selects the EXE to use is the same a the #REQUIRES directive, so please read up on it in the docs, but there are a few differences:

* If you don't specify an exact version, the latest version available on the system that matches the #REQUIRES directive is used.
* AHK docs specify that including "AutoHotkey" is optional, but since this script also works with AutoHotkey_H, specifying the product is required.
* If you don't specify a #REQUIRES directive then the selected/installed `base version` is used.

## Compiling Scripts

The #REQUIRES directive is also used to determine which compiler to use.  The logic is the same as the section above.  If no #REQUIRES directive is used, then the selected `base version` compiler is used.

## Setting up Ahk2Exe

All versions of AutoHotkey v1 come with a compiler (Ahk2Exe), `.bin` files, and `mpress.exe`.  These versions of `Ahk2Exe` also work for AutoHotkey v2.  Just copy `Ahk2Exe.exe` and `mpress.exe` from the AHK v1 compiler folder to the AHK v2 compiler folder.  DO NOT copy the `.bin` files, unless you know what you are doing.

The latest versions of AutoHotkey_H v1 and v2, as of the updating of this document (2021/04/16), both have their own separate updated compilers which contain `Ahk2Exe.exe`.

So if you were to run all versions of AutoHotkey in parallel (in theory) your compiler setup for each version of AutoHotkey in your base folder should follow these general guidelines:

* All AutoHotkey v1 and v2 folders should have the same latest release of Ahk2Exe, but the `.bin` files will be different.
* All AutoHotkey_H v1 folders should have the same version compiler.  Just replace the older compiler with the newer one.
* All AutoHotkey_H v2 folders should have the same version compiler.  Just replace the older compiler with the newer one.

This setup will allow you to properly compile any version of AutoHotkey you wish to setup on your system.

## What AHK Portable Installer does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with modifying the App list of installed programs.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.

## Troubleshooting and avoiding problems

1) It is NOT recommended to run this script along side a normal installation of AutoHotkey with the setup program, it is however theoretically possible.  But this script will override the proper install with its own settings in the registry.

2) If you move your AutoHotkey folder, then you must "re-install" your chosen AutoHotkey `base version`  Simply click `Install` again to update registry entries that refer to the location of AHK Portable Installer.

3) Every version folder of AutoHotkey should have its own `help file`, `WindowSpy.ahk`, and `Compiler` folder.

4) You should generally always use the latest Ahk2Exe.  Remember there are 3 different Ahk2Exe's:
* AutoHotkey v1 and v2 all use the same version.
* AutoHotkey_H v1 has it's own compiler.  The latest one will work for all verions, just replace the olders ones with the latest.
* AutoHotkey_H v2 has it's own compiler.  The latest one will work for all verions, just replace the olders ones with the latest.

5) In regards to `A_AhkPath`:

For compiled scripts, this is usually pulled from the registry.  If you are managing multiple versions of AHK using this tool, remember that the `base version` selected from the main GUI is the only one written to the registry.  The `AHK Portable Installer.exe` file is what sorts out which AHK exe to use based on the `first-line version comment` (defined in the `AHK Launcher` tab).  Just keep this in mind if you need (for some reason) to reference `A_AhkPath` from a compiled script on your system while using AHK Portable Installer.

6) Running scripts in Fully Portable Mode:
You need first `single click` with the `left mouse button` to select a script, and THEN you can `middle click` to run the script.  Usually after running a script it is not uncommon for the selection to be undone, especially when scripts are on the desktop.  So just remember, SELECT the script first (single left click) then `middle click` to run, every time.  If the file is already selected you can just `middle click`.

## To-Do List

* Allow options to compile one script into multiple versions with minimal clicks (maybe).
* Incorporate downloading the sha256 files and verifying downloads.

## Other remarks...

This program will NOT circumvent User Account Control settings.  If you leave UAC enabled and try to this program as an installer, then you will get an "Access Denied" error.  You will need to run this progrma as Administrator.

If you want to completely disable UAC on Win 7+ you need to disable Admin Approval mode.

```
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
"EnableLUA"=dword:00000000
```

If you dont have some of these registry keys/items you need to create them.

You can also follow [this tutorial on TenForums](https://www.tenforums.com/tutorials/112488-enable-disable-user-account-control-uac-windows.html).

## *** WARNING ABOUT DISABLING UAC ***
If you disable UAC, you will disable some of the built-in countermeasures in Windows that protect your system.

Do not do this unless you are:
1) Able to administer your own system security (like a paid anti-virus subscription).
2) You are willing to accept the consequences.

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.
