/// The face shown against a detected mood, in one place.
///
/// Nine icons ship in `assets/mood_icons/`. What has to reach them is messier than nine
/// words: `nowli-ai` has **two** vocabularies — `_TOP_EMOTIONS`
/// (`happy, motivated, angry, tired, sad`), which is what a call summary's
/// `dominant_emotion` carries, and `_EMOTION_BUCKETS`
/// (`happy, sad, angry, anxious, confused, neutral`) used by the analytics endpoints —
/// and the summary's own `mood_detected` is a free-text sentence written by the model.
///
/// So the lookup takes the category when there is one and otherwise reads the sentence,
/// and it is deliberately generous with synonyms: an unmapped mood used to be invisible
/// (every call showed the same `Icons.mood`), and the cost of a near-miss is a slightly
/// wrong face, not a broken screen.
library;

const String _dir = 'assets/mood_icons';

/// Longest keys first — `overwhelmed` must not be decided by `whelm`, and `not happy`
/// must not match `happy`. Order is load-bearing; keep the negations at the top.
const List<(String, String)> _keywords = [
  // Negations, before the words they contain.
  ('not great', 'sad'),
  ('not happy', 'sad'),
  ('less tired', 'peaceful'),

  ('overwhelm', 'anxious'),
  ('frustrat', 'angry'),
  ('irritat', 'angry'),
  ('annoy', 'angry'),
  ('anger', 'angry'),
  ('angry', 'angry'),
  ('mad', 'angry'),

  ('anxious', 'anxious'),
  ('anxiety', 'anxious'),
  ('nervous', 'anxious'),
  ('worried', 'anxious'),
  ('worry', 'anxious'),
  ('stress', 'anxious'),
  ('tense', 'anxious'),
  ('afraid', 'anxious'),
  ('scared', 'anxious'),
  ('fear', 'anxious'),
  ('panic', 'anxious'),
  ('confus', 'anxious'),
  ('uncertain', 'anxious'),

  ('exhaust', 'tired'),
  ('drained', 'tired'),
  ('sleepy', 'tired'),
  ('weary', 'tired'),
  ('tired', 'tired'),
  ('fatigue', 'tired'),
  ('low energy', 'tired'),

  ('numb', 'empty'),
  ('empty', 'empty'),
  ('hollow', 'empty'),
  ('flat', 'empty'),
  ('blank', 'empty'),
  ('nothing', 'empty'),
  ('disconnect', 'empty'),

  ('heartbroken', 'sad'),
  ('lonely', 'sad'),
  ('down', 'sad'),
  ('sad', 'sad'),
  ('unhappy', 'sad'),
  ('upset', 'sad'),
  ('grief', 'sad'),
  ('disappoint', 'sad'),
  ('discourag', 'sad'),
  ('blue', 'sad'),

  ('motivat', 'awesome'),
  ('determin', 'awesome'),
  ('inspir', 'awesome'),
  ('focused', 'awesome'),
  ('driven', 'awesome'),
  ('proud', 'awesome'),
  ('accomplish', 'awesome'),
  ('confident', 'awesome'),
  ('hopeful', 'awesome'),
  ('ready', 'awesome'),

  ('excited', 'joyful'),
  ('excite', 'joyful'),
  ('joy', 'joyful'),
  ('delight', 'joyful'),
  ('thrill', 'joyful'),
  ('energetic', 'joyful'),
  ('playful', 'joyful'),
  ('cheerful', 'joyful'),

  ('peaceful', 'peaceful'),
  ('peace', 'peaceful'),
  ('calm', 'peaceful'),
  ('relax', 'peaceful'),
  ('content', 'peaceful'),
  ('grateful', 'peaceful'),
  ('settled', 'peaceful'),
  ('steady', 'peaceful'),
  ('neutral', 'peaceful'),
  ('okay', 'peaceful'),
  ('fine', 'peaceful'),

  ('happy', 'happy'),
  ('happi', 'happy'),
  ('good', 'happy'),
  ('great', 'happy'),
  ('positive', 'happy'),
  ('light', 'happy'),
  ('better', 'happy'),
  ('smil', 'happy'),
];

/// Asset path for a mood, or null when neither input says anything recognisable —
/// the caller decides what a blank mood looks like rather than being handed a
/// cheerful face for a call the model could not read.
///
/// [text] is the free-text `mood_detected`; [category] is the `dominant_emotion` bucket.
///
/// **The sentence is read first, and that is deliberate.** `dominant_emotion` looks like
/// the more reliable input — it is a classification — but `nowli-ai` falls back to
/// `happy: 100.0` whenever it has no emotion scores at all (`test17.py`, the
/// `_te_total > 0` branch), which is exactly what a short or silent call produces. Trust
/// it first and every unreadable call gets a grin, while `mood_detected` for the same
/// call reads "you sounded pretty neutral". Observed on a real call, not theorised: the
/// summary said neutral and the face beamed. The sentence is what the model actually
/// wrote about *this* conversation, so it decides; the bucket is the backstop.
String? moodIconAsset({String? category, String? text}) {
  for (final source in [text, category]) {
    if (source == null) continue;
    final needle = source.toLowerCase();
    if (needle.trim().isEmpty) continue;
    for (final (key, icon) in _keywords) {
      if (needle.contains(key)) return '$_dir/$icon.svg';
    }
  }
  return null;
}
