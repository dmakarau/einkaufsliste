import 'package:equatable/equatable.dart';
import '../../../data/models/shopping_list_model.dart';

sealed class ShoppingListState extends Equatable {
  const ShoppingListState();

  @override
  List<Object?> get props => [];
}

final class ShoppingListLoading extends ShoppingListState {
  const ShoppingListLoading();
}

final class ShoppingListLoaded extends ShoppingListState {
  final List<ShoppingListModel> lists;

  const ShoppingListLoaded(this.lists);

  @override
  List<Object?> get props => [lists];
}

final class ShoppingListError extends ShoppingListState {
  final String message;

  const ShoppingListError(this.message);

  @override
  List<Object?> get props => [message];
}
