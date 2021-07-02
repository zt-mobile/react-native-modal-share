import React from "react";
import { NativeModules, Platform } from "react-native";
import { apps, translations } from "../constants";

const { ModalShare } = NativeModules;

export async function getSharableApps(data) {
  var firstSec = [];
  var secondSec = [];
  var i, res;

  if (Platform.OS === "android") {
    const smsPackageName = await ModalShare.getSmsPackageName();
    i = apps.secondSec.findIndex(x => x.name == "sms");

    if (i > -1) {
      apps.secondSec[i].android = smsPackageName;
    }
  }

  for (i = 0; i < apps.firstSec.length; i++) {
    res = await ModalShare.checkAppExist(apps.firstSec[i][Platform.OS]);

    if (res) {
      firstSec.push(apps.firstSec[i]);
    }
  }

  for (i = 0; i < apps.secondSec.length; i++) {
    if (!apps.secondSec[i].action) {
      res = await ModalShare.checkAppExist(apps.secondSec[i][Platform.OS]);
    } else {
      if (apps.secondSec[i].name == "copyLink" && data.url) {
        res = true;
      } else if (apps.secondSec[i].name == "copyInfo" && data.message) {
        res = true;
      } else {
        res = false;
      }
    }

    if (res) {
      secondSec.push(apps.secondSec[i]);
    }
  }

  return {
    firstSec,
    secondSec
  };
}

export async function shouldCloseModal(packageName) {
  if (packageName) {
    if (
      Platform.OS === "ios" &&
      (packageName == "fb://" || packageName == "fb-messenger://")
    ) {
      return true;
    }
  }
  return false;
}

export function translate(locale, key) {
  var translated;

  if (locale) {
    translated = translations[locale][key];
  } else {
    translated = translations["en"][key];
  }

  if (!translated) return "NULL";
  return translated;
}

export function share(app, data) {
  var timeout = 0;

  if (app[Platform.OS] === "fb://") {
    timeout = 200;
  }

  setTimeout(() => {
    ModalShare.shareTo(app[Platform.OS], JSON.stringify(data)).then(res => {});
  }, timeout);
}
