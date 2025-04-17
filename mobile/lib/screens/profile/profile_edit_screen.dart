import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/config/constants.dart';
import 'package:instagram_clone/models/auth.dart';
import 'package:instagram_clone/services/auth.dart';
import 'package:instagram_clone/state/global_state_provider.dart';
import 'package:instagram_clone/theme/theme.dart';
import 'package:instagram_clone/widgets/core/clickable_list_item.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(globalStateProvider).user;
      if (user != null) {
        nameController.text = user.name ?? '';
        usernameController.text = user.username ?? '';
        emailController.text = user.email ?? '';
        phoneController.text = user.phone ?? '';
        bioController.text = user.bio ?? '';
        setState(() {
          selectedGender = user.gender;
        });
      }
    });
  }

  Future<void> onNewProfilePicture() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
          ),
        ],
      );

      if (cropped == null) return;

      await AuthService.updateAvatar(localFilePath: cropped.path);
      final userResponse = await AuthService.getMe();
      ref.read(globalStateProvider.notifier).setUser(userResponse.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  Future<void> onProfilePictureRemove() async {
    try {
      await AuthService.updateAvatar(removeAvatar: true);
      final userResponse = await AuthService.getMe();
      ref.read(globalStateProvider.notifier).setUser(userResponse.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      }
    }
  }

  void showProfilePhotoChangeModal({UserResponseData? user}) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (_) => SizedBox(
        height: 120,
        child: Column(
          children: [
            ClickableListItem(
              prefixIcon: Icons.photo,
              text: 'New Profile Picture',
              onTap: () {
                Navigator.pop(context);
                onNewProfilePicture();
              },
            ),
            if (user?.avatar != 'default-profile.png')
              ClickableListItem(
                text: 'Remove Current Picture',
                textColor: Colors.red,
                prefixIcon: Icons.delete,
                onTap: () {
                  Navigator.pop(context);
                  onProfilePictureRemove();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> onUpdateProfileInformation() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final user = ref.read(globalStateProvider).user;
      await AuthService.updateUserDetails(
        name: nameController.text,
        username: usernameController.text,
        email: emailController.text,
        phone: phoneController.text,
        bio: bioController.text,
        gender: selectedGender ?? '',
        isPrivateAccount: user?.isPrivateAccount ?? false,
      );

      final userResponse = await AuthService.getMe();
      ref.read(globalStateProvider.notifier).setUser(userResponse.data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(globalStateProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPagePadding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: '$apiUrl/avatar/${user?.avatar}',
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorWidget: (_, __, ___) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showProfilePhotoChangeModal(user: user),
                child: const Text('Change Profile Photo'),
              ),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildTextField(nameController, 'Name'),
                    _buildTextField(usernameController, 'Username'),
                    _buildTextField(emailController, 'Email'),
                    _buildTextField(phoneController, 'Phone',
                        hint: 'Add Phone Number'),
                    _buildTextField(bioController, 'Bio',
                        hint: 'Add a Bio', maxLength: 150),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        filled: false,
                        hintText: 'Gender',
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      value: selectedGender,
                      icon: const Icon(Icons.arrow_drop_down_sharp),
                      elevation: 16,
                      onChanged: (value) =>
                          setState(() => selectedGender = value),
                      validator: (value) => selectedGender == null
                          ? 'Please, Select your Gender'
                          : null,
                      items: ['Male', 'Female'].map((value) {
                        return DropdownMenuItem(
                            value: value, child: Text(value));
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onUpdateProfileInformation,
                child: const Text('Update Profile'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          filled: false,
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please, Enter your $label'.toLowerCase();
          }
          return null;
        },
      ),
    );
  }
}
