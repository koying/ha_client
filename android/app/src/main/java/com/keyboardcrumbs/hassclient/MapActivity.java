package com.keyboardcrumbs.hassclient;

import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.preference.PreferenceManager;

import org.osmdroid.config.Configuration;
import org.osmdroid.tileprovider.tilesource.TileSourceFactory;
import org.osmdroid.views.MapView;

public class MapActivity extends Activity
{
  private MapView map = null;

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    Context ctx = getApplicationContext();
    Configuration.getInstance().load(ctx, PreferenceManager.getDefaultSharedPreferences(ctx));

    setContentView(R.layout.activity_map);

    map = (MapView) findViewById(R.id.map);
    map.setTileSource(TileSourceFactory.MAPNIK);
    map.setBuiltInZoomControls(true);
    map.setMultiTouchControls(true);
  }

  @Override
  protected void onPause()
  {
    super.onPause();
    map.onPause();  //needed for compass, my location overlays, v6.0.0 and up
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    map.onResume(); //needed for compass, my location overlays, v6.0.0 and up
  }
}
