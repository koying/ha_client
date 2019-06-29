package com.keyboardcrumbs.hassclient;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.Log;

import com.google.maps.android.ui.IconGenerator;

import org.osmdroid.api.IMapController;
import org.osmdroid.config.Configuration;
import org.osmdroid.tileprovider.tilesource.ITileSource;
import org.osmdroid.tileprovider.tilesource.TileSourceFactory;
import org.osmdroid.tileprovider.tilesource.XYTileSource;
import org.osmdroid.util.GeoPoint;
import org.osmdroid.views.MapView;
import org.osmdroid.views.overlay.ItemizedIconOverlay;
import org.osmdroid.views.overlay.ItemizedOverlayWithFocus;
import org.osmdroid.views.overlay.OverlayItem;
import org.osmdroid.views.overlay.mylocation.MyLocationNewOverlay;

import java.util.ArrayList;
import java.util.List;

public class MapActivity extends Activity
{
  private static String TAG = "MapActivity";

  public static boolean isRunning = false;
  private MapView mMapView = null;
  private MyLocationNewOverlay mLocationOverlay;
  private ItemizedOverlayWithFocus<OverlayItem> mOverlay = null;

  private static String update_tracker_action = "ACTION_UPDATE_TRACKER";

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    Log.d(TAG, "onCreate: ");
    Context ctx = getApplicationContext();
    Configuration.getInstance().load(ctx, PreferenceManager.getDefaultSharedPreferences(ctx));

    setContentView(R.layout.activity_map);

    mMapView = (MapView) findViewById(R.id.map);

    // Create a custom tile source
    final ITileSource tileSource = new XYTileSource( "Carto", 1, 30, 256, ".png",
        new String[] {
            "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/",
            "https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/",
            "https://cartodb-basemaps-c.global.ssl.fastly.net/light_all/",
            },"Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL.");
    mMapView.setTileSource(tileSource);
    //mMapView.setTileSource(TileSourceFactory.MAPNIK);

    mMapView.setBuiltInZoomControls(true);
    mMapView.setMultiTouchControls(true);

    LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
    List<String> providers = locationManager.getProviders(true);
    Location bestLocation = null;
    for (String provider : providers) {
      @SuppressLint("MissingPermission") Location l = locationManager.getLastKnownLocation(provider);
      if (l == null) {
        continue;
      }
      if (bestLocation == null || l.getAccuracy() < bestLocation.getAccuracy()) {
        // Found best last known location: %s", l);
        bestLocation = l;
      }
    }
    IMapController mapController = mMapView.getController();
    mapController.setZoom(14d);
    if( bestLocation != null ) {
      GeoPoint startPoint = new GeoPoint(bestLocation.getLatitude(), bestLocation.getLongitude());
      mapController.setCenter(startPoint);
    }

    mOverlay = new ItemizedOverlayWithFocus<OverlayItem>(new ArrayList<OverlayItem>(),
        new ItemizedIconOverlay.OnItemGestureListener<OverlayItem>() {
          @Override
          public boolean onItemSingleTapUp(final int index, final OverlayItem item) {
            //do something
            return true;
          }
          @Override
          public boolean onItemLongPress(final int index, final OverlayItem item) {
            return false;
          }
        }, this);
    mOverlay.setFocusItemsOnTap(true);

    Bundle bundle = getIntent().getExtras();
    ArrayList<Bundle> trackers = bundle.getParcelableArrayList("trackers");
    for (Bundle b : trackers)
      Update_Tracker(b);

    mMapView.getOverlays().add(mOverlay);
  }

  @Override
  protected void onPause()
  {
    super.onPause();
    Log.d(TAG, "onPause: ");
    isRunning = false;
    mMapView.onPause();  //needed for compass, my location overlays, v6.0.0 and up
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    Log.d(TAG, "onResume: ");
    mMapView.onResume(); //needed for compass, my location overlays, v6.0.0 and up
    isRunning = true;
  }

  @Override
  protected void onNewIntent(Intent intent)
  {
    super.onNewIntent(intent);

    if (intent.getAction() == MainActivity.ACTION_UPDATE_TRACKER)
    {
      Update_Tracker(intent.getExtras());
    }
  }

  void Update_Tracker(Bundle bundle)
  {
    String id = bundle.getString("id");
    for(int i = 0; i < mOverlay.size(); ++i)
    {
      if (mOverlay.getItem(i).getUid().equals(id))
      {
        mOverlay.removeItem(i);
        break;
      }
    }
    OverlayItem new_tracker = new OverlayItem(id, bundle.getString("description"), "", new GeoPoint(bundle.getDouble("latitude"), bundle.getDouble("longitude")));
    IconGenerator tc = new IconGenerator(this);
    if (bundle.getBoolean("isThis"))
      tc.setStyle(IconGenerator.STYLE_BLUE);
    Bitmap bmp = tc.makeIcon(bundle.getString("description"));
    new_tracker.setMarker(new BitmapDrawable(getResources(), bmp));
    Log.d(TAG, "Update_Tracker: " + new_tracker.getTitle() + ", " + new_tracker.getPoint().toString());
    mOverlay.addItem(new_tracker);
  }
}
