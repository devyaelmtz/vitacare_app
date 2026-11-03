import 'package:flutter/material.dart';

void mostrarAlertaGlobal(
  BuildContext context,
  String mensaje, {
  IconData icono = Icons.info_outline,
  Color colorIcono = Colors.blue,
  String titulo = 'Aviso',
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icono, color: colorIcono, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}