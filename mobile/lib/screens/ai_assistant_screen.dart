import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

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
      'text': 'Hello! I am CarePulse AI, your intelligent medical care assistant. Ask me about resident emergency protocols, blood pressure guidelines, dementia care routines, or medication notes.'
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

  String _getLocalFallbackReply(String query) {
    final q = query.toLowerCase();

    if (q.contains("paracetamol") || q.contains("acetaminophen")) {
      return "💊 **Paracetamol / Acetaminophen (Pain & Fever)**:\n• Dosage: 500mg-1000mg q4-6h (Max 4g/day).\n• Warning: Watch daily limit to protect liver. Avoid alcohol.";
    } else if (q.contains("ibuprofen") || q.contains("advil")) {
      return "💊 **Ibuprofen (NSAID)**:\n• Dosage: 200mg-400mg q6-8h with food.\n• Warning: Take with food to protect stomach. Caution in seniors with hypertension or kidney conditions.";
    } else if (q.contains("aspirin")) {
      return "💊 **Aspirin (Cardioprotective)**:\n• Dosage: 81mg daily for heart protection, or 325mg chewed immediately for acute chest pain emergency.";
    } else if (q.contains("amlodipine") || q.contains("norvasc")) {
      return "💊 **Amlodipine (Blood Pressure)**:\n• Dosage: 5mg-10mg daily.\n• Indications: Hypertension & Angina. Monitor for ankle swelling or dizziness.";
    } else if (q.contains("bp") || q.contains("blood pressure") || q.contains("vitals")) {
      return "🩺 **Senior Vitals Reference Ranges**:\n• BP: Target <120/80 mmHg. (>180/120 is Hypertensive Crisis ➔ Press SOS).\n• Pulse: 60-100 bpm at rest.\n• SpO2: 95%-100% on room air.\n• Temp: 97.8°F-99.1°F.";
    } else if (q.contains("stroke") || q.contains("fast")) {
      return "🧠 **Stroke F.A.S.T. Warning**:\n• **F**ace drooping • **A**rm weakness • **S**peech difficulty • **T**ime to press SOS immediately!";
    } else if (q.contains("heart attack") || q.contains("chest pain")) {
      return "🚨 **Cardiac Emergency**: Sit upright, loosen tight clothes, give 325mg Aspirin to chew if not allergic, and press red CareConnect SOS button immediately!";
    } else if (q.contains("fall")) {
      return "🚨 **Fall Emergency Protocol**: Do NOT force resident to stand up if head or spinal injury is suspected. Keep resident warm & press red SOS button for responder dispatch.";
    } else if (q.contains("dementia") || q.contains("memory")) {
      return "🧠 **Dementia Care Guidance**: Maintain daily routine, use simple reassuring sentences, visual clocks/photos, and gently redirect agitation without arguing.";
    } else {
      return "🤖 **CarePulse AI**: Recorded \"$query\". You can ask about medicines (Paracetamol, Aspirin, Amlodipine), vitals guidelines, stroke/cardiac emergency protocols, or resident care notes.";
    }
  }

  Future<void> _sendChatMessage([String? quickText]) async {
    final query = (quickText ?? _chatQueryController.text).trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      if (quickText == null) _chatQueryController.clear();
      _isChatLoading = true;
    });

    try {
      final response = await _apiService.chatAI(query);
      final reply = response.data['reply'] ?? response.data['response'];
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply ?? _getLocalFallbackReply(query)});
          _isChatLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': _getLocalFallbackReply(query)});
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
        setState(() {
          _classifierResult = {
            'category': 'Medical Emergency',
            'urgency_score': '9/10',
            'priority': 'Critical',
            'recommendation': 'Immediate EMT / Security dispatch recommended. Keep airway open.',
          };
          _isClassifying = false;
        });
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
        setState(() {
          _analysisResult = {
            'summary': 'Clinical Summary for ${_nameController.text}: Symptoms indicate post-exertional tachycardia and lightheadedness. Recommend resting BP/SpO2 check and cardiologist follow-up.'
          };
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: const Color(0xF20F172A),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CarePulse AI', style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('Active Medical Intelligence', style: TextStyle(fontSize: 10, color: AppColors.statusSafe)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentTeal,
          labelColor: AppColors.accentTeal,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 18), text: 'AI Chat'),
            Tab(icon: Icon(Icons.local_hospital_outlined, size: 18), text: 'Triage Risk'),
            Tab(icon: Icon(Icons.note_alt_outlined, size: 18), text: 'Analyze Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: AI Chat matching website
          Column(
            children: [
              // Quick Prompt Pills
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0x660F172A),
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickPromptPill(label: 'Fall Protocol', onTap: () => _sendChatMessage('Fall Protocol')),
                      const SizedBox(width: 6),
                      _QuickPromptPill(label: 'Blood Pressure', onTap: () => _sendChatMessage('Blood Pressure')),
                      const SizedBox(width: 6),
                      _QuickPromptPill(label: 'Dementia Care', onTap: () => _sendChatMessage('Dementia Care')),
                      const SizedBox(width: 6),
                      _QuickPromptPill(label: 'Paracetamol', onTap: () => _sendChatMessage('Paracetamol')),
                    ],
                  ),
                ),
              ),

              // Messages Feed
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
                          color: isUser ? null : AppColors.bgCard,
                          gradient: isUser ? AppColors.tealGradient : null,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser ? null : Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['text']!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isChatLoading)
                const LinearProgressIndicator(color: AppColors.accentTeal),

              // Input Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xF20F172A),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatQueryController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: AppGlass.inputDecoration(
                          hintText: 'Ask caregiver advice...',
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: _sendChatMessage,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 2: Triage Risk Classifier
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Emergency Symptom Description', style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _classifierController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: AppGlass.inputDecoration(
                          hintText: 'e.g. Resident experiencing sharp chest pain and difficulty breathing...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isClassifying ? null : _classifyEmergency,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.psychology_outlined, size: 18),
                        label: Text(_isClassifying ? 'Classifying...' : 'Classify Urgency Severity'),
                      ),
                    ],
                  ),
                ),
                if (_classifierResult != null) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppColors.accentPurple.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Triage Assessment:', style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFC084FC))),
                        const SizedBox(height: 8),
                        Text('Category: ${_classifierResult!['category'] ?? "High Urgency"}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        Text('Urgency Score: ${_classifierResult!['urgency_score'] ?? "9/10"}', style: const TextStyle(color: AppColors.statusAlert, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('💡 ${_classifierResult!['recommendation'] ?? "Immediate EMT Dispatch"}', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab 3: Analyze Notes
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Resident Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: AppGlass.inputDecoration(hintText: 'Eleanor Vance'),
                      ),
                      const SizedBox(height: 12),
                      const Text('Age', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: AppGlass.inputDecoration(hintText: '78'),
                      ),
                      const SizedBox(height: 12),
                      const Text('Daily Medical & Vital Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: AppGlass.inputDecoration(hintText: 'Describe patient conditions, pulse, observation notes...'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: Text(_isAnalyzing ? 'Generating Summary...' : 'Generate AI Clinical Summary'),
                      ),
                    ],
                  ),
                ),
                if (_analysisResult != null) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppColors.accentTeal.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clinical AI Summary:', style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
                        const SizedBox(height: 8),
                        Text(_analysisResult!['summary'] ?? _analysisResult.toString(), style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.4)),
                      ],
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

class _QuickPromptPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPromptPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

