import React, { useState } from 'react';
import { Platform, SafeAreaView, Text, TouchableOpacity } from 'react-native';
import { Video } from 'rn-media-player';
import { downloadFile } from './downloadFile';
import { directories } from '@kesha-antonov/react-native-background-downloader';
import { useRoute } from '@react-navigation/native';

const SpeedsKey = 'Velocidades de reprodução';
const Qualities = 'Qualidade';

const speedsValues = [
  { name: '0.5x', value: 0.5 },
  { name: 'Normal', value: 1.0 },
  { name: '1.5x', value: 1.5 },
  { name: '2.0x', value: 2.0 },
];

const qualitiesValues = [
  {
    name: 'Baixa',
    value: 'https://content.jwplatform.com/videos/ijHnL627-VIgN1lMW.mp4',
  },
  {
    name: 'Média',
    value: 'https://content.jwplatform.com/videos/ijHnL627-zZbIuxVJ.mp4',
  },
  {
    name: 'Alta',
    value: 'https://content.jwplatform.com/videos/ijHnL627-aoHq8DIe.mp4',
  },
];

function App(): JSX.Element {
  const route = useRoute<any>();
  const uri = route.params?.uri;
  const title = route.params?.title;
  const artist = route.params?.subtitle;

  const [rate, setRate] = useState(1);
  const [playbackQuality, setPlaybackQuality] = useState('');

  let downloadedUrl =
    Platform.OS === 'android'
      ? `file://${directories.documents}/file.mp4`
      : uri;

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Video
        source={{
          url: uri,
          metadata: { title, artist },
          startTime: 150,
        }}
        // thumbnails={{ isEnabled: true, sourceUrl: uri }}
        style={{
          width: '100%',
          height: 300,
          backgroundColor: 'black',
        }}
        autoPlay={true}
        rate={rate}
        replaceMediaUrl={playbackQuality}
        entersFullScreenWhenPlaybackBegins
        // doubleTapToSeek={{
        //   value: 15,
        //   suffixLabel: 'segundos',
        // }}
        menus={{
          [SpeedsKey]: { data: speedsValues, initialItemSelected: 'Normal' },
          [Qualities]: {
            data: qualitiesValues,
            initialItemSelected: qualitiesValues[0]?.name as string,
          },
        }}
        // onFullScreenStateChanged={({ nativeEvent }) => {
        //   console.log('fullscreen', nativeEvent);
        // }}
        onMenuItemSelected={({ nativeEvent }) => {
          if (nativeEvent.name === SpeedsKey) {
            setRate(nativeEvent.value);
          }
          if (nativeEvent.name === Qualities) {
            setPlaybackQuality(nativeEvent.value);
          }
        }}
        // onMediaBuffering={({ nativeEvent }) => {
        //   console.log('video progress', nativeEvent);
        // }}
        // onMediaPlayPause={(event) => console.log(event.nativeEvent.isPlaying)}
        // onMediaRouter={(event) => console.log(event.nativeEvent.isActive)}
        // onMediaSeekBar={(event) => {
        //   console.log(event.nativeEvent);
        // }}
        // onMediaCompleted={({ nativeEvent: { completed } }) =>
        //   console.log(completed)
        // }
        // onMediaBufferCompleted={(e) => console.log(e.nativeEvent)}
        onMediaReady={({ nativeEvent }) => console.log(nativeEvent)}
        // onMediaPinchZoom={({ nativeEvent }) =>
        //   console.log(nativeEvent.currentZoom)
        // }
        // onMediaError={(e) => console.log('native Error', e.nativeEvent)}
        // lockControls={true}
        controlsStyles={
          {
            // loading: {
            //   color: '#cab9d1',
            // },
            // playback: {
            //   color: '#a90ee6',
            // },
            // seekSlider: {
            //   maximumTrackColor: '#f2f2f2',
            //   minimumTrackColor: '#890cba',
            //   seekableTintColor: '#df3030',
            //   thumbImageColor: '#a90ee6',
            // thumbnailBorderColor: '#a90ee6',
            // thumbnailTimeCodeColor: '#a90ee6',
            // },
            // timeCodes: {
            //   currentTimeColor: '#f3e9f7',
            //   durationColor: '#1a161c',
            //   slashColor: '#a90ee6',
            // },
            // menus: {
            //   color: '#a90ee6',
            // },
            // fullScreen: {
            //   color: '#a90ee6',
            // },
            // download: {
            //   color: '#696969',
            //   progressBarColor: '#908c91',
            //   progressBarFillColor: '#0df85f',
            //   messageDelete: 'Delete',
            //   messageDownload: 'Download',
            //   labelDelete: 'Delete',
            //   labelCancel: 'Cancel',
            //   labelDownload: 'Download',
            // },
            // toast: {
            //   // label: 'Video baixado com sucesso',
            //   // backgroundColor: '#0df85f',
            //   // labelColor: '#ffff',
            // },
            // header: {
            //   leftButtonColor: 'rgba(255,255,255,1)',
            //   titleColor: '#d71e1e',
            // },
          }
        }
      />
      <TouchableOpacity
        style={{ height: 50, backgroundColor: 'red' }}
        onPress={() => downloadFile(url)}
      >
        <Text style={{}}>Baixar Arquivo</Text>
      </TouchableOpacity>
    </SafeAreaView>
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
