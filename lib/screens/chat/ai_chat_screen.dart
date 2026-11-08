import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/modern_background.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_coach_response.dart';
import '../../services/ai_coach_context_service.dart';
import '../../services/ai_coach_service.dart';
import '../../utils/navigation_helper.dart';
import '../exercises/exercise_detail_screen.dart';
import '../workouts/daily_workout_tracker_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.initialMessage});

  /// Açılışta otomatik gönderilecek hazır mesaj (ör. ana sayfa hızlı buton).
  final String? initialMessage;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _coachService = AiCoachService();
  final _contextService = AiCoachContextService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<AiChatMessage> _messages = [];
  List<String> _suggestionChips = [];
  List<String> _followUpChips = [];
  List<AiCoachAction> _followUpActions = [];
  AiCoachWorkoutAction _workoutAction = const AiCoachWorkoutAction();
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  bool _isLoadingSuggestions = true;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _userBubble = const Color(0xFF1A3A5C);
  final Color _aiBubble = const Color(0xFF1B2438);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final contextFuture = _loadInitialContext();
    await _loadHistory();

    final preset = widget.initialMessage?.trim();
    if (preset != null && preset.isNotEmpty && mounted) {
      await _sendMessage(preset);
    }

    await contextFuture;
  }

  Future<void> _loadInitialContext() async {
    try {
      final results = await Future.wait([
        _contextService.buildPersonalizedSuggestions(),
        _contextService.getWorkoutAction(),
      ]);

      if (mounted) {
        setState(() {
          _suggestionChips = results[0] as List<String>;
          _workoutAction = results[1] as AiCoachWorkoutAction;
          _isLoadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _coachService.getChatHistory();
      if (!mounted) return;

      final messages = history.where((m) => !m.isSystem).toList();
      setState(() {
        _messages = messages;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
      await _refreshFollowUpsFromHistory(messages);
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _refreshFollowUpsFromHistory(List<AiChatMessage> messages) async {
    if (messages.isEmpty || !messages.last.isAssistant) return;

    final lastAssistant = messages.last;
    if (lastAssistant.content.startsWith('⚠️')) return;

    AiChatMessage? lastUser;
    for (var i = messages.length - 2; i >= 0; i--) {
      if (messages[i].isUser) {
        lastUser = messages[i];
        break;
      }
    }
    if (lastUser == null) return;

    final apiSuggestions = lastAssistant.followUpSuggestions;
    final apiActions = lastAssistant.coachActions;

    if (apiSuggestions.isNotEmpty || apiActions.isNotEmpty) {
      if (mounted) {
        setState(() {
          _followUpChips = apiSuggestions;
          _followUpActions = apiActions;
        });
      }
      return;
    }

    final followUps = await _contextService.buildFollowUpSuggestions(
      lastUserMessage: lastUser.content,
      lastAiReply: lastAssistant.content,
    );

    if (mounted) {
      setState(() {
        _followUpChips = followUps;
        _followUpActions = const [];
      });
    }
  }

  Future<void> _applyInteractivePayload(AiChatMessage assistantMessage, String userText) async {
    final apiSuggestions = assistantMessage.followUpSuggestions;
    final apiActions = assistantMessage.coachActions;

    if (apiSuggestions.isNotEmpty || apiActions.isNotEmpty) {
      setState(() {
        _followUpChips = apiSuggestions;
        _followUpActions = apiActions;
      });
      return;
    }

    final followUps = await _contextService.buildFollowUpSuggestions(
      lastUserMessage: userText,
      lastAiReply: assistantMessage.content,
    );

    setState(() {
      _followUpChips = followUps;
      _followUpActions = const [];
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _messageController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (presetText == null) {
      _messageController.clear();
    }
    _focusNode.requestFocus();

    setState(() {
      _followUpChips = [];
      _followUpActions = [];
      _messages.add(AiChatMessage(
        userId: '',
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _coachService.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(response);
          _isLoading = false;
        });
        await _applyInteractivePayload(response, text);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            userId: '',
            role: 'assistant',
            content: _formatError(e.toString()),
            createdAt: DateTime.now(),
          ));
          _followUpChips = [];
          _followUpActions = [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleCoachAction(AiCoachAction action) {
    switch (action.type) {
      case 'open_workout':
        Navigator.of(context).push(
          NavigationHelper.createSlideRoute(
            DailyWorkoutTrackerScreen(
              initialWorkoutId: action.workoutId ?? _workoutAction.workoutId,
            ),
          ),
        );
        break;
      case 'open_exercise':
        final exerciseId = action.exerciseId;
        if (exerciseId == null || exerciseId.isEmpty) return;
        Navigator.of(context).push(
          NavigationHelper.createSlideRoute(
            ExerciseDetailScreen(exerciseId: exerciseId),
          ),
        );
        break;
      case 'send_message':
        final message = action.message?.trim();
        if (message == null || message.isEmpty) return;
        _sendMessage(message);
        break;
    }
  }

  String _formatError(String error) {
    final cleaned = error.replaceFirst('Exception: ', '');
    if (cleaned.contains('API anahtarı')) {
      return '⚠️ $cleaned';
    }
    return '⚠️ Bir hata oluştu: $cleaned';
  }

  /// Ana sayfa AI Koç kartı ile aynı `AI.svg` görseli (ölçeklenebilir).
  Widget _coachAiAvatar(double size, {double backgroundAlpha = 0.15}) {
    final pad = size * (4 / 48);
    final outerRadius = size * (14 / 48);
    final clipRadius = size * (10 / 48);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _cyanAccent.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(clipRadius),
          child: SvgPicture.asset(
            'assets/images/AI.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    const dialogBackground = Color(0xFF121A2F);

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text(
          'Sohbeti Temizle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tüm sohbet geçmişi silinecek. Emin misin?',
          style: TextStyle(color: Colors.grey[300], height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _coachService.clearHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
          _followUpChips = [];
          _followUpActions = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _coachAiAvatar(34),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PhysioFit Koç',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('AI Antrenör',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white54, size: 22),
              onPressed: _clearChat,
            ),
        ],
      ),
      body: ModernBackground(
        child: Column(
          children: [
          // Mesaj listesi
          Expanded(
            child: _isLoadingHistory
                ? Center(child: CircularProgressIndicator(color: _cyanAccent))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),

          if (_workoutAction.visible) _buildWorkoutActionBar(),

          // Mesaj giriş alanı
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _coachAiAvatar(80, backgroundAlpha: 0.1),
          const SizedBox(height: 20),
          const Text(
            'PhysioFit Koç',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Antrenman, beslenme ve sağlık hakkında\nsorularını sor!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 28),
          if (_isLoadingSuggestions)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _cyanAccent,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestionChips
                  .map((text) => _buildSuggestionChip(text))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyanAccent.withValues(alpha: 0.2)),
        ),
        child: Text(text, style: TextStyle(color: _cyanAccent, fontSize: 13)),
      ),
    );
  }

  Widget _buildMessageList() {
    final lastAssistantIndex =
        _messages.lastIndexWhere((message) => message.isAssistant);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        final showFollowUps = !_isLoading &&
            index == lastAssistantIndex &&
            !message.content.startsWith('⚠️') &&
            (_followUpChips.isNotEmpty || _followUpActions.isNotEmpty);

        return Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _buildMessageBubble(message),
            if (showFollowUps) _buildInteractiveFollowUp(),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveFollowUp() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 48, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_followUpActions.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _followUpActions.map(_buildActionButton).toList(),
            ),
          if (_followUpActions.isNotEmpty && _followUpChips.isNotEmpty)
            const SizedBox(height: 8),
          if (_followUpChips.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _followUpChips.map(_buildFollowUpChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(AiCoachAction action) {
    return GestureDetector(
      onTap: () => _handleCoachAction(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _cyanAccent.withValues(alpha: 0.22),
              _cyanAccent.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyanAccent.withValues(alpha: 0.45)),
        ),
        child: Text(
          action.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _aiBubble,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyanAccent.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: TextStyle(color: _cyanAccent.withValues(alpha: 0.9), fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _aiBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14.5, height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _aiBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _cyanAccent),
            ),
            const SizedBox(width: 10),
            Text('Düşünüyor...',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openTodayWorkout,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cyanAccent.withValues(alpha: 0.18),
                  _cyanAccent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cyanAccent.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _workoutAction.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: _cyanAccent.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openTodayWorkout() {
    Navigator.of(context).push(
      NavigationHelper.createSlideRoute(
        DailyWorkoutTrackerScreen(initialWorkoutId: _workoutAction.workoutId),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Mesajını yaz...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[800] : _cyanAccent,
                borderRadius: BorderRadius.circular(23),
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading ? Colors.grey[600] : Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk';
    if (diff.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'dün';
    return '${dateTime.day}/${dateTime.month}';
  }
}
