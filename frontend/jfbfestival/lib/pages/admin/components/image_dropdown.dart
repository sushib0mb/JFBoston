import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/db_image_service.dart';

class ImageDropdown extends StatefulWidget {
  const ImageDropdown({
    super.key,
    required this.folderPath,
    required this.label,
    required this.onChanged, // 1. The bridge to your parent widget
    required this.errorMessage, // 2. The red error text
    this.initialValue, // 3. Useful if editing an existing performance
  });

  final String folderPath;
  final String label;
  final ValueChanged<String?> onChanged;
  final String errorMessage;
  final String? initialValue;

  @override
  _ImageDropdownState createState() => _ImageDropdownState();
}

class _ImageDropdownState extends State<ImageDropdown> {
  String? _selectedIconUrl;

  @override
  void initState() {
    super.initState();
    // Set the initial value if one was provided
    _selectedIconUrl = widget.initialValue;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DbImageService>().fetchFolder(widget.folderPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<DbImageService>(
      builder: (context, iconService, child) {
        if (iconService.isLoading(widget.folderPath)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (iconService.getErrorFor(widget.folderPath) != null) {
          return Text('Error: ${iconService.getErrorFor(widget.folderPath)}');
        }

        if (iconService.getUrlsFor(widget.folderPath).isEmpty) {
          return const Text('No icons found in storage.');
        }

        if (_selectedIconUrl != null &&
            !iconService
                .getUrlsFor(widget.folderPath)
                .contains(_selectedIconUrl)) {
          _selectedIconUrl = null;
        }

        // 4. Wrap the whole thing in a FormField!
        return FormField<String>(
          initialValue: _selectedIconUrl,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return widget.errorMessage;
            }
            return null;
          },
          builder: (FormFieldState<String> state) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: widget.label,
                errorText:
                    state
                        .errorText, // 5. This makes the border turn red automatically!
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIconUrl,
                  hint: const Text('Select an image'),
                  isExpanded: true,
                  menuMaxHeight: screenHeight * 0.4,
                  items:
                      iconService.getUrlsFor(widget.folderPath).map((
                        String url,
                      ) {
                        final fileName = url.split('/').last.split('?').first;
                        return DropdownMenuItem<String>(
                          value: url,
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                width: 30,
                                height: 30,
                                fit: BoxFit.contain,
                                placeholder:
                                    (context, url) => const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => const Icon(
                                      Icons.broken_image,
                                      size: 30,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  Uri.decodeFull(fileName),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedIconUrl = newValue;
                    });
                    // 6. Tell the FormField that the data changed
                    state.didChange(newValue);
                    // 7. Pass the URL back up to your parent widget!
                    widget.onChanged(newValue);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
