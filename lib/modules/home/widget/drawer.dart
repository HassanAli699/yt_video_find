import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SearchSuggestionDrawer extends StatelessWidget {
  final bool usePlaceName;
  final List<String> searchSuggestions;
  final String selectedSuggestion;
  final ValueChanged<bool> onTogglePlaceName;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback onCloseDrawer;
  final  void Function(String, int) onDeleteSuggestion;
  final TextEditingController newSuggestionController;
  final VoidCallback onAddSuggestion;

  const SearchSuggestionDrawer({
    super.key,
    required this.usePlaceName,
    required this.searchSuggestions,
    required this.selectedSuggestion,
    required this.onTogglePlaceName,
    required this.onSuggestionSelected,
    required this.onCloseDrawer,
    required this.onDeleteSuggestion,
    required this.newSuggestionController,
    required this.onAddSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Obx(
            ()=> Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Search Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SwitchListTile(
                  title: const Text("Use Place name in search"),
                  value: usePlaceName,
                  onChanged: onTogglePlaceName,
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Search Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = searchSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      leading: Radio<String>(
                        value: suggestion,
                        groupValue: selectedSuggestion,
                        onChanged: (value) {
                          onSuggestionSelected(value!);
                          onCloseDrawer();
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.delete_solid, color: Colors.redAccent),
                        onPressed: () => onDeleteSuggestion(suggestion, index),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.black45)),
                      SizedBox(width: 10),
                      Text("OR"),
                      SizedBox(width: 10),
                      Expanded(child: Divider(color: Colors.black45)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newSuggestionController,
                          decoration: InputDecoration(
                            suffixIcon: TextButton(
                              onPressed: onAddSuggestion,
                              child: const Icon(CupertinoIcons.add, color: Colors.black, size: 24),
                            ),
                            hintText: 'Add Suggestions...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
