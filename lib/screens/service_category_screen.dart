import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonwonw2/providers/service_category_provider.dart';
import 'package:wonwonw2/models/service_category.dart';
import 'package:wonwonw2/widgets/lazy_loading_image.dart';

class ServiceCategoryScreen extends StatelessWidget {
  const ServiceCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceCategoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              provider.currentLanguage == 'th' ? 'บริการ' : 'Services',
            ),
            actions: [
              IconButton(
                icon: Icon(
                  provider.currentLanguage == 'th'
                      ? Icons.language
                      : Icons.language,
                ),
                onPressed: () {
                  provider.setLanguage(
                    provider.currentLanguage == 'th' ? 'en' : 'th',
                  );
                },
              ),
            ],
          ),
          body:
              provider.selectedCategory == null
                  ? _buildCategoryGrid(provider)
                  : _buildSubServiceList(provider),
        );
      },
    );
  }

  Widget _buildCategoryGrid(ServiceCategoryProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _buildCategoryCard(provider, category);
      },
    );
  }

  Widget _buildCategoryCard(
    ServiceCategoryProvider provider,
    ServiceCategory category,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => provider.selectCategory(category.id),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LazyLoadingImage(
              imageUrl: category.icon,
              width: 64,
              height: 64,
              placeholder: const Icon(Icons.image, size: 64),
              errorWidget: const Icon(Icons.error, size: 64),
            ),
            const SizedBox(height: 8),
            Text(
              provider.getLocalizedName(category),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubServiceList(ServiceCategoryProvider provider) {
    final category = provider.selectedCategory!;
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => provider.clearSelection(),
          ),
          title: Text(provider.getLocalizedName(category)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: category.subServices.length,
            itemBuilder: (context, index) {
              final subService = category.subServices[index];
              return _buildSubServiceCard(provider, subService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubServiceCard(
    ServiceCategoryProvider provider,
    SubService subService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => provider.selectSubService(subService.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LazyLoadingImage(
                    imageUrl: subService.icon,
                    width: 48,
                    height: 48,
                    placeholder: const Icon(Icons.image, size: 48),
                    errorWidget: const Icon(Icons.error, size: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      provider.getLocalizedName(subService),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subService.descriptionTh != null) ...[
                const SizedBox(height: 8),
                Text(
                  provider.getLocalizedDescription(subService) ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
