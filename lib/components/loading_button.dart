import 'package:flutter/material.dart';

import '../theme/theme.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: TextButton(
        style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0)),
            textStyle: whiteTextStyle.copyWith(fontWeight: bold)),
        onPressed: (){},
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kWhiteColor,
                    valueColor: AlwaysStoppedAnimation(tPrimaryColor),
                  )
              ),
              SizedBox(width: 4,),
              Text("Loading"),
            ],
          ),
        ),
      ),
    );
  }
}
