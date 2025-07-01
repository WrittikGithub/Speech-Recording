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
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showBankDetails = true;

  @override
  void initState() {
    super.initState();
    // Start with 2 tabs by default
    _tabController = TabController(length: 2, vsync: this);
    _checkSignupAppValue();
  }

  Future<void> _checkSignupAppValue() async {
    try {
      final signupApp = await getSignupApp();
      
      // Only update if the value is '1' and we need to hide the bank details
      if (signupApp == '1' && _showBankDetails && mounted) {
        setState(() {
          _showBankDetails = false;
          // Create a new TabController with the correct length
          _tabController.dispose(); // Dispose the old controller
          _tabController = TabController(length: 1, vsync: this);
        });
        
        // Store in global state for other widgets
        GlobalState().setSignupApp(signupApp);
      }
    } catch (e) {
      // Just log the error and continue with default value
      debugPrint('Error getting signup app value: $e');
    }
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
                return TextStyles.body(text: 'Hello! ${GlobalState().username}');
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
              child: _showBankDetails ? _buildFullTabBar() : _buildProfileOnlyTabBar(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _showBankDetails 
                ? [const ScreenProfileContent(), const ScreenBankdetailsPage()]
                : [const ScreenProfileContent()],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullTabBar() {
    return TabBar(
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
    );
  }
  
  Widget _buildProfileOnlyTabBar() {
    return TabBar(
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
      ],
    );
  }
}
