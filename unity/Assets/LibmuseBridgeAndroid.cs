using UnityEngine;
using System.Collections;
using System;
using System.Runtime.InteropServices;

/*
 * This class implements the functionalities in LibmuseBridge.cs for Android platform.
 */
public class LibmuseBridgeAndroid : LibmuseBridge {

    public LibmuseBridgeAndroid() {
        unityJavaClass = new AndroidJavaClass("com.unity3d.player.UnityPlayer"); 
        unityMainActivity = unityJavaClass.GetStatic<AndroidJavaObject>("currentActivity");

        // Used to call member method
        libmuseObj = new AndroidJavaObject("com.muse.lib.LibmuseUnityProjectAndroid", unityMainActivity); 
    }


    override public void startListening() {
        libmuseObj.Call("startListening"); 
    }

    override public void stopListening() {
        libmuseObj.Call("stopListening"); 
    }

    override public void connect(string headband) {
        libmuseObj.Call("connect", headband); 
    } 

    override public void disconnect() {
        libmuseObj.Call("disconnect"); 
    }

    override public void registerMuseListener(string obj, string method) {
        libmuseObj.Call("registerMuseListener", obj, method); 
    }

    override public void registerConnectionListener(string obj, string method) {
        libmuseObj.Call("registerConnectionListener", obj, method); 
    }  

    override public void registerDataListener(string obj, string method) {
        libmuseObj.Call("registerDataListener", obj, method); 
    } 

    override public void registerArtifactListener(string obj, string method) {
        libmuseObj.Call("registerArtifactListener", obj, method); 
    } 

    override public void listenForDataPacket(string packetType) {
        libmuseObj.Call("listenForDataPacket", packetType);
    }

    override public string getLibmuseVersion() {
        return libmuseObj.Call<string>("getLibmuseVersion");
    }


    /*
     *  Private Members
     */
    private AndroidJavaClass unityJavaClass;
    private AndroidJavaObject unityMainActivity;
    private AndroidJavaObject libmuseObj;


}
