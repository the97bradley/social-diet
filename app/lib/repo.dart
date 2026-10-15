import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class DietRepo {
  DietRepo(this.client);

  final SupabaseClient client;

  String get uid {
    final id = client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not signed in');
    }
    return id;
  }

  Future<Profile?> myProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> updateProfile({
    required String displayName,
    required String bio,
    required int dailyCalorieGoal,
  }) {
    return client.from('profiles').update({
      'display_name': displayName,
      'bio': bio,
      'daily_calorie_goal': dailyCalorieGoal,
    }).eq('id', uid);
  }

  Future<List<FoodLog>> foodForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await client
        .from('food_logs')
        .select()
        .eq('user_id', uid)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at');
    return [for (final row in rows) FoodLog.fromJson(row)];
  }

  Future<void> addFood({
    required String name,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required String mealType,
    bool shareToFeed = false,
  }) async {
    await client.from('food_logs').insert({
      'user_id': uid,
      'name': name,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'meal_type': mealType,
    });
    if (shareToFeed) {
      await addPost(body: 'Logged $name · $calories kcal', kind: 'meal');
    }
  }

  Future<List<Workout>> workoutsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await client
        .from('workouts')
        .select()
        .eq('user_id', uid)
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at');
    return [for (final row in rows) Workout.fromJson(row)];
  }

  Future<void> addWorkout({
    required String title,
    required String category,
    required int durationMinutes,
    required int caloriesBurned,
    String notes = '',
    bool shareToFeed = false,
  }) async {
    await client.from('workouts').insert({
      'user_id': uid,
      'title': title,
      'category': category,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'notes': notes,
    });
    if (shareToFeed) {
      await addPost(
        body: 'Finished $title · ${durationMinutes}m · $caloriesBurned kcal',
        kind: 'workout',
      );
    }
  }

  Future<List<Tracker>> myTrackers() async {
    final rows = await client
        .from('trackers')
        .select('*, tracker_goals(*), tracker_members(*)')
        .order('created_at', ascending: false);
    return [for (final row in rows) Tracker.fromJson(row)];
  }

  Future<Tracker> createTracker({
    required String title,
    required String description,
    required List<TrackerGoal> goals,
  }) async {
    final created = await client.from('trackers').insert({
      'owner_id': uid,
      'title': title,
      'description': description,
    }).select().single();
    final trackerId = created['id'] as String;
    if (goals.isNotEmpty) {
      await client.from('tracker_goals').insert([
        for (var i = 0; i < goals.length; i++) goals[i].toInsert(trackerId),
      ]);
    }
    final row = await client
        .from('trackers')
        .select('*, tracker_goals(*), tracker_members(*)')
        .eq('id', trackerId)
        .single();
    return Tracker.fromJson(row);
  }

  Future<List<TrackerEntry>> entriesForGoals(List<String> goalIds) async {
    if (goalIds.isEmpty) return [];
    final rows = await client.from('tracker_entries').select().inFilter('goal_id', goalIds);
    return [for (final row in rows) TrackerEntry.fromJson(row)];
  }

  Future<void> logGoal({
    required String goalId,
    required double value,
    String note = '',
  }) {
    return client.from('tracker_entries').insert({
      'goal_id': goalId,
      'user_id': uid,
      'value': value,
      'note': note,
    });
  }

  Future<void> shareTracker(String trackerId, String friendId) {
    return client.from('tracker_members').insert({
      'tracker_id': trackerId,
      'user_id': friendId,
      'role': 'member',
      'status': 'active',
    });
  }

  Future<void> leaveTracker(String trackerId) {
    return client.from('tracker_members').delete().eq('tracker_id', trackerId).eq('user_id', uid);
  }

  Future<List<Profile>> searchPeople(String query) async {
    final trimmed = query.trim().replaceAll(RegExp(r'[%_,]'), '');
    if (trimmed.length < 2) return [];
    final rows = await client
        .from('profiles')
        .select()
        .or('username.ilike.%$trimmed%,display_name.ilike.%$trimmed%')
        .neq('id', uid)
        .limit(20);
    return [for (final row in rows) Profile.fromJson(row)];
  }

  Future<List<Friendship>> friendships() async {
    final rows = await client.from('friendships').select();
    return [for (final row in rows) Friendship.fromJson(row)];
  }

  Future<Map<String, Profile>> profilesByIds(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return {};
    final rows = await client.from('profiles').select().inFilter('id', unique);
    return {
      for (final row in rows) row['id'] as String: Profile.fromJson(row),
    };
  }

  Future<void> sendFriendRequest(String addresseeId) {
    return client.from('friendships').insert({
      'requester_id': uid,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> respondToFriend(String friendshipId, String status) {
    return client.from('friendships').update({
      'status': status,
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', friendshipId);
  }

  Future<List<FeedPost>> feed() async {
    final rows = await client
        .from('feed_posts')
        .select('*, feed_likes(user_id), profiles!feed_posts_author_id_fkey(*)')
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final row in rows) FeedPost.fromJson(row, uid)];
  }

  Future<void> addPost({required String body, String kind = 'status'}) {
    return client.from('feed_posts').insert({
      'author_id': uid,
      'body': body,
      'kind': kind,
    });
  }

  Future<void> toggleLike(FeedPost post) async {
    if (post.likedByMe) {
      await client.from('feed_likes').delete().eq('post_id', post.id).eq('user_id', uid);
    } else {
      await client.from('feed_likes').insert({'post_id': post.id, 'user_id': uid});
    }
  }

  Future<String> openConversation(String otherUserId) async {
    final id = await client.rpc('create_direct_conversation', params: {
      'other_user': otherUserId,
    });
    return id as String;
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final rows = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return [for (final row in rows) ChatMessage.fromJson(row)];
  }

  Future<void> sendMessage(String conversationId, String body) {
    return client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'body': body,
    });
  }

  Future<TrelloConnection?> trelloConnection() async {
    final row = await client
        .from('trello_connections')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? null : TrelloConnection.fromJson(row);
  }

  Future<void> saveTrelloConnection({
    required String apiKey,
    required String token,
    required String boardId,
    required String boardName,
  }) {
    return client.from('trello_connections').upsert({
      'user_id': uid,
      'api_key': apiKey,
      'token': token,
      'board_id': boardId,
      'board_name': boardName,
    });
  }

  Future<void> clearTrelloConnection() {
    return client.from('trello_connections').delete().eq('user_id', uid);
  }

  RealtimeChannel watchMessages(
    String conversationId,
    void Function(ChatMessage message) onInsert,
  ) {
    return client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onInsert(ChatMessage.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}
