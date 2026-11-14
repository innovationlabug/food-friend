import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../data/fridge_vision_service.dart';
import '../data/ingredient_storage_service.dart';
import '../domain/fridge_detected_item.dart';
import '../domain/ingredient.dart';

/// Screen allowing the user to photograph or upload a picture of their
/// refrigerator or pantry to automatically detect cooking ingredients (US-3.2).
class FridgeScannerScreen extends StatefulWidget {
  const FridgeScannerScreen({
    super.key,
    this.storageService,
    this.visionService,
    this.imagePicker,
    this.initialImageBytes,
  });

  final IngredientStorageService? storageService;
  final FridgeVisionService? visionService;
  final ImagePicker? imagePicker;
  final Uint8List? initialImageBytes;

  static Future<List<Ingredient>?> navigate(
    BuildContext context, {
    IngredientStorageService? storageService,
    FridgeVisionService? visionService,
    ImagePicker? imagePicker,
    Uint8List? initialImageBytes,
  }) {
    return Navigator.of(context).push<List<Ingredient>>(
      MaterialPageRoute(
        builder: (_) => FridgeScannerScreen(
          storageService: storageService,
          visionService: visionService,
          imagePicker: imagePicker,
          initialImageBytes: initialImageBytes,
        ),
      ),
    );
  }

  @override
  State<FridgeScannerScreen> createState() => _FridgeScannerScreenState();
}

class _FridgeScannerScreenState extends State<FridgeScannerScreen> {
  late final IngredientStorageService _storageService;
  late final FridgeVisionService _visionService;
  late final ImagePicker _imagePicker;

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _errorMessage;
  List<FridgeDetectedItem> _items = [];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    _visionService = widget.visionService ?? FridgeVisionService();
    _imagePicker = widget.imagePicker ?? ImagePicker();

    if (widget.initialImageBytes != null &&
        widget.initialImageBytes!.isNotEmpty) {
      _processImage(widget.initialImageBytes!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      await _processImage(bytes);
    } catch (e) {
      setState(() {
        _errorMessage =
            'No se pudo acceder a la cámara o galería. Puedes reintentar o usar el ingreso manual.';
      });
    }
  }

  Future<void> _loadSamplePhoto(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      await _processImage(bytes);
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo cargar la imagen de prueba.';
      });
    }
  }

  int _confidenceRank(String confidence) {
    switch (confidence.trim().toLowerCase()) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 1;
    }
  }

  List<FridgeDetectedItem> _sortItemsByConfidence(List<FridgeDetectedItem> items) {
    final indexed = items.asMap().entries.toList();
    indexed.sort((a, b) {
      final diff = _confidenceRank(a.value.confidence)
          .compareTo(_confidenceRank(b.value.confidence));
      if (diff != 0) return diff;
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }

  Future<void> _processImage(Uint8List bytes) async {
    setState(() {
      _imageBytes = bytes;
      _isLoading = true;
      _errorMessage = null;
      _items = [];
    });

    final result = await _visionService.detectFridgeIngredients(bytes);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isLoading = false;
        _items = _sortItemsByConfidence(result.items);
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ??
            'Ocurrió un error al analizar la fotografía. Por favor intenta de nuevo o agrega tus ingredientes manualmente.';
      });
    }
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isSelected: !_items[index].isSelected,
      );
    });
  }

  void _selectAll() {
    setState(() {
      _items = _items.map((it) => it.copyWith(isSelected: true)).toList();
    });
  }

  void _deselectAll() {
    setState(() {
      _items = _items.map((it) => it.copyWith(isSelected: false)).toList();
    });
  }

  Future<void> _confirmSelected() async {
    final selected = _items.where((it) => it.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un ingrediente para agregar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newIngredients = selected
        .map((it) => Ingredient(name: it.standardIngredient))
        .toList();

    await _storageService.addIngredients(newIngredients);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se agregaron ${newIngredients.length} ingredientes a tu despensa',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop(newIngredients);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = _items.where((it) => it.isSelected).length;

    return Scaffold(
      drawer: const AppNavigationDrawer(
        settingsSection: SettingsSection.ingredients,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text(
          'Escanear refrigerador',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? _buildLoadingState(theme, colorScheme)
              : _errorMessage != null
                  ? _buildErrorState(theme, colorScheme)
                  : _items.isNotEmpty
                      ? _buildResultsState(theme, colorScheme, selectedCount)
                      : _buildInitialPromptState(theme, colorScheme),
        ),
      ),
      bottomNavigationBar: (!_isLoading && _items.isNotEmpty)
          ? _buildBottomBar(theme, colorScheme, selectedCount)
          : null,
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Analizando alimentos en tu refrigerador...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Identificando marcas locales e ingredientes para tu cocina.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                assetName: 'alert',
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo completar el análisis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_imageBytes != null) {
                        _processImage(_imageBytes!);
                      } else {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    icon: AppSvgIcon(
                      assetName: 'refresh',
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    label: const Text('Reintentar'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: AppSvgIcon(
                      assetName: 'edit',
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                    label: const Text('Ingresar manualmente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialPromptState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppSvgIcon(
                    assetName: 'fridge',
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Detectar ingredientes por foto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toma una foto clara o sube una imagen de tu refrigerador o alacena para detectar automáticamente los productos disponibles.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: AppSvgIcon(
              assetName: 'camera',
              size: 18,
              color: colorScheme.onPrimary,
            ),
            label: const Text('Tomar foto con la cámara'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: AppSvgIcon(
              assetName: 'image',
              size: 18,
              color: colorScheme.primary,
            ),
            label: const Text('Elegir foto de la galería / archivo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'O prueba con una foto de ejemplo:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: AppSvgIcon(
              assetName: 'image',
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Refrigerador completo'),
            subtitle: const Text('Alimentos, salsas Ducal/Campero, lácteos y bebidas'),
            trailing: AppSvgIcon(
              assetName: 'chevron_right',
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _loadSamplePhoto(
              'assets/samples/fridge/sample03_refrigerator.jpeg',
            ),
          ),
          ListTile(
            leading: AppSvgIcon(
              assetName: 'snowflake',
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Congelador'),
            subtitle: const Text('Carnes y productos congelados'),
            trailing: AppSvgIcon(
              assetName: 'chevron_right',
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _loadSamplePhoto(
              'assets/samples/fridge/sample01_freezer.jpeg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsState(
    ThemeData theme,
    ColorScheme colorScheme,
    int selectedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detectados (${_items.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Todos'),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: const Text('Ninguno'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _buildItemCard(theme, colorScheme, item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    ThemeData theme,
    ColorScheme colorScheme,
    FridgeDetectedItem item,
    int index,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    Color confidenceColor;
    switch (item.confidence) {
      case 'high':
        confidenceColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case 'low':
        confidenceColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        break;
      case 'medium':
      default:
        confidenceColor = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: item.isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: item.isSelected,
                onChanged: (_) => _toggleItem(index),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.standardIngredient,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.name}${item.brand != "Genérica" ? " • ${item.brand}" : ""}${item.quantity.isNotEmpty ? " • ${item.quantity}" : ""}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.confidenceLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    ThemeData theme,
    ColorScheme colorScheme,
    int selectedCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: FilledButton.icon(
        onPressed: selectedCount > 0 ? _confirmSelected : null,
        icon: AppSvgIcon(
          assetName: 'check',
          size: 18,
          color: selectedCount > 0
              ? colorScheme.onPrimary
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        label: Text('Agregar seleccionados ($selectedCount)'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
