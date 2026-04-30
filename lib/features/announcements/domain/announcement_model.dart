enum AnnouncementStatus { pending, approved, rejected }

extension AnnouncementStatusX on AnnouncementStatus {
  String get wire => name;
  static AnnouncementStatus fromWire(String? v) =>
      AnnouncementStatus.values.firstWhere((e) => e.wire == v,
          orElse: () => AnnouncementStatus.pending);
}

class AnnouncementAuthor {
  AnnouncementAuthor({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });
  final String id;
  final String? displayName;
  final String? avatarUrl;

  factory AnnouncementAuthor.fromJson(Map<String, dynamic> json) =>
      AnnouncementAuthor(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class AnnouncementAttachment {
  AnnouncementAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });
  final String id;
  final String fileUrl;
  final String fileName;
  final String fileType;

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) =>
      AnnouncementAttachment(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        fileName: json['file_name'] as String,
        fileType: json['file_type'] as String,
      );
}

class AnnouncementReaction {
  AnnouncementReaction({
    required this.emoji,
    required this.count,
    required this.mine,
  });
  final String emoji;
  final int count;
  final bool mine;
}

class PollOption {
  PollOption({
    required this.id,
    required this.text,
    required this.votes,
    required this.orderIndex,
  });
  final String id;
  final String text;
  final int votes;
  final int orderIndex;
}

class Poll {
  Poll({
    required this.id,
    required this.question,
    required this.options,
    this.isClosed = false,
    this.myVoteOptionId,
  });
  final String id;
  final String question;
  final List<PollOption> options;
  final bool isClosed;
  final String? myVoteOptionId;

  bool get hasVoted => myVoteOptionId != null;
  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);
}

class Announcement {
  Announcement({
    required this.id,
    required this.groupId,
    required this.content,
    required this.status,
    this.author,
    this.rejectNote,
    this.createdAt,
    this.approvedAt,
    this.attachments = const [],
    this.reactions = const [],
    this.poll,
    this.groupName,
  });

  final String id;
  final String groupId;
  final String content;
  final AnnouncementStatus status;
  final AnnouncementAuthor? author;
  final String? rejectNote;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final List<AnnouncementAttachment> attachments;
  final List<AnnouncementReaction> reactions;
  final Poll? poll;
  final String? groupName;

  factory Announcement.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final authorRaw = json['users'];
    final attRaw = json['announcement_attachments'] as List?;
    final reactRaw = json['announcement_reactions'] as List?;
    final pollRaw = json['polls'];
    final groupRaw = json['groups'] as Map?;

    final reactions = <String, List<Map>>{};
    for (final r in (reactRaw ?? [])) {
      final m = Map<String, dynamic>.from(r as Map);
      final e = m['emoji'] as String;
      reactions.putIfAbsent(e, () => []).add(m);
    }
    final reactionSummary = reactions.entries
        .map((e) => AnnouncementReaction(
              emoji: e.key,
              count: e.value.length,
              mine: currentUserId != null &&
                  e.value.any((m) => m['user_id'] == currentUserId),
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    Poll? poll;
    var currentPollRaw = pollRaw;
    if (currentPollRaw is List && currentPollRaw.isNotEmpty) {
      currentPollRaw = currentPollRaw.first;
    }
    if (currentPollRaw is Map) {
      final p = Map<String, dynamic>.from(currentPollRaw);
      final optsRaw = (p['poll_options'] as List?) ?? [];
      final votesRaw = (p['poll_votes'] as List?) ?? [];
      final voteCounts = <String, int>{};
      String? myOpt;
      for (final v in votesRaw) {
        final vm = Map<String, dynamic>.from(v as Map);
        final oid = vm['option_id'] as String;
        voteCounts[oid] = (voteCounts[oid] ?? 0) + 1;
        if (currentUserId != null && vm['user_id'] == currentUserId) {
          myOpt = oid;
        }
      }
      final opts = optsRaw.map((o) {
        final om = Map<String, dynamic>.from(o as Map);
        final id = om['id'] as String;
        return PollOption(
          id: id,
          text: om['option_text'] as String,
          votes: voteCounts[id] ?? 0,
          orderIndex: (om['order_index'] as int?) ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      poll = Poll(
        id: p['id'] as String,
        question: p['question'] as String,
        options: opts,
        isClosed: (p['is_closed'] as bool?) ?? false,
        myVoteOptionId: myOpt,
      );
    }

    return Announcement(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      content: json['content'] as String,
      status: AnnouncementStatusX.fromWire(json['status'] as String?),
      author: authorRaw is Map
          ? AnnouncementAuthor.fromJson(Map<String, dynamic>.from(authorRaw))
          : null,
      rejectNote: json['reject_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      attachments: (attRaw ?? [])
          .map((e) => AnnouncementAttachment.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      reactions: reactionSummary,
      poll: poll,
      groupName: groupRaw?['name'] as String?,
    );
  }
}

class CreateAnnouncementInput {
  CreateAnnouncementInput({
    required this.groupId,
    required this.content,
    this.pollQuestion,
    this.pollOptions = const [],
  });
  final String groupId;
  final String? content;
  final String? pollQuestion;
  final List<String> pollOptions;

  bool get hasPoll =>
      pollQuestion != null &&
      pollQuestion!.trim().isNotEmpty &&
      pollOptions.where((o) => o.trim().isNotEmpty).length >= 2;
}
