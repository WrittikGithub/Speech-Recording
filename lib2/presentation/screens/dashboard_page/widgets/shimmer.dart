// import 'package:flutter/material.dart';
// import 'package:sdcp_new/core/colors.dart';
// import 'package:sdcp_new/core/constants.dart';
// import 'package:sdcp_new/core/responsive_utils.dart';

// class ScreenDashboard extends StatefulWidget {
//   const ScreenDashboard({super.key});

//   @override
//   State<ScreenDashboard> createState() => _HomePageState();
// }

// class _HomePageState extends State<ScreenDashboard> {
//   final ScrollController _scrollController = ScrollController();
//   double _scrollProgress = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_updateScrollProgress);
//   }

//   void _updateScrollProgress() {
//     if (_scrollController.position.maxScrollExtent > 0) {
//       setState(() {
//         _scrollProgress = _scrollController.offset /
//             _scrollController.position.maxScrollExtent;
//       });
//     }
//   }

//   final List<String> titles = ["26", "14", "10", "2"];
//   final List<String> subtitles = [
//     "Tasks",
//     "Completed",
//     "Pending Record Task",
//     "Pending Review Task"
//   ];

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextStyles.subheadline(text: 'My Dashboard'),
//             TextStyles.body(text: 'Welcome Test User')
//           ],
//         ),
//   actions: [
//   PopupMenuButton<String>(
//     onSelected: (value) {
//       // Navigate to the corresponding page based on the selected value
//       switch (value) {
//         case 'Option 1':
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(builder: (context) => NotificationPage()),
//           //);
//           break;
//         case 'Option 2':
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(builder: (context) => ReportPage()),
//           // );
//           break;
//         case 'Option 3':
         
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(builder: (context) => LogoutPage()),
//           // );
//           break;
//       }
//     },
//     itemBuilder: (BuildContext context) {
//       return [
//         const PopupMenuItem<String>(
//           value: 'Option 1',
//           child: Row(
//             children: [
//               Icon(Icons.notifications, color:Appcolors.kblackColor),
//               SizedBox(width: 8),
//               Text('Notification'),
//             ],
//           ),
//         ),
//         const PopupMenuItem<String>(
//           value: 'Option 2',
//           child: Row(
//             children: [
//               Icon(Icons.report, color: Appcolors.kblackColor),
//               SizedBox(width: 8),
//               Text('Report'),
//             ],
//           ),
//         ),
//         const PopupMenuItem<String>(
//           value: 'Option 3',
//           child: Row(
//             children: [
//               Icon(Icons.logout, color:Appcolors.kblackColor),
//               SizedBox(width: 8),
//               Text('Logout'),
//             ],
//           ),
//         ),
//       ];
//     },
//   ),
// ],


//       ),
//       body: Padding(
//         padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
//         child: ListView(
//           children: [
//             ResponsiveSizedBox.height20,
//             GridView.builder(
//               shrinkWrap: true,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 10,
//                 crossAxisSpacing: 14,
//                 childAspectRatio: 1.7,
//               ),
//               itemCount: 4,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () {},
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Appcolors.kpurplelightColor,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Center(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           TextStyles.headline(
//                               text: titles[index],
//                               color: Appcolors.kwhiteColor),
//                           ResponsiveSizedBox.height5,
//                           ResponsiveText(subtitles[index],
//                               weight: FontWeight.bold,
//                               sizeFactor: .85,
//                               color: Appcolors.kwhiteColor)
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'My Progress',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             // Horizontal scrolling containers
//             SizedBox(
//               height: ResponsiveUtils.hp(24),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 scrollDirection: Axis.horizontal,
//                 itemCount: 10,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     margin: const EdgeInsets.only(right: 16),
//                     width: ResponsiveUtils.wp(38),
//                     decoration: BoxDecoration(
//                       color: Appcolors.kskybluecolor,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Stack(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               ResponsiveSizedBox.height30,
//                               Center(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const Icon(Icons.task, size: 50),
//                                     ResponsiveSizedBox.height10,
//                                     TextStyles.body(
//                                         text: 'Task Progress',
//                                         weight: FontWeight.bold),
//                                     ResponsiveSizedBox.height10,
//                                     LinearProgressIndicator(
//                                       value:
//                                           0.5, // Set progress value here (0.0 to 1.0)
//                                       minHeight: 6,
//                                       color: Colors.blue,
//                                       backgroundColor: Colors.grey[300],
//                                     ),
//                                     ResponsiveSizedBox.height10,
//                                     const ResponsiveText(
//                                       'Project Name',
//                                       sizeFactor: .9,
//                                       weight: FontWeight.bold,
//                                     ),
//                                     ResponsiveSizedBox.height5,
//                                     TextStyles.caption(text: 'PKT test'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         // "In Progress" Label in the top-right corner
//                         Positioned(
//                           right: 0,
//                           top: 0,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             decoration: const BoxDecoration(
//                               color: Appcolors.korangeColor,
//                               borderRadius: BorderRadius.only(
//                                   topRight: Radius.circular(10),
//                                   bottomLeft: Radius.circular(5)),
//                             ),
//                             child: const ResponsiveText(
//                               'In-Progress',
//                               sizeFactor: .7,
//                               color: Appcolors.kwhiteColor,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             ResponsiveSizedBox.height20,
//             LinearProgressIndicator(
//               minHeight: 6,
//               value: _scrollProgress,
//               backgroundColor: Colors.grey[200],
//               valueColor: const AlwaysStoppedAnimation<Color>(
//                   Appcolors.kpurplelightColor),
//             ),
//             Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.alarm,
//                   size: 40,
//                   color: Appcolors.korangeColor,
//                 ),
//                 ResponsiveSizedBox.height10,
//                 TextStyles.subheadline(text: 'Hurry up!'),
//                 ResponsiveSizedBox.height5,
//                 const Text(
//                   'Please complete the remaining\n12 pending tasks',
//                   textAlign:
//                       TextAlign.center, 
//                   style: TextStyle(fontSize: 16, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
