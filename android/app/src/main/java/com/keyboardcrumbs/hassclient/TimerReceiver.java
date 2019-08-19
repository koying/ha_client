package com.keyboardcrumbs.hassclient;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.BatteryManager;
import android.util.Log;

public class TimerReceiver extends BroadcastReceiver
{
  public final static String TAG = "HassReceiver";

  @Override
  public void onReceive(Context context, Intent intent)
  {
    if (intent.getAction().equals(Intent.ACTION_BATTERY_CHANGED))
    {
      int status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
      int level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
      int scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);

      boolean isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
          status == BatteryManager.BATTERY_STATUS_FULL;

      UpdateService.GetInstance().StartLocation(isCharging);

      if (level > 0.0 && scale > 0.0)
      {
        long battery_level = Math.round(level / (float) scale * 100.0);
        Log.d(TAG, "onReceive: ACTION_BATTERY_CHANGED");
        UpdateService.GetInstance().UpdateLocation(isCharging, battery_level);
      }
    }
  }
}
