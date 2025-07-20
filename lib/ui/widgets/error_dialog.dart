import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showErrorDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('发生错误'),
        content: SingleChildScrollView(
          child: Text(errorMessage),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('复制'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: errorMessage));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('错误信息已复制到剪贴板')),
              );
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
