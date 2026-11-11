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
      expect(ingredients, contains('Maicena'));
      expect(ingredients, contains('Nutella'));
      expect(ingredients, contains('Plátano maduro'));
      expect(ingredients, contains('Queso seco'));
    });

    test('resolves brand query like maseca or maicena to canonical descriptor via synonyms', () {
      final masecaSuggestions = catalog.searchSuggestions('maseca');
      expect(masecaSuggestions, contains('Harina de maíz'));

      final maicenaMatch = catalog.getClosestMatch('maicena');
      expect(maicenaMatch, equals('Maicena'));

      final feculaMatch = catalog.getClosestMatch('fécula de maíz');
      expect(feculaMatch, equals('Maicena'));
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

  group('US-5.2: Expanded Ingredient Catalog & User-Tested Missing Staples', () {
    late IngredientCatalog catalog;

    setUp(() {
      catalog = IngredientCatalog.instance;
    });

    test('catalog contains all 5 user-tested staples in allIngredients', () {
      expect(catalog.allIngredients, contains('Nueces'));
      expect(catalog.allIngredients, contains('Maní'));
      expect(catalog.allIngredients, contains('Queso gouda'));
      expect(catalog.allIngredients, contains('Queso parmesano'));
      expect(catalog.allIngredients, contains('Curry'));
    });

    test('catalog contains additional everyday grocery items from Walmart and La Torre', () {
      expect(catalog.allIngredients, contains('Champiñones'));
      expect(catalog.allIngredients, contains('Brócoli'));
      expect(catalog.allIngredients, contains('Coliflor'));
      expect(catalog.allIngredients, contains('Lentejas'));
      expect(catalog.allIngredients, contains('Garbanzos'));
      expect(catalog.allIngredients, contains('Almendras'));
      expect(catalog.allIngredients, contains('Semillas de marañón'));
      expect(catalog.allIngredients, contains('Queso cheddar'));
      expect(catalog.allIngredients, contains('Páprika'));
      expect(catalog.allIngredients, contains('Jengibre'));
      expect(catalog.allIngredients, contains('Cúrcuma'));
    });

    test('exact match retrieval works for all 5 staples', () {
      expect(catalog.getClosestMatch('Nueces'), equals('Nueces'));
      expect(catalog.getClosestMatch('Maní'), equals('Maní'));
      expect(catalog.getClosestMatch('Queso gouda'), equals('Queso gouda'));
      expect(catalog.getClosestMatch('Queso parmesano'), equals('Queso parmesano'));
      expect(catalog.getClosestMatch('Curry'), equals('Curry'));
    });

    test('case- and accent-insensitive queries return the correct staples', () {
      expect(catalog.getClosestMatch('nueces'), equals('Nueces'));
      expect(catalog.getClosestMatch('NUECES'), equals('Nueces'));

      expect(catalog.getClosestMatch('mani'), equals('Maní'));
      expect(catalog.getClosestMatch('maní'), equals('Maní'));
      expect(catalog.getClosestMatch('MANÍ'), equals('Maní'));

      expect(catalog.getClosestMatch('queso gouda'), equals('Queso gouda'));
      expect(catalog.getClosestMatch('QUESO GOUDA'), equals('Queso gouda'));

      expect(catalog.getClosestMatch('queso parmesano'), equals('Queso parmesano'));
      expect(catalog.getClosestMatch('QUESO PARMESANO'), equals('Queso parmesano'));

      expect(catalog.getClosestMatch('curry'), equals('Curry'));
      expect(catalog.getClosestMatch('CURRY'), equals('Curry'));
    });

    test('synonyms resolve to canonical staples in getClosestMatch and searchSuggestions', () {
      // Nuez -> Nueces
      expect(catalog.getClosestMatch('nuez'), equals('Nueces'));
      expect(catalog.searchSuggestions('nuez'), contains('Nueces'));

      // Cacahuate -> Maní
      expect(catalog.getClosestMatch('cacahuate'), equals('Maní'));
      expect(catalog.searchSuggestions('cacahuate'), contains('Maní'));

      // Gouda -> Queso gouda
      expect(catalog.getClosestMatch('gouda'), equals('Queso gouda'));
      expect(catalog.searchSuggestions('gouda'), contains('Queso gouda'));

      // Parmesano -> Queso parmesano
      expect(catalog.getClosestMatch('parmesano'), equals('Queso parmesano'));
      expect(catalog.searchSuggestions('parmesano'), contains('Queso parmesano'));

      // Curry en polvo -> Curry
      expect(catalog.getClosestMatch('curry en polvo'), equals('Curry'));
      expect(catalog.searchSuggestions('curry en polvo'), contains('Curry'));
    });

    test('staples appear in their corresponding category leaves in category browser', () {
      final frutosSecos = catalog.categories.firstWhere((c) => c.id == 'frutos_secos_semillas');
      expect(frutosSecos.allLeafNames, contains('Nueces'));
      expect(frutosSecos.allLeafNames, contains('Maní'));

      final lacteos = catalog.categories.firstWhere((c) => c.id == 'lacteos_huevos');
      final quesos = lacteos.children.firstWhere((c) => c.id == 'quesos_crema');
      expect(quesos.allLeafNames, contains('Queso gouda'));
      expect(quesos.allLeafNames, contains('Queso parmesano'));

      final hierbas = catalog.categories.firstWhere((c) => c.id == 'hierbas_especias');
      final especias = hierbas.children.firstWhere((c) => c.id == 'especias');
      expect(especias.allLeafNames, contains('Curry'));
    });
  });

  group('Catalog Adjustments: Refined Items, Structure & Sorting', () {
    test('added staples arveja china, sardinas, and granola are present in catalog', () {
      expect(catalog.allIngredients, contains('Arveja china'));
      expect(catalog.allIngredients, contains('Sardinas'));
      expect(catalog.allIngredients, contains('Granola'));

      // Check category placement
      final legumbres = catalog.categories
          .firstWhere((c) => c.id == 'verduras')
          .children
          .firstWhere((c) => c.id == 'legumbres_frescas');
      expect(legumbres.allLeafNames, contains('Arveja china'));

      final pescados = catalog.categories
          .firstWhere((c) => c.id == 'proteinas')
          .children
          .firstWhere((c) => c.id == 'pescados_mariscos');
      expect(pescados.allLeafNames, contains('Sardinas'));

      final cereales = catalog.categories
          .firstWhere((c) => c.id == 'granos_cereales')
          .children
          .firstWhere((c) => c.id == 'cereales');
      expect(cereales.allLeafNames, contains('Granola'));
    });

    test('huevo is consolidated and promoted as a direct leaf under Lácteos y Huevos', () {
      final lacteos = catalog.categories.firstWhere((c) => c.id == 'lacteos_huevos');
      
      // Huevo is a direct child of lacteos_huevos
      final huevoNode = lacteos.children.firstWhere((c) => c.id == 'huevo');
      expect(huevoNode.isLeaf, isTrue);
      expect(huevoNode.name, equals('Huevo'));

      // The old intermediate "huevos" subcategory is gone
      expect(lacteos.children.any((c) => c.id == 'huevos'), isFalse);

      // Redundant egg entries are not leaf names
      expect(catalog.allIngredients, contains('Huevo'));
      expect(catalog.allIngredients, isNot(contains('Huevos de gallina')));

      // Synonyms still resolve
      expect(catalog.getClosestMatch('huevos'), equals('Huevo'));
      expect(catalog.getClosestMatch('huevos de gallina'), equals('Huevo'));
    });

    test('overly specific and prepared food items are removed from catalog', () {
      final all = catalog.allIngredients;
      expect(all, isNot(contains('Yogur de fresa')));
      expect(all, isNot(contains('Frijol de vara')));
      expect(all, isNot(contains('Pepitona')));
      expect(all, isNot(contains('Sal yodada')));
      expect(all, isNot(contains('Sal marina')));
      expect(all, isNot(contains('Pipían')));
    });

    test('replacements are applied correctly for güicoy, ketchup, and maicena', () {
      final all = catalog.allIngredients;
      expect(all, contains('Güicoy'));
      expect(all, isNot(contains('Calabacita')));
      expect(catalog.getClosestMatch('calabacita'), equals('Güicoy'));
      expect(catalog.getClosestMatch('zucchini'), equals('Güicoy'));

      expect(all, contains('Ketchup'));
      expect(all, isNot(contains('Salsa dulce')));
      expect(catalog.getClosestMatch('salsa dulce'), equals('Ketchup'));

      expect(all, contains('Maicena'));
      expect(all, isNot(contains('Fécula de maíz')));
      expect(catalog.getClosestMatch('fécula de maíz'), equals('Maicena'));
    });

    test('nutella is organized under Untables in Despensa, Aceites y Salsas', () {
      final despensa = catalog.categories.firstWhere((c) => c.id == 'despensa_aceites');
      final untables = despensa.children.firstWhere((c) => c.id == 'untables');
      expect(untables.name, equals('Untables'));
      expect(untables.allLeafNames, contains('Nutella'));

      final basicos = despensa.children.firstWhere((c) => c.id == 'basicos');
      expect(basicos.allLeafNames, isNot(contains('Nutella')));
    });

    test('ingredients in subcategories are ordered alphabetically with generic first if present', () {
      // Pollo: generic Pollo first, then Alitas, Cuadriles, etc.
      final pollo = catalog.categories
          .firstWhere((c) => c.id == 'proteinas')
          .children
          .firstWhere((c) => c.id == 'pollo');
      final polloNames = pollo.children.map((c) => c.name).toList();
      expect(polloNames.first, equals('Pollo'));
      final remainingPollo = polloNames.sublist(1);
      final sortedPollo = List<String>.from(remainingPollo)..sort();
      expect(remainingPollo, equals(sortedPollo));

      // Res: generic Carne de res first, then alphabetical
      final res = catalog.categories
          .firstWhere((c) => c.id == 'proteinas')
          .children
          .firstWhere((c) => c.id == 'res');
      final resNames = res.children.map((c) => c.name).toList();
      expect(resNames.first, equals('Carne de res'));
      final remainingRes = resNames.sublist(1);
      final sortedRes = List<String>.from(remainingRes)..sort();
      expect(remainingRes, equals(sortedRes));

      // Verduras para cocido y guisos: no generic, all alphabetical
      final cocido = catalog.categories
          .firstWhere((c) => c.id == 'verduras')
          .children
          .firstWhere((c) => c.id == 'verduras_cocido_guisos');
      final cocidoNames = cocido.children.map((c) => c.name).toList();
      final sortedCocido = List<String>.from(cocidoNames)..sort();
      expect(cocidoNames, equals(sortedCocido));
    });

    test('ingredients can appear in multiple categories and resolve to identical canonical name', () {
      // Cilantro appears in both Hierbas y montes and Hierbas frescas
      final hierbasMontes = catalog.categories
          .firstWhere((c) => c.id == 'verduras')
          .children
          .firstWhere((c) => c.id == 'hierbas_montes');
      final hierbasFrescas = catalog.categories
          .firstWhere((c) => c.id == 'hierbas_especias')
          .children
          .firstWhere((c) => c.id == 'hierbas_frescas');

      expect(hierbasMontes.allLeafNames, contains('Cilantro'));
      expect(hierbasFrescas.allLeafNames, contains('Cilantro'));

      // Lookup and suggestions resolve to the identical single canonical name
      expect(catalog.getClosestMatch('cilantro'), equals('Cilantro'));
      expect(catalog.getClosestMatch('culantro'), equals('Cilantro'));

      // allIngredients list deduplicates leaves
      final cilantroCount = catalog.allIngredients.where((i) => i == 'Cilantro').length;
      expect(cilantroCount, equals(1));
    });
  });
}

