package com.reactmodalshare;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Environment;
import android.provider.Telephony;

import androidx.core.content.FileProvider;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.google.gson.Gson;
import com.reactmodalshare.Models.ShareData;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ModalShareModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private String sharedStorage;

    public ModalShareModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        sharedStorage = reactContext.getFilesDir().toString() + "/";
    }

    @Override
    public String getName() {
        return "ModalShare";
    }

    @ReactMethod
    public void getSmsPackageName(final Promise promise) {
        PackageManager pm = reactContext.getPackageManager();

        try {
            promise.resolve(Telephony.Sms.getDefaultSmsPackage(reactContext));
        } catch (Exception e) {
            promise.resolve(null);
        }
    }

    @ReactMethod
    public void checkAppExist(String packageName, final Promise promise) {
        PackageManager pm = reactContext.getPackageManager();

        try {
            pm.getPackageInfo(packageName, 0);
            promise.resolve(true);
        } catch (PackageManager.NameNotFoundException e) {
            promise.resolve(false);
        }
    }

    @ReactMethod
    public void shareTo(String packageName, String data, final Promise promise) {
        Gson g = new Gson();
        ShareData shareData = g.fromJson(data, ShareData.class);
        String message = "";

        System.out.println(shareData.message + " " + shareData.url);

        if (shareData.message != null){
            System.out.println("ENTER MESSAGE " + shareData.url);
            message = shareData.message + " ";
        }
        if (shareData.url != null){
            System.out.println("ENTER URL " + shareData.url);
            message += shareData.url;
        }

        Intent sendIntent = new Intent();
        sendIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        sendIntent.setAction(Intent.ACTION_SEND);

//        List<String> noImgSharing = Arrays.asList("com.facebook.katana", "com.facebook.orca");
        List<String> noImgSharing = Arrays.asList();

        if (shareData.image != null && !noImgSharing.contains(packageName)) {
            try {
                shareData.image = shareData.image.replace("file://", "");

                File shareFile = new File(shareData.image);

                Uri bmpUri = FileProvider.getUriForFile(reactContext, reactContext.getPackageName() + ".fileprovider", shareFile);
                File bmpFile = new File(bmpUri.toString());

                if (shareFile.exists()) {
                    sendIntent.putExtra(Intent.EXTRA_STREAM, bmpUri);
//                    sendIntent.putExtra(Intent.EXTRA_STREAM, Uri.parse(shareData.image));
                    sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    sendIntent.setType("*/*");
                }
            } catch (Exception e) {
                sendIntent.setType("text/plain");
                System.out.println("IMG FAILED");
                e.printStackTrace();
            }
        } else {
            sendIntent.setType("text/plain");
        }

        sendIntent.putExtra(Intent.EXTRA_TEXT, message);
        promise.resolve(true);

        try {
            switch (packageName) {
                case "com.google.android.gm": {
                    if (shareData.subject != null) {
                        sendIntent.putExtra(Intent.EXTRA_SUBJECT, shareData.subject);
                    }
                    sendIntent.setPackage(packageName);
                    reactContext.startActivity(sendIntent);
                    break;
                }
                default: {
                    sendIntent.setPackage(packageName);
                    reactContext.startActivity(sendIntent);
                    break;
                }
            }
        } catch (Exception e) {
            System.out.println("ERROR");
            e.printStackTrace();
        }
    }
}
