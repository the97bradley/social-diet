class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.dailyCalorieGoal,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final int dailyCalorieGoal;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      dailyCalorieGoal: (json['daily_calorie_goal'] as num?)?.toInt() ?? 2000,
    );
  }

  String get initials {
    final source = displayName.isNotEmpty ? displayName : username;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String,
    );
  }

  String otherId(String me) => requesterId == me ? addresseeId : requesterId;
}

class FoodLog {
  const FoodLog({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealType,
    required this.loggedAt,
  });

  final String id;
  final String userId;
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String mealType;
  final DateTime loggedAt;

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      mealType: json['meal_type'] as String? ?? 'snack',
      loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
    );
  }
}

class Workout {
  const Workout({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.loggedAt,
    this.notes = '',
  });

  final String id;
  final String userId;
  final String title;
  final String category;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime loggedAt;
  final String notes;

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'other',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toInt() ?? 0,
      loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class TrackerGoal {
  const TrackerGoal({
    required this.id,
    required this.trackerId,
    required this.title,
    required this.category,
    required this.kind,
    required this.targetValue,
    required this.targetUnit,
    required this.period,
    required this.sortOrder,
  });

  final String id;
  final String trackerId;
  final String title;
  final String category;
  final String kind;
  final double targetValue;
  final String targetUnit;
  final String period;
  final int sortOrder;

  factory TrackerGoal.fromJson(Map<String, dynamic> json) {
    return TrackerGoal(
      id: json['id'] as String? ?? '',
      trackerId: json['tracker_id'] as String? ?? '',
      title: json['title'] as String,
      category: json['category'] as String? ?? 'custom',
      kind: json['kind'] as String? ?? 'count',
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 1,
      targetUnit: json['target_unit'] as String? ?? 'times',
      period: json['period'] as String? ?? 'week',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsert(String trackerId) {
    return {
      'tracker_id': trackerId,
      'title': title,
      'category': category,
      'kind': kind,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'period': period,
      'sort_order': sortOrder,
    };
  }
}

class TrackerMember {
  const TrackerMember({
    required this.trackerId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String trackerId;
  final String userId;
  final String role;
  final String status;

  factory TrackerMember.fromJson(Map<String, dynamic> json) {
    return TrackerMember(
      trackerId: json['tracker_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class TrackerEntry {
  const TrackerEntry({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.loggedOn,
    required this.value,
    this.note = '',
  });

  final String id;
  final String goalId;
  final String userId;
  final DateTime loggedOn;
  final double value;
  final String note;

  factory TrackerEntry.fromJson(Map<String, dynamic> json) {
    return TrackerEntry(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      loggedOn: DateTime.parse(json['logged_on'] as String),
      value: (json['value'] as num?)?.toDouble() ?? 1,
      note: json['note'] as String? ?? '',
    );
  }
}

class Tracker {
  const Tracker({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.goals,
    required this.members,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String icon;
  final String color;
  final List<TrackerGoal> goals;
  final List<TrackerMember> members;

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'flag',
      color: json['color'] as String? ?? 'lime',
      goals: [
        for (final row in (json['tracker_goals'] as List<dynamic>? ?? []))
          TrackerGoal.fromJson(Map<String, dynamic>.from(row as Map)),
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      members: [
        for (final row in (json['tracker_members'] as List<dynamic>? ?? []))
          TrackerMember.fromJson(Map<String, dynamic>.from(row as Map)),
      ],
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.body,
    required this.kind,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
    this.author,
  });

  final String id;
  final String authorId;
  final String body;
  final String kind;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;
  final Profile? author;

  factory FeedPost.fromJson(Map<String, dynamic> json, String myId) {
    final likes = (json['feed_likes'] as List<dynamic>? ?? []);
    return FeedPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      body: json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? 'status',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      likeCount: likes.length,
      likedByMe: likes.any((like) => like['user_id'] == myId),
      author: json['profiles'] is Map
          ? Profile.fromJson(Map<String, dynamic>.from(json['profiles'] as Map))
          : null,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class GoalDraft {
  GoalDraft({
    required this.title,
    this.category = 'custom',
    this.kind = 'count',
    this.targetValue = 1,
    this.targetUnit = 'times',
    this.period = 'week',
  });

  String title;
  String category;
  String kind;
  double targetValue;
  String targetUnit;
  String period;

  TrackerGoal toGoal(int sortOrder) {
    return TrackerGoal(
      id: '',
      trackerId: '',
      title: title,
      category: category,
      kind: kind,
      targetValue: targetValue,
      targetUnit: targetUnit,
      period: period,
      sortOrder: sortOrder,
    );
  }
}
