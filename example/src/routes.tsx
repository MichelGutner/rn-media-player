import * as React from 'react';
import { View, Button } from 'react-native';
import { NavigationContainer, useNavigation } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import App from './App';

function HomeScreen() {
  const navigation = useNavigation();
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Button
        title="Video"
        onPress={() => navigation.navigate('Videos' as never)}
      />
    </View>
  );
}

const Stack = createNativeStackNavigator();

export const Routes = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Videos" component={App} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};
