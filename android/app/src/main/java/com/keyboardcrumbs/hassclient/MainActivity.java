package com.keyboardcrumbs.hassclient;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.urllauncher.UrlLauncherPlugin;

import static android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP;
import static android.content.pm.PackageManager.PERMISSION_GRANTED;

public class MainActivity extends FlutterActivity implements MethodCallHandler {

  public static final int REQUEST_LOCATION = 167;
  private static final String FLUTTER_CHANNEL = "com.keyboardcrumbs.hassclient/main";
  public static String ACTION_UPDATE_TRACKER = "ACTION_UPDATE_TRACKER";

  private ArrayList<Bundle> mTrackers = new ArrayList<Bundle>();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    Intent backgroundService = new Intent(getApplicationContext(), UpdateService.class);
    startService(backgroundService);

    if (ActivityCompat.checkSelfPermission(getApplicationContext(), Manifest.permission.ACCESS_FINE_LOCATION)
        != PackageManager.PERMISSION_GRANTED) {
      // Check permission
      ActivityCompat.requestPermissions(this,
          new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
          REQUEST_LOCATION);
    }

    MethodChannel channel =
        new MethodChannel(getFlutterView(), FLUTTER_CHANNEL);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults)
  {
    switch (requestCode)
    {
      case REQUEST_LOCATION:
      {
        // If request is cancelled, the result arrays are empty.
        if (grantResults.length > 0
            && grantResults[0] == PERMISSION_GRANTED)
        {
          UpdateService.GetInstance().StartLocation();
        }
      }
    }
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result)
  {
    if (methodCall.method.equals("launchActivity")) {
      launchActivity(methodCall, result);
    } else if (methodCall.method.equals("launchMap")) {
      launchMap(methodCall, result);
    } else if (methodCall.method.equals("updateTracker")) {
      updateTracker(methodCall, result);
    } else {
      result.notImplemented();
    }
  }

  private void launchActivity(MethodCall call, Result result)
  {
    String _class = call.argument("class");
    Intent launchIntent = null;
    try
    {
      launchIntent = new Intent(this, Class.forName(_class));
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
    startActivity(launchIntent);
    result.success(true);
  }


  private void launchMap(MethodCall call, Result result)
  {
    Log.d("flutter", "launchMap: ");
    Intent launchIntent = null;
    try
    {
      launchIntent = new Intent(this, Class.forName("com.keyboardcrumbs.hassclient.MapActivity"));
      launchIntent.addFlags (FLAG_ACTIVITY_SINGLE_TOP);

      Bundle bundle = new Bundle();
      bundle.putParcelableArrayList("trackers", mTrackers);
      launchIntent.putExtras(bundle);
      startActivity(launchIntent);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      return;
    }
    result.success(true);
  }

  private void updateTracker(MethodCall call, Result result)
  {
    Bundle bundle = new Bundle();
    bundle.putString("id", (String) call.argument("id"));
    bundle.putString("description", (String) call.argument("description"));
    bundle.putDouble("longitude", (Double) call.argument("longitude"));
    bundle.putDouble("latitude", (Double) call.argument("latitude"));
    bundle.putInt("accuracy", (int) call.argument("accuracy"));
    bundle.putString("picture_url", (String) call.argument("picture_url"));

    for (int i = 0; i < mTrackers.size(); ++i)
    {
      if (mTrackers.get(i).getString("id").equals(call.argument("id")))
      {
        mTrackers.remove(i);
        break;
      }
    }
    mTrackers.add(bundle);
    Log.d("flutter", "updateTracker: " + bundle.getString("id"));

    if (!MapActivity.isRunning)
      return;

    Intent launchIntent = null;
    try
    {
      launchIntent = new Intent(this, Class.forName("com.keyboardcrumbs.hassclient.MapActivity"));
      launchIntent.setAction(ACTION_UPDATE_TRACKER);
      launchIntent.addFlags (FLAG_ACTIVITY_SINGLE_TOP);

      launchIntent.putExtras(bundle);

      startActivity(launchIntent);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      return;
    }
    result.success(true);
  }
}
