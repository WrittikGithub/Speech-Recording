import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/completed_task_page/completed_taskpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';

// class BottomNavigationWidget extends StatelessWidget {
//   const BottomNavigationWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<BottomNavigationbarBloc, BottomNavigationbarState>(
//       builder: (context, state) {
//         return BottomNavigationBar(
//           currentIndex: state.currentPageIndex,
//           onTap: (index) {
//             context
//                 .read<BottomNavigationbarBloc>()
//                 .add(NavigateToPageEvent(pageIndex: index));
//           },
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Appcolors.kpurpleColor,
//           selectedItemColor: Appcolors.kwhiteColor,
//           unselectedItemColor: Appcolors.kpurplelightColor,
//           selectedIconTheme: const IconThemeData(color: Appcolors.kwhiteColor),
//           unselectedIconTheme:
//               const IconThemeData(color: Appcolors.kpurplelightColor),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.house_alt),
//               label: 'Dashboard',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.list_bullet_below_rectangle),
//               label: 'Tasks',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.text_bubble),
//               label: 'Reviews',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person_outline),
//               label: 'Profile',
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationbarBloc, BottomNavigationbarState>(
      builder: (context, state) {
        return BottomNavigationBar(
          currentIndex: state.currentPageIndex,
          onTap: (index) {
            // Navigate to the corresponding page
            switch (index) {
              case 0:
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ScreenMainPage()),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ScreenMainPage()),
                  (route) => false,
                );
                break;
                     case 2:
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ScreenMainPage()),
                  (route) => false,
                );
                break;
                     case 3:
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ScreenMainPage()),
                  (route) => false,
                );
                break;
              // Add cases for other pages similarly
            }
            
            // Update the bottom navigation state
            context.read<BottomNavigationbarBloc>().add(
                  NavigateToPageEvent(pageIndex: index),
                );
          },
                    type: BottomNavigationBarType.fixed,
          backgroundColor: Appcolors.kpurpleColor,
          selectedItemColor: Appcolors.kwhiteColor,
          unselectedItemColor: Appcolors.kpurplelightColor,
          selectedIconTheme: const IconThemeData(color: Appcolors.kwhiteColor),
          unselectedIconTheme:
              const IconThemeData(color: Appcolors.kpurplelightColor),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_alt),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet_below_rectangle),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.text_bubble),
              label: 'Reviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          // ... rest of your existing BottomNavigationBar configuration
        );
      },
    );
  }
}
//////////////////
class CompletedTaskWrapper extends StatelessWidget {
  const CompletedTaskWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenCompletedTaskPage(),
      bottomNavigationBar: BottomNavigationWidget(),
    );
  }
}