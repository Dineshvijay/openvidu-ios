# openvidu-ios
Video call app using openvidu - webRTC

Openvidu website
https://openvidu.io

[![Watch the video](./assets/3.PNG)](./assets/demo-vid.mp4)

## Flow
<p align="center">
  <img src="./assets/1.png" width="1000" height="800" title="hover text">
</p>
<p align="center">
  <img src="./assets/2.png" width="2520" height="720" title="hover text">
</p>

#### Steps to connect video call between two iOS devices
- Run this project in two iOS devices
- Enter the Same RoomID in both devices (Minimun 15 characters)
- Enter the username and click join
- Mute video & audio, do iOS device screen share, toggle front & back camera
#### Steps to connect video call between iOS device & web
- open your browser and go to https://demos.openvidu.io/openvidu-call/#/
- By default, RoomID already generated in web app.
- Enter the same RoomID (web app room id) to iOS device
- Join call


## Pods used
 - 'GoogleWebRTC' - WebRTC client
 - 'Starscream', - Web Socket connection
 - 'MBProgressHUD' - Showing progress indicator