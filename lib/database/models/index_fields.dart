class IndexFields {
  final String name;
  final bool unique;

  const IndexFields(
    this.name, {
    this.unique = true,
  });

  IndexFields copyWith({
    String? name,
    bool? unique,
  }) {
    return IndexFields(
      name ?? this.name,
      unique: unique ?? this.unique,
    );
  }

  @override
  String toString() => 'IndexFields(name: $name, unique: $unique)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IndexFields && other.name == name && other.unique == unique;
  }

  @override
  int get hashCode => name.hashCode ^ unique.hashCode;
}
