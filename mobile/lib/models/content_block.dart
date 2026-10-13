enum BlockType { text, imageSvg, pdf, warning }

class ContentBlock {
  final BlockType type;
  final String content;
  final int order;

  const ContentBlock({
    required this.type,
    required this.content,
    required this.order,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    BlockType t = BlockType.text;
    switch (json['type']) {
      case 'image_svg':
        t = BlockType.imageSvg;
        break;
      case 'pdf':
        t = BlockType.pdf;
        break;
      case 'warning':
        t = BlockType.warning;
        break;
    }
    return ContentBlock(
      type: t,
      content: json['content'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'content': content,
        'order': order,
      };
}
