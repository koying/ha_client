package com.keyboardcrumbs.hassclient;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;

import java.math.BigDecimal;
import java.net.URL;
import java.util.List;
import java.util.Vector;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeoutException;

import io.swagger.client.ApiException;
import io.swagger.client.api.MobileAppApi;
import io.swagger.client.model.Webhook;
import io.swagger.client.model.WebhookData;

import static io.swagger.client.model.Webhook.TypeEnum.update_location;

public class UpdateService extends Service implements LocationListener
{
  public final static String TAG = "HassService";
  private static UpdateService sInstance = null;
  private static final String ACTION_CLOSE = "ACTION_CLOSE";

  private static final String NOTIF_CHANNEL_ID = "haclient_channel_svc";
  private static final int NOTIF_NET_ERROR = 333;

  boolean mIsGPSEnabled = false;
  boolean mIsNetworkEnabled = false;
  boolean mForcedGPS = false;

  private Location mLastLocation = null;
  private long mLastBatteryLevel = -1;
  private boolean mIsCharging = false;

  private NotificationManager mNotificationManager = null;
  private TimerReceiver mReceiver = null;

  // Declaring a Location Manager
  protected LocationManager locationManager;
  // The minimum distance to change Updates in meters
  private static final long MIN_DISTANCE_CHANGE_FOR_UPDATES = 25; // 10 meters
  // The minimum time between updates in milliseconds
  private static final long MIN_TIME_BW_UPDATES = 1000 * 60 * 1; // 1 minute

  private static class FireAndForgetExecutor
  {

    private static Executor executor = Executors.newFixedThreadPool(5);

    public static void exec(Runnable command){
      executor.execute(command);
    }
  }

  public class UpdateLocationTask implements Runnable
  {
    private Context mContext;
    private boolean mIsCharging;
    private Location mLocation;

    double latitude = 0.0; // Latitude
    double longitude = 0.0; // Longitude
    double accuracy = 0.0; // Accuracy in meters
    double altitude = 0.0; // Altitude in meters
    double vert_accuracy = 0.0; // Vertical Accuracy in meters
    double speed = 0.0; // Speed in m/s
    double bearing = 0.0; // Bearing in degrees
    double battery_level = 0.0; // Battery percentage

    public UpdateLocationTask(Context context, Boolean isCharging, Location loc)
    {
      this.mContext = context;
      this.mLocation = loc;
      this.mIsCharging = isCharging;
    }

    /**
     * Function to get latitude
     * */
    public double getLatitude(){
      if(mLocation != null){
        latitude = mLocation.getLatitude();
      }
      return latitude;
    }

    /**
     * Function to get longitude
     * */
    public double getLongitude(){
      if(mLocation != null){
        longitude = mLocation.getLongitude();
      }
      return longitude;
    }

    /**
     * Function to get accuracy
     * */
    public double getAccuracy(){
      if(mLocation != null){
        accuracy = mLocation.getAccuracy();
      }
      return accuracy;
    }

    /**
     * Function to get altitude
     * */
    public double getAltitude(){
      if(mLocation != null){
        altitude = mLocation.getAltitude();
      }
      return altitude;
    }

    /**
     * Function to get speed
     * */
    public double getSpeed(){
      if(mLocation != null){
        speed = mLocation.getSpeed();
      }
      return speed;
    }

    /**
     * Function to get vertical accuracy
     * */
    public double getVerticalAccuracy(){
      if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && mLocation != null)
      {
        vert_accuracy = mLocation.getVerticalAccuracyMeters();
      }
      return vert_accuracy;
    }

    /**
     * Function to get bearing
     * */
    public double getBearing(){
      if( mLocation != null)
      {
        bearing = mLocation.getBearing();
      }
      return bearing;
    }


    @Override
    public void run()
    {
      /* Get Battery */
      IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
      Intent batteryStatus = mContext.registerReceiver(null, ifilter);

      int status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
      int level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
      int scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1);

      boolean isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
          status == BatteryManager.BATTERY_STATUS_FULL;
      if (level > 0.0 && scale > 0.0)
        battery_level = level / (float)scale * 100.0;

