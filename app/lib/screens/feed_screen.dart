import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _composer = TextEditingController();
  List<FeedPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _posts = await SessionScope.of(context).repo.feed();
    } catch (error) {
      if (mounted) await showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final body = _composer.text.trim();
    if (body.isEmpty) return;
    try {
      await SessionScope.of(context).repo.addPost(body: body);
      _composer.clear();
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _like(FeedPost post) async {
    try {
      await SessionScope.of(context).repo.toggleLike(post);
      await _load();
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  PulseCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _composer,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'How did the day go?',
                            filled: false,
                            border: InputBorder.none,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(onPressed: _post, child: const Text('Post')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_posts.isEmpty)
                    const EmptyHint('Your posts and your friends’ posts show up here.'),
                  for (final post in _posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PulseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AvatarMark(initials: post.author?.initials ?? 'SD'),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.author?.displayName ?? 'Friend'),
                                      Text(
                                        '${post.kind} · ${DateFormat.MMMd().add_jm().format(post.createdAt)}',
                                        style: const TextStyle(color: PulseTheme.mist, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(post.body, style: const TextStyle(height: 1.4)),
                            TextButton.icon(
                              onPressed: () => _like(post),
                              icon: Icon(
                                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                                color: post.likedByMe ? PulseTheme.clay : PulseTheme.mist,
                              ),
                              label: Text('${post.likeCount}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
