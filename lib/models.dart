import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Word {
  final String id;
  final String word;
  final String translation;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? exampleSent;
  final String? tags;
  final int masteryLevel;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  Word({
    String? id,
    required this.word,
    required this.translation,
    this.pronunciation,
    this.partOfSpeech,
    this.exampleSent,
    this.tags,
    this.masteryLevel = 0,
    int? createdAt,
    int? updatedAt,
    this.deleted = false,
  })  : id = id ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'word': word,
        'translation': translation,
        'pronunciation': pronunciation,
        'part_of_speech': partOfSpeech,
        'example_sent': exampleSent,
        'tags': tags,
        'mastery_level': masteryLevel,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted': deleted ? 1 : 0,
      };

  factory Word.fromMap(Map<String, dynamic> map) => Word(
        id: map['id'] as String,
        word: map['word'] as String,
        translation: map['translation'] as String,
        pronunciation: map['pronunciation'] as String?,
        partOfSpeech: map['part_of_speech'] as String?,
        exampleSent: map['example_sent'] as String?,
        tags: map['tags'] as String?,
        masteryLevel: map['mastery_level'] as int,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
        deleted: (map['deleted'] as int) == 1,
      );

  Word copyWith({
    String? word,
    String? translation,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSent,
    String? tags,
    int? masteryLevel,
    bool? deleted,
  }) =>
      Word(
        id: id,
        word: word ?? this.word,
        translation: translation ?? this.translation,
        pronunciation: pronunciation ?? this.pronunciation,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        exampleSent: exampleSent ?? this.exampleSent,
        tags: tags ?? this.tags,
        masteryLevel: masteryLevel ?? this.masteryLevel,
        createdAt: createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deleted: deleted ?? this.deleted,
      );
}

class ReviewRecord {
  final String id;
  final String wordId;
  final int reviewedAt;
  final int result; // 0=忘记 1=模糊 2=记得
  final int nextReview;
  final int repetition;
  final double efactor;
  final int createdAt;

  ReviewRecord({
    String? id,
    required this.wordId,
    int? reviewedAt,
    required this.result,
    required this.nextReview,
    this.repetition = 0,
    this.efactor = 2.5,
    int? createdAt,
  })  : id = id ?? uuid.v4(),
        reviewedAt = reviewedAt ?? DateTime.now().millisecondsSinceEpoch,
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'word_id': wordId,
        'reviewed_at': reviewedAt,
        'result': result,
        'next_review': nextReview,
        'repetition': repetition,
        'efactor': efactor,
        'created_at': createdAt,
      };

  factory ReviewRecord.fromMap(Map<String, dynamic> map) => ReviewRecord(
        id: map['id'] as String,
        wordId: map['word_id'] as String,
        reviewedAt: map['reviewed_at'] as int,
        result: map['result'] as int,
        nextReview: map['next_review'] as int,
        repetition: map['repetition'] as int,
        efactor: (map['efactor'] as num).toDouble(),
        createdAt: map['created_at'] as int,
      );
}
