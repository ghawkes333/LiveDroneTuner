import { Text, View } from "react-native";
import { PitchDetector } from 'react-native-pitch-detector';

// async function test() {

// // To start recording
//   await PitchDetector.start(); // Promise<void>

//   // // To stop recording
//   // await PitchDetector.stop(); // Promise<void>

//   // // To get current status
//   // await PitchDetector.isRecording(); // Promise<true | false>

//   // To listener results
//   const subscription = PitchDetector.addListener(console.log) // { frequency: 440.14782, tone: "C#" }

//   // // To stop listen results
//   // PitchDetector.removeListener()
// }

export default function Index() {
  PitchDetector.start()
  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <Text>Edit app/index.tsx to edit this screen.</Text>
    </View>
  );
}
