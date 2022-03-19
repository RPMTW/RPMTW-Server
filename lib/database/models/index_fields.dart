class IndexField {
  final String name;
  final bool unique;

  const IndexField(
    this.name, {
    required this.unique,
  });

  IndexField copyWith({
    String? name,
    bool? unique,
  }) {
    return IndexField(
      name ?? this.name,
      unique: unique ?? this.unique,
    );
  }

  @override
  String toString() => "IndexFields(name: $name, unique: $unique)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IndexField && other.name == name && other.unique == unique;
  }

  @override
  int get hashCode => name.hashCode ^ unique.hashCode;
}
