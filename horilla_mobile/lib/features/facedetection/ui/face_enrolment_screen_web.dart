import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_top_bar.dart';

class FaceEnrolmentScreen extends StatelessWidget {
  const FaceEnrolmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Face ID enrolment', onBack: () => context.pop()),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpace.screen),
                child: Text(
                  'Face ID enrolment is not available on web.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
