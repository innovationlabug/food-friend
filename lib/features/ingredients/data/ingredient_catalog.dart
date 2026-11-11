import '../../../core/utils/string_normalizer.dart';
import '../domain/category_node.dart';

/// Predefined Spanish ingredient catalog with hierarchical taxonomy (up to 3-4 levels)
/// and real-time search / auto-suggestion capabilities.
class IngredientCatalog {
  IngredientCatalog._();

  /// Global singleton instance.
  static final IngredientCatalog instance = IngredientCatalog._();

  /// Hierarchical taxonomy organized by culinary categories.
  /// Max depth is strictly <= 4 levels.
  final List<CategoryNode> categories = const [
    CategoryNode(
      id: 'verduras',
      name: 'Verduras y Vegetales',
      children: [
        CategoryNode(
          id: 'verduras_cocido_guisos',
          name: 'Verduras para cocido y guisos',
          children: [
            CategoryNode(id: 'guisquil', name: 'Güisquil', synonyms: ['chayote']),
            CategoryNode(id: 'perulero', name: 'Perulero', synonyms: ['chayote blanco']),
            CategoryNode(id: 'ayote', name: 'Ayote', synonyms: ['calabaza']),
            CategoryNode(id: 'pipian', name: 'Pipían'),
            CategoryNode(id: 'calabacita', name: 'Calabacita', synonyms: ['zucchini']),
            CategoryNode(id: 'zanahoria', name: 'Zanahoria'),
            CategoryNode(id: 'papa', name: 'Papa', synonyms: ['patata']),
            CategoryNode(id: 'yuca', name: 'Yuca', synonyms: ['mandioca']),
            CategoryNode(id: 'camote', name: 'Camote', synonyms: ['batata']),
            CategoryNode(id: 'elote', name: 'Elote', synonyms: ['maíz tierno', 'choclo']),
            CategoryNode(id: 'brocoli', name: 'Brócoli'),
            CategoryNode(id: 'coliflor', name: 'Coliflor'),
          ],
        ),
        CategoryNode(
          id: 'verduras_ensalada',
          name: 'Verduras para ensalada',
          children: [
            CategoryNode(id: 'tomate', name: 'Tomate'),
            CategoryNode(id: 'miltomate', name: 'Miltomate', synonyms: ['tomate verde']),
            CategoryNode(id: 'pepino', name: 'Pepino'),
            CategoryNode(id: 'aguacate', name: 'Aguacate', synonyms: ['palta']),
            CategoryNode(id: 'lechuga', name: 'Lechuga'),
            CategoryNode(id: 'rabano', name: 'Rábano'),
            CategoryNode(id: 'remolacha', name: 'Remolacha', synonyms: ['betabel']),
            CategoryNode(id: 'repollo_blanco', name: 'Repollo blanco', synonyms: ['col']),
            CategoryNode(id: 'repollo_morado', name: 'Repollo morado'),
            CategoryNode(id: 'berenjena', name: 'Berenjena'),
            CategoryNode(id: 'champinones', name: 'Champiñones', synonyms: ['hongos', 'setas']),
          ],
        ),
        CategoryNode(
          id: 'cebollas_chiles',
          name: 'Cebollas, ajos y chiles',
          children: [
            CategoryNode(id: 'cebolla_blanca', name: 'Cebolla blanca'),
            CategoryNode(id: 'cebolla_morada', name: 'Cebolla morada'),
            CategoryNode(id: 'cebolla_tallo', name: 'Cebolla con tallo', synonyms: ['cebollín']),
            CategoryNode(id: 'ajo', name: 'Ajo'),
            CategoryNode(id: 'puerro', name: 'Puerro', synonyms: ['ajoporro']),
            CategoryNode(id: 'chile_pimiento', name: 'Chile pimiento', synonyms: ['pimiento dulce', 'pimentón']),
            CategoryNode(id: 'chile_jalapeno', name: 'Chile jalapeño'),
            CategoryNode(id: 'chile_serrano', name: 'Chile serrano'),
          ],
        ),
        CategoryNode(
          id: 'hierbas_montes',
          name: 'Hierbas y montes',
          children: [
            CategoryNode(id: 'cilantro', name: 'Cilantro', synonyms: ['culantro']),
            CategoryNode(id: 'perejil', name: 'Perejil'),
            CategoryNode(id: 'hierbabuena', name: 'Hierbabuena'),
            CategoryNode(id: 'epazote', name: 'Epazote', synonyms: ['apazote']),
            CategoryNode(id: 'samat', name: 'Samat', synonyms: ['alcapate', 'culantro coyote']),
            CategoryNode(id: 'albahaca', name: 'Albahaca'),
            CategoryNode(id: 'apio', name: 'Apio'),
            CategoryNode(id: 'espinaca', name: 'Espinaca'),
            CategoryNode(id: 'acelga', name: 'Acelga'),
            CategoryNode(id: 'berro', name: 'Berro'),
          ],
        ),
        CategoryNode(
          id: 'legumbres_frescas',
          name: 'Ejotes y arvejas',
          children: [
            CategoryNode(id: 'ejote', name: 'Ejote', synonyms: ['judía verde', 'habichuela']),
            CategoryNode(id: 'arveja', name: 'Arveja', synonyms: ['chícharo']),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'proteinas',
      name: 'Proteínas y Carnes',
      children: [
        CategoryNode(
          id: 'pollo',
          name: 'Pollo',
          children: [
            CategoryNode(id: 'pechuga_pollo', name: 'Pechuga de pollo'),
            CategoryNode(id: 'alitas_pollo', name: 'Alitas de pollo'),
            CategoryNode(id: 'muslos_pollo', name: 'Muslos de pollo'),
            CategoryNode(id: 'cuadriles_pollo', name: 'Cuadriles de pollo'),
            CategoryNode(id: 'pollo_entero', name: 'Pollo entero'),
            CategoryNode(id: 'pollo_desmenuzado', name: 'Pollo desmenuzado'),
            CategoryNode(id: 'menudos_pollo', name: 'Menudos de pollo'),
            CategoryNode(id: 'pollo_generico', name: 'Pollo'),
          ],
        ),
        CategoryNode(
          id: 'res',
          name: 'Res',
          children: [
            CategoryNode(id: 'carne_molida_res', name: 'Carne molida de res'),
            CategoryNode(id: 'posta_res', name: 'Posta de res'),
            CategoryNode(id: 'costilla_res', name: 'Costilla de res'),
            CategoryNode(id: 'bolovique', name: 'Bolovique'),
            CategoryNode(id: 'lomo_res', name: 'Lomo de res'),
            CategoryNode(id: 'cecina', name: 'Cecina'),
            CategoryNode(id: 'hueso_res', name: 'Hueso con carne de res'),
            CategoryNode(id: 'carne_res_generico', name: 'Carne de res'),
          ],
        ),
        CategoryNode(
          id: 'cerdo',
          name: 'Cerdo',
          children: [
            CategoryNode(id: 'chuleta_cerdo', name: 'Chuleta de cerdo'),
            CategoryNode(id: 'costilla_cerdo', name: 'Costilla de cerdo'),
            CategoryNode(id: 'lomo_cerdo', name: 'Lomo de cerdo'),
            CategoryNode(id: 'posta_cerdo', name: 'Posta de cerdo'),
            CategoryNode(id: 'tocino', name: 'Tocino', synonyms: ['bacon', 'panceta']),
            CategoryNode(id: 'chicharron', name: 'Chicharrón'),
            CategoryNode(id: 'carne_cerdo_generico', name: 'Carne de cerdo'),
          ],
        ),
        CategoryNode(
          id: 'pescados_mariscos',
          name: 'Pescados y Mariscos',
          children: [
            CategoryNode(id: 'filete_tilapia', name: 'Filete de tilapia'),
            CategoryNode(id: 'filete_robalo', name: 'Filete de robalo'),
            CategoryNode(id: 'camarones', name: 'Camarones'),
            CategoryNode(id: 'atun_lata', name: 'Atún en lata'),
            CategoryNode(id: 'salmon', name: 'Salmón'),
            CategoryNode(id: 'mojarra', name: 'Mojarra entera'),
          ],
        ),
        CategoryNode(
          id: 'embutidos_carnes_frias',
          name: 'Embutidos y carnes frías',
          children: [
            CategoryNode(id: 'longaniza_guatemalteca', name: 'Longaniza guatemalteca'),
            CategoryNode(id: 'chorizo_negro', name: 'Chorizo negro'),
            CategoryNode(id: 'chorizo_colorado', name: 'Chorizo colorado'),
            CategoryNode(id: 'salchicha', name: 'Salchicha'),
            CategoryNode(id: 'jamon', name: 'Jamón'),
            CategoryNode(id: 'jamon_pavo', name: 'Jamón de pavo'),
            CategoryNode(id: 'salami', name: 'Salami'),
            CategoryNode(id: 'mortadela', name: 'Mortadela'),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'granos_cereales',
      name: 'Granos, Cereales y Harinas',
      children: [
        CategoryNode(
          id: 'frijoles',
          name: 'Frijoles',
          children: [
            CategoryNode(id: 'frijoles_negros', name: 'Frijoles negros'),
            CategoryNode(id: 'frijoles_colorados', name: 'Frijoles colorados'),
            CategoryNode(id: 'frijoles_blancos', name: 'Frijoles blancos'),
            CategoryNode(id: 'frijol_vara', name: 'Frijol de vara'),
            CategoryNode(id: 'frijol_generico', name: 'Frijol'),
          ],
        ),
        CategoryNode(
          id: 'arroz',
          name: 'Arroz',
          children: [
            CategoryNode(id: 'arroz_blanco', name: 'Arroz blanco'),
            CategoryNode(id: 'arroz_precocido', name: 'Arroz precocido'),
            CategoryNode(id: 'arroz_integral', name: 'Arroz integral'),
            CategoryNode(id: 'arroz_generico', name: 'Arroz'),
          ],
        ),
        CategoryNode(
          id: 'harinas_masas',
          name: 'Harinas y Masas',
          children: [
            CategoryNode(id: 'masa_maiz', name: 'Masa de maíz'),
            CategoryNode(id: 'harina_maiz', name: 'Harina de maíz', synonyms: ['maseca']),
            CategoryNode(id: 'harina_trigo', name: 'Harina de trigo'),
            CategoryNode(id: 'maicena', name: 'Fécula de maíz', synonyms: ['maicena']),
          ],
        ),
        CategoryNode(
          id: 'pastas',
          name: 'Pastas',
          children: [
            CategoryNode(id: 'fideos', name: 'Fideos'),
            CategoryNode(id: 'espagueti', name: 'Espagueti'),
            CategoryNode(id: 'coditos', name: 'Coditos'),
            CategoryNode(id: 'pasta_generica', name: 'Pasta'),
          ],
        ),
        CategoryNode(
          id: 'cereales',
          name: 'Cereales',
          children: [
            CategoryNode(id: 'avena_hojuelas', name: 'Avena en hojuelas'),
            CategoryNode(id: 'avena_molida', name: 'Avena molida'),
            CategoryNode(id: 'avena_generica', name: 'Avena'),
          ],
        ),
        CategoryNode(
          id: 'legumbres_secas',
          name: 'Lentejas y garbanzos',
          children: [
            CategoryNode(id: 'lentejas', name: 'Lentejas'),
            CategoryNode(id: 'garbanzos', name: 'Garbanzos'),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'lacteos_huevos',
      name: 'Lácteos y Huevos',
      children: [
        CategoryNode(
          id: 'huevos',
          name: 'Huevos',
          children: [
            CategoryNode(id: 'huevos_gallina', name: 'Huevos de gallina'),
            CategoryNode(id: 'huevos_generico', name: 'Huevos'),
          ],
        ),
        CategoryNode(
          id: 'leche',
          name: 'Leches',
          children: [
            CategoryNode(id: 'leche_entera', name: 'Leche entera'),
            CategoryNode(id: 'leche_descremada', name: 'Leche descremada'),
            CategoryNode(id: 'leche_deslactosada', name: 'Leche deslactosada'),
            CategoryNode(id: 'leche_evaporada', name: 'Leche evaporada'),
            CategoryNode(id: 'leche_condensada', name: 'Leche condensada'),
            CategoryNode(id: 'leche_generica', name: 'Leche'),
          ],
        ),
        CategoryNode(
          id: 'quesos_crema',
          name: 'Quesos y crema',
          children: [
            CategoryNode(id: 'queso_fresco', name: 'Queso fresco'),
            CategoryNode(id: 'queso_seco', name: 'Queso seco'),
            CategoryNode(id: 'queso_capas', name: 'Queso de capas'),
            CategoryNode(id: 'queso_crema', name: 'Queso crema'),
            CategoryNode(id: 'queso_mozzarella', name: 'Queso mozzarella'),
            CategoryNode(id: 'queso_gouda', name: 'Queso gouda', synonyms: ['gouda']),
            CategoryNode(id: 'queso_parmesano', name: 'Queso parmesano', synonyms: ['parmesano', 'queso parmesano rallado']),
            CategoryNode(id: 'queso_cheddar', name: 'Queso cheddar', synonyms: ['cheddar']),
            CategoryNode(id: 'crema_pura', name: 'Crema pura'),
            CategoryNode(id: 'crema_fresca', name: 'Crema fresca'),
            CategoryNode(id: 'queso_generico', name: 'Queso'),
          ],
        ),
        CategoryNode(
          id: 'mantequillas_margarinas',
          name: 'Mantequilla y margarina',
          children: [
            CategoryNode(id: 'mantequilla', name: 'Mantequilla'),
            CategoryNode(id: 'margarina', name: 'Margarina'),
          ],
        ),
        CategoryNode(
          id: 'yogurt',
          name: 'Yogurt',
          children: [
            CategoryNode(id: 'yogur_natural', name: 'Yogur natural'),
            CategoryNode(id: 'yogur_griego', name: 'Yogur griego'),
            CategoryNode(id: 'yogur_fresa', name: 'Yogur de fresa'),
            CategoryNode(id: 'yogur_generico', name: 'Yogur'),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'frutas',
      name: 'Frutas',
      children: [
        CategoryNode(
          id: 'citricos',
          name: 'Cítricos',
          children: [
            CategoryNode(id: 'limon_criollo', name: 'Limón criollo'),
            CategoryNode(id: 'limon_persa', name: 'Limón persa'),
            CategoryNode(id: 'limon_generico', name: 'Limón'),
            CategoryNode(id: 'naranja', name: 'Naranja'),
            CategoryNode(id: 'mandarina', name: 'Mandarina'),
          ],
        ),
        CategoryNode(
          id: 'tropicales',
          name: 'Tropicales',
          children: [
            CategoryNode(id: 'platano_maduro', name: 'Plátano maduro'),
            CategoryNode(id: 'platano_verde', name: 'Plátano verde'),
            CategoryNode(id: 'platano_generico', name: 'Plátano'),
            CategoryNode(id: 'banano', name: 'Banano', synonyms: ['guineo', 'banana']),
            CategoryNode(id: 'pina', name: 'Piña', synonyms: ['ananá']),
            CategoryNode(id: 'papaya', name: 'Papaya'),
            CategoryNode(id: 'mango', name: 'Mango'),
            CategoryNode(id: 'sandia', name: 'Sandía'),
            CategoryNode(id: 'melon', name: 'Melón'),
          ],
        ),
        CategoryNode(
          id: 'frutas_arbol',
          name: 'Otras Frutas',
          children: [
            CategoryNode(id: 'manzana_roja', name: 'Manzana roja'),
            CategoryNode(id: 'manzana_verde', name: 'Manzana verde'),
            CategoryNode(id: 'manzana_generica', name: 'Manzana'),
            CategoryNode(id: 'fresa', name: 'Fresa', synonyms: ['frutilla']),
            CategoryNode(id: 'mora', name: 'Mora'),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'hierbas_especias',
      name: 'Hierbas, Especias y Condimentos',
      children: [
        CategoryNode(
          id: 'hierbas_frescas',
          name: 'Hierbas frescas',
          children: [
            CategoryNode(id: 'cilantro', name: 'Cilantro', synonyms: ['culantro']),
            CategoryNode(id: 'perejil', name: 'Perejil'),
            CategoryNode(id: 'hierbabuena', name: 'Hierbabuena'),
            CategoryNode(id: 'epazote', name: 'Epazote', synonyms: ['apazote']),
            CategoryNode(id: 'samat', name: 'Samat', synonyms: ['alcapate', 'culantro coyote']),
            CategoryNode(id: 'albahaca', name: 'Albahaca'),
            CategoryNode(id: 'apio', name: 'Apio'),
          ],
        ),
        CategoryNode(
          id: 'hierbas_secas',
          name: 'Hierbas secas',
          children: [
            CategoryNode(id: 'laurel', name: 'Laurel'),
            CategoryNode(id: 'tomillo', name: 'Tomillo'),
            CategoryNode(id: 'oregano_seco', name: 'Orégano seco'),
            CategoryNode(id: 'romero', name: 'Romero'),
          ],
        ),
        CategoryNode(
          id: 'especias',
          name: 'Especias',
          children: [
            CategoryNode(id: 'canela_raja', name: 'Canela en raja'),
            CategoryNode(id: 'canela_polvo', name: 'Canela en polvo'),
            CategoryNode(id: 'canela_generica', name: 'Canela'),
            CategoryNode(id: 'pimienta_gorda', name: 'Pimienta gorda'),
            CategoryNode(id: 'pimienta_negra', name: 'Pimienta negra molida'),
            CategoryNode(id: 'comino_molido', name: 'Comino molido'),
            CategoryNode(id: 'achiote', name: 'Achiote en pasta'),
            CategoryNode(id: 'clavos_olor', name: 'Clavos de olor'),
            CategoryNode(id: 'curry', name: 'Curry', synonyms: ['curry en polvo']),
            CategoryNode(id: 'paprika', name: 'Páprika', synonyms: ['paprika en polvo', 'pimentón dulce']),
            CategoryNode(id: 'jengibre', name: 'Jengibre', synonyms: ['jengibre en polvo']),
            CategoryNode(id: 'curcuma', name: 'Cúrcuma', synonyms: ['curcuma en polvo', 'curcuma']),
          ],
        ),
        CategoryNode(
          id: 'chiles_secos',
          name: 'Chiles secos',
          children: [
            CategoryNode(id: 'chile_pasa', name: 'Chile pasa'),
            CategoryNode(id: 'chile_guaque', name: 'Chile guaque'),
            CategoryNode(id: 'chile_cobanero', name: 'Chile cobanero'),
          ],
        ),
        CategoryNode(
          id: 'sazonadores',
          name: 'Sazonadores y Caldos',
          children: [
            CategoryNode(id: 'consome_pollo', name: 'Consomé de pollo'),
            CategoryNode(id: 'sal_ajo', name: 'Sal de ajo'),
            CategoryNode(id: 'sal_cebolla', name: 'Sal de cebolla'),
          ],
        ),
      ],
    ),
    CategoryNode(
      id: 'frutos_secos_semillas',
      name: 'Frutos secos y semillas',
      children: [
        CategoryNode(id: 'nueces', name: 'Nueces', synonyms: ['nuez', 'nueces de nogal', 'nuez de castilla']),
        CategoryNode(id: 'mani', name: 'Maní', synonyms: ['cacahuate', 'cacahuates', 'mani tostado', 'manies']),
        CategoryNode(id: 'almendras', name: 'Almendras', synonyms: ['almendra']),
        CategoryNode(id: 'semillas_maranon', name: 'Semillas de marañón', synonyms: ['marañón', 'anacardos']),
        CategoryNode(id: 'pepitona', name: 'Pepitona', synonyms: ['semilla de ayote', 'pepitas']),
        CategoryNode(id: 'ajonjoli', name: 'Ajonjolí', synonyms: ['sésamo']),
        CategoryNode(id: 'pasas', name: 'Pasas', synonyms: ['uvas pasas', 'pasitas']),
        CategoryNode(id: 'semillas_girasol', name: 'Semillas de girasol', synonyms: ['pipas']),
      ],
    ),
    CategoryNode(
      id: 'despensa_aceites',
      name: 'Despensa, Aceites y Salsas',
      children: [
        CategoryNode(
          id: 'aceites_grasas',
          name: 'Aceites y Grasas',
          children: [
            CategoryNode(id: 'aceite_vegetal', name: 'Aceite vegetal'),
            CategoryNode(id: 'aceite_oliva', name: 'Aceite de oliva'),
            CategoryNode(id: 'aceite_maiz', name: 'Aceite de maíz'),
            CategoryNode(id: 'manteca_vegetal', name: 'Manteca vegetal'),
          ],
        ),
        CategoryNode(
          id: 'basicos',
          name: 'Básicos de cocina',
          children: [
            CategoryNode(id: 'sal_yodada', name: 'Sal yodada'),
            CategoryNode(id: 'sal_marina', name: 'Sal marina'),
            CategoryNode(id: 'sal_generica', name: 'Sal'),
            CategoryNode(id: 'azucar_blanca', name: 'Azúcar blanca'),
            CategoryNode(id: 'azucar_morena', name: 'Azúcar morena'),
            CategoryNode(id: 'panela', name: 'Panela', synonyms: ['rapadura']),
            CategoryNode(id: 'nutella', name: 'Nutella'),
          ],
        ),
        CategoryNode(
          id: 'vinagres_salsas',
          name: 'Vinagres y Salsas',
          children: [
            CategoryNode(id: 'vinagre_blanco', name: 'Vinagre blanco'),
            CategoryNode(id: 'vinagre_manzana', name: 'Vinagre de manzana'),
            CategoryNode(id: 'salsa_soya', name: 'Salsa de soya'),
            CategoryNode(id: 'salsa_inglesa', name: 'Salsa inglesa'),
            CategoryNode(id: 'salsa_dulce', name: 'Salsa dulce', synonyms: ['ketchup']),
            CategoryNode(id: 'pasta_tomate', name: 'Pasta de tomate'),
            CategoryNode(id: 'mostaza', name: 'Mostaza'),
            CategoryNode(id: 'mayonesa', name: 'Mayonesa'),
          ],
        ),
      ],
    ),
  ];

  /// Flattened list of all selectable unique ingredient names.
  late final List<String> allIngredients = _extractAllLeaves();

  /// Normalized map connecting normalized names and synonyms to the canonical name.
  late final Map<String, String> _lookupMap = _buildLookupMap();

  List<String> _extractAllLeaves() {
    final leaves = <String>{};
    for (final cat in categories) {
      leaves.addAll(cat.allLeafNames);
    }
    final sorted = leaves.toList()..sort();
    return List.unmodifiable(sorted);
  }

  Map<String, String> _buildLookupMap() {
    final map = <String, String>{};

    void visit(CategoryNode node) {
      if (node.isLeaf) {
        map[StringNormalizer.normalize(node.name)] = node.name;
        for (final syn in node.synonyms) {
          map[StringNormalizer.normalize(syn)] = node.name;
        }
      } else {
        for (final child in node.children) {
          visit(child);
        }
      }
    }

    for (final cat in categories) {
      visit(cat);
    }
    return map;
  }

  /// Searches for ingredient suggestions matching [query].
  /// Matches are case- and accent-insensitive, matching anywhere in the name or synonyms.
  /// Results are prioritized:
  /// 1. Exact matches / starts-with matches first
  /// 2. Word boundary / substring matches second
  List<String> searchSuggestions(String query, {int limit = 10}) {
    final normalizedQuery = StringNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) return const [];

    final startsWith = <String>[];
    final contains = <String>[];
    final seen = <String>{};

    for (final name in allIngredients) {
      final normName = StringNormalizer.normalize(name);

      if (normName == normalizedQuery) {
        if (seen.add(name)) startsWith.insert(0, name);
      } else if (normName.startsWith(normalizedQuery)) {
        if (seen.add(name)) startsWith.add(name);
      } else if (normName.contains(normalizedQuery)) {
        if (seen.add(name)) contains.add(name);
      }
    }

    // Also check synonyms
    for (final entry in _lookupMap.entries) {
      if (seen.contains(entry.value)) continue;

      if (entry.key.startsWith(normalizedQuery)) {
        if (seen.add(entry.value)) startsWith.add(entry.value);
      } else if (entry.key.contains(normalizedQuery)) {
        if (seen.add(entry.value)) contains.add(entry.value);
      }
    }

    final combined = [...startsWith, ...contains];
    if (combined.length > limit) {
      return combined.sublist(0, limit);
    }
    return combined;
  }

  /// Returns the closest matching catalog ingredient name for the given [input].
  /// If [input] is empty, returns null.
  /// Uses a combined heuristic:
  /// 1. Exact normalized match.
  /// 2. First search suggestion if any exist.
  /// 3. Minimum Levenshtein distance across all catalog names and synonyms.
  String? getClosestMatch(String input) {
    final normalized = StringNormalizer.normalize(input);
    if (normalized.isEmpty) return null;

    // 1. Direct match in lookup map (including synonyms)
    if (_lookupMap.containsKey(normalized)) {
      return _lookupMap[normalized];
    }

    // 2. Suggestions check
    final suggestions = searchSuggestions(input, limit: 1);
    if (suggestions.isNotEmpty) {
      return suggestions.first;
    }

    // 3. Levenshtein distance fallback
    String? closestName;
    int minDistance = 999999;

    for (final name in allIngredients) {
      final normName = StringNormalizer.normalize(name);
      final dist = _levenshtein(normalized, normName);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = name;
      }
    }

    return closestName ?? (allIngredients.isNotEmpty ? allIngredients.first : null);
  }

  /// Calculates Levenshtein edit distance between two normalized strings.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;
    final distanceMatrix = List.generate(
      rows,
      (i) => List<int>.filled(cols, 0),
    );

    for (int i = 0; i < rows; i++) {
      distanceMatrix[i][0] = i;
    }
    for (int j = 0; j < cols; j++) {
      distanceMatrix[0][j] = j;
    }

    for (int i = 1; i < rows; i++) {
      for (int j = 1; j < cols; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        distanceMatrix[i][j] = [
          distanceMatrix[i - 1][j] + 1, // deletion
          distanceMatrix[i][j - 1] + 1, // insertion
          distanceMatrix[i - 1][j - 1] + cost, // substitution
        ].reduce((curr, next) => curr < next ? curr : next);
      }
    }

    return distanceMatrix[a.length][b.length];
  }
}

