import 'package:flutter/material.dart';
import 'package:wonwonw2/models/service_category.dart';

class ServiceCategoryProvider extends ChangeNotifier {
  List<ServiceCategory> _categories = [];
  ServiceCategory? _selectedCategory;
  SubService? _selectedSubService;
  String _currentLanguage = 'th'; // 'th' or 'en'

  ServiceCategoryProvider() {
    _loadCategories();
  }

  void _loadCategories() {
    _categories = ServiceCategories.getCategories();
    notifyListeners();
  }

  List<ServiceCategory> get categories => _categories;
  ServiceCategory? get selectedCategory => _selectedCategory;
  SubService? get selectedSubService => _selectedSubService;
  String get currentLanguage => _currentLanguage;

  void selectCategory(String categoryId) {
    _selectedCategory = _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => throw Exception('Category not found'),
    );
    _selectedSubService = null;
    notifyListeners();
  }

  void selectSubService(String subServiceId) {
    if (_selectedCategory == null) {
      throw Exception('No category selected');
    }
    _selectedSubService = _selectedCategory!.subServices.firstWhere(
      (subService) => subService.id == subServiceId,
      orElse: () => throw Exception('Sub service not found'),
    );
    notifyListeners();
  }

  void setLanguage(String language) {
    if (language != 'th' && language != 'en') {
      throw Exception('Invalid language');
    }
    _currentLanguage = language;
    notifyListeners();
  }

  String getLocalizedName(dynamic item) {
    if (item is ServiceCategory) {
      return _currentLanguage == 'th' ? item.nameTh : item.nameEn;
    } else if (item is SubService) {
      return _currentLanguage == 'th' ? item.nameTh : item.nameEn;
    }
    throw Exception('Invalid item type');
  }

  String? getLocalizedDescription(SubService subService) {
    return _currentLanguage == 'th'
        ? subService.descriptionTh
        : subService.descriptionEn;
  }

  void clearSelection() {
    _selectedCategory = null;
    _selectedSubService = null;
    notifyListeners();
  }
}
