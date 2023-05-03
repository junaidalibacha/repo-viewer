import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/infrastructure/sembast_database.dart';

final sembasetProvider = Provider((ref) => SembastDatabase());

final dioProvider = Provider((ref) => Dio());
