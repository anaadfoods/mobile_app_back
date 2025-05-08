import 'package:flutter/material.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/screens/explore_screen.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/home/home_video.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/subscription_card.dart';
import 'package:grocery_app/widgets/subscription_table.dart';
import 'grocery_featured_Item_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override

  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.logo_dev), onPressed: () {}),
        title: Text(
          "AnaadFoods",
          style: TextStyle(
            fontSize: 24,
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              // padded(SearchBarWidget()),
              padded(AssetVideoPlayer()),
              padded(Text("Subscription Plans", style: TextStyle(fontWeight: FontWeight.bold , fontSize: 28),)),
              SubscriptionTable(),
              padded(Text("Active Subscription", style: TextStyle(fontWeight: FontWeight.bold , fontSize: 28),)),

              padded(SubscriptionCard()),

              padded(subTitle(context, "Exclusive Order")),
              getHorizontalItemSlider(exclusiveOffers),

              padded(subTitle(context, "Best Selling")),
              getHorizontalItemSlider(bestSelling),

              padded(subTitle(context, "Coming Soon")),

              SizedBox(
                height: 105,
                child: ListView(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(width: 20),
                    GroceryFeaturedCard(
                      groceryFeaturedItems[0],
                      color: Color(0xffF8A44C),
                    ),
                    SizedBox(width: 10),
                    GroceryFeaturedCard(
                      groceryFeaturedItems[1],
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 20),
                  ],
                ),
              ),
              // SizedBox(
              //   height: 15,
              // ),
              // // getHorizontalItemSlider(groceries),
              // SizedBox(
              //   height: 15,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget padded(Widget widget) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: widget,
    );
  }

  Widget getHorizontalItemSlider(List<GroceryItem> items) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 250,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              onItemClicked(context, items[index]);
            },
            child: GroceryItemCardWidget(
              item: items[index],
              heroSuffix: "home_screen",
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(width: 20);
        },
      ),
    );
  }

  void onItemClicked(BuildContext context, GroceryItem groceryItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ProductDetailsScreen(groceryItem, heroSuffix: "home_screen"),
      ),
    );
  }

  Widget subTitle(BuildContext context, String text) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExploreScreen()),
            );
          },
          child: Text(
            "See All",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget locationWidget() {
    String locationIconPath = "assets/icons/location_icon.svg";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(locationIconPath),
        SizedBox(width: 8),
        Text(
          "Khartoum,Sudan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
