import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../models/user_profile.dart';
import '../theme/dialog_colors.dart';

class NotesPanel extends StatefulWidget {
  const NotesPanel({super.key});

  @override
  State<NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<NotesPanel> {
  final _store = ProfileStore();
  List<LocalNote> _notes = [];
  LocalNote? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _store.loadNotes();
    if (mounted) setState(() => _notes = notes);
  }

  Future<void> _createNote() async {
    final note = LocalNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Новая заметка',
      body: '',
      updatedAt: DateTime.now(),
    );
    _notes = [note, ..._notes];
    await _store.saveNotes(_notes);
    setState(() => _selected = note);
  }

  Future<void> _saveSelected(String title, String body) async {
    if (_selected == null) return;
    final updated = LocalNote(
      id: _selected!.id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes = _notes.map((n) => n.id == updated.id ? updated : n).toList();
    await _store.saveNotes(_notes);
    setState(() => _selected = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Container(
            color: DialogColors.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text('Заметки', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(onPressed: _createNote, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                Expanded(
                  child: _notes.isEmpty
                      ? const Center(child: Text('Нет заметок'))
                      : ListView.builder(
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final selected = _selected?.id == note.id;
                            return Material(
                              color: selected ? DialogColors.activeChat : Colors.transparent,
                              child: ListTile(
                                title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: () => setState(() => _selected = note),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Выберите или создайте заметку'))
              : _NoteEditor(
                  key: ValueKey(_selected!.id),
                  note: _selected!,
                  onSave: _saveSelected,
                ),
        ),
      ],
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({super.key, required this.note, required this.onSave});

  final LocalNote note;
  final Future<void> Function(String title, String body) onSave;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note.title);
    _body = TextEditingController(text: widget.note.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Заголовок'),
          ),
          Expanded(
            child: TextField(
              controller: _body,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Текст заметки...',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => widget.onSave(_title.text.trim(), _body.text),
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}
