<div align="center">
  <h1 align="center">Aselapse</h1>
  <img src=resources/AselapseIcon.png alt="Icon" width="160" height="160"/>

</div>

Record and generate timelapses automatically whilst drawing in the [aseprite](https://www.aseprite.org/) program.

Below is the timelapse generated, for the creation of the extension icon:

<img src=resources/AselapseIcon-lapse.gif alt="Icon" width="160" height="160"/>

## Usage

To enable timelapse recording for a sprite, locate the 'Edit Timelapse' command, under the Sprite menu. The sprite must be saved to disk before this is done!

<img src=resources/MenuLocation.png alt="Icon" width="160" height="160"/>

When pressed the following dialog window will appear.

<img src=resources/Dialog.png alt="Icon" height="160"/>

This window displays the current number of frames recorded for the timelapse, and lets one  pause and restart recording, as well as generate a sprite, that contains the timelapse.


<img src=resources/UsageExample.gif alt="Icon" height="400"/>

The extension automatically begins recording sprites on project load, that previously have enabled the timelapse function.
### Modifying timelapses

To modify a timelapse, first close the sprite which timelapse needs to be modified.

Then locate a file with the same name as the target sprite, suffixed with '-lapse'.
For example 'Sprite.aseprite' will have its modifyable timelapse stored in the 'Sprite-lapse.aseprite' in the same folder.

Perform any modifications to the timelapse, and reopen the target sprite.

The timelapse stored in the extension should now match up with the modified version on disk.


## Installation

Download the 'aselapse.aseprite-extension' file, under [Releases](https://github.com/karstensensensen/aselapse/releases/latest).

Double-click and say yes to install.

Whenever the extension is run for the first time, some popup windows will appear asking for some permissions. These permissions are needed by the extension, to store the timelapse and some json files on disk.

To disable these popups check the 'Dont't show this specific alert again for this script' (this will need to be done multiple times for every sprite). And press 'Allow Write Access' (or similar).

<img src=resources/DontShowAlert.png alt="Icon" height="160"/>
To avoid doing this multiple times, check the 'Give full trust to this script', and press 'Give Script Full Access'. This only needs to be done once, to prevent all alert popup windows.
<img src=resources/FullTrust.png alt="Icon" height="160"/>

## License
see LICENSE file.
