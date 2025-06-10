import 'package:flutter/material.dart';

class FancyNameInput extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  final VoidCallback onRandom;
  final String label;

  const FancyNameInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onRandom,
    this.label = '修士道号：',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label 固定宽度 + 右对齐
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),

        // 输入框内容左对齐（加 Align 包裹）
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              onChanged: onChanged,
              maxLength: 8,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "请输入修士道号",
                hintStyle: const TextStyle(color: Colors.black26),
                filled: true,
                fillColor: const Color(0xFFFDFCF5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF9C8E7B), size: 22),
                suffixIcon: GestureDetector(
                  onTap: onRandom,
                  child: const Icon(
                    Icons.casino_rounded,
                    size: 26,
                    color: Color(0xFF5E4B36),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD8CFC0), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD8CFC0), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF9C8E7B), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
