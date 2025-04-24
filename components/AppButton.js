import React, { useState, useEffect } from "react";
import {
  Dimensions,
  View,
  Text,
  Image,
  TouchableOpacity,
  Platform
} from "react-native";
import Clipboard from "@react-native-clipboard/clipboard";
import Toast from "react-native-simple-toast";
import { NativeController } from "./index";
import { shouldCloseModal, translate } from "../utils/AppHelper";

function AppButton(props) {
  const { app, data, setShareAction } = props;

  const appClicked = () => {
    if (app[Platform.OS] && shouldCloseModal(app[Platform.OS])) {
      setShareAction(app);
      props.hideModal();
    } else {
      shareAction();
    }
  };

  const shareAction = () => {
    if (app.action) {
      switch (app.action) {
        case "copyInfo":
          var msg = data.message;
          
          if (data.url){
            msg += ` ${data.url}`;
          }
          Clipboard.setString(`${msg}`);
          Toast.show(translate(props.locale, "infoCopied"));
          break;
        case "copyLink":
          Clipboard.setString(`${data.url}`);
          Toast.show(translate(props.locale, "linkCopied"));
          break;
        default:
          console.log("break " + app.action);
          break;
      }
    } else {
      //Call native share function
      NativeController.shareTo(
        app[Platform.OS],
        JSON.stringify(data)
      ).then(res => {});
    }
  };

  return (
    <View
      style={[
        {
          width: Dimensions.get("window").width * 0.25,
          height: Dimensions.get("window").width * 0.25,
          alignItems: "center",
          justifyContent: "center"
        }
      ]}
    >
      <TouchableOpacity style={styles.appContainer} onPress={appClicked}>
        <Image source={app.icon} style={styles.appIcon} />
        <Text style={styles.appText}>
          {translate(props.locale, app.name)}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = {
  appContainer: {
    justifyContent: "center",
    alignItems: "center",
    width: "75%",
    height: "75%",
    alignSelf: "center"
  },
  appIcon: {
    width: 50,
    height: 50
  },
  appText: {
    textAlign: "center",
    marginTop: 5,
    fontSize: 13,
    color: 'black'
  }
};

export { AppButton };
