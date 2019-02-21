//  Copyright © 2016 choosemuse. All rights reserved.

package com.muse.lib;

import android.app.Activity;
import android.util.Log;

import com.choosemuse.libmuse.Accelerometer;
import com.choosemuse.libmuse.Battery;
import com.choosemuse.libmuse.DrlRef;
import com.choosemuse.libmuse.Eeg;
import com.choosemuse.libmuse.Gyro;
import com.choosemuse.libmuse.LibmuseVersion;
import com.choosemuse.libmuse.Muse;
import com.choosemuse.libmuse.MuseArtifactPacket;
import com.choosemuse.libmuse.MuseConnectionListener;
import com.choosemuse.libmuse.MuseConnectionPacket;
import com.choosemuse.libmuse.MuseDataListener;
import com.choosemuse.libmuse.MuseDataPacket;
import com.choosemuse.libmuse.MuseDataPacketType;
import com.choosemuse.libmuse.MuseListener;
import com.choosemuse.libmuse.MuseManagerAndroid;
import com.unity3d.player.UnityPlayer;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;

public class LibmuseUnityProjectAndroid {
    /**
     * Libmuse API requires an application context to be passed to the muse manager.
     * The context is required to register receivers for broadcast events related to bluetooth.
     */
    private Activity activityContext;

    /**
     * The MuseManager is how you detect Muse headbands and receive notifications
     * when the list of available headbands changes.
     */
    private MuseManagerAndroid manager;

    /**
     * A Muse refers to a Muse headband.  Use this to connect/disconnect from the
     * headband, register listeners to receive EEG data and get headband
     * configuration and version information.
     */
    private Muse muse;

    /**
     * The ConnectionListener will be notified whenever there is a change in
     * the connection state of a headband, for example when the headband connects
     * or disconnects.
     *
     * Note that ConnectionListener is an inner class at the bottom of this file
     * that extends MuseConnectionListener.
     */
    private ConnectionListener connectionListener;

    /**
     * The DataListener is how you will receive EEG (and other) data from the
     * headband.
     *
     * Note that DataListener is an inner class at the bottom of this file
     * that extends MuseDataListener.
     */
    private DataListener dataListener;

    /**
     * ArrayLists of listeners from c# side. When you register a listener for a
     * particular data, the C# object and method name will be stored in these array.
     * Each element of arraylist is another arraylist of size 2.
     * The 1st elem in sub array is the c# obj and 2nd is the method.
     */
    private ArrayList<ArrayList<String>> unityDataListener;
    private ArrayList<ArrayList<String>> unityConnectionListener;
    private ArrayList<ArrayList<String>> unityMuseListener;
    private ArrayList<ArrayList<String>> unityArtifactListener;

    /**
     * When we discover list of muses, we keep a map of their
     * name to the muse object. This is because we return everything
     * to c# side as strings and when c# calls connect with the
     * headband name, we can retrieve the actual muse object.
     */
    private HashMap<String, Muse> museHashMap;

    /**
     * ArrayList of DataPacketTypes to pass to Unity (c#)
     */
    private ArrayList<MuseDataPacketType> dataTypeToListen;

    /**
     * Map string to DataPacketType and another map that is the reverse.
     */
    private HashMap<String, MuseDataPacketType> stringToDataPacketType;
    private HashMap<MuseDataPacketType, String> dataPacketTypeToString;

    /**
     * Array that map int -> different data packet Enums.
     * Useful in for-loops to retrieve values more easily.
     */
    private final Accelerometer[] accelMap =
            new Accelerometer[]{Accelerometer.FORWARD_BACKWARD, Accelerometer.UP_DOWN, Accelerometer.LEFT_RIGHT};
    private final Battery[] batteryMap =
            new Battery[]{Battery.CHARGE_PERCENTAGE_REMAINING, Battery.MILLIVOLTS, Battery.TEMPERATURE_CELSIUS};

