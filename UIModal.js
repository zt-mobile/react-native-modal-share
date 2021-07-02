import React, { useState, useEffect } from "react";
import {
  View,
  Animated,
  Dimensions,
  SafeAreaView,
  Text,
  NativeModules
} from "react-native";
import { AppButton } from "./components";
import Modal from "react-native-modal";
import { getSharableApps, translate, share } from "./utils/AppHelper";

const { ModalShare } = NativeModules;

export default function UIModal(props) {
  const [panY, setPanY] = useState(
    new Animated.Value(Dimensions.get("window").height)
  );
  const [animHeight, setAnimHeight] = useState(new Animated.Value(1));
  const [isAnimating, setIsAnimating] = useState(false);
  const [searchDone, setSearchDone] = useState(false);
  const [sharableFirstSec, setSharableFirstSec] = useState([]);
  const [sharableSecondSec, setSharableSecondSec] = useState([]);

  const [containerOpacity, setContainerOpacity] = useState(0);
  const [containerHeight, setContainerHeight] = useState(0);
  const [isSheetShown, setIsSheetShown] = useState(false);

  const [shareAction, setShareAction] = useState(null);

  useEffect(
    () => {
      if (props.visible && props.data) {
        if (Platform.OS === "ios" && props.data.image) {
          const { data } = props;
          
          ModalShare.shareNative(props.data.image).then(() => {
            props.closeModal();
          }).catch(() => {
            props.closeModal();
          });
        } else {
          getAppData();
        }
      }
    },
    [props.visible]
  );

  useEffect(
    () => {
      if (containerHeight > 0) {
        showBtmSheet();
      }
    },
    [containerHeight]
  );

  const getAppData = () => {
    getSharableApps(props.data).then(res => {
      setSharableFirstSec([...res.firstSec]);
      setSharableSecondSec([...res.secondSec]);
      setSearchDone(true);
    });
  };

  const getSheetHeight = e => {
    const { height } = e.nativeEvent.layout;
    if (!containerHeight && !containerOpacity && !isAnimating && searchDone) {
      if (height > 50) {
        setIsAnimating(true);
        Animated.timing(animHeight, {
          toValue: 0,
          timing: 100,
          useNativeDriver: false
        }).start(() => {
          setIsAnimating(false);
          setContainerHeight(height);
        });
      }
    }
  };

  const showBtmSheet = () => {
    if (!isSheetShown) {
      if (containerHeight > 50) {
        setContainerOpacity(1);
        setIsSheetShown(true);
        setIsAnimating(true);
        Animated.spring(animHeight, {
          toValue: containerHeight,
          timing: 500,
          useNativeDriver: false
        }).start(() => {
          setIsAnimating(false);
        });
      } else {
        setTimeout(() => {
          showBtmSheet();
        }, 200);
      }
    }
  };

  const hideBtmSheet = () => {
    setIsAnimating(true);

    Animated.timing(animHeight, {
      toValue: 0,
      timing: 100,
      useNativeDriver: false
    }).start(() => {
      props.closeModal();
      setIsSheetShown(false);
      setIsAnimating(false);
      setTimeout(() => {
        setContainerHeight(0);
        setContainerOpacity(0);
      }, 500);
    });
  };

  if (Platform.OS === "ios" && props.data && props.data.image) {
    return <View style={{ width: 0, height: 0 }} />;
  }
  return (
    <Modal
      isVisible={props.visible}
      style={styles.modal}
      animationIn={"fadeIn"}
      animationOut={"fadeOut"}
      backdropTransitionOutTiming={0}
      onBackdropPress={hideBtmSheet}
      onBackButtonPress={hideBtmSheet}
      onModalHide={() => {
        if (shareAction) {
          share(shareAction, props.data);
          setShareAction(null);
        }
      }}
    >
      <SafeAreaView style={[styles.container, { opacity: containerOpacity }]}>
        <Animated.View
          style={[
            {
              width: "100%",
              height: !containerHeight ? "auto" : animHeight
            }
          ]}
          onLayout={getSheetHeight}
        >
          <Text style={styles.shareText}>
            {translate(props.locale, "shareVia")}
          </Text>
          {searchDone &&
            <View style={styles.wrapContainer}>
              {sharableFirstSec.map((app, i) => {
                if (props.exclude && props.exclude.includes(app.name)) return;
                return (
                  <AppButton
                    key={`f${i}`}
                    app={app}
                    hideModal={hideBtmSheet}
                    setShareAction={setShareAction}
                    {...props}
                  />
                );
              })}
              {sharableSecondSec.map((app, i) => {
                if (props.exclude && props.exclude.includes(app.name)) return;
                return (
                  <AppButton
                    key={`s${i}`}
                    app={app}
                    hideModal={hideBtmSheet}
                    setShareAction={setShareAction}
                    {...props}
                  />
                );
              })}
            </View>}
        </Animated.View>
      </SafeAreaView>
    </Modal>
  );
}

const styles = {
  modal: {
    margin: 0
  },
  container: {
    width: "100%",
    position: "absolute",
    bottom: 0,
    backgroundColor: "#fff",
    paddingBottom: 10
  },
  wrapContainer: {
    flexDirection: "row",
    flexWrap: "wrap"
  },
  shareText: {
    fontSize: 18,
    fontWeight: "700",
    marginLeft: 20,
    marginTop: 10,
    color: 'black'
  }
};
