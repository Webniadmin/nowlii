import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/utils/mood_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every icon the lookup can name is actually in the bundle', () async {
    // The lookup builds paths by string, so a renamed or unregistered file fails only
    // at runtime, and quietly — the card falls back to the old fixed smiley.
    const all = [
      'sad',
      'happy',
      'awesome',
      'peaceful',
      'angry',
      'anxious',
      'tired',
      'empty',
      'joyful',
    ];
    for (final name in all) {
      final bytes = await rootBundle.load('assets/mood_icons/$name.svg');
      expect(bytes.lengthInBytes, greaterThan(0), reason: '$name.svg is empty');
    }
  });

  test('the five categories a call summary can carry all resolve', () {
    // `_TOP_EMOTIONS` in nowli-ai — this is what `dominant_emotion` holds.
    const fromBackend = {
      'happy': 'happy',
      'motivated': 'awesome',
      'angry': 'angry',
      'tired': 'tired',
      'sad': 'sad',
    };
    fromBackend.forEach((category, icon) {
      expect(moodIconAsset(category: category), 'assets/mood_icons/$icon.svg');
    });
  });

  test('the analytics buckets resolve too', () {
    // `_EMOTION_BUCKETS` — a different vocabulary from the same service.
    expect(moodIconAsset(category: 'anxious'), 'assets/mood_icons/anxious.svg');
    expect(moodIconAsset(category: 'confused'), 'assets/mood_icons/anxious.svg');
    expect(moodIconAsset(category: 'neutral'), 'assets/mood_icons/peaceful.svg');
  });

  test('a free-text mood sentence is read when there is no category', () {
    expect(
      moodIconAsset(text: 'You sounded pretty drained by the end of the day.'),
      'assets/mood_icons/tired.svg',
    );
    expect(
      moodIconAsset(text: 'A bit overwhelmed, but you pushed through.'),
      'assets/mood_icons/anxious.svg',
    );
    expect(
      moodIconAsset(text: 'Calm and settled today.'),
      'assets/mood_icons/peaceful.svg',
    );
  });

  test('the sentence wins over the category', () {
    // nowli-ai reports `happy: 100.0` when it has no emotion scores at all, which is what
    // a silent or very short call produces — so the bucket says "happy" for a call it
    // could not read, while the sentence it wrote says otherwise. Seen on a real call:
    // "You sounded pretty neutral throughout our chat" under a beaming face.
    expect(
      moodIconAsset(
        category: 'happy',
        text: 'You sounded pretty neutral throughout our chat.',
      ),
      'assets/mood_icons/peaceful.svg',
    );
  });

  test('the category is still the backstop when there is no sentence', () {
    expect(moodIconAsset(category: 'sad', text: ''),
        'assets/mood_icons/sad.svg');
    expect(moodIconAsset(category: 'tired', text: 'mmmhmm'),
        'assets/mood_icons/tired.svg');
  });

  test('a negation is not read as the word inside it', () {
    // "not happy" contains "happy"; ordering in the keyword table is what stops it
    // returning a grin for a bad day.
    expect(moodIconAsset(text: 'Not happy with how today went.'),
        'assets/mood_icons/sad.svg');
  });

  test('an unreadable mood returns null rather than a cheerful default', () {
    // The card then keeps its neutral fallback. Guessing "happy" for a call the model
    // could not read is the one wrong answer here.
    expect(moodIconAsset(), isNull);
    expect(moodIconAsset(category: '', text: '   '), isNull);
    expect(moodIconAsset(text: 'zzzz qqqq'), isNull);
  });
}
