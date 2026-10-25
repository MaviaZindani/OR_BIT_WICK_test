import 'package:equatable/equatable.dart';

/// One entry of `/products/categories`. [slug] is what the category endpoint
/// and the product payload's `category` field use; [name] is for display.
class CategoryModel extends Equatable {
  final String slug;
  final String name;

  const CategoryModel({required this.slug, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String? ?? '';
    return CategoryModel(slug: slug, name: json['name'] as String? ?? slug);
  }

  @override
  List<Object?> get props => [slug, name];
}
