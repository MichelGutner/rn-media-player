import {
  View,
  Text,
  FlatList,
  Image,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
} from 'react-native';
import React from 'react';
import { useFetch } from './hooks';
import type { Root } from './types';
import { useNavigation } from '@react-navigation/native';

export const HomeScreen = () => {
  const navigation = useNavigation<any>();
  const { data } = useFetch(
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/f.json'
  );
  const videos = data?.categories[0]?.videos || [];

  const handleWatchVideo = (item: Root['categories'][0]['videos'][0]) => {
    const url = item?.sources?.find((s) => s.type === 'mp4')?.url;
    navigation.navigate('Videos', {
      uri: `https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/${url}`,
      title: item.title,
      subtitle: item.subtitle,
      artwork: item.thumb,
      duration: item.duration,
    });
  };

  const renderVideoItem = ({ item }: { item: (typeof videos)[0] }) => (
    <View style={styles.card}>
      <Image
        source={{
          uri: `https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/images/${item['image-480x270']}`,
        }}
        style={styles.thumbnail}
      />
      <View style={styles.info}>
        <Text style={styles.title}>{item.title}</Text>
        <Text style={styles.studio}>{item.studio}</Text>
        <Text style={styles.duration}>
          Duration: {Math.floor(item.duration / 60)}m {item.duration % 60}s
        </Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => handleWatchVideo(item)}
        >
          <Text style={styles.buttonText}>Watch</Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  return (
    <SafeAreaView>
      <FlatList
        data={videos}
        renderItem={renderVideoItem}
        keyExtractor={(item) => item.title}
        contentContainerStyle={styles.container}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#f9f9f9',
  },
  card: {
    flexDirection: 'row',
    marginBottom: 16,
    backgroundColor: '#fff',
    borderRadius: 8,
    overflow: 'hidden',
    elevation: 2,
  },
  thumbnail: {
    flex: 1,
    width: 120,
    resizeMode: 'cover',
  },
  info: {
    flex: 1,
    padding: 8,
    justifyContent: 'center',
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  studio: {
    fontSize: 14,
    color: '#555',
    marginVertical: 4,
  },
  duration: {
    fontSize: 12,
    color: '#777',
  },
  button: {
    marginTop: 8,
    backgroundColor: '#007BFF',
    padding: 8,
    borderRadius: 4,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
});
