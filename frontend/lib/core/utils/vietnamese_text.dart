const _withMarks = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _withoutMarks = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Bỏ dấu tiếng Việt + viết thường + bỏ khoảng trắng hai đầu, để tìm kiếm không phân biệt dấu / hoa thường.
String foldVietnamese(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final i = _withMarks.indexOf(char);
    buffer.write(i >= 0 ? _withoutMarks[i] : char);
  }
  return buffer.toString().trim();
}