      /* Publish update */
      HassPrefs prefs = new HassPrefs(mContext);
      URL hassUrl = prefs.GetBaseUrl();
      if (hassUrl == null || prefs.GetHassWebhookId().isEmpty())
      {
        Log.w(TAG, "Webhook url not set");
        return;
      }
      Log.d(TAG, "Update: " + hassUrl.toString());

      BigDecimal latitude = BigDecimal.valueOf(getLatitude());
      BigDecimal longitude = BigDecimal.valueOf(getLongitude());
      List<BigDecimal> coordinates = new Vector<BigDecimal>();
      coordinates.add(latitude);
      coordinates.add(longitude);

      MobileAppApi apiInstance = new MobileAppApi();
      apiInstance.setBasePath(hassUrl.toString());

      String webhookId = prefs.GetHassWebhookId();
      Webhook body = new Webhook(); // Webhook | json body
      body.setType(update_location);

      WebhookData data = new WebhookData();
      data.setGps(coordinates);

      if (getAccuracy() > 0.0)
        data.setGpsAccuracy((int)Math.round(getAccuracy()));
      if (getAltitude() != 0.0)
        data.setAltitude((int)Math.round(getAltitude()));
      if (getVerticalAccuracy() > 0.0)
        data.setVerticalAccuracy((int)Math.round(getVerticalAccuracy()));
      if (getSpeed() > 0.0)
        data.setSpeed((int)Math.round(getSpeed()));
      if (getBearing() != 0.0)
        data.setCourse((int)Math.round(getBearing()));

      if (battery_level > 0.0)
        data.setBattery((int)Math.round(battery_level));

      body.setData(data);

      NotificationManagerCompat notificationManager = NotificationManagerCompat.from(getApplicationContext());
      boolean ok = true;

      try {
        apiInstance.webhookWebhookIdPost(webhookId, body);
      } catch (ApiException e) {
        e.printStackTrace();
        ok = false;
      }
      catch (InterruptedException e)
      {
        e.printStackTrace();
        ok = false;
      }
      catch (ExecutionException e)
      {
        e.printStackTrace();
        ok = false;
      }
      catch (TimeoutException e)
      {
        System.err.println("Exception when calling MobileAppApi#webhookWebhookIdPost");
        e.printStackTrace();

        Notification.Builder builder = new Notification.Builder(getApplicationContext())
            .setContentTitle("HA is unreachable")
            .setSmallIcon(R.drawable.mini_icon)
            ;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
          builder.setChannelId(NOTIF_CHANNEL_ID);
        Notification notification = builder.build();

        notificationManager.notify(NOTIF_NET_ERROR, builder.build());
        ok = false;
      }
      catch (Exception e)
      {
        e.printStackTrace();
        ok = false;
      }