    private final DrlRef[] drlMap = new DrlRef[]{DrlRef.DRL, DrlRef.REF};
    private final Gyro[] gyroMap = new Gyro[]{Gyro.FORWARD_BACKWARD, Gyro.UP_DOWN, Gyro.LEFT_RIGHT};
    private final Eeg[] eegMap = new Eeg[]{Eeg.EEG1, Eeg.EEG2, Eeg.EEG3, Eeg.EEG4, Eeg.AUX_LEFT, Eeg.AUX_RIGHT};

    // Debug string
    private final String TAG = "LibmuseUnityProjectAndroid";


    //--------------------------------------
    // Constructor and public method that can be called from C#

    public LibmuseUnityProjectAndroid(Activity context) {
        if(context == null) {
            Log.e(TAG, "Must pass in application context");

        } else {
            Log.v(TAG, "Initialization successful");
            activityContext = context;

            // We need to set the context on MuseManagerAndroid before we can do anything.
            // This must come before other LibMuse API calls as it also loads the library.
            manager = MuseManagerAndroid.getInstance();
            manager.setContext(activityContext);


            // Register a listener to receive connection state changes.
            connectionListener = new ConnectionListener();
            // Register a listener to receive data from a Muse.
            dataListener = new DataListener();
            // Register a listener to receive notifications of what Muse headbands
            // we can connect to.
            manager.setMuseListener(new MuseL());

            initDataStructures();
        }
    }

    public void startListening() {
        if(unityMuseListener.size() > 0) {
            // Start listening for nearby or paired Muse headbands. We call stopListening
            // first to make sure startListening will clear the list of headbands and start fresh.
            manager.stopListening();
            manager.startListening();
        } else {
            Log.e(TAG, "Please register a muse listener before start listening for headbands, " +
                    "otherwise you won't get any callbacks");
        }

    }

    public void stopListening() {
        manager.stopListening();
    }

    public String getLibmuseVersion() {
        return LibmuseVersion.instance().getString();
    }

    public void connect(String headband) {
        // Get the muse object from the hashmap
        if(museHashMap.get(headband) != null) {
            manager.stopListening();
            muse = museHashMap.get(headband);
            muse.unregisterAllListeners();
            muse.registerConnectionListener(connectionListener);

            // Register for all the data packet types requested by unity.
            for(MuseDataPacketType data : dataTypeToListen) {
                muse.registerDataListener(dataListener, data);
            }

            // Initiate a connection to the headband and stream the data asynchronously.
            muse.runAsynchronously();
        } else {
            Log.e(TAG, "Chosen muse to connect to couldn't be found. Make sure you scan for headbands first");
        }
    }

    public void disconnect() {
        muse.disconnect();
    }

    // This method will add the data types to emit back to unity in a list.
    public void listenForDataPacket(String packetType) {
        if(stringToDataPacketType.containsKey(packetType)) {
            dataTypeToListen.add(stringToDataPacketType.get(packetType));
        } else {
            Log.e(TAG, "Invalid input string data packet type");
        }
    }

    //--------------------------------------
    // Methods to register Unity listeners

    public void registerMuseListener(String obj, String method) {
        ArrayList<String> listener = new ArrayList<String>();
        listener.add(obj);
        listener.add(method);
        unityMuseListener.add(listener);
    }

    public void registerConnectionListener(String obj, String method) {
        ArrayList<String> listener = new ArrayList<String>();
        listener.add(obj);
        listener.add(method);
        unityConnectionListener.add(listener);
    }

    public void registerDataListener(String obj, String method) {
        ArrayList<String> listener = new ArrayList<String>();
        listener.add(obj);
        listener.add(method);
        unityDataListener.add(listener);
    }

    public void registerArtifactListener(String obj, String method) {
        ArrayList<String> listener = new ArrayList<String>();
        listener.add(obj);
        listener.add(method);
        unityArtifactListener.add(listener);
    }

    //--------------------------------------
    // Listeners that forwards data to Unity listeners.
    // These methods are called by the inner classes below,
    // which in turn gets called by libmuse sdk when data comes in.

