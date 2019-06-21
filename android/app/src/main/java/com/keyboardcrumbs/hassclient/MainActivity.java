package com.keyboardcrumbs.hassclient;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;

import androidx.core.app.ActivityCompat;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import static android.content.pm.PackageManager.PERMISSION_GRANTED;

public class MainActivity extends FlutterActivity {

  public static final int REQUEST_LOCATION = 167;

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
}
