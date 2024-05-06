import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { Video, EResizeMode } from 'rn-media-player';

function App(): JSX.Element {
  return (
    <View>
      <Video
        source={{
          url: 'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
          // url: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          // url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
          // url: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          title: 'ElephantsDream',
        }}
        style={{ height: 320 }}
        resizeMode={EResizeMode.Contain}
        paused={false}
        startTime={0}
        enterInFullScreenWhenDeviceRotated={true}
        autoPlay={true}
        loop={false}
        doubleTapSeekValue={8}
        suffixLabelDoubleTapSeek="segundos"
        // onLoaded={({nativeEvent}) => console.log(nativeEvent.duration)}
        // onVideoProgress={data => console.log(data.nativeEvent)}
        // onPlayPause={event => console.log(event.nativeEvent.isPlaying)}
        // onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        // resizeMode={'stretch'}
        // doubleTapSeekValue={doubleTapSeekValue}
        // suffixLabelDoubleTapSeek={suffixLabelDoubleTapSeek}
        // lockControls={true}
        onError={(e) => console.log('native Error', e.nativeEvent)}
        speeds={{
          initialSelected: 'Normal',
          data: [
            {
              name: '0.25x',
              value: '0.25',
              enabled: true,
            },
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
            {
              name: '2x',
              value: '2',
              enabled: true,
            },
          ],
        }}
        qualities={{
          initialSelected: '240p',
          data: [
            {
              name: '4320p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              enabled: false,
            },
            {
              name: '2880p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              enabled: false,
            },
            {
              name: '2160p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              enabled: false,
            },
            {
              name: '1440p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              enabled: false,
            },
            {
              name: '1080p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              enabled: true,
            },
            {
              name: '720p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
              enabled: true,
            },
            {
              name: '480p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              enabled: true,
            },
            {
              name: '360p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              enabled: true,
            },
            {
              name: '240p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              enabled: true,
            },
            {
              name: '144p',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              enabled: true,
            },
          ],
        }}
        settings={{
          data: [
            {
              name: 'Qualidades',
              enabled: true,
              value: 'qualities',
            },
            {
              name: 'Playback Speeds',
              enabled: true,
              value: 'speeds',
            },
            {
              name: 'More Options',
              enabled: true,
              value: 'moreOptions',
            },
          ],
        }}
        controlsProps={{
          loading: {
            color: '#a90ee6',
          },
          // playback: {
          //   color: '#a90ee6',
          // },
          // seekSlider: {
          //   maximumTrackColor: '#4f4c50',
          //   minimumTrackColor: '#890cba',
          //   seekableTintColor: '#b6b6b6',
          //   thumbImageColor: '#a90ee6',
          //   // thumbnailBorderColor: '#a90ee6',
          //   // thumbnailTimeCodeColor: '#a90ee6',
          // },
          // timeCodes: {
          //   currentTimeColor: '#f3e9f7',
          //   durationColor: '#1a161c',
          //   slashColor: '#a90ee6',
          // },
          // settings: {
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
        }}
        onSettings={() => console.log('MORE OPTIONS TAPPED')}
        // onFullScreen={({nativeEvent}) =>
        //   console.log(nativeEvent.fullScreen)
        // }
        // onGoBack={() => console.log('GO BACK TAPPED')}
        onPlaybackSpeed={() => console.log('onPlaybackSpeedTapped')}
        onQuality={() => console.log('onQualityTapped')}
        onBufferCompleted={(e) =>
          console.log(`BUFFER COMPLETED ${JSON.stringify(e.nativeEvent)}`)
        }
        onBuffer={(e) =>
          console.log(`BUFFER STARTED ${JSON.stringify(e.nativeEvent)}`)
        }
        onVideoDownloaded={(e) =>
          console.log(`VIDEO DOWNLOADED ${JSON.stringify(e.nativeEvent)}`)
        }
      />
      <TouchableOpacity onPress={() => console.log('oi')}>
        <Text>Olá Mundo</Text>
      </TouchableOpacity>
    </View>
  );
}

export default App;
