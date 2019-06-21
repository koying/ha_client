package com.keyboardcrumbs.hassclient;

import android.content.Context;
import android.util.Log;

import java.net.URL;

public class HassPrefs
{
  final static String TAG = "HassPrefs";

  private static final String SHARED_PREFERENCES_NAME = "FlutterSharedPreferences";

  private android.content.SharedPreferences preferences;
  private String HassDomain;
  private String HassPort;
  private String HassProtocol;
  private String HassWebhook;

  public HassPrefs(Context context)
  {
    preferences = context.getApplicationContext().getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
  }

  public String GetHassDomain()
  {
    return preferences.getString("flutter.hassio-domain", "");
  }

  public String GetHassPort()
  {
    return preferences.getString("flutter.hassio-port", "");
  }

  public String GetHassProtocol()
  {
    return preferences.getString("flutter.hassio-res-protocol", "");
  }

  public String GetHassWebhookId()
  {
    return preferences.getString("flutter.app-webhook-id", "");
  }

  public URL GetBaseUrl()
  {
    try
    {
      if (GetHassWebhookId().isEmpty())
        return null;

      return new URL(GetHassProtocol(), GetHassDomain(), Integer.parseInt(GetHassPort()), "/api");
    }
    catch (Exception e)
    {
      return null;
    }
  }
}
