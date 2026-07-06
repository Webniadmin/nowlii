import 'package:flutter/material.dart';
import 'package:nowlii/api/profile_controller.dart';
import 'package:nowlii/api/profile_model.dart';

class ProfileTestScreen extends StatefulWidget {
  const ProfileTestScreen({super.key});

  @override
  State<ProfileTestScreen> createState() => _ProfileTestScreenState();
}

class _ProfileTestScreenState extends State<ProfileTestScreen> {
  final ProfileController _profileController = ProfileController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = "I'm a man";
  String _selectedLanguage = "English";
  String _selectedVoice = "Male";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _profileController.loadCachedProfile();
    if (_profileController.profile != null) {
      setState(() {
        _nameController.text = _profileController.profile!.name;
        _selectedGender = _profileController.profile!.gender;
        _selectedLanguage = _profileController.profile!.language;
        _selectedVoice = _profileController.profile!.voice;
      });
    }
  }

  Future<void> _createProfile() async {
    final success = await _profileController.createProfile(
      name: _nameController.text,
      gender: _selectedGender,
      language: _selectedLanguage,
      voice: _selectedVoice,
      customNowliiName: _nameController.text.toLowerCase().replaceAll(' ', ''),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile created successfully!'
                : 'Error: ${_profileController.errorMessage}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchProfile() async {
    final success = await _profileController.fetchProfile();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile fetched successfully!'
                : 'Error: ${_profileController.errorMessage}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    final success = await _profileController.updateProfile(
      name: _nameController.text,
      gender: _selectedGender,
      language: _selectedLanguage,
      voice: _selectedVoice,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully!'
                : 'Error: ${_profileController.errorMessage}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile API Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Profile Display
            if (_profileController.profile != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Profile:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_profileController.profile!.id}'),
                      Text('Name: ${_profileController.profile!.name}'),
                      Text('Gender: ${_profileController.profile!.gender}'),
                      Text('Language: ${_profileController.profile!.language}'),
                      Text('Voice: ${_profileController.profile!.voice}'),
                      Text('Nowlii Name: ${_profileController.profile!.nowliiName}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: [
                "I'm a man",
                "I'm a woman",
                "Another gender",
              ].map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Language Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: ['English', 'Espanol'].map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Voice Dropdown
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(
                labelText: 'Voice',
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female'].map((voice) {
                return DropdownMenuItem(
                  value: voice,
                  child: Text(voice),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoice = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton(
              onPressed: _profileController.isLoading ? null : _createProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: _profileController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Profile (POST)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _profileController.isLoading ? null : _fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: _profileController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Fetch Profile (GET)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _profileController.isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: _profileController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Update Profile (PATCH)',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            // Error Message
            if (_profileController.errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${_profileController.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
