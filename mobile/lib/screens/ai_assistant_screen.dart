import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Chat tab controllers
  final _chatQueryController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Hello! I am CarePulse AI, your intelligent medical care assistant. How can I assist with medical triage, symptoms, or resident care today?'
    }
  ];
  bool _isChatLoading = false;

  // Classifier tab controllers
  final _classifierController = TextEditingController();
  Map<String, dynamic>? _classifierResult;
  bool _isClassifying = false;

  // Medical Notes Analyzer controllers
  final _nameController = TextEditingController(text: 'Eleanor Vance');
  final _ageController = TextEditingController(text: '78');
  final _notesController = TextEditingController(
      text: 'Patient complained of sudden dizziness, mild shortness of breath, and pulse 105 bpm after morning walk.');
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatQueryController.dispose();
    _classifierController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendChatMessage() async {
    final query = _chatQueryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _chatQueryController.clear();
      _isChatLoading = true;
    });

    try {
      final response = await _apiService.chatAI(query);
      final reply = response.data['reply'] ?? response.data['response'] ?? 'AI responded to your query.';
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
          _isChatLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'I encountered an issue connecting to the AI agent service. Please verify your backend server.'});
          _isChatLoading = false;
        });
      }
    }
  }

  Future<void> _classifyEmergency() async {
    final desc = _classifierController.text.trim();
    if (desc.isEmpty) return;

    setState(() => _isClassifying = true);
    try {
      final response = await _apiService.classifyEmergency(desc);
      if (mounted) {
        setState(() {
          _classifierResult = response.data;
          _isClassifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClassifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _analyzeNotes() async {
    setState(() => _isAnalyzing = true);
    try {
      final age = int.tryParse(_ageController.text) ?? 75;
      final response = await _apiService.analyzeNotes(
        _nameController.text,
        age,
        _notesController.text,
      );
      if (mounted) {
        setState(() {
          _analysisResult = response.data;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text('CarePulse AI Agent'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'AI Chat'),
            Tab(icon: Icon(Icons.local_hospital_outlined), text: 'Triage Risk'),
            Tab(icon: Icon(Icons.note_alt_outlined), text: 'Analyze Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: AI Chat
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isChatLoading)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatQueryController,
                        decoration: InputDecoration(
                          hintText: 'Ask AI emergency question...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sendChatMessage,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 2: Triage Risk Classifier
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _classifierController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Emergency Symptom Description',
                    hintText: 'e.g. Resident experiencing sharp chest pain and difficulty breathing',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isClassifying ? null : _classifyEmergency,
                  icon: const Icon(Icons.psychology_outlined),
                  label: _isClassifying
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Classify Urgency Severity'),
                ),
                if (_classifierResult != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.purple.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Triage Assessment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Category: ${_classifierResult!['category'] ?? "High Urgency"}'),
                          Text('Urgency Score: ${_classifierResult!['urgency_score'] ?? "9/10"}'),
                          Text('Recommended Action: ${_classifierResult!['recommendation'] ?? "Immediate EMT Dispatch"}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab 3: Analyze Notes
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Resident Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Daily Medical & Vital Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeNotes,
                  icon: const Icon(Icons.analytics_outlined),
                  label: _isAnalyzing
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Generate AI Clinical Summary'),
                ),
                if (_analysisResult != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.teal.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clinical AI Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(_analysisResult!['summary'] ?? _analysisResult.toString()),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
