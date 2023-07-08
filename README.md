<div align="center">
  <h1 align="center">Aselapse</h1>
  <img src=resources/AselapseIcon.png alt="Icon" width="160" height="160"/>

</div>

Record and generate time lapses automatically whilst drawing in the [aseprite](https://www.aseprite.org/) program.

Below is the time lapse generated, for the creation of the extension icon:

<img src=resources/AselapseIcon-lapse.gif alt="Icon" width="160" height="160"/>

This extension requires Aseprite version 1.3-rc3 or greater to function.

To download the latest beta trough steam, please perform the following steps:
- go to 'Library'
- Right click Aseprite,
- Click 'Properties'
- Go to the 'Betas' menu
- Select 'beta - v1.3 ...' under beta participation.
## Usage

To enable time lapse recording for a sprite, locate the 'Edit time lapse' command, under the Sprite menu. The sprite must be saved to disk before this is done!

<img src=resources/MenuLocation.png alt="Icon" width="160" height="160"/>

When pressed the following dialog window will appear.

<img src=resources/Dialog.png alt="Icon" height="160"/>

This window displays the current number of frames recorded for the time lapse, and lets one  pause and restart recording, as well as generate a sprite, that contains the time lapse.


<img src=resources/UsageExample.gif alt="Icon" height="400"/>

The extension automatically begins recording sprites on project load, that previously have enabled the time lapse function.
### Modifying time lapses

To modify a time lapse, first close the sprite which time lapse needs to be modified.

Then locate a file with the same name as the target sprite, suffixed with '-lapse'.
For example 'Sprite.aseprite' will have its modifyable time lapse stored in the 'Sprite-lapse.aseprite' in the same folder.

Perform any modifications to the time lapse, and reopen the target sprite.

The time lapse stored in the extension should now match up with the modified version on disk.

## [IMPORTANT] Moving / Renaming Sprites

If your sprite (lets say 'Sprite.aseprite') has a time lapse, and you want to move it to a different folder, you also need to move the 'Sprite-lapse.json' as well as the 'Sprite-lapse.aseprite' files along with it, to preserve the time lapse data.

Simmilarly, when renaming a sprite file, (e.g. 'Sprite_A.aseprite' to 'Sprite_B.aseprite'), you need to rename the following files as well:

'Sprite_A-lapse.json' -> 'Sprite_B-lapse.json'

'Sprite_A-lapse.aseprite' -> 'Sprite_B-lapse.aseprite'

## Installation

Download the 'aselapse.aseprite-extension' file, under [Releases](https://github.com/karstensensensen/aselapse/releases/latest).

Double-click and say yes to install.

Whenever the extension is run for the first time, some popup windows will appear asking for some permissions. These permissions are needed by the extension, to store the time lapse and some json files on disk.

To disable these popups check the 'Dont't show this specific alert again for this script' (this will need to be done multiple times for every sprite). And press 'Allow Write Access' (or similar).

<img src=resources/DontShowAlert.png alt="Icon" height="160"/>
To avoid doing this multiple times, check the 'Give full trust to this script', and press 'Give Script Full Access'. This only needs to be done once, to prevent all alert popup windows.
<img src=resources/FullTrust.png alt="Icon" height="160"/>

## License
see LICENSE file.
