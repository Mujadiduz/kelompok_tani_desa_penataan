import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class UbahPasswordPage extends StatefulWidget {
  final String nik;

  const UbahPasswordPage({
    super.key,
    required this.nik,
  });

  @override
  State<UbahPasswordPage> createState() =>
      _UbahPasswordPageState();
}

class _UbahPasswordPageState
    extends State<UbahPasswordPage> {
  static const Color primaryGreen =
      Color(0xff2E7D32);
  static const Color deepTeal =
      Color(0xff0E5F57);
  static const Color teal =
      Color(0xff167A6B);
  static const Color tealLight =
      Color(0xff248C76);
  static const Color blue =
      Color(0xff326FA3);
  static const Color redColor =
      Color(0xffC83B3B);

  static const Color softGreen =
      Color(0xffE9F5EB);
  static const Color softTeal =
      Color(0xffE6F4F1);
  static const Color softBlue =
      Color(0xffEAF3FA);

  static const Color pageBackground =
      Color(0xffF2F7F5);
  static const Color cardBorder =
      Color(0xffE0E8E5);
  static const Color textDark =
      Color(0xff18212B);
  static const Color textGrey =
      Color(0xff66727F);
  static const Color textSoft =
      Color(0xff8B96A2);

  final TextEditingController oldPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  final DatabaseReference anggotaRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('anggota');

  bool isLoading = false;
  bool hideOldPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final oldPassword =
        oldPasswordController.text.trim();

    final newPassword =
        newPasswordController.text.trim();

    final confirmPassword =
        confirmPasswordController.text.trim();

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showSnack(
        'Semua kolom wajib diisi.',
        redColor,
        Icons.warning_amber_rounded,
      );
      return;
    }

    if (newPassword.length < 6) {
      showSnack(
        'Password baru minimal 6 karakter.',
        redColor,
        Icons.lock_clock_outlined,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showSnack(
        'Konfirmasi password tidak sama.',
        redColor,
        Icons.password_rounded,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await anggotaRef
          .orderByChild('nik')
          .equalTo(widget.nik.trim())
          .get()
          .timeout(
            const Duration(seconds: 12),
          );

      if (!mounted) return;

      if (!snapshot.exists ||
          snapshot.value == null) {
        showSnack(
          'Data anggota tidak ditemukan.',
          redColor,
          Icons.person_off_outlined,
        );
        return;
      }

      final data =
          Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final memberId =
          data.keys.first.toString();

      final member =
          Map<dynamic, dynamic>.from(
        data.values.first as Map,
      );

      final currentPassword =
          (member['password'] ?? '')
              .toString()
              .trim();

      if (oldPassword != currentPassword) {
        showSnack(
          'Password lama salah.',
          redColor,
          Icons.lock_outline_rounded,
        );
        return;
      }

      await anggotaRef
          .child(memberId)
          .update({
            'password': newPassword,
            'tanggal_ubah_password':
                DateTime.now().toIso8601String(),
          })
          .timeout(
            const Duration(seconds: 12),
          );

      if (!mounted) return;

      await showSuccessDialog();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      showSnack(
        'Gagal mengubah password. Periksa koneksi internet.',
        redColor,
        Icons.wifi_off_rounded,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showSnack(
    String message,
    Color color,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .clearSnackBars();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(
          17,
          0,
          17,
          17,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> showSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(25),
              border: Border.all(
                color: cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: deepTeal.withValues(
                    alpha: 0.14,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration:
                      const BoxDecoration(
                    color: softGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .verified_user_rounded,
                    color: primaryGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Password Berhasil Diubah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Gunakan password baru saat '
                  'login berikutnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.7,
                    height: 1.45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 19),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 12,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.viewInsetsOf(context)
            .bottom;

    final width =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding =
        width < 340 ? 13.0 : 17.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _UserDashboardBackground(),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context)
                        .unfocus();
                  },
                  child: SafeArea(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior
                              .onDrag,
                      physics:
                          const BouncingScrollPhysics(),
                      padding:
                          EdgeInsets.fromLTRB(
                        horizontalPadding,
                        13,
                        horizontalPadding,
                        bottomInset + 28,
                      ),
                      children: [
                        Center(
                          child:
                              ConstrainedBox(
                            constraints:
                                const BoxConstraints(
                              maxWidth: 720,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .stretch,
                              children: [
                                _header(),
                                const SizedBox(
                                  height: 14,
                                ),
                                _securityBanner(),
                                const SizedBox(
                                  height: 14,
                                ),
                                _formCard(),
                                const SizedBox(
                                  height: 14,
                                ),
                                _submitButton(),
                                const SizedBox(
                                  height: 12,
                                ),
                                _securityCaption(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
            tealLight,
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.20,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -45,
              child: Container(
                height: 105,
                width: 105,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                  child: InkWell(
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.14,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                        border: Border.all(
                          color: Colors.white
                              .withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Ubah Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Perbarui keamanan akun TaniGo',
                        maxLines: 1,
                        overflow: TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          color: Color(
                            0xffD1FAE5,
                          ),
                          fontSize: 10.7,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.14,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    border: Border.all(
                      color: Colors.white
                          .withValues(
                        alpha: 0.16,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .security_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: blue.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.045,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Lindungi akun Anda',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12.8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Gunakan password yang sulit '
                  'ditebak dan berbeda dari '
                  'password sebelumnya.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10.3,
                    height: 1.38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        15,
      ),
      decoration:
          _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Password',
            style: TextStyle(
              color: textDark,
              fontSize: 16.5,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Masukkan password lama dan '
            'password baru Anda.',
            style: TextStyle(
              color: textGrey,
              fontSize: 10.2,
              height: 1.35,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          _passwordField(
            label: 'Password Lama',
            hintText:
                'Masukkan password saat ini',
            controller:
                oldPasswordController,
            hidden: hideOldPassword,
            icon: Icons
                .lock_outline_rounded,
            color: teal,
            fillColor: softTeal,
            autofillHints: const [
              AutofillHints.password,
            ],
            onTap: () {
              setState(
                () => hideOldPassword =
                    !hideOldPassword,
              );
            },
            textInputAction:
                TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _passwordField(
            label: 'Password Baru',
            hintText:
                'Minimal 6 karakter',
            controller:
                newPasswordController,
            hidden: hideNewPassword,
            icon:
                Icons.password_rounded,
            color: blue,
            fillColor: softBlue,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            onTap: () {
              setState(
                () => hideNewPassword =
                    !hideNewPassword,
              );
            },
            textInputAction:
                TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _passwordField(
            label:
                'Konfirmasi Password Baru',
            hintText:
                'Ulangi password baru',
            controller:
                confirmPasswordController,
            hidden:
                hideConfirmPassword,
            icon: Icons
                .verified_user_outlined,
            color: primaryGreen,
            fillColor: softGreen,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            onTap: () {
              setState(
                () =>
                    hideConfirmPassword =
                        !hideConfirmPassword,
              );
            },
            textInputAction:
                TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) {
                changePassword();
              }
            },
          ),
          const SizedBox(height: 14),
          _requirementBox(),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required String hintText,
    required TextEditingController
        controller,
    required bool hidden,
    required IconData icon,
    required Color color,
    required Color fillColor,
    required VoidCallback onTap,
    List<String>? autofillHints,
    TextInputAction textInputAction =
        TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      enabled: !isLoading,
      obscureText: hidden,
      keyboardType:
          TextInputType.visiblePassword,
      textInputAction:
          textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: textDark,
        fontSize: 13.8,
        fontWeight:
            FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Container(
            height: 38,
            width: 38,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.95,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(
          minWidth: 58,
          minHeight: 58,
        ),
        suffixIcon: IconButton(
          onPressed:
              isLoading ? null : onTap,
          icon: Icon(
            hidden
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
            color: textGrey,
            size: 21,
          ),
        ),
        filled: true,
        fillColor: fillColor.withValues(
          alpha: 0.70,
        ),
        labelStyle: const TextStyle(
          color: textGrey,
          fontSize: 11.5,
          fontWeight:
              FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: textSoft,
          fontSize: 11.2,
          fontWeight:
              FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide(
            color: color.withValues(
              alpha: 0.12,
            ),
          ),
        ),
        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: cardBorder,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(17),
          borderSide: BorderSide(
            color: color,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _requirementBox() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(
          0xffF7FAF9,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .check_circle_outline_rounded,
                color: teal,
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                'Ketentuan password',
                style: TextStyle(
                  color: textDark,
                  fontSize: 10.8,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _RequirementItem(
            text:
                'Minimal terdiri dari 6 karakter',
          ),
          SizedBox(height: 5),
          _RequirementItem(
            text:
                'Password baru harus sama dengan konfirmasi',
          ),
          SizedBox(height: 5),
          _RequirementItem(
            text:
                'Jangan bagikan password kepada siapa pun',
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            isLoading ? null : changePassword,
        style:
            ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              teal.withValues(
            alpha: 0.42,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Menyimpan...',
                    style: TextStyle(
                      fontSize: 13.8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .save_outlined,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Simpan Password',
                    style: TextStyle(
                      fontSize: 14.2,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _securityCaption() {
    return const Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: textSoft,
          size: 14,
        ),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Password disimpan untuk keamanan akun TaniGo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSoft,
              fontSize: 9.7,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(
            alpha: 0.055,
          ),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _RequirementItem
    extends StatelessWidget {
  final String text;

  const _RequirementItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 2,
          ),
          child: Icon(
            Icons.circle,
            color: Color(0xff8B96A2),
            size: 5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xff66727F),
              fontSize: 9.8,
              height: 1.35,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserDashboardBackground
    extends StatelessWidget {
  const _UserDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

            final baseSize =
                width < height
                    ? width
                    : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(
                      280.0,
                      460.0,
                    )
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.68)
                    .clamp(
                      190.0,
                      330.0,
                    )
                    .toDouble();

            final smallCircle =
                (baseSize * 0.42)
                    .clamp(
                      120.0,
                      205.0,
                    )
                    .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin: Alignment
                            .topCenter,
                        end: Alignment
                            .bottomCenter,
                        colors: [
                          Color(
                            0xff0E5F57,
                          ),
                          Color(
                            0xff177A6B,
                          ),
                          Color(
                            0xffDDEFEA,
                          ),
                          Color(
                            0xffF2F7F5,
                          ),
                        ],
                        stops: [
                          0,
                          0.22,
                          0.49,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top:
                        -largeCircle *
                            0.54,
                    right:
                        -largeCircle *
                            0.29,
                    child:
                        _DashboardCircle(
                      size:
                          largeCircle,
                      color:
                          const Color(
                        0xff53B69C,
                      ),
                      alpha: 0.20,
                      borderColor:
                          Colors.white,
                    ),
                  ),
                  Positioned(
                    top:
                        -smallCircle *
                            0.12,
                    left:
                        -smallCircle *
                            0.24,
                    child:
                        _DashboardRing(
                      size:
                          smallCircle,
                      color:
                          Colors.white,
                    ),
                  ),
                  Positioned(
                    top:
                        height * 0.28,
                    left:
                        -mediumCircle *
                            0.57,
                    child:
                        _DashboardCircle(
                      size:
                          mediumCircle,
                      color:
                          const Color(
                        0xffA9DCCF,
                      ),
                      alpha: 0.38,
                      borderColor:
                          const Color(
                        0xff167A6B,
                      ),
                    ),
                  ),
                  Positioned(
                    top:
                        height * 0.48,
                    right:
                        -mediumCircle *
                            0.61,
                    child:
                        _DashboardCircle(
                      size:
                          mediumCircle *
                              1.08,
                      color:
                          const Color(
                        0xffE6F2F8,
                      ),
                      alpha: 0.84,
                      borderColor:
                          const Color(
                        0xff326FA3,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -largeCircle *
                            0.52,
                    left:
                        -largeCircle *
                            0.30,
                    child:
                        _DashboardCircle(
                      size:
                          largeCircle,
                      color:
                          const Color(
                        0xffDDEFE5,
                      ),
                      alpha: 0.82,
                      borderColor:
                          const Color(
                        0xff2E7D32,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -mediumCircle *
                            0.36,
                    right:
                        -mediumCircle *
                            0.43,
                    child:
                        _DashboardCircle(
                      size:
                          mediumCircle,
                      color:
                          const Color(
                        0xffEAF3FA,
                      ),
                      alpha: 0.88,
                      borderColor:
                          const Color(
                        0xff326FA3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _DashboardCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: alpha,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color:
              borderColor.withValues(
            alpha: 0.08,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _DashboardRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _DashboardRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
          width: 2,
        ),
      ),
    );
  }
}
