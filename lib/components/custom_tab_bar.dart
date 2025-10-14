import 'package:flutter/material.dart';

import '../theme/theme.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: kGreyColor,
              ),
              child: TabBar(
                padding: const EdgeInsets.all(5),
                unselectedLabelColor: tSecondaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: kWhiteColor,
                ),
                labelColor: kPrimaryColor,
                tabs: [
                  Tab(
                    child: Text(
                      "Studi",
                      style: TextStyle(fontSize: 14, fontWeight: medium),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Rekap Nilai",
                      style: TextStyle(fontSize: 14, fontWeight: medium),
                    ),
                  ),
                ],
              )
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                MyTabOne(),
                MyTabTwo(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MyTabOne extends StatelessWidget {
  const MyTabOne({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Content for Studi Tab",
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}

class MyTabTwo extends StatelessWidget {
  const MyTabTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Content for Rekap Nilai Tab",
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
