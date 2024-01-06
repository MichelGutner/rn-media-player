import {SafeAreaView, StyleSheet, View} from 'react-native';

export const PlayerInFullScreen = ({children, isFullScreen}) => {
  return (
    <>
      {isFullScreen && <View style={styles.overlayView}>{children}</View>}
      {!isFullScreen && (
        <SafeAreaView style={styles.safeArea}>
          <View style={styles.container}>{children}</View>
        </SafeAreaView>
      )}
    </>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  container: {
    flex: 1,
  },
  overlayView: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
