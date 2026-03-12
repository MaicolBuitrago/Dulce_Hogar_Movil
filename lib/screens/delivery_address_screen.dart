// lib/screens/delivery_address_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/address_service.dart';
import '../utils/formatters.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});
  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  List<DireccionEntrega> _addresses = [];
  bool _loading         = true;
  bool _showForm        = false;
  bool _savingAddress   = false;
  int? _selectedId;

  final _newAddressCtrl = TextEditingController();

  // Argumentos recibidos desde carrito o detalle de producto
  List<ProductoCheckout> _productos = [];
  String _source = 'carrito';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _productos = (args['productos'] as List<ProductoCheckout>?) ?? [];
      _source    = args['source'] as String? ?? 'carrito';
    }
    _loadAddresses();
  }

  @override
  void dispose() {
    _newAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final r = await AddressService.getDirecciones();
    if (!mounted) return;
    setState(() {
      _addresses  = r.data ?? [];
      _selectedId = _addresses.isNotEmpty ? _addresses.first.iddireccion : null;
      _loading    = false;
    });
  }

  Future<void> _saveAddress() async {
    final text = _newAddressCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _savingAddress = true);
    final r = await AddressService.agregar(text);
    if (!mounted) return;
    setState(() => _savingAddress = false);
    if (r.ok && r.data != null) {
      setState(() {
        _addresses.add(r.data!);
        _selectedId = r.data!.iddireccion;
        _showForm   = false;
        _newAddressCtrl.clear();
      });
    } else {
      _showSnack(r.error ?? 'Error al guardar dirección');
    }
  }

  Future<void> _deleteAddress(int id) async {
    final r = await AddressService.eliminar(id);
    if (!mounted) return;
    if (r.ok) {
      setState(() {
        _addresses.removeWhere((a) => a.iddireccion == id);
        if (_selectedId == id) _selectedId = _addresses.isNotEmpty ? _addresses.first.iddireccion : null;
      });
    } else {
      _showSnack(r.error ?? 'No se puede eliminar');
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  void _continuar() {
    if (_selectedId == null) { _showSnack('Selecciona una dirección'); return; }
    Navigator.of(context).pushNamed('/payment', arguments: {
      'productos': _productos,
      'source': _source,
      'iddireccion': _selectedId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: _showForm ? _buildForm() : _buildAddressList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingS),
    child: Row(
      children: [
        GestureDetector(
          onTap: _showForm ? () => setState(() => _showForm = false) : () => Navigator.of(context).maybePop(),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Text(_showForm ? 'Nueva dirección' : 'Dirección de entrega', style: AppTextStyles.headlineMedium),
      ],
    ),
  );

  Widget _buildAddressList() => Column(
    children: [
      // Lista de direcciones
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusL), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona una dirección', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppDimensions.paddingM),
            if (_addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                child: Center(child: Text('No tienes direcciones guardadas', style: AppTextStyles.bodyMedium)),
              )
            else
              ..._addresses.map((addr) {
                final isSelected = _selectedId == addr.iddireccion;
                return GestureDetector(
                  onTap: () => setState(() => _selectedId = addr.iddireccion),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2)),
                          child: isSelected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary))) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(addr.direccion, style: AppTextStyles.bodyMedium)),
                        GestureDetector(
                          onTap: () => _deleteAddress(addr.iddireccion),
                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Agregar nueva
            GestureDetector(
              onTap: () => setState(() => _showForm = true),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Agregar nueva dirección', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: AppDimensions.paddingL),

      ElevatedButton(
        onPressed: _selectedId != null ? _continuar : null,
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continuar'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)]),
      ),
    ],
  );

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Nueva dirección de entrega', style: AppTextStyles.headlineMedium),
      const SizedBox(height: AppDimensions.paddingM),
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dirección completa *', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _newAddressCtrl,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(hintText: 'Calle 10 #9-04, Caicedonia, Valle del Cauca', prefixIcon: Icon(Icons.home_outlined, color: AppColors.textHint, size: AppDimensions.iconS)),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppDimensions.paddingL),
      Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _showForm = false), child: const Text('Cancelar'))),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _savingAddress ? null : _saveAddress,
              child: _savingAddress ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar'),
            ),
          ),
        ],
      ),
    ],
  );
}
