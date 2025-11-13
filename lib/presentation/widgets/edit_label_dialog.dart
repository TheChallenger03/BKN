import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class EditLabelDialog extends StatefulWidget {
  final String currentLabel;

  const EditLabelDialog({
      super.key, 
      required this.currentLabel
    });

  @override
  State<EditLabelDialog> createState() => _EditLabelDialogState();
}

class _EditLabelDialogState extends State<EditLabelDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica Etichetta'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: AppConstants.maxLabelLength,
          decoration: const InputDecoration(
            labelText: 'Nuova etichetta',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci un\'etichetta';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salva'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }
}