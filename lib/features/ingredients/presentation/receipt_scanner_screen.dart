import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../data/ingredient_storage_service.dart';
import '../data/receipt_parser_service.dart';
import '../domain/ingredient.dart';
import '../domain/receipt_food_item.dart';

/// Screen allowing the user to photograph or upload a supermarket receipt
/// to automatically extract food items and populate their pantry (US-3.4).
class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({
    super.key,
    this.storageService,
    this.parserService,
    this.imagePicker,
    this.initialImageBytes,
  });

  final IngredientStorageService? storageService;
  final ReceiptParserService? parserService;
  final ImagePicker? imagePicker;
  final Uint8List? initialImageBytes;

  static Future<List<Ingredient>?> navigate(
    BuildContext context, {
    IngredientStorageService? storageService,
    ReceiptParserService? parserService,
    ImagePicker? imagePicker,
    Uint8List? initialImageBytes,
  }) {
    return Navigator.of(context).push<List<Ingredient>>(
      MaterialPageRoute(
        builder: (_) => ReceiptScannerScreen(
          storageService: storageService,
          parserService: parserService,
          imagePicker: imagePicker,
          initialImageBytes: initialImageBytes,
        ),
      ),
    );
  }

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  late final IngredientStorageService _storageService;
  late final ReceiptParserService _parserService;
  late final ImagePicker _imagePicker;

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _errorMessage;
  String? _supermarket;
  double? _totalFacturaGtq;
  double? _totalAlimentosGtq;
  List<ReceiptFoodItem> _items = [];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    _parserService = widget.parserService ?? ReceiptParserService();
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
    } catch (_) {
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
        _errorMessage = 'No se pudo cargar la imagen de prueba del recibo.';
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

  List<ReceiptFoodItem> _sortItemsByConfidence(List<ReceiptFoodItem> items) {
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
      _supermarket = null;
      _totalFacturaGtq = null;
      _totalAlimentosGtq = null;
    });

    final result = await _parserService.parseReceipt(bytes);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isLoading = false;
        _items = _sortItemsByConfidence(result.items);
        _supermarket = result.supermarket;
        _totalFacturaGtq = result.totalFacturaGtq;
        _totalAlimentosGtq = result.totalAlimentosGtq;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage ??
            'Ocurrió un error al procesar el recibo. Por favor intenta de nuevo o agrega tus ingredientes manualmente.';
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
          content: Text('Selecciona al menos un alimento para agregar'),
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
      appBar: AppBar(
        title: const Text('Escanear recibo'),
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
              'Digitalizando recibo de supermercado...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Interpretando abreviaturas de supermercado y extrayendo precios en Quetzales (Q).',
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
              Icon(
                Icons.receipt_long,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo procesar el recibo',
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
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.edit),
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
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Extraer alimentos de factura / ticket',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toma una foto clara de tu recibo de supermercado para agregar automáticamente los alimentos comprados ignorando artículos de limpieza.',
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
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar foto del recibo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Elegir foto del recibo de la galería'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'O prueba con un recibo de ejemplo:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Recibo Despensa / Multiproducto'),
            subtitle: const Text('Arroz, frijol, fideos, embutidos y artículos del hogar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadSamplePhoto(
              'assets/samples/receipt/sample02.jpg',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Recibo Walmart'),
            subtitle: const Text('Productos naturales y semillas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _loadSamplePhoto(
              'assets/samples/receipt/sample01.jpg',
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
        if (_supermarket != null || _totalAlimentosGtq != null)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _supermarket ?? 'Supermercado',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_totalAlimentosGtq != null)
                          Text(
                            'Alimentos: Q ${_totalAlimentosGtq!.toStringAsFixed(2)}${_totalFacturaGtq != null ? " (Total factura: Q ${_totalFacturaGtq!.toStringAsFixed(2)})" : ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alimentos detectados (${_items.length})',
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
    ReceiptFoodItem item,
    int index,
  ) {
    Color confidenceColor;
    switch (item.confidence) {
      case 'high':
        confidenceColor = Colors.green.shade700;
        break;
      case 'low':
        confidenceColor = Colors.grey.shade600;
        break;
      case 'medium':
      default:
        confidenceColor = Colors.amber.shade800;
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
                      '${item.rawName}${item.unitCount > 1 ? " (${item.unitCount} unidades)" : ""}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.formattedPrice != null)
                    Text(
                      item.formattedPrice!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.confidenceLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
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
