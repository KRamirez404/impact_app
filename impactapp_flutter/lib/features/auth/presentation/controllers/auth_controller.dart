import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../infrastructure/models/user_model.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';

class AuthController extends GetxController {
  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.repository,
    required this.storage,
  });

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final AuthRepositoryImpl repository;
  final GetStorage storage;

  final isLoading = false.obs;
  final user = Rxn<UserEntity>();

  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }

  void showSuccess(String msg) {
    Get.snackbar(
      'Éxito',
      msg,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> loadUserFromStorage() async {
    final cached = storage.read<String>(StorageKeys.user);
    if (cached != null) {
      user.value = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
  }

  Future<void> checkSession() async {
    final token = storage.read<String>(StorageKeys.token);
    if (token == null || token.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    try {
      isLoading.value = true;
      user.value = await repository.me();
      Get.offAllNamed(AppRoutes.home);
    } catch (_) {
      logout();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String correo, String contrasena) async {
    try {
      isLoading.value = true;
      await loginUseCase(correo, contrasena);
      user.value = await repository.me();
      showSuccess('Bienvenido a ImpactApp');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    String? telefono,
  }) async {
    try {
      isLoading.value = true;
      await registerUseCase(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        contrasena: contrasena,
        telefono: telefono,
      );
      showSuccess('Registro exitoso');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await storage.remove(StorageKeys.token);
    await storage.remove(StorageKeys.user);
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}

