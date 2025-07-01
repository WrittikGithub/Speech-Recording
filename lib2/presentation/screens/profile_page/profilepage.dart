import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/screens/profile_page/widgets/screen_bankdetails.dart';
import 'package:sdcp_rebuild/presentation/screens/profile_page/widgets/screen_profilecontent.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';


class ScreenProfile extends StatefulWidget {
  const ScreenProfile({super.key});

  @override
  State<ScreenProfile> createState() => _ScreenProfileState();
}

class _ScreenProfileState extends State<ScreenProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextStyles.subheadline(text: 'My Profile'),
                  ListenableBuilder(
  listenable: GlobalState(),
  builder: (context, _) {
    return      TextStyles.body(text: 'Hello! ${GlobalState().username}');
  },
)
          ],
        ),
      ),
      body: Column(
        children: [
          ResponsiveSizedBox.height20,
          Container(
            width: ResponsiveUtils.wp(80),
            height: ResponsiveUtils.hp(5),
            decoration: BoxDecoration(
              color: Appcolors.kpurpleColor.withOpacity(.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Appcolors.kwhiteColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelColor: Appcolors.kblackColor,
                unselectedLabelColor: Appcolors.kwhiteColor,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Profile'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Bank Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ScreenProfileContent(),
                ScreenBankdetailsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
