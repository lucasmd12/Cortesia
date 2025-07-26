import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';

class QRREditScreen extends StatefulWidget {
  final QRRModel qrr;

  const QRREditScreen({super.key, required this.qrr});

  @override
  State<QRREditScreen> createState() => _QRREditScreenState();
}

class _QRREditScreenState extends State<QRREditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late QRRType _selectedType;
  late QRRPriority _selectedPriority;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.qrr.title);
    _descriptionController = TextEditingController(text: widget.qrr.description);

    _selectedType = widget.qrr.type;
    _selectedPriority = widget.qrr.priority;
    _selectedStartDate = widget.qrr.startDate;
    _selectedEndDate = widget.qrr.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime((isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartDate) {
            _selectedStartDate = selectedDateTime;
          } else {
            _selectedEndDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _updateQRR() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final qrrService = Provider.of<QRRService>(context, listen: false);
        final updatedQRRData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'type': _selectedType.toString().split('.').last,
          'priority': _selectedPriority.toString().split('.').last,
          'startTime': _selectedStartDate?.toIso8601String(),
          'endTime': _selectedEndDate?.toIso8601String(),
        };

        await qrrService.updateQRR(widget.qrr.id, updatedQRRData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QRR atualizada com sucesso!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        Logger.error('Erro ao atualizar QRR', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar QRR: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParallaxScaffold(
      backgroundType: ParallaxBackground.qrr,
      appBar: AppBar(
        title: const Text('Editar Missão QRR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título da Missão',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descrição da Missão',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<QRRType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Missão',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: QRRType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<QRRPriority>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Prioridade da Missão',
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: QRRPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ListTile(
                      title: Text(
                        _selectedStartDate == null
                            ? 'Selecionar Data e Hora de Início'
                            : 'Início: ${_formatDateTime(_selectedStartDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, true),
                      tileColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      title: Text(
                        _selectedEndDate == null
                            ? 'Selecionar Data e Hora de Término'
                            : 'Término: ${_formatDateTime(_selectedEndDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, false),
                      tileColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 24.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateQRR,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Atualizar Missão QRR',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
