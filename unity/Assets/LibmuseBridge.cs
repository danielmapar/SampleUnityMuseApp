using UnityEngine;
using System.Collections;
using System;
using System.Runtime.InteropServices;

/*
 * This is the class to use to communicate with the muse headband from Unity.
 */
abstract public class LibmuseBridge {

    /*
     * Start scanning for Muse headbands that are available to connect to.
     * You muse register a listener using registerMuseListener method in 
     * order to get a callback with a list of muses ready for connection.
     */
    abstract public void startListening();

    /*
     * This will stop scanning for bluetooth headbands. Scanning for 
     * bluetooth headband is expensive operation. When you call connect
     * method to connect to a headband, this will be automatically done.
     * So don't really need to call this explicitly. 
     */
    abstract public void stopListening(); 

    /*
     * Connect to a headband with a given name. 
     * The muse listener you registered will get a list of muse names.
     * You can then call connect on one of those muses.
     */
    abstract public void connect(string headband);  

    /*
     * Disconnects from the headband. You will get a connection callback
     * notifying you that it is disconnected. Then in your connection listeners
     * you can unregister all listeners if you no longer need to communicate with
     * the headband. Note that you can still receive some data after calling this
     * method since disconnect will happen asynchronously. 
     */
    abstract public void disconnect();    

    /*
     * You can register any C# object's method to get a callback when available
     * muses are discovered and ready to for connection. You should register one
     * listener using this method before calling startListening().
     */
    abstract public void registerMuseListener(string obj, string method); 

    /*
     * Register a connection listener for any connection related events such as
     * when headband is connected or disconnected. 
     */    
    abstract public void registerConnectionListener(string obj, string method);   

    /*
     * Register a data listener to recieve data packets from the headband.
     * You can specify what data packets you want to recieve using listenForDataPacket
     * method before you connect to a headband.
     */
    abstract public void registerDataListener(string obj, string method); 

    /*
     * Register a listener to recieve artifact packets such as eye blink. 
     */
    abstract public void registerArtifactListener(string obj, string method); 

    /*
     * Use this method to request for the type of data packets you want to
     * recieve in your data listeners. Call this before connecting to headband.
     */
    abstract public void listenForDataPacket(string packetType);

    /*
     * This will return the current version of Libmuse SDK
     */
    abstract public string getLibmuseVersion();
	
}
