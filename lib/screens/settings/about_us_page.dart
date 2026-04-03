import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/data_table_widget.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withValues(alpha: 0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond_rounded,
                    size: 66,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'The Diamond Story',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Manifesto',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We craft operational clarity for diamond businesses with a premium, focused workflow. From rough intake to final sale, every action in this console is optimized for speed, trust, and auditability.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Precision',
                      subtitle: 'Accurate records across inventory and process flows.',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.shield_moon_rounded,
                      title: 'Reliability',
                      subtitle: 'Consistent local-first operations with data safety controls.',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.rocket_launch_rounded,
                      title: 'Growth',
                      subtitle: 'A streamlined ERP experience ready for scale.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _CompanyFooter(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thin divider with fade
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.transparent, Color(0x220F172A), Colors.transparent],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Container(height: 1, color: AppTheme.divider),
        ),
        const SizedBox(height: 28),
        // Hexagon-style logo badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'H',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.accent,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Company name
        Text(
          'HIVNK',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 8),
        // Tagline
        Text(
          'Transforming businesses through innovative software solutions.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 20),
        // Bottom year line
        Text(
          '© 2026 HIVNK. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}


