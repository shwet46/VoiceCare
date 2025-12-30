import 'package:flutter/material.dart';
import 'package:voicecare/utils/constants.dart';

class VoiceCareHeader extends StatelessWidget {
  final String titlePart1;
  final String titlePart2;
  final String subtitle;
  final String fontFamily;

  const VoiceCareHeader({
    super.key,
    this.titlePart1 = 'Voice',
    this.titlePart2 = 'Care',
    this.subtitle = 'Your digital friend, day and night.',
    this.fontFamily = 'GoogleSans',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titlePart1,
              style: TextStyle(
                fontSize: 32,
                color: Constants.primaryOrange,
                fontWeight: FontWeight.w400,
                fontFamily: fontFamily,
              ),
            ),
            Text(
              titlePart2,
              style: TextStyle(
                fontSize: 32,
                color: Constants.darkOrange,
                fontWeight: FontWeight.w400,
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontFamily: fontFamily,
            height: 1,
          ),
        ),
      ],
    );
  }
}
