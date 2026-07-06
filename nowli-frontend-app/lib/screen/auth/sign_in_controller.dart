import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInController extends GetxController {
  final emailController = TextEditingController(text: "");
  final passwordController = TextEditingController(text: "");

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  var obscurePassword = true.obs;
  var isButtonEnabled = false.obs;
  var isEmailValid = true.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() => _onEmailChanged(emailController.text));
    passwordController.addListener(_validateForm);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  void _validateForm() {
    final isValid =
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        _isValidEmail(emailController.text);

    if (isValid != isButtonEnabled.value) {
      isButtonEnabled.value = isValid;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  void _onEmailChanged(String value) {
    final valid = value.isEmpty || _isValidEmail(value);
    if (valid != isEmailValid.value) {
      isEmailValid.value = valid;
    }
    _validateForm();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
}
