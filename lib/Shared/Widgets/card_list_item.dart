// lib/common_widgets/app_list_item.dart
import 'package:flutter/material.dart';

/// A highly reusable list item widget with a consistent design (Card, ListTile).
/// It supports a main text, an optional subtitle, and styling based on 'active' status.
class CardListItem extends StatelessWidget {

  const CardListItem({
    super.key, // Using super.key to allow ValueKey or other keys to be passed
    required this.title,
    this.subtitle,
    required this.textColor,
    required this.textFontStyle, // Defaults to true (active)
    this.onTap,
    this.trailing, // Optional trailing widget
    this.margin = const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    this.elevation = 0.5,
    this.borderRadius = 8.0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
  });

  final String title;
  final String? subtitle;
  final Color? textColor;
  final FontStyle textFontStyle;
  final VoidCallback? onTap;
  final Widget? trailing; // e.g., Icon(Icons.arrow_forward_ios)
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;


  @override
  Widget build(BuildContext context) {

    return Card(
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ListTile(
        contentPadding: contentPadding,
        title: Text(title,
          style: TextStyle(
            color: textColor,
            fontStyle: textFontStyle,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null && subtitle!.isNotEmpty ? Text(subtitle!) : null,
        subtitleTextStyle: TextStyle(
          color: textColor,
          fontStyle: textFontStyle,
        ),
        trailing: trailing ?? const Icon( // Default trailing if not provided
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}