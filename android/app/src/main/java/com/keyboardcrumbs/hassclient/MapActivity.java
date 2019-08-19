package com.keyboardcrumbs.hassclient;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.location.Location;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.TextPaint;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
import android.text.style.TypefaceSpan;
import android.util.Log;
import android.view.Gravity;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.google.maps.android.ui.IconGenerator;

import org.osmdroid.api.IMapController;
import org.osmdroid.config.Configuration;
import org.osmdroid.tileprovider.tilesource.ITileSource;
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

  public class CustomTypefaceSpan extends TypefaceSpan
  {
    private final Typeface newType;

    public CustomTypefaceSpan(String family, Typeface type)
    {
      super(family);
      newType = type;
    }

    @Override
    public void updateDrawState(TextPaint ds)
    {
      applyCustomTypeFace(ds, newType);
    }

    @Override
    public void updateMeasureState(TextPaint paint)
    {
      applyCustomTypeFace(paint, newType);
    }

    private  void applyCustomTypeFace(Paint paint, Typeface tf)
    {
      int oldStyle;
      Typeface old = paint.getTypeface();
      if (old == null) {
        oldStyle = 0;
      } else {
        oldStyle = old.getStyle();
      }

      int fake = oldStyle & ~tf.getStyle();
      if ((fake & Typeface.BOLD) != 0) {
        paint.setFakeBoldText(true);
      }

      if ((fake & Typeface.ITALIC) != 0) {
        paint.setTextSkewX(-0.25f);
      }

      paint.setTypeface(tf);
    }
  }

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

            String sGeo = new StringBuilder().append(item.getPoint().getLatitude()).append(",").append(item.getPoint().getLongitude()).toString();
            // Create google map intent.
            Uri gmmIntentUri = Uri.parse(new StringBuilder()
                .append("geo:")
                .append(sGeo)
                .append("?q=")
                .append(sGeo)
                .append("(" + item.getTitle() + ")")
                .toString());
            Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
            mapIntent.setPackage("com.google.android.apps.maps");
            startActivity(mapIntent);
            Log.d(TAG, "onItemSingleTapUp: " + gmmIntentUri.toString());

            return true;
          }
          @Override
          public boolean onItemLongPress(final int index, final OverlayItem item) {
            return false;
          }
        }, this);

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

    String pic_url = bundle.getString("picture_url");
    if (pic_url != null && !pic_url.isEmpty())
    {
      Glide.with(this)
          .load(pic_url)
          .override(150, 150)
          .fitCenter()
          .into(new CustomTarget<Drawable>()
          {
            @Override
            public void onResourceReady(@NonNull Drawable resource, @Nullable Transition<? super Drawable> transition)
            {
              ImageView view = new ImageView(MapActivity.this);
              view.setImageDrawable(resource);
              tc.setContentView(view);
              Bitmap bmp = tc.makeIcon();
              new_tracker.setMarker(new BitmapDrawable(getResources(), bmp));
            }

            @Override
            public void onLoadCleared(@Nullable Drawable placeholder)
            {
              // Remove the Drawable provided in onResourceReady from any Views and ensure
              // no references to it remain.
            }
          });
    }
    else
    {
      TextView view = new TextView(MapActivity.this);

      SpannableStringBuilder builder = new SpannableStringBuilder();
      int iIcon = bundle.getInt("icon");
      if (iIcon > 0)
      {
        builder.append(new String(Character.toChars(iIcon)));
        builder.setSpan(new CustomTypefaceSpan("", MainActivity.mMDIicons), 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        builder.setSpan(new RelativeSizeSpan(2f), 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        builder.append("\n");
        builder.append(bundle.getString("description"));
        builder.setSpan(new AbsoluteSizeSpan(15, true), 2, builder.length(), 0);
      }
      else
      {
        builder.append(bundle.getString("description"));
        builder.setSpan(new AbsoluteSizeSpan(15, true), 0, builder.length(), 0);
      }

      view.setText(builder);
      view.setGravity(Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL);
      tc.setContentView(view);
      if (bundle.getBoolean("isThis"))
      {
        builder.setSpan(new ForegroundColorSpan(Color.parseColor("#ffeeeeee")), 0, builder.length(), 0);
        tc.setStyle(IconGenerator.STYLE_BLUE);
      }
      else
      {
        builder.setSpan(new ForegroundColorSpan(Color.parseColor("#ff7f7f7f")), 0, builder.length(), 0);
      }

      Bitmap bmp = tc.makeIcon();
      new_tracker.setMarker(new BitmapDrawable(getResources(), bmp));
    }
    Log.d(TAG, "Update_Tracker: " + new_tracker.getTitle() + ", " + new_tracker.getPoint().toString());
    mOverlay.addItem(new_tracker);
  }
}
