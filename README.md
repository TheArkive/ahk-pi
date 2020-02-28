# AHK Portable Installer

This is a portable install manager.  This script is meant to be run compiled, and is only meant to work with the `.zip` archives.  It is written for AHKv2 (hence the need to compile).  If you run this as a script, switch to AHK v1, close, and try to reopen the script, it will not work.  For best results, please comipile, or use the included precompiled EXE.

Please make sure to use the 64-bit EXE if you are running 64-bit windows.  The uninstall process for 64-bit AHK won't uninstall reg key `HKEY_LOCAL_MACHINE\SOFTWARE\AutoHotkey` if you use the 32-bit EXE.

<!-- ![Settings pane toggled open](/images/ahk-pi.png) ![Main window](/images/ahk-pi2.png) -->
<img src="/images/ahk-pi2.png" width="420" align="top"/><img src="/images/ahk-pi.png" width="420"/>

## Basic Setup

The AHK `base folder` is intended to look something like this:

Example:
```
C:\AutoHotkey    <-- place the base folder anywhere you want
             \AHK v1.1.30.03\...
             \AHK v1.1.31.00\...
             \AHK v2.0-a107-03296ce9\...
             \AHK v2.0-a108-a2fa0498\...
             \etc...
```

NOTE: If you are using AutoHotkey_H, you will need to append the appropriate suffix to the exe file name:

```
AutoHotkey.exe  --->  AutoHotkey_x64w_MT.exe
```

It doesn't matter what you add or how you add it, but make sure it isn't plain `AutoHotkey.exe`.  This file is deleted and the selected EXE is copied to `AutoHotkey.exe`.

There is no "installation" for this script/program.  You can download and unzip to your `base folder` that contains all your subfolders of extracted AHK `.zip` versions, or you can place it anywhere and specify your `base folder` in the settings.

The following settings are available:
* Select base folder.
* Define AHK v1 and v2 update URLs, ie.
  * https://www.autohotkey.com/download/1.1/
  * https://www.autohotkey.com/download/2.0/
* Toggle checking for updates on program start.
* Define a custom text editor, or revert back to `notepad.exe`.

Each subfolder should have it's own copy of a `help file`, `WindowSpy.ahk`, `Compiler` folder with `Ahk2Exe` and all necessary support files (including `mpress.exe` if you want to use it).

There is no need to keep `Installer.ahk` or `Template.ahk` unless you have a need for them.

This package includes two template files, one for AHK v1 and one for AHK v2.  You can customize them as you like, and when you activate an EXE (same as installing... sort of) that template will be automatically written to `C:\Windows\ShellNew\Template.ahk` based on the major version number of the EXE you selected.

You can get a copy of Window Spy for AHK v2 [here](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=72333&sid=3b87fff7974d5900bc41619869692564).

## What this does...

As a portable installer, based on your selected/activated version, here's what it does:

* Writes registry values to associate the `.ahk` extension.
* Writes registry values to define the default `.bin` file to use with Ahk2Exe compiler.
* Writes registry values to enable `mpress.exe` if present in `Compiler` folder (or disables it if not).
* Writes `InstallDir` and `Version` registry entries in `HKEY_LOCAL_MACHINE/Software/AutoHotkey`.

This program also:

* Checks for updates when prompted, or does so automatially if enabled.
* Displays the latest versions of AHK v1 and v2 (with internet connection of course).
* Displays currently active version of AHK.
* Easy access to edit templates for new AutoHotkey.ahk files with Context Menu > New > ...
* Provides links to AHK v1 and v2 download pages / version archives.
* Allows you to invoke `WindowSpy.ahk`, `help file`, and opt to Uninstall all traces of AHK in the registry.

If you installed AutoHotkey with a setup file, then `HKEY_LOCAL_MACHINE/Software/AutoHotkey` may not be removable until after you uninstall it first.

## What this does NOT do...

This is a PORTABLE installer, so this script:

* WILL NOT write or remove registry entries that deal with installing or uninstalling.
* WILL NOT run two versions of AutoHotkey side-by-side.
* WILL NOT create a separate `.ahk2` extension or any other extension besides `.ahk`.
* WILL NOT automatically download new versions.

The user may be prompted to specify a program to associate before everything works nicely.  This shouldn't happen.  I haven't has this problem yet.  Let me know if you do.

Some of these features may change or be added in the future.

One more thing this program will not do is circumvent User Account Control settings.  If you leave UAC enabled, then you will likely be prompted when this program tries to write to the registry.  I leave it to the user to decide how to manage their UAC settings.

---

Any feedback would be appreciated.  Hopefully this tool will help people, and just get better over time.
