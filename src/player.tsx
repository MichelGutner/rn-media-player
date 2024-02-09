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
  useWindowDimensions,
} from 'react-native';
const VPlayer = requireNativeComponent<{
  style: ViewStyle;
  sliderProps: {maximumTrackColor: string};
  forwardProps: TAdvanceVideoControlProps<'forward'>;
  backwardProps: TAdvanceVideoControlProps<'backward'>;
}>('RNVideoPlayer');

export type TAdvanceVideoControlProps<T extends TImageTypes> = {
  color?: string;
  hidden?: boolean;
  image?: TImageControlProps<T>;
};

type TImageTypes = 'forward' | 'backward';

type TImageControlProps<T extends TImageTypes> =
  | `${T}empty`
  | `${T}15`
  | `${T}30`
  | `${T}45`
  | `${T}60`
  | `${T}75`
  | `${T}90`
  | `${T}Default`;

export const RNPlayerVideo = ({
  style,
  isFullScreen,
  onFullScreen,
  resizeMode,
  loading,
  paused,
}: {
  style: ViewStyle;
  isFullScreen: boolean;
  onFullScreen: () => void;
  loading: boolean;
}): JSX.Element => {
  const {width, height} = useWindowDimensions();
  const [pause, setPause] = useState(false);
  const [rate, setRate] = useState(1);
  const [currentTime, setCurrentTime] = useState(undefined);
  const [loadData, setLoadData] = useState<any>();

  return (
    <View style={style}>
      <VPlayer
        // forwardProps={{color: '#ffffff', image: 'forward15'}}
        style={{...StyleSheet.absoluteFillObject, overflow: 'hidden'}}
        // source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        source="https://content.jwplatform.com/videos/MGAxJ46m-aoHq8DIe.mp4"
        // source="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        paused={paused}
        rate={rate}
        videoTitle={'Game of Thrones'}
        onLoaded={({nativeEvent}) => setLoadData(nativeEvent)}
        onVideoProgress={data => setCurrentTime(data.nativeEvent)}
        // onCompleted={({nativeEvent: {completed}}) => console.log(completed)}
        fullScreen={isFullScreen}
        resizeMode={resizeMode}
        timeValueForChange={10}
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
          title: 'Quality',
          initialQualitySelected: 'Low Quality',
          data: [
            {
              name: 'Very High Quality',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              id: 'veryHighQuality',
            },
            {
              name: 'High Quality',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-aoHqIe.mp4',
              id: 'highQuality',
            },
            {
              name: 'Medium Quality',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-zZbIuxVJ.mp4',
              id: 'mediumQuality',
            },
            {
              name: 'Low Quality',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              id: 'lowQuality',
            },
            {
              name: 'Very Low Quality',
              value:
                'https://content.jwplatform.com/videos/MGAxJ46m-fQPeQtU3.mp4',
              id: 'veryLowQuality',
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
    </View>
  );
};
