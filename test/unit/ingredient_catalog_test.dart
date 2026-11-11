import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_catalog.dart';
import 'package:food_friend/features/ingredients/domain/category_node.dart';

void main() {
  final catalog = IngredientCatalog.instance;

  group('US-2.1: Predefined Spanish Ingredient Catalog & Category Taxonomy', () {
    test('catalog provides a rich dataset of predefined Spanish ingredients', () {
      final ingredients = catalog.allIngredients;
      expect(ingredients, isNotEmpty);
      expect(ingredients.length, greaterThanOrEqualTo(80));

      // Guatemalan staples
      expect(ingredients, contains('Güisquil'));
      expect(ingredients, contains('Perulero'));
      expect(ingredients, contains('Miltomate'));
      expect(ingredients, contains('Chile guaque'));
      expect(ingredients, contains('Chile pasa'));
      expect(ingredients, contains('Chile cobanero'));
      expect(ingredients, contains('Samat'));
      expect(ingredients, contains('Epazote'));
      expect(ingredients, contains('Longaniza guatemalteca'));
      expect(ingredients, contains('Chorizo negro'));
      expect(ingredients, contains('Frijoles negros'));
      expect(ingredients, contains('Harina de maíz'));
      expect(ingredients, contains('Fécula de maíz'));
      expect(ingredients, contains('Nutella'));
      expect(ingredients, contains('Plátano maduro'));
      expect(ingredients, contains('Queso seco'));
    });

    test('resolves brand query like maseca or maicena to clean descriptor via synonyms', () {
      final masecaSuggestions = catalog.searchSuggestions('maseca');
      expect(masecaSuggestions, contains('Harina de maíz'));

      final maicenaMatch = catalog.getClosestMatch('maicena');
      expect(maicenaMatch, equals('Fécula de maíz'));
    });

    test('catalog includes cooking-specific granularity alongside general options', () {
      final ingredients = catalog.allIngredients;

      // Chicken granularity
      expect(ingredients, contains('Pechuga de pollo'));
      expect(ingredients, contains('Alitas de pollo'));
      expect(ingredients, contains('Muslos de pollo'));
      expect(ingredients, contains('Pollo'));

      // Beef granularity
      expect(ingredients, contains('Carne molida de res'));
      expect(ingredients, contains('Posta de res'));
      expect(ingredients, contains('Costilla de res'));
      expect(ingredients, contains('Carne de res'));

      // Pork granularity
      expect(ingredients, contains('Chuleta de cerdo'));
      expect(ingredients, contains('Costilla de cerdo'));
      expect(ingredients, contains('Carne de cerdo'));

      // Beans granularity
      expect(ingredients, contains('Frijoles negros'));
      expect(ingredients, contains('Frijoles colorados'));
      expect(ingredients, contains('Frijol'));
    });

    test('catalog organizes ingredients into a hierarchical tree of at most 3 to 4 levels deep', () {
      for (final root in catalog.categories) {
        expect(root.maxDepth, lessThanOrEqualTo(4),
            reason: 'Category "${root.name}" exceeds maximum allowed depth of 4');
      }

      // Verify explicit hierarchy: Level 1 (Proteínas) -> Level 2 (Pollo) -> Level 3 (Pechuga de pollo)
      final proteinas = catalog.categories.firstWhere((c) => c.id == 'proteinas');
      expect(proteinas.name, equals('Proteínas y Carnes'));
      expect(proteinas.isLeaf, isFalse);

      final pollo = proteinas.children.firstWhere((c) => c.id == 'pollo');
      expect(pollo.name, equals('Pollo'));
      expect(pollo.isLeaf, isFalse);

      final pechuga = pollo.children.firstWhere((c) => c.id == 'pechuga_pollo');
      expect(pechuga.name, equals('Pechuga de pollo'));
      expect(pechuga.isLeaf, isTrue);

      final genericPollo = pollo.children.firstWhere((c) => c.id == 'pollo_generico');
      expect(genericPollo.name, equals('Pollo'));
      expect(genericPollo.isLeaf, isTrue);
    });

    test('CategoryNode supports depth computation, leaf collection, and id lookup', () {
      const leaf = CategoryNode(id: 'sal', name: 'Sal');
      expect(leaf.maxDepth, equals(1));
      expect(leaf.isLeaf, isTrue);
      expect(leaf.allLeafNames, equals(['Sal']));

      const subCategory = CategoryNode(
        id: 'sub',
        name: 'Sub',
        children: [leaf],
      );
      expect(subCategory.maxDepth, equals(2));
      expect(subCategory.isLeaf, isFalse);
      expect(subCategory.allLeafNames, equals(['Sal']));

      const root = CategoryNode(
        id: 'root',
        name: 'Root',
        children: [subCategory],
      );
      expect(root.maxDepth, equals(3));
      expect(root.findById('sal')?.name, equals('Sal'));
      expect(root.findById('non_existent'), isNull);
    });
  });

  group('US-5.1: Guatemalan Supermarket Taxonomy & Category Naming Refinement', () {
    test('technical or botanical group names are absent across all category and subcategory names', () {
      final categoryNames = <String>[];

      void collectCategoryNames(CategoryNode node) {
        if (!node.isLeaf) {
          categoryNames.add(node.name);
          for (final child in node.children) {
            collectCategoryNames(child);
          }
        }
      }

      for (final root in catalog.categories) {
        collectCategoryNames(root);
      }

      final forbiddenTerms = [
        'cucurbit',
        'hortaliz',
        'bulbo',
        'tubérculo',
        'tuberculo',
        'raíces',
        'raices',
      ];

      for (final name in categoryNames) {
        final lower = name.toLowerCase();
        for (final term in forbiddenTerms) {
          expect(lower.contains(term), isFalse,
              reason: 'Category name "$name" contains forbidden botanical/technical term "$term"');
        }
      }
    });

    test('everyday Guatemalan supermarket terms inspired by Walmart and La Torre are present', () {
      final categoryNames = <String>[];

      void collectCategoryNames(CategoryNode node) {
        if (!node.isLeaf) {
          categoryNames.add(node.name);
          for (final child in node.children) {
            collectCategoryNames(child);
          }
        }
      }

      for (final root in catalog.categories) {
        collectCategoryNames(root);
      }

      expect(categoryNames, contains('Verduras para cocido y guisos'));
      expect(categoryNames, contains('Hierbas y montes'));
      expect(categoryNames, contains('Embutidos y carnes frías'));
      expect(categoryNames, contains('Quesos y crema'));
      expect(categoryNames, contains('Frutos secos y semillas'));
      expect(categoryNames, contains('Verduras para ensalada'));
      expect(categoryNames, contains('Cebollas, ajos y chiles'));
    });

    test('all leaf nodes remain reachable within <= 4 steps from root', () {
      for (final root in catalog.categories) {
        expect(root.maxDepth, lessThanOrEqualTo(4),
            reason: 'Root category "${root.name}" exceeds max allowed depth of 4');
      }

      void verifyLeafSteps(CategoryNode node, int currentDepth) {
        expect(currentDepth, lessThanOrEqualTo(4),
            reason: 'Leaf node "${node.name}" reached at depth $currentDepth, exceeding max 4 steps');
        if (!node.isLeaf) {
          for (final child in node.children) {
            verifyLeafSteps(child, currentDepth + 1);
          }
        }
      }

      for (final root in catalog.categories) {
        verifyLeafSteps(root, 1);
      }
    });
  });
}

