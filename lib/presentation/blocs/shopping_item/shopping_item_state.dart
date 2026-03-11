import 'package:equatable/equatable.dart';
import '../../../data/models/shopping_item_model.dart';

sealed class ShoppingItemState extends Equatable {
  const ShoppingItemState();

  @override
  List<Object?> get props => [];
}

final class ShoppingItemLoading extends ShoppingItemState {
  const ShoppingItemLoading();
}

final class ShoppingItemLoaded extends ShoppingItemState {
  final List<ShoppingItemModel> items;
  final String listId;
  final int version;

  const ShoppingItemLoaded({
    required this.items,
    required this.listId,
    required this.version,
  });

  @override
  List<Object?> get props => [listId, version];
}

final class ShoppingItemError extends ShoppingItemState {
  final String message;

  const ShoppingItemError(this.message);

  @override
  List<Object?> get props => [message];
}
