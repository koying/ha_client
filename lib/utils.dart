part of 'main.dart';

class haUtils {
  static void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      TheLogger.log("Error", "Could not launch $url");
    }
  }
}