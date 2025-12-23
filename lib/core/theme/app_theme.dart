
// // lib/theme/app_theme.dart

// import 'package:flutter/material.dart';

// /// AppTheme defines the global theme for the application.
// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primaryColor: Colors.blue,
//     scaffoldBackgroundColor: Colors.white,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.blue,
//       elevation: 0,
//       iconTheme: IconThemeData(color: Colors.white),
//     ),
//     textTheme: const TextTheme(
//       headline1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
//       bodyText1: TextStyle(fontSize: 16, color: Colors.black87),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         primary: Colors.blue,
//         onPrimary: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: Colors.blue),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: const BorderSide(color: Colors.blue, width: 2),
//       ),
//       labelStyle: const TextStyle(color: Colors.blue),
//     ),
//   );

//   static final ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primaryColor: Colors.blue[700],
//     scaffoldBackgroundColor: Colors.grey[900],
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.grey[800],
//       elevation: 0,
//       iconTheme: const IconThemeData(color: Colors.white),
//     ),
//     textTheme: const TextTheme(
//       headline1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//       bodyText1: TextStyle(fontSize: 16, color: Colors.white70),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         primary: Colors.blue[700],
//         onPrimary: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.blue[700]!),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
//       ),
//       labelStyle: TextStyle(color: Colors.blue[700]),
//     ),
//   );
// }
