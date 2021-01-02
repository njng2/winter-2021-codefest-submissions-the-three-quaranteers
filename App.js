import React from 'react';
import { render } from 'react-dom';
import { Text, View, StyleSheet, TouchableOpacity, PermissionsAndroid } from 'react-native';
import MapView from './node_modules/react-native-maps';
import * as Permissions from 'expo-permissions';
import * as Constants from 'expo-permissions';
import * as Location from 'expo-permissions';

export default class WorldApp extends React.Component
{
  state = {
    latitude: null,
    longitude: null
  };

  findCurrentLocation = () =>{
    navigator.geolocation.getCurrentPosition(
      position => {
        const latitude = JSON.stringify(position.coords.latitude);
        const longitude = JSON.stringify(position.coords.longitude);

        this.setState({
          latitude,
          longitude
        });
      },
      {enableHighAccuracy: true, timeout: 2000, maximumAge: 1000}
    );
  };

  async componentDidMount() 
  {
    this.findCurrentLocation();
    const {status} = await Permissions.getAsync(Permissions.LOCATION)

    if( status !== 'granted'){
      const response = await Permissions.askAsync(Permissions.LOCATION)
    }
    navigator.geolocation.getCurrentPosition(
        ({ coords: {latitude, longitude}}) => this.setState({latitude, longitude}, () => console.log('State:', this.state)),
        (error) => console.log('Error: ', error)
    )
  };

  render(){ 
    
    const {latitude,longitude} = this.state;
    
    if(latitude)
    {
      return(
        <MapView 
        style = {{flex : 1}} 
        initialRegion = 
        {{ 
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          latitudeDelta: 0.0922, 
          longitudeDelta: 0.0421,
        }} />
      );
    }
  
    return(
      <MapView 
      style = {{flex : 1}} 
      region = 
      {{ 
        latitude: 0,
        longitude:0,
        latitudeDelta: 0.0922, 
        longitudeDelta: 0.0421,
      }} />
    )
  }
}

const styles = StyleSheet.create({
  container:
  {
    flex: 1,
    padding: 24,
    justifyContent: 'center', 
    alignItems:'center'
  }
});