import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/generation_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/admob_service.dart';
import '../utils/app_theme.dart';
import 'result_screen.dart';
import '../widgets/gradient_switch.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _promptController = TextEditingController();
  String _selectedAspectRatio = '16:9';
  final List<String> _aspectRatios = ['16:9', '1:1', '9:16'];
  bool _isEnhancing = false;
  bool _isThumbnailMode = true;
  final GeminiService _geminiService = GeminiService();
  final AdMobService _adMobService = AdMobService();
  String? _originalPrompt;

  @override
  void initState() {
    super.initState();
    _adMobService.initialize();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _enhancePrompt() async {
    final currentText = _promptController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to enhance')),
      );
      return;
    }

    setState(() {
      _isEnhancing = true;
      _originalPrompt = currentText; // Store original prompt
    });

    try {
      final enhanced = await _geminiService.enhancePrompt(currentText);
      if (enhanced != null) {
        setState(() => _promptController.text = enhanced);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prompt enhanced! ✨'),
              backgroundColor: AppTheme.accentCyan,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enhance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnhancing = false);
    }
  }

  void _undoEnhance() {
    if (_originalPrompt != null) {
      setState(() {
        _promptController.text = _originalPrompt!;
        _originalPrompt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restored original prompt'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // --- FIXED FUNCTION START ---
  void _showAdDialog(String uid) {
    // Fix: Messenger ko pehle hi store kar lo taake Ad ke baad error na aaye
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Out of Credits 🪙',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Watch a short video to earn 3 free credits!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog band karo

              // Ad dikhao
              _adMobService.showRewardedAd(() async {
                // Reward milne par:
                await FirestoreService().addCredits(uid, 3);

                // UI Update karo
                if (mounted) {
                  setState(() {});

                  // Safe SnackBar Call
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Success! You earned 3 Credits 💰'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }
  // --- FIXED FUNCTION END ---

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final generationProvider = Provider.of<GenerationProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user == null) return;

    // Construct Enhanced Prompt
    String finalPrompt = prompt;

    // Append Thumbnail Style
    if (_isThumbnailMode) {
      finalPrompt +=
          ", YouTube thumbnail style, high quality, 8k, vibrant colors, dramatic lighting, trending on artstation";
    }

    await generationProvider.generateImage(
      finalPrompt,
      _selectedAspectRatio,
      user.uid,
    );

    if (generationProvider.error != null) {
      // Check specifically for credits error
      if (generationProvider.error!.contains('Insufficient credits')) {
        if (mounted) _showAdDialog(user.uid);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(generationProvider.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (generationProvider.generatedImage != null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResultScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final generationProvider = Provider.of<GenerationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Text(
                "Generate Thumbnail",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Prompt Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe your imagination...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 5,
                  onChanged: (value) {
                    // If user types manually, clear undo history to avoid confusion
                    if (_originalPrompt != null && value != _originalPrompt) {
                      setState(() => _originalPrompt = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Undo Button
                    if (_originalPrompt != null)
                      TextButton.icon(
                        onPressed: _undoEnhance,
                        icon: const Icon(
                          Icons.undo_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                        label: Text(
                          "Undo",
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else
                      const SizedBox(),

                    // Enhance Button
                    GestureDetector(
                      onTap: _isEnhancing ? null : _enhancePrompt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accentCyan.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: Text(
                                "Enhance your prompt",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _isEnhancing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.accentCyan,
                                      ),
                                    ),
                                  )
                                : ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppTheme.primaryGradient.createShader(
                                          Rect.fromLTWH(
                                            0,
                                            0,
                                            bounds.width,
                                            bounds.height,
                                          ),
                                        ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Thumbnail Mode Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Thumbnail Mode",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Optimized for YouTube",
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              ),
              trailing: GradientSwitch(
                value: _isThumbnailMode,
                onChanged: (value) => setState(() => _isThumbnailMode = value),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Aspect Ratio Selector
          Text(
            "Aspect Ratio",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _aspectRatios.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final ratio = _aspectRatios[index];
                final isSelected = _selectedAspectRatio == ratio;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAspectRatio = ratio),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[800]!),
                    ),
                    child: Center(
                      child: Text(
                        ratio,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),

          // Generate Button
          if (generationProvider.isGenerating)
            Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.accentCyan),
                const SizedBox(height: 16),
                Text(
                  "Dreaming up your image...",
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
              ],
            )
          else
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Generate Image',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
