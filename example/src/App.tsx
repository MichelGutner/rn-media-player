import React, { useState } from 'react';
import { Text, TouchableOpacity } from 'react-native';
import { Video, EResizeMode } from 'rn-media-player';

const SpeedsKey = 'Velocidades';
const Qualities = 'Qualidades';

const speedsValues = [
  { name: '0.5x', value: 0.5 },
  { name: '1.0x', value: 1.0 },
  { name: '1.5x', value: 1.5 },
  { name: '2.0x', value: 2.0 },
];

const qualitiesValues = [
  {
    name: 'Baixa',
    value: 'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
  },
  {
    name: 'Média',
    value: 'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
  },
  {
    name: 'Alta',
    value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
  },
];

function App(): JSX.Element {
  const [rate, setRate] = useState(1);
  const [playbackQuality, setPlaybackQuality] = useState('');

  return (
    <>
      <Video
        source={{
          // url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          // url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
          url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          title: '',
          // TODO: must be implement ios
          startTime: 35,
          thumbnails: {
            enableGenerate: true,
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          },
        }}
        style={{ height: 320 }}
        rate={rate}
        autoPlay={true}
        changeQualityUrl={playbackQuality}
        tapToSeek={{
          // TODO: must be implement ios
          value: 8,
          suffixLabel: 'segundos',
        }}
        menus={{
          [Qualities]: qualitiesValues,
          [SpeedsKey]: speedsValues,
        }}
        onMenuItemSelected={({ nativeEvent }) => {
          if (nativeEvent.name === SpeedsKey) {
            setRate(nativeEvent.value);
          }
          if (nativeEvent.name === Qualities) {
            setPlaybackQuality(nativeEvent.value);
          }
        }}
        onLoaded={({ nativeEvent }) => console.log(nativeEvent.duration)}
        // onVideoProgress={(data) => {
        //   console.log('video progress', data.nativeEvent);
        // }}
        onPlayPause={(event) => console.log(event.nativeEvent.isPlaying)}
        onCompleted={({ nativeEvent: { completed } }) => console.log(completed)}
        onBufferCompleted={(e) =>
          console.log(`BUFFER COMPLETED ${JSON.stringify(e.nativeEvent)}`)
        }
        onBuffer={(e) =>
          console.log(`BUFFER STARTED ${JSON.stringify(e.nativeEvent)}`)
        }
        onError={(e) => console.log('native Error', e.nativeEvent)}
        // -------->
        resizeMode={EResizeMode.Contain} // must be implement android
        enterInFullScreenWhenDeviceRotated={false} // must be implemented android
        paused={false}
        // lockControls={true}
        // controlsProps={{
        //   loading: {
        //     color: '#a90ee6',
        //   },
        //   playback: {
        //     color: '#a90ee6',
        //   },
        //   seekSlider: {
        //     maximumTrackColor: '#4f4c50',
        //     minimumTrackColor: '#890cba',
        //     seekableTintColor: '#b6b6b6',
        //     thumbImageColor: '#a90ee6',
        //     // thumbnailBorderColor: '#a90ee6',
        //     // thumbnailTimeCodeColor: '#a90ee6',
        //   },
        //   // timeCodes: {
        //   //   currentTimeColor: '#f3e9f7',
        //   //   durationColor: '#1a161c',
        //   //   slashColor: '#a90ee6',
        //   // },
        //   settings: {
        //     color: '#a90ee6',
        //   },
        //   fullScreen: {
        //     color: '#a90ee6',
        //   },
        //   // download: {
        //   //   color: '#696969',
        //   //   progressBarColor: '#908c91',
        //   //   progressBarFillColor: '#0df85f',
        //   //   messageDelete: 'Delete',
        //   //   messageDownload: 'Download',
        //   //   labelDelete: 'Delete',
        //   //   labelCancel: 'Cancel',
        //   //   labelDownload: 'Download',
        //   // },
        //   // toast: {
        //   //   // label: 'Video baixado com sucesso',
        //   //   // backgroundColor: '#0df85f',
        //   //   // labelColor: '#ffff',
        //   // },
        //   // header: {
        //   //   leftButtonColor: 'rgba(255,255,255,1)',
        //   //   titleColor: '#d71e1e',
        //   // },
        // }}
        onSettings={() => console.log('MORE OPTIONS TAPPED')}
        // onFullScreen={({nativeEvent}) =>
        //   console.log(nativeEvent.fullScreen)
        // }
      />
      <TouchableOpacity onPress={() => console.log('oi')}>
        <Text>Olá Mundo</Text>
      </TouchableOpacity>
    </>
  );
}

export default App;

/**
 *     url: 'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
    title: 'Sample Video',
    startTime: 35,
    type: 'video/mp4',
    duration: 600,
    thumbnails: [
      'https://example.com/thumb1.jpg',
      'https://example.com/thumb2.jpg'
    ],
    poster: 'https://example.com/poster.jpg',
    subtitles: [
      { src: 'https://example.com/subtitles-en.vtt', language: 'en', label: 'English' }
    ],
    drm: { licenseUrl: 'https://drm.example.com/license' }
 */
