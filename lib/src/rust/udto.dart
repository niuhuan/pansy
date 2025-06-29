// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class UiAppendToDownload {
  final PlatformInt64 illustId;
  final String illustTitle;
  final String illustType;
  final PlatformInt64 imageIdx;
  final String squareMedium;
  final String medium;
  final String large;
  final String original;

  const UiAppendToDownload({
    required this.illustId,
    required this.illustTitle,
    required this.illustType,
    required this.imageIdx,
    required this.squareMedium,
    required this.medium,
    required this.large,
    required this.original,
  });

  @override
  int get hashCode =>
      illustId.hashCode ^
      illustTitle.hashCode ^
      illustType.hashCode ^
      imageIdx.hashCode ^
      squareMedium.hashCode ^
      medium.hashCode ^
      large.hashCode ^
      original.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiAppendToDownload &&
          runtimeType == other.runtimeType &&
          illustId == other.illustId &&
          illustTitle == other.illustTitle &&
          illustType == other.illustType &&
          imageIdx == other.imageIdx &&
          squareMedium == other.squareMedium &&
          medium == other.medium &&
          large == other.large &&
          original == other.original;
}

class UiDownloading {
  final String hash;
  final PlatformInt64 illustId;
  final String illustTitle;
  final String illustType;
  final PlatformInt64 imageIdx;
  final String squareMedium;
  final String medium;
  final String large;
  final String original;
  final int downloadStatus;
  final String errorMsg;

  const UiDownloading({
    required this.hash,
    required this.illustId,
    required this.illustTitle,
    required this.illustType,
    required this.imageIdx,
    required this.squareMedium,
    required this.medium,
    required this.large,
    required this.original,
    required this.downloadStatus,
    required this.errorMsg,
  });

  @override
  int get hashCode =>
      hash.hashCode ^
      illustId.hashCode ^
      illustTitle.hashCode ^
      illustType.hashCode ^
      imageIdx.hashCode ^
      squareMedium.hashCode ^
      medium.hashCode ^
      large.hashCode ^
      original.hashCode ^
      downloadStatus.hashCode ^
      errorMsg.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiDownloading &&
          runtimeType == other.runtimeType &&
          hash == other.hash &&
          illustId == other.illustId &&
          illustTitle == other.illustTitle &&
          illustType == other.illustType &&
          imageIdx == other.imageIdx &&
          squareMedium == other.squareMedium &&
          medium == other.medium &&
          large == other.large &&
          original == other.original &&
          downloadStatus == other.downloadStatus &&
          errorMsg == other.errorMsg;
}

class UiIllustRankQuery {
  final String mode;
  final String date;

  const UiIllustRankQuery({required this.mode, required this.date});

  @override
  int get hashCode => mode.hashCode ^ date.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiIllustRankQuery &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          date == other.date;
}

class UiIllustSearchQuery {
  final String mode;
  final String word;

  const UiIllustSearchQuery({required this.mode, required this.word});

  @override
  int get hashCode => mode.hashCode ^ word.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiIllustSearchQuery &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          word == other.word;
}

class UiLoginByCodeQuery {
  final String code;
  final String verify;

  const UiLoginByCodeQuery({required this.code, required this.verify});

  @override
  int get hashCode => code.hashCode ^ verify.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiLoginByCodeQuery &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          verify == other.verify;
}
