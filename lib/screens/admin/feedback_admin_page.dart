import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_state.dart';
import '../../services/feedback_service.dart';

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  State<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends State<FeedbackAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('FEEDBACK')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FEEDBACK',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'NOTED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedbackList(
            stream: _feedbackService.getPendingFeedback(),
            showNotedButton: true,
            feedbackService: _feedbackService,
          ),
          _FeedbackList(
            stream: _feedbackService.getNotedFeedback(),
            showNotedButton: false,
            feedbackService: _feedbackService,
          ),
        ],
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final bool showNotedButton;
  final FeedbackService feedbackService;

  const _FeedbackList({
    required this.stream,
    required this.showNotedButton,
    required this.feedbackService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              showNotedButton ? 'No pending feedback' : 'No noted feedback',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final feedbackDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: feedbackDocs.length,
          itemBuilder: (context, index) {
            final doc = feedbackDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final email = data['email'] as String? ?? 'Unknown';
            final text = data['text'] as String? ?? '';
            final createdAt = data['createdAt'] as Timestamp?;

            return _FeedbackItem(
              email: email,
              text: text,
              createdAt: createdAt,
              showNotedButton: showNotedButton,
              feedbackService: feedbackService,
              feedbackId: doc.id,
            );
          },
        );
      },
    );
  }
}

class _FeedbackItem extends StatefulWidget {
  final String email;
  final String text;
  final Timestamp? createdAt;
  final bool showNotedButton;
  final FeedbackService feedbackService;
  final String feedbackId;

  const _FeedbackItem({
    required this.email,
    required this.text,
    required this.createdAt,
    required this.showNotedButton,
    required this.feedbackService,
    required this.feedbackId,
  });

  @override
  State<_FeedbackItem> createState() => _FeedbackItemState();
}

class _FeedbackItemState extends State<_FeedbackItem> {
  bool _isExpanded = false;
  static const int _maxLines = 1;

  @override
  Widget build(BuildContext context) {
    final isLongText = widget.text.split('\n').length > _maxLines;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.email.isNotEmpty
                        ? widget.email[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.createdAt != null)
                      Text(
                        _formatDate(widget.createdAt!.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLongText && !_isExpanded)
            Stack(
              children: [
                Text(
                  widget.text.split('\n').take(_maxLines).join('\n'),
                  style: const TextStyle(fontSize: 14),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(widget.text, style: const TextStyle(fontSize: 14)),
          if (isLongText) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isExpanded ? 'Show less' : 'Show all',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (widget.showNotedButton) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () async {
                  await widget.feedbackService.markAsNoted(widget.feedbackId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked as noted'),
                        backgroundColor: Colors.black,
                      ),
                    );
                  }
                },
                child: const Text('NOTED'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