    private void museListChanged() {
        // Create a white space separated string of list of muses that was found.
        // Also store a map of muse name -> the Muse obj; muse names should be all unique.
        final ArrayList<Muse> list = manager.getMuses();
        String muses = new String();
        for(Muse m : list) {
            museHashMap.put(m.getName(), m);
            muses += m.getName() + " ";
        }
        // Notify all the unity muse listeners
        // First element in list is the obj, 2nd is the method to call
        for(ArrayList<String> listener: unityMuseListener) {
            UnityPlayer.UnitySendMessage(listener.get(0), listener.get(1), muses);
        }
    }

    private void receiveMuseConnectionPacket(final MuseConnectionPacket p, final Muse muse) {
        JSONObject status = new JSONObject();
        try {
            status.put("PreviousConnectionState", p.getPreviousConnectionState());
            status.put("CurrentConnectionState", p.getCurrentConnectionState());
        } catch (JSONException e) {
            Log.e(TAG, "Could not create JSON object for connection packet");
        }

        // Notify all the unity connection listeners.
        for(ArrayList<String> listener : unityConnectionListener) {
            UnityPlayer.UnitySendMessage(listener.get(0), listener.get(1), status.toString());
        }
    }

    private void receiveMuseDataPacket(final MuseDataPacket p, final Muse muse) {
        JSONObject data = new JSONObject();
        try {
            data.put("DataPacketType", dataPacketTypeToString.get(p.packetType()));
            data.put("DataPacketValue", createDataJSONArray(p));
            data.put("TimeStamp", p.timestamp());
        } catch (JSONException e) {
            Log.e(TAG, "Could not create JSON object for " + p.packetType().toString());
        }

        // Notify all the unity data listeners.
        for(ArrayList<String> listener : unityDataListener) {
            UnityPlayer.UnitySendMessage(listener.get(0), listener.get(1), data.toString());
        }
    }

    private void receiveMuseArtifactPacket(final MuseArtifactPacket p, final Muse muse) {
        JSONObject artifact = new JSONObject();
        try {
            artifact.put("HeadbandOn", String.valueOf(p.getHeadbandOn()));
            artifact.put("Blink", String.valueOf(p.getBlink()));
            artifact.put("JawClench", String.valueOf(p.getJawClench()));
        } catch (JSONException e) {
            Log.e(TAG, "Could not create JSON object for artifact packet");
        }

        // Notify all the unity artifact listeners.
        for(ArrayList<String> listener : unityArtifactListener) {
            UnityPlayer.UnitySendMessage(listener.get(0), listener.get(1), artifact.toString());
        }
    }


    //--------------------------------------
    // Helper methods

    private void initDataStructures() {
        unityDataListener = new ArrayList<ArrayList<String>>();
        unityArtifactListener = new ArrayList<ArrayList<String>>();
        unityConnectionListener = new ArrayList<ArrayList<String>>();
        unityMuseListener = new ArrayList<ArrayList<String>>();
        museHashMap = new HashMap<String, Muse>();
        dataTypeToListen = new ArrayList<MuseDataPacketType>();
        stringToDataPacketType = new HashMap<String, MuseDataPacketType>();
        dataPacketTypeToString = new HashMap<MuseDataPacketType, String>();
        initMaps();
    }

