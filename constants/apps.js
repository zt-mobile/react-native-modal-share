const apps = {
  firstSec: [
    {
      name: "whatsapp",
      ios: "whatsapp://",
      android: "com.whatsapp",
      icon: require("../assets/whatsapp.png")
    },
    {
      name: "twitter",
      ios: "twitter://",
      android: "com.twitter.android",
      icon: require("../assets/twitter.png")
    },
    {
      name: "facebook",
      ios: "fb://",
      android: "com.facebook.katana",
      icon: require("../assets/facebook.png")
    },
    {
      name: "messenger",
      ios: "fb-messenger://",
      android: "com.facebook.orca",
      icon: require("../assets/messenger.png")
    },
    {
      name: "telegram",
      ios: "tg://",
      android: "org.telegram.messenger",
      icon: require("../assets/telegram.png")
    }
  ],
  secondSec: [
    {
      name: "copyInfo",
      icon: require("../assets/copyInfo.png"),
      action: "copyInfo"
    },
    {
      name: "copyLink",
      icon: require("../assets/copyLink.png"),
      action: "copyLink"
    },
    {
      name: "email",
      ios: "mailto://",
      android: "com.google.android.gm",
      icon: require("../assets/email.png")
    },
    {
      name: "sms",
      ios: "message://",
      android: "",
      icon: require("../assets/sms.png")
    }
  ]
};

export { apps };
