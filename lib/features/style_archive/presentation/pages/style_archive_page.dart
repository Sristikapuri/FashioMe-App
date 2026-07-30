import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';
import 'package:fashio_me/features/style_archive/presentation/view_model/style_archive_view_model.dart';

class StyleArchivePage extends ConsumerStatefulWidget {
  const StyleArchivePage({super.key});

  @override
  ConsumerState<StyleArchivePage> createState() => _StyleArchivePageState();
}

class _StyleArchivePageState extends ConsumerState<StyleArchivePage> {
  bool _loading = true;
  String _error = '';
  List<StyleArchiveEntry> _entries = [];
  String? _selectedWeekKey;

  static const _dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final entries = await ref
          .read(styleArchiveViewModelProvider)
          .fetchStyleArchive();
      if (!mounted) return;
      final weekKeys = _sortedWeekKeys(entries);
      setState(() {
        _entries = entries;
        _selectedWeekKey = weekKeys.isNotEmpty ? weekKeys.first : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load your style archive.';
        _loading = false;
      });
    }
  }

  List<String> _sortedWeekKeys(List<StyleArchiveEntry> entries) {
    final keys = entries.map((e) => e.weekKey).toSet().toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final weekKeys = _sortedWeekKeys(_entries);
    final weekEntries =
        _entries.where((e) => e.weekKey == _selectedWeekKey).toList()
          ..sort(
            (a, b) =>
                _dayOrder.indexOf(a.day).compareTo(_dayOrder.indexOf(b.day)),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Style Archive'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (_error.isNotEmpty) ...[
                    Text(_error, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                  ],
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'No saved looks yet. Your AI style of the day '
                          'will appear here as you use the app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: weekKeys.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final weekKey = weekKeys[index];
                          final selected = weekKey == _selectedWeekKey;
                          return ChoiceChip(
                            label: Text(weekKey),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedWeekKey = weekKey),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: AppColors.surfaceSoft,
                            side: BorderSide(color: AppColors.divider),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...weekEntries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ArchiveEntryCard(entry: entry),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ArchiveEntryCard extends StatelessWidget {
  const _ArchiveEntryCard({required this.entry});

  final StyleArchiveEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: entry.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(Icons.checkroom_outlined),
                    )
                  : Image.network(
                      entry.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.day,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.occasion,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (entry.title.isNotEmpty)
                  Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                if (entry.outfit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.outfit,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