    private void initMaps() {
        stringToDataPacketType.put("ACCELEROMETER", MuseDataPacketType.ACCELEROMETER);
        stringToDataPacketType.put("GYRO", MuseDataPacketType.GYRO);
        stringToDataPacketType.put("EEG", MuseDataPacketType.EEG);
        stringToDataPacketType.put("QUANTIZATION", MuseDataPacketType.QUANTIZATION);
        stringToDataPacketType.put("BATTERY", MuseDataPacketType.BATTERY);
        stringToDataPacketType.put("DRL_REF", MuseDataPacketType.DRL_REF);
        stringToDataPacketType.put("ALPHA_ABSOLUTE", MuseDataPacketType.ALPHA_ABSOLUTE);
        stringToDataPacketType.put("BETA_ABSOLUTE", MuseDataPacketType.BETA_ABSOLUTE);
        stringToDataPacketType.put("DELTA_ABSOLUTE", MuseDataPacketType.DELTA_ABSOLUTE);
        stringToDataPacketType.put("THETA_ABSOLUTE", MuseDataPacketType.THETA_ABSOLUTE);
        stringToDataPacketType.put("GAMMA_ABSOLUTE", MuseDataPacketType.GAMMA_ABSOLUTE);
        stringToDataPacketType.put("ALPHA_RELATIVE", MuseDataPacketType.ALPHA_RELATIVE);
        stringToDataPacketType.put("BETA_RELATIVE", MuseDataPacketType.BETA_RELATIVE);
        stringToDataPacketType.put("DELTA_RELATIVE", MuseDataPacketType.DELTA_RELATIVE);
        stringToDataPacketType.put("THETA_RELATIVE", MuseDataPacketType.THETA_RELATIVE);
        stringToDataPacketType.put("GAMMA_RELATIVE", MuseDataPacketType.GAMMA_RELATIVE);
        stringToDataPacketType.put("ALPHA_SCORE", MuseDataPacketType.ALPHA_SCORE);
        stringToDataPacketType.put("BETA_SCORE", MuseDataPacketType.BETA_SCORE);
        stringToDataPacketType.put("DELTA_SCORE", MuseDataPacketType.DELTA_SCORE);
        stringToDataPacketType.put("THETA_SCORE", MuseDataPacketType.THETA_SCORE);
        stringToDataPacketType.put("GAMMA_SCORE", MuseDataPacketType.GAMMA_SCORE);
        stringToDataPacketType.put("HSI_PRECISION", MuseDataPacketType.HSI_PRECISION);
        stringToDataPacketType.put("ARTIFACTS", MuseDataPacketType.ARTIFACTS);

        // init the reverse map
        for(String key : stringToDataPacketType.keySet()) {
            dataPacketTypeToString.put(stringToDataPacketType.get(key), key);
        }
    }

    private JSONArray createDataJSONArray(final MuseDataPacket p) {
        JSONArray result = new JSONArray();
        try{
            switch (p.packetType()) {
                case ACCELEROMETER:
                    for(int i = 0; i < p.valuesSize(); i++) {
                        result.put(p.getAccelerometerValue(accelMap[i]));
                    }
                    break;
                case BATTERY:
                    for(int i = 0; i < p.valuesSize(); i++) {
                        result.put(p.getBatteryValue(batteryMap[i]));
                    }
                    break;
                case DRL_REF:
                    for(int i = 0; i < p.valuesSize(); i++) {
                        result.put(p.getDrlRefValue(drlMap[i]));
                    }
                    break;
                case GYRO:
                    for(int i = 0; i < p.valuesSize(); i++) {
                        result.put(p.getGyroValue(gyroMap[i]));
                    }
                    break;
                // Everything else is EEG or EEG derived value
                default:
                    for(int i = 0; i < p.valuesSize(); i++) {
                        double value = p.getEegChannelValue(eegMap[i]);
                        double num = (Double.isNaN(value))? 0 : value;
                        result.put(num);
                    }
                    break;
            }
        } catch (JSONException e) {
            Log.e(TAG, "Could not create JSON array for " + p.packetType().toString());
        }
        return result;
    }


    //--------------------------------------
    // Listener translators
    //
    // Each of these classes extend from the appropriate listener and contain a weak reference to
    // outer class. Each class simply forwards the messages it receives back to the LibmuseUnityProjectAndroid.
    class MuseL extends MuseListener {

        @Override
        public void museListChanged() {
            LibmuseUnityProjectAndroid.this.museListChanged();
        }
    }

    class ConnectionListener extends MuseConnectionListener {

        @Override
        public void receiveMuseConnectionPacket(final MuseConnectionPacket p, final Muse muse) {
            LibmuseUnityProjectAndroid.this.receiveMuseConnectionPacket(p, muse);
        }
    }

    class DataListener extends MuseDataListener {

        @Override
        public void receiveMuseDataPacket(final MuseDataPacket p, final Muse muse) {
            LibmuseUnityProjectAndroid.this.receiveMuseDataPacket(p, muse);
        }

        @Override
        public void receiveMuseArtifactPacket(final MuseArtifactPacket p, final Muse muse) {
            LibmuseUnityProjectAndroid.this.receiveMuseArtifactPacket(p, muse);
        }
    }
}
