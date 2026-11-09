/// Represents a node in the hierarchical ingredient category taxonomy.
/// Can be either an intermediate category (with [children]) or a selectable leaf ingredient.
class CategoryNode {
  const CategoryNode({
    required this.id,
    required this.name,
    this.children = const [],
    this.synonyms = const [],
  });

  /// Unique identifier (e.g., 'proteinas', 'pollo', 'pechuga_pollo').
  final String id;

  /// Spanish display name (e.g., 'Proteínas y Carnes', 'Pollo', 'Pechuga de pollo').
  final String name;

  /// Subcategories or leaf ingredients contained within this category.
  final List<CategoryNode> children;

  /// Alternative search terms or synonyms in Spanish (e.g., ['chayote'] for Güisquil).
  final List<String> synonyms;

  /// Indicates if this node is a selectable leaf ingredient (has no children).
  bool get isLeaf => children.isEmpty;

  /// Computes the maximum depth of the tree starting from this node.
  /// A leaf has depth 1.
  int get maxDepth {
    if (isLeaf) return 1;
    int maxChildDepth = 0;
    for (final child in children) {
      final childDepth = child.maxDepth;
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return 1 + maxChildDepth;
  }

  /// Recursively collects all leaf ingredient names from this node and its descendants.
  List<String> get allLeafNames {
    if (isLeaf) return [name];
    final list = <String>[];
    for (final child in children) {
      list.addAll(child.allLeafNames);
    }
    return list;
  }

  /// Finds a descendant node by its [targetId], or returns null if not found.
  CategoryNode? findById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final match = child.findById(targetId);
      if (match != null) return match;
    }
    return null;
  }

  @override
  String toString() => 'CategoryNode(id: $id, name: $name, isLeaf: $isLeaf, children: ${children.length})';
}
