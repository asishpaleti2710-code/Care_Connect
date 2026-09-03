import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/glass_card.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: const Color(0xF20F172A),
        title: Text('Campus GPS & Live Map', style: AppTheme.heading(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.tealGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentTeal.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.explore_rounded, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Interactive Emergency Map',
                          style: AppTheme.heading(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Live GPS coordinates (13.0827° N, 80.2707° E), building zones, and turn-by-turn responder routes active.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgDarkInput,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.statusSafe),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gps_fixed_rounded, color: AppColors.statusSafe, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'CAMPUS BEACON: ONLINE • ACCURACY 1.2M',
                                style: TextStyle(color: AppColors.statusSafe, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📍 Refreshing GPS location beacon and building markers...'),
                        backgroundColor: AppColors.accentTeal,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh GPS Location Pins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
