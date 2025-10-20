// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'piece_inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PieceInventory _$PieceInventoryFromJson(Map<String, dynamic> json) =>
    PieceInventory(
      availablePieces: (json['availablePieces'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$PieceInventoryToJson(PieceInventory instance) =>
    <String, dynamic>{'availablePieces': instance.availablePieces};
