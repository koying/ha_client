package com.keyboardcrumbs.hassclient;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.Log;

import org.osmdroid.api.IMapController;
import org.osmdroid.config.Configuration;
import org.osmdroid.tileprovider.tilesource.TileSourceFactory;
import org.osmdroid.util.GeoPoint;
import org.osmdroid.views.MapView;
import org.osmdroid.views.overlay.mylocation.GpsMyLocationProvider;
import org.osmdroid.views.overlay.mylocation.MyLocationNewOverlay;

import java.util.List;

public class MapActivity extends Activity
{
  private static String TAG = "MapActivity";
  private MapView mMapView = null;
  private MyLocationNewOverlay mLocationOverlay;

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    Log.d(TAG, "onCreate: ");
    Context ctx = getApplicationContext();
    Configuration.getInstance().load(ctx, PreferenceManager.getDefaultSharedPreferences(ctx));

    setContentView(R.layout.activity_map);

    mMapView = (MapView) findViewById(R.id.map);
    mMapView.setTileSource(TileSourceFactory.MAPNIK);
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

/*
    this.mLocationOverlay = new MyLocationNewOverlay(new GpsMyLocationProvider(ctx),mMapView);
    this.mLocationOverlay.enableMyLocation();
    mMapView.getOverlays().add(this.mLocationOverlay);
*/
  }

  @Override
  protected void onPause()
  {
    super.onPause();
    Log.d(TAG, "onPause: ");
    mMapView.onPause();  //needed for compass, my location overlays, v6.0.0 and up
  }

  @Override
  protected void onResume()
  {
    super.onResume();
    Log.d(TAG, "onResume: ");
    mMapView.onResume(); //needed for compass, my location overlays, v6.0.0 and up
  }
}
