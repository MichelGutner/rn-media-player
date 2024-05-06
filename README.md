# rn-media-player

### Introduction

This library is specifically designed for the React Native developer community, aiming to provide a robust and highly performant video player solution. By utilizing native components, our goal is to maximize the performance and efficiency of video playback in React Native applications. Maintaining the fluidity and responsiveness that users expect from native video experiences.

#### table of contents
- [Installation](#installation)

## Installation
```sh
npm install rn-media-player
```
````sh
yarn add rn-media-player
````

## Usage

```js
import { Video } from "rn-media-player";

// ...
const url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
const title = "Big Buck Bunny"

<Video source={{url, title}} />
```

## API Reference
This section provides detailed information about the props, methods, and events supported by the VideoPlayer component.

#### Configurations

| Property     | Description                                          | Type         | Default |
| ------------ | -----------------------------------------------------| ------------ | -------------- |
| **`source`** | Object attribute where to pass url and title of the video. | `Object`| {url: "" title: ""}     |
| **`thumbnailFramesSeconds`** | Quantity preview frames generated per seconds. | `Number`| 1     |
| **`enterInFullScreenWhenDeviceRotated`** | Enter full screen when rotate device. | `Boolean`| false     |
| **`autoPlay`** | Enable/Disable auto play on playback init. | `Boolean`| true    |
| **`loop`** | Enable/Disable loop on playback finish. | `Boolean`| false    |
| **`paused`** | Pauses playback. | `Boolean`| false    |
| **`rate`** | Able to change playback rate. | `Number`| 1    |
| **`startTime`** | Initial time of playback. | `Number`| 0    |
| **`resizeMode`** | Resizes of playback. | `EResizeMode`| contain   |
| **`tapToSeekValue`** | Value to seek player with backward or forward. | `Number`| 15    |
| **`suffixLabelTapToSeek`** | enable/disable loop on playback finish. | `Boolean`| false    |
| **`lockControls`** | lock controls playback - **WIP**. | `Boolean`| false    |
| **`speeds`** | Object with data to display speeds into settings and initial speed selected. | `Object`| [speeds](#Speeds)    |
| **`qualities`** | Object with data to display qualities into settings and initial quality selected. | `Object`| null    |
| **`settings`** | Object with data to display settings. | `Object`| [settings](#Settings)    |
| **`controlsProps`** | Configure controls properties. | `Object`| [controls](#Controls)    |


##### Settings
| Property     | Description                                          | Type         |
| ------------ | -----------------------------------------------------| ------------ |
| **`name`** | value to settings display. | `String`|
| **`enabled`** | enable or disable to display into interface. | `Boolean`|
```js
{
  data: [
    {
      name: 'Qualities',
      enabled: true,
    },
    {
      name: 'Playback Speeds',
      enabled: true,
    },
    {
      name: 'More Options',
      enabled: true,
    },
  ],
}
```
##### Speeds
| Property     | Description                                          | Type         |
| ------------ | -----------------------------------------------------| ------------ |
| **`name`** | value to display in settings. | `String`|
| **`value`** | value to pass to playback speed. | `String`|
| **`enabled`** | enable or disable to display into interface. | `Boolean`|
```js
{
    initialSelected: 'Normal',
    data: [
        {
            name: '0.5x',
            value: '0.5',
            enabled: true,
        },
        {
            name: 'Normal',
            value: '1',
            enabled: true,
        },
        {
            name: '1.5x',
            value: '1.5',
            enabled: true,
        },
    ],
}
```

##### Controls
| Property     | Description                                          | Type         | Details  |
| ------------ | -----------------------------------------------------| ------------ | -------- |
| **`loading`** | Customizes the loading indicator. | `Object`| { color?: string; }
| **`playback`** | Controls the appearance of playback elements. | `Object`| { color?: string; }
| **`seekSlider`** | Styles the seek slider. | `Object`| Detailed below
| **`settings`** | Styles the settings control. | `Object`| { color?: string; }
| **`fullScreen`** | Customizes the full-screen button appearance. | `Object`| { color?: string; }
| **`download`** | Configures the download button and related UI. | `Object`| Detailed below
| **`toast`** | Styles toast notifications within the player. | `Object`| Detailed below
| **`header`** | Styles the video player header. | `Object`| Detailed below

##### Detailed Configuration Options
***Note***: This library accepts color specifications in hexadecimal format only. Please ensure that all color properties are provided as hex codes.

`seekSlider`
*    maximumTrackColor: Color of the slider track (string)
*    minimumTrackColor: Color of the slider track before the thumb (string)
*    seekableTintColor: Color of the track showing seekable range (string)
*    thumbImageColor: Color of the slider thumb (string)
*    thumbnailBorderColor: Border color of the thumbnail on the slider (string)
*    thumbnailTimeCodeColor: Color of the time code on the thumbnail (string)

`timeCodes`

* currentTimeColor: Color of the current playback time (string)
* durationColor: Color of the total duration (string)
* slashColor: Color of the slash between current time and duration (string)

`download`

* color: Color of the download icon (string)
* progressBarColor: Color of the progress bar frame (string)
* progressBarFillColor: Fill color of the progress bar (string)
* messageDelete: Message displayed on deleting (string)
* messageDownload: Message displayed during downloading (string)
* labelDelete: Label for delete button (string)
* labelCancel: Label for cancel button (string)
* labelDownload: Label for download button (string)

`toast`

* label: Text label for the toast (string)
* backgroundColor: Background color of the toast (string)
* labelColor: Color of the label text (string)

`header`

* leftButtonColor: Color of the left button in the header (string)
* titleColor: Color of the title in the header (string)


## License

MIT
