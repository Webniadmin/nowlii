/// The one colour code for the four quest zones.
///
/// There were five of these, and only Soft steps agreed across all of them. The same quest
/// was green on Today, and its Power move badge was red on the Quests tab, coral in the
/// suggestions list and lilac on the Soft steps screen — a colour code that means a
/// different thing on each screen is not a code at all.
///
/// The values are the set the Quests tab already shipped, which is also the one two design
/// tokens back up: `#A0E871` is the green of the out-of-sparks card (Figma 1:1008) and
/// `#FF8F26` is `background/bg-secondary`. Stretch zone and Power move are the app's
/// existing values, pending a node-specific Figma reference for the chips.
///
/// Zone names come from the backend as the exact strings below (`Quests.zone`), but the
/// suggestion endpoints have sent them lower-cased, so lookup is case-insensitive.
library;

import 'package:flutter/material.dart';

/// Green — gentle and doable.
const Color kSoftStepsColor = Color(0xFFA0E871);

/// Orange — balanced and steady.
const Color kElevatedColor = Color(0xFFFF8F26);

/// Blue — a bit beyond your comfort.
const Color kStretchZoneColor = Color(0xFF3D87F5);

/// Red — full focus, no distractions.
const Color kPowerMoveColor = Color(0xFFD53D40);

/// The colour for a zone name, falling back to Soft steps for anything unrecognised.
///
/// The fallback is deliberate rather than a hard failure: a zone the app does not know is
/// still a quest the user can see, and the gentlest colour is the safest thing to show
/// against an unknown difficulty.
Color zoneColor(String zone) {
  switch (zone.trim().toLowerCase()) {
    case 'soft steps':
      return kSoftStepsColor;
    case 'elevated':
      return kElevatedColor;
    case 'stretch zone':
      return kStretchZoneColor;
    case 'power move':
      return kPowerMoveColor;
    default:
      return kSoftStepsColor;
  }
}

/// The same colour as a `#RRGGBB` string, for the few places that pass colours as text.
String zoneColorHex(String zone) {
  final value = zoneColor(zone).toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