      if (ok)
      {
        notificationManager.cancel(NOTIF_NET_ERROR);
      }
    }

  }

  @Override
  public IBinder onBind(Intent intent)
  {
    return null;
  }

  @Override
  public void onCreate() {
    super.onCreate();
    sInstance = this;

    mReceiver = new TimerReceiver();
    IntentFilter mFilter = new IntentFilter();
    mFilter.addAction(Intent.ACTION_TIME_TICK);
    mFilter.addAction(Intent.ACTION_BATTERY_CHANGED);
    registerReceiver(mReceiver, mFilter);

    locationManager = (LocationManager) getSystemService(LOCATION_SERVICE);
    // Getting GPS status
    mIsGPSEnabled = locationManager
        .isProviderEnabled(LocationManager.GPS_PROVIDER);
    // Getting network status
    mIsNetworkEnabled = locationManager
        .isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        && !Build.FINGERPRINT.contains("generic") /* Emulator only work with GPS */;
  }

  static public UpdateService GetInstance()
  {
    return sInstance;
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId)
  {
    if (intent != null) {
      final String action = intent.getAction();
      if (action != null) {
        switch (action) {
          case ACTION_CLOSE:
            stopSelf();
            return START_NOT_STICKY;
        }
      }
    }

/*
    Bitmap icon = BitmapFactory.decodeResource(getResources(),
        R.drawable.mini_icon);
*/

    Intent launchIntent = new Intent(getApplicationContext(), MainActivity.class);
    launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
    PendingIntent launchPendingIntent = PendingIntent.getActivity(getApplicationContext(), 0, launchIntent, 0);

    Intent closeIntent = new Intent(getApplicationContext(), UpdateService.class);
    closeIntent.setAction(ACTION_CLOSE);
    PendingIntent closePendingIntent = PendingIntent.getService(getApplicationContext(),
        1, closeIntent, PendingIntent.FLAG_UPDATE_CURRENT);

    Notification.Builder builder = new Notification.Builder(this)
        .setContentTitle("HA Service is running...")
        .setSmallIcon(R.drawable.mini_icon)
        .setContentIntent(launchPendingIntent)
        .addAction(R.drawable.ic_close, getString(R.string.notif_close),
            closePendingIntent);
    ;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
    {
      mNotificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

      CharSequence name = getString(R.string.notif_channel_name);

      // The user-visible description of the channel.
      String description = getString(R.string.notif_channel_desc);
      int importance = NotificationManager.IMPORTANCE_LOW;

      NotificationChannel mChannel = new NotificationChannel(NOTIF_CHANNEL_ID, name, importance);

      // Configure the notification channel.
      mChannel.setDescription(description);

      mNotificationManager.createNotificationChannel(mChannel);
      builder.setChannelId(NOTIF_CHANNEL_ID);
    }

    Notification notification = builder.build();
    startForeground(1, notification);
    Log.d(TAG, "Service started");

    return START_STICKY;
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
    unregisterReceiver(mReceiver);
    if (mNotificationManager != null)
      mNotificationManager.cancelAll();
    Log.d(TAG, "Service destroyed.");
  }

  synchronized public void StartLocation(boolean forceGPS)
  {
    if (ActivityCompat.checkSelfPermission(getApplicationContext(), Manifest.permission.ACCESS_FINE_LOCATION)
        == PackageManager.PERMISSION_GRANTED)
    {
      if (forceGPS != mForcedGPS)
      {
        StopLocation();
        mForcedGPS = forceGPS;
      }

      if (mIsNetworkEnabled && !(mIsGPSEnabled && mForcedGPS))
      {
        locationManager.requestLocationUpdates(
            LocationManager.NETWORK_PROVIDER,
            MIN_TIME_BW_UPDATES,
            MIN_DISTANCE_CHANGE_FOR_UPDATES, this);
        Log.d(TAG, "Network provider");
      }
      else
      {
        locationManager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            MIN_TIME_BW_UPDATES,
            MIN_DISTANCE_CHANGE_FOR_UPDATES, this);
        Log.d(TAG, "GPS provider");
      }
    }
  }

  synchronized public void StopLocation()
  {
    locationManager.removeUpdates(this);
  }

  synchronized public void UpdateLocation()
  {
    FireAndForgetExecutor.exec(new UpdateLocationTask(getApplicationContext(), false, mLastLocation));
  }

  synchronized public void UpdateLocation(long battery_level)
  {
    if (battery_level != mLastBatteryLevel)
    {
      FireAndForgetExecutor.exec(new UpdateLocationTask(getApplicationContext(), false, mLastLocation));
      mLastBatteryLevel = battery_level;
    }
  }

  synchronized public void UpdateLocation(boolean isCharging, long battery_level)
  {
    if (battery_level != mLastBatteryLevel || isCharging != mIsCharging)
    {
      FireAndForgetExecutor.exec(new UpdateLocationTask(getApplicationContext(), mIsCharging, mLastLocation));
      mLastBatteryLevel = battery_level;
    }
  }

  @Override
  public void onLocationChanged(Location location)
  {
    mLastLocation = location;
    UpdateLocation();
  }

  @Override
  public void onStatusChanged(String s, int i, Bundle bundle)
  {

  }

  @Override
  public void onProviderEnabled(String s)
  {

  }

  @Override
  public void onProviderDisabled(String s)
  {

  }
}
