import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../providers/generation_provider.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<void> _saveToGallery(BuildContext context) async {
    final generationProvider = Provider.of<GenerationProvider>(
      context,
      listen: false,
    );
    final imageBytes = generationProvider.generatedImage;

    if (imageBytes == null) return;

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/generated_thumbnail_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(imageBytes);

      await Gal.putImage(path);

      // Increment saved count
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().incrementSavedCount(user.uid);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditor(BuildContext context, Uint8List imageBytes) async {
    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          imageBytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              Provider.of<GenerationProvider>(
                context,
                listen: false,
              ).setGeneratedImage(bytes);
              Navigator.pop(context);
            },
          ),
          configs: const ProImageEditorConfigs(
            designMode: ImageEditorDesignMode.material,
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, Uint8List imageBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(imageBytes),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generationProvider = Provider.of<GenerationProvider>(context);
    final imageBytes = generationProvider.generatedImage;

    return Scaffold(
      backgroundColor: Colors.black, // Immersive black background
      appBar: AppBar(
        title: Text(
          'Generated Result',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: imageBytes == null
          ? const Center(
              child: Text(
                'No image generated.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Stack(
              children: [
                // Centered Image with Glow
                Center(
                  child: GestureDetector(
                    onTap: () => _openFullScreen(context, imageBytes),
                    child: Hero(
                      tag: 'generatedImage',
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(imageBytes, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),

                // Hint Text
                const Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Tap image to Zoom",
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Floating Action Bar
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          onTap: () => _openEditor(context, imageBytes),
                          isPrimary: false,
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _ActionButton(
                          icon: Icons.save_alt,
                          label: 'Save',
                          onTap: () => _saveToGallery(context),
                          isPrimary: true,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppTheme.primaryBlue : Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppTheme.primaryBlue : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
