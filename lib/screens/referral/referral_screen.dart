import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class ReferAndEarnScreen extends StatelessWidget {
  final String referralCode = "ANAAD2025";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F5F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Refer & Earn",
          style: TextStyle(
            color: Color(0xFF3E3E3E),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF3E3E3E)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            "https://st2.depositphotos.com/1219867/8235/i/450/depositphotos_82350542-stock-photo-beautiful-gold-present-box-with.jpg",
            height: 150,
            width: 150,
          ),
          SizedBox(height: 20),
          Text(
            "Share Health, Earn Trust",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E3E3E),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Invite your friends and family to join the ANAAD community and earn rewards while spreading health.",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7C7C7C),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: referralCode),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy, color: Color(0xFF8BC34A)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    SnackBarHelper.showSuccess(
                      context,
                      "Referral code copied to clipboard!",
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8BC34A),
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Invite Friends",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.whatshot, color: Color(0xFF25D366), size: 30),
                onPressed: () async {
                  final message = Uri.encodeComponent(
                    'Join me on ANAAD! Use my referral code: $referralCode',
                  );
                  final url = 'https://wa.me/?text=$message';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    SnackBarHelper.showError(
                      context,
                      'No app found to open WhatsApp.',
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.facebook, color: Color(0xFF4267B2), size: 30),
                onPressed: () async {
                  final fbUrl =
                      'https://www.facebook.com/sharer/sharer.php?u=https://anaadfoods.com&quote=Join me on ANAAD! Use my referral code: $referralCode';
                  if (await canLaunch(fbUrl)) {
                    await launch(fbUrl);
                  } else {
                    SnackBarHelper.showError(
                      context,
                      'No app found to open Facebook.',
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.email, color: Color(0xFFDD4B39), size: 30),
                onPressed: () async {
                  final subject = Uri.encodeComponent('Join me on ANAAD!');
                  final body = Uri.encodeComponent(
                    'Use my referral code: $referralCode',
                  );
                  final emailUrl = 'mailto:?subject=$subject&body=$body';
                  if (await canLaunch(emailUrl)) {
                    await launch(emailUrl);
                  } else {
                    SnackBarHelper.showError(
                      context,
                      'No app found to open email.',
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.share, color: Color(0xFF3E3E3E), size: 30),
                onPressed: () {
                  Share.share(
                    'Join me on ANAAD! Use my referral code: $referralCode',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
