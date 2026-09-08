import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/presets/diet_content.dart';

/// 饮食与健康指导页：分类浏览静态内容
class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  static const Map<String, IconData> _icons = {
    'food': Icons.restaurant,
    'sleep': Icons.bedtime,
    'eyes': Icons.visibility,
    'exercise': Icons.fitness_center,
    'habits': Icons.lightbulb,
  };

  static const Map<String, Color> _colors = {
    'food': AppTheme.alertRed,
    'sleep': AppTheme.violetNeural,
    'eyes': AppTheme.neonCyan,
    'exercise': AppTheme.successGreen,
    'habits': AppTheme.amberPulse,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('饮食与健康')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: kDietCategories.length,
          itemBuilder: (context, index) {
            final category = kDietCategories[index];
            final icon = _icons[category.id] ?? Icons.info_outline;
            final color = _colors[category.id] ?? AppTheme.neonCyan;
            return Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DietArticleListScreen(category: category, icon: icon, color: color),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.title, style: context.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(category.subtitle, style: context.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '${category.articles.length} 篇文章',
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 文章列表页
class DietArticleListScreen extends StatelessWidget {
  final DietCategory category;
  final IconData icon;
  final Color color;

  const DietArticleListScreen({
    super.key,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: category.articles.length,
          itemBuilder: (context, index) {
            final article = category.articles[index];
            return Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DietArticleDetailScreen(article: article, color: color),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(article.title, style: context.textTheme.titleMedium),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 文章详情页
class DietArticleDetailScreen extends StatelessWidget {
  final DietArticle article;
  final Color color;

  const DietArticleDetailScreen({super.key, required this.article, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                article.title,
                style: context.textTheme.headlineSmall?.copyWith(color: color),
              ),
            ),
            const SizedBox(height: 16),
            ...article.paragraphs.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    p,
                    style: context.textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
