using UnityEngine;
using System.Collections;
using System;
using System.Runtime.InteropServices;

/*
 * This class implements the functionalities in LibmuseBridge.cs for iOS platform.
 */
public class LibmuseBridgeIos : LibmuseBridge {

    //-------------------------------------------
    // extern C functions
    // These functions are defined in the objc++ (.mm) files

    [DllImport("__Internal")]
    private static extern void _startListening();

    [DllImport("__Internal")]
    private static extern void _stopListening(); 

    [DllImport("__Internal")]
    private static extern void _connect(IntPtr headband);  

    [DllImport("__Internal")]
    private static extern void _disconnect();    

    [DllImport("__Internal")]
    private static extern void _registerMuseListener(IntPtr obj, IntPtr method); 

    [DllImport("__Internal")]
    private static extern void _registerConnectionListener(IntPtr obj, IntPtr method);   

    [DllImport("__Internal")]
    private static extern void _registerDataListener(IntPtr obj, IntPtr method); 

    [DllImport("__Internal")]
    private static extern void _registerArtifactListener(IntPtr obj, IntPtr method); 

    [DllImport("__Internal")]
    private static extern void _listenForDataPacket(IntPtr packetType); 

    [DllImport("__Internal")]
    public static extern IntPtr _getLibmuseVersion ();


    //-------------------------------------------
    // Derived public methods
    // Many of these methods need to convert string to IntPtr before calling the extern c functions

    override public void startListening() {
        _startListening();
    }

    override public void stopListening() {
        _stopListening();
    }

    override public void connect(string headband) {
        IntPtr hband = Marshal.StringToHGlobalAuto(headband);
        _connect(hband);
    } 

    override public void disconnect() {
        _disconnect();
    } 

    override public void registerMuseListener(string obj, string method) {
        IntPtr objec = Marshal.StringToHGlobalAuto(obj);
        IntPtr func = Marshal.StringToHGlobalAuto(method);
        _registerMuseListener(objec, func);
    }

    override public void registerConnectionListener(string obj, string method) {
        IntPtr objec = Marshal.StringToHGlobalAuto(obj);
        IntPtr func = Marshal.StringToHGlobalAuto(method);
        _registerConnectionListener(objec, func);
    }   

    override public void registerDataListener(string obj, string method) {
        IntPtr objec = Marshal.StringToHGlobalAuto(obj);
        IntPtr func = Marshal.StringToHGlobalAuto(method);
        _registerDataListener(objec, func);
    } 

    override public void registerArtifactListener(string obj, string method) {
        IntPtr objec = Marshal.StringToHGlobalAuto(obj);
        IntPtr func = Marshal.StringToHGlobalAuto(method);
        _registerArtifactListener(objec, func);
    } 

    override public void listenForDataPacket(string packetType) {
        IntPtr pType = Marshal.StringToHGlobalAuto(packetType);
        _listenForDataPacket(pType);
    }

    override public string getLibmuseVersion() {
        return Marshal.PtrToStringAuto(_getLibmuseVersion());
    }
}
