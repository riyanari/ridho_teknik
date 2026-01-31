// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// === Spacing & Radius ===
double defaultMargin = 18.0;
double defaultRadius = 12.0;
double cardRadius = 16.0;
double buttonRadius = 12.0;

// === Color Palette ===
const Color kPrimaryColor = Color(0xFF4851A5);
const Color kSecondaryColor = Color(0xFFEE9B00);
const Color kGreyColor = Color(0xFFBEBEBE);
const Color kBackgroundColor = Color(0xFFF5F6FA);
const Color kWhiteColor = Color(0xFFFFFFFF);
const Color kBoxMenuGreenColor = Color(0xFF1B998B);
const Color kBoxMenuOrangeColor = Color(0xFFEE9B00);
const Color kBoxMenuRedColor = Color(0xFFD1495B);
const Color kBoxMenuBlackColor = Color(0xFF2B2B2B);
const Color kBoxMenuCoklatColor = Color(0xFFAD6B00);
const Color kBoxMenuLightBlueColor = Color(0xFF3A86FF);
const Color kBoxMenuDarkBlueColor = Color(0xFF2E3A7A);
const Color tPrimaryColor = Color(0xFF1E1E2F);
const Color tDarkGreenColor = Color(0xFF006D77);
const Color tErrorColor = Color(0xFFD1495B);

// === Text Styles ===
TextStyle primaryTextStyle = GoogleFonts.poppins(color: tPrimaryColor);
TextStyle secondaryTextStyle = GoogleFonts.poppins(color: kSecondaryColor);
TextStyle whiteTextStyle = GoogleFonts.poppins(color: kWhiteColor);
TextStyle greyTextStyle = GoogleFonts.poppins(color: kGreyColor);
TextStyle darkGreenTextStyle = GoogleFonts.poppins(color: tDarkGreenColor);
TextStyle errorTextStyle = GoogleFonts.poppins(color: tErrorColor);
TextStyle orangeTextStyle = GoogleFonts.poppins(color: kBoxMenuOrangeColor);
TextStyle blackTextStyle = GoogleFonts.poppins(color: kBoxMenuBlackColor);

TextStyle titleTextStyle = GoogleFonts.sairaStencilOne(color: tPrimaryColor);
TextStyle titleWhiteTextStyle = GoogleFonts.sairaStencilOne(color: kWhiteColor);

// === Font Weights ===
FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semiBold = FontWeight.w600;
FontWeight bold = FontWeight.w700;