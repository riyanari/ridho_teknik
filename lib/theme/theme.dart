import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

double defaultMargin = 18.0;
double defaultRadius = 10.0;

// const Color kPrimaryColor = Color(0xff2B7C79);
const Color kPrimaryColor = Color(0xFF4851A5); // Biru keunguan - warna utama
const Color kSecondaryColor = Color(0xFFEE9B00); // Oranye lembut hangat, kontras elegan
const Color kGreyColor = Color(0xFFBEBEBE); // Abu netral, lembut
const Color kBackgroundPrimaryColor = Color(0xFF1E1E2F); // Gelap keunguan untuk mode dark
const Color kBackgroundColor = Color(0xFFF5F6FA); // Abu terang untuk mode terang
const Color kWhiteColor = Color(0xFFFFFFFF); // Putih bersih

// --- Warna untuk Box/Menu/Accent ---
const Color kBoxGreyColor = Color(0xFF6D6D6D);
const Color kBoxMenuGreenColor = Color(0xFF1B998B); // Hijau teal segar
const Color kBoxMenuOrangeColor = Color(0xFFEE9B00); // Oranye hangat, cocok dengan sekunder
const Color kBoxMenuRedColor = Color(0xFFD1495B); // Tetap bagus untuk error
const Color kBoxMenuBlackColor = Color(0xFF2B2B2B);
const Color kBoxMenuCoklatColor = Color(0xFFAD6B00); // Aksen hangat natural
const Color kBoxMenuLightBlueColor = Color(0xFF3A86FF); // Biru cerah untuk aksen sekunder
const Color kBoxMenuDarkBlueColor = Color(0xFF2E3A7A); // Biru gelap harmonis dengan primary

// --- Warna tambahan tema teks ---
const Color tPrimaryColor = Color(0xFF1E1E2F);
const Color tDarkGreenColor = Color(0xFF006D77);
const Color tSecondaryColor = Color(0xFFEE9B00);
const Color tWhiteColor = Color(0xFFFFFFFF);
const Color tErrorColor = Color(0xFFD1495B);


TextStyle primaryTextStyle = GoogleFonts.poppins(
    color:tPrimaryColor
);

TextStyle errorTextStyle = GoogleFonts.poppins(
    color:tErrorColor
);

TextStyle secondaryTextStyle = GoogleFonts.poppins(
    color:kSecondaryColor
);

TextStyle titleTextStyle = GoogleFonts.sairaStencilOne(
  color: tPrimaryColor
);

TextStyle titleWhiteTextStyle = GoogleFonts.sairaStencilOne(
    color: kWhiteColor
);
TextStyle whiteTextStyle = GoogleFonts.poppins(
    color: kWhiteColor
);

TextStyle darkGreenTextStyle = GoogleFonts.poppins(
    color: tDarkGreenColor
);

TextStyle greyTextStyle = GoogleFonts.poppins(
    color: kGreyColor
);

TextStyle orangeTextStyle = GoogleFonts.poppins(
    color: kBoxMenuOrangeColor
);

TextStyle blackTextStyle = GoogleFonts.poppins(
    color: kBoxMenuBlackColor
);

FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semiBold = FontWeight.w600;
FontWeight bold = FontWeight.w700;
FontWeight extraBold = FontWeight.w800;
FontWeight black = FontWeight.w900;