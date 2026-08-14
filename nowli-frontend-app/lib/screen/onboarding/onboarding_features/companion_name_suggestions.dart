/// Alternative names offered by the ↻ control on the "how would you like to call
/// it?" onboarding step, keyed by the companion's own name (lowercased).
///
/// ⚠️ **PLACEHOLDER COPY — needs sign-off.**
/// The design calls for "5–7 predefined names for that specific character
/// archetype" but does not say what they are, and there is no field for them on
/// the backend (`NowliiPredefinedOption` stores only name / avatar / voice). These
/// are stand-ins so the control works end to end; replace them with the real list
/// when the client supplies it. Changing this map is the whole job — no other file
/// needs to be touched.
///
/// The companion's own name is prepended automatically at read time, so it must
/// NOT be repeated here. Keys must match the names served by
/// `GET /api/nowlii-options/` (currently: milo, knotty, gumo, fizzy, bloop, zee).
///
/// Every entry must satisfy the same limits the typed name does:
/// [kCompanionNameMin]–[kCompanionNameMax] characters.
const Map<String, List<String>> kCompanionNameSuggestions = {
  'milo': ['Miles', 'Momo', 'Milo Jr'],
  'knotty': ['Knot', 'Nots', 'Knotsy'],
  'gumo': ['Gummy', 'Gus', 'Gumdrop'],
  'fizzy': ['Fizz', 'Fizzer', 'Sparks'],
  'bloop': ['Blip', 'Bloopy', 'Bubbles'],
  'zee': ['Zed', 'Zeezee', 'Zip'],
};
