/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  StyleSheet,
  View,
  ViewStyle,
  requireNativeComponent,
} from 'react-native';
const VPlayer = requireNativeComponent<{
  style: ViewStyle;
  sliderProps: {maximumTrackColor: string};
}>('RNVideoPlayer');

export const RNPlayerVideo = ({
  style,
  isFullScreen,
  onFullScreen,
  resizeMode,
  loading,
  paused,
  startTime,
  didEnterInFullScreenWhenDeviceRotated,
}: {
  style: ViewStyle;
  isFullScreen: boolean;
  onFullScreen: () => void;
  loading: boolean;
}): JSX.Element => {
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(undefined);
  const [loadData, setLoadData] = useState<any>();

  return (
    // <View style={style}>
    <VPlayer
      style={{...style, overflow: 'hidden'}}
      // source={{
      //   url: 'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
      //   videoTile: 'testing',
      // }}
      source={{
        url: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        videoTitle: 'Title de test',
      }}
      // thumbnailFramesSeconds={1}
      paused={paused}
      rate={rate}
      didEnterInFullScreenWhenDeviceRotated={
        didEnterInFullScreenWhenDeviceRotated
      }
      startTime={startTime}
      onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
      // onVideoProgress={data => console.log(data.nativeEvent)}
      onPlayPause={event => console.log(event.nativeEvent.status)}
      // onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
      fullScreen={isFullScreen}
      resizeMode={resizeMode}
      advanceValue={15}
      lockControls={true}
      onError={e => console.log('native Error', e.nativeEvent)}
      loadingProps={{
        color: '#aca5a5a7',
      }}
      sliderProps={{
        maximumTrackColor: 'rgba(255,255,255,0.2)',
        // minimumTrackColor: '#3939ae',
        thumbSize: 15,
        // thumbColor: '#412cdf',
      }}
      // playPauseProps={{
      //   color: '#ce0808',
      //   hidden: false,
      // }}
      // fullScreenProps={{
      //   color: '#ce0808',
      //   hidden: false,
      // }}
      // labelDurationProps={{
      //   color: '#ce0808',
      // }}
      // labelProgressProps={{
      //   color: '#ce0808',
      // }}
      // settingsSymbolProps={{
      //   color: '#ce0808',
      // }}
      // fullScreenProps={{
      //   color: '#ce0808',
      // }}
      // titleProps={{
      //   color: '#ce0808',
      // }}
      // goBackProps={{
      //   color: '#ce0808',
      // }}
      settingsItemsSymbolProps={{
        download: {
          color: '#fbf7f7',
          hidden: false,
        },
        quality: {
          // color: '#581212',
          hidden: false,
        },
        speedRate: {
          color: '#d80d0d',
          hidden: false,
        },
      }}
      speedRateModalProps={{
        title: 'Speed Rate',
      }}
      qualityModalProps={{
        initialSelected: '240p',
        data: [
          {
            name: '4320p',
            value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
            enabled: true,
          },
          {
            name: '2880p',
            value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
            enabled: true,
          },
          {
            name: '2160p',
            value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
            enabled: true,
          },
          {
            name: '1440p',
            value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
            enabled: true,
          },
          {
            name: '1080p',
            value: 'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
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
      onSettingsTapped={() => console.log('MORE OPTIONS TAPPED')}
      onFullScreenTapped={onFullScreen}
      onGoBackTapped={() => console.log('GO BACK TAPPED')}
      onDownloadVideoTapped={() => console.log('onDownloadVideoTapped')}
      onPlaybackSpeedTapped={() => console.log('onPlaybackSpeedTapped')}
      onQualityTapped={() => console.log('onQualityTapped')}
      // onBufferCompleted={e =>
      //   console.log(`BUFFER COMPLETED ${JSON.stringify(e.nativeEvent)}`)
      // }
      onBuffer={
        e => undefined
        // console.log(`BUFFER STARTED ${JSON.stringify(e.nativeEvent)}`)
      }
      onVideoDownloaded={e =>
        console.log(`VIDEO DOWNLOADED ${JSON.stringify(e.nativeEvent)}`)
      }
    />
    // </View>
  );
};
