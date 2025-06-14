import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'search_history_provider.dart';
import '../Data/UserData.dart';
import '../Login/LoginPage.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/app_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Login/preference_selector.dart';
import '../Settings/notifications_preferences.dart';
import '../FCM.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool receiveNotifications = true;
  bool isDarkMode = true;
  bool isUploadMode = false;
  String? pickedFileName;
  bool adapdf = false;

  // Add these variables to track replacement
  String? replacingDocId;
  String? replacingFileName;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    checkResumeExists();
    // Initialize dark mode state from current theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationPreferences.getNotificationsEnabled();
    if (mounted) {
      setState(() {
        receiveNotifications = enabled;
      });
    }
  }

  void _toggleTheme(bool isDark) {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
  }

  Future<void> checkResumeExists() async {
    final snapshot =
    await FirebaseFirestore.instance
        .collection('Student')
        .doc(UserData().id)
        .collection('CV')
        .limit(1)
        .get();

    setState(() {
      adapdf = snapshot.docs.isNotEmpty;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  // Modified _pickFile method to handle replacement
  Future<void> _pickFile({String? replaceDocId, String? replaceFileName}) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      if (file.size <= 200 * 1024) {
        setState(() => pickedFileName = file.name);

        // Different confirmation message for replacement
        final confirmMessage = replaceDocId != null
            ? "Replace $replaceFileName with ${file.name}?"
            : "Confirm upload of ${file.name}?";

        _showConfirmationDialog(confirmMessage, () async {
          try {
            // If replacing, delete the old file first
            if (replaceDocId != null && replaceFileName != null) {
              // Delete from Storage
              await FirebaseStorage.instance
                  .ref()
                  .child('resumes/${UserData().id}_$replaceFileName')
                  .delete();

              // Delete from Firestore
              await FirebaseFirestore.instance
                  .collection('Student')
                  .doc(UserData().id)
                  .collection('CV')
                  .doc(replaceDocId)
                  .delete();
            }

            // Upload new file
            final storageRef = FirebaseStorage.instance.ref().child(
              'resumes/${UserData().id}_${file.name}',
            );
            final uploadTask = await storageRef.putData(file.bytes!);
            final downloadUrl = await storageRef.getDownloadURL();

            // Add new document to Firestore
            await FirebaseFirestore.instance
                .collection('Student')
                .doc(UserData().id)
                .collection('CV')
                .add({
              'url': downloadUrl,
              'uploaded_at': FieldValue.serverTimestamp(),
              'file_name': file.name,
            });

            await checkResumeExists();
            setState(() {
              isUploadMode = false;
              replacingDocId = null;
              replacingFileName = null;
            });

            final successMessage = replaceDocId != null
                ? "File replaced successfully"
                : "Resume uploaded successfully";

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
          } catch (e) {
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text("Operation Failed"),
                content: Text(e.toString()),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        });
      } else {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text("File too large"),
            content: Text("Please select a file smaller than 200 KB."),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(String title, VoidCallback onConfirm) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        actions: [
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Yes"),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MyTheme.getSettingsSectionTitleColor(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final displayLabel =
    label == "Dark Mode" ? (value ? "Dark Mode" : "Light Mode") : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MyTheme.getSettingsTextColor(isDarkMode),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor:
            isDarkMode ? Color(0xFFB4C975) : Color(0xFFAFDAAA),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 10, top: 0),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: MyTheme.getSettingsTextColor(isDarkMode),
                      child: ClipOval(
                        child:
                        UserData().profile == ''
                            ? Icon(
                          Icons.person,
                          color: Color(0xFF6F4F7E),
                          size: 50,
                        )
                            : Image.network(
                          UserData().profile ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      UserData().chinese_name,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: MyTheme.getSettingsSectionTitleColor(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UserData().id,
                      style: TextStyle(
                        fontSize: 20,
                        color: MyTheme.getSettingsSectionTitleColor(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      try {
                        final snapshot =
                        await FirebaseFirestore.instance
                            .collection('Student')
                            .doc(UserData().id)
                            .get();

                        if (!snapshot.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No user data found')),
                          );
                          return;
                        }

                        final githubUrl = snapshot.data()?['GITHUB'] as String?;

                        if (githubUrl == null || githubUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No GitHub URL found')),
                          );
                          return;
                        }

                        await _launchUrl(githubUrl);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                    child: Icon(
                      FontAwesomeIcons.github,
                      size: 30,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(width: 30),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      try {
                        final snapshot =
                        await FirebaseFirestore.instance
                            .collection('Student')
                            .doc(UserData().id)
                            .get();

                        if (!snapshot.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No user data found')),
                          );
                          return;
                        }

                        final linkedinUrl =
                        snapshot.data()?['LINKEDIN'] as String?;

                        if (linkedinUrl == null || linkedinUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No LinkedIn URL found')),
                          );
                          return;
                        }

                        await _launchUrl(linkedinUrl);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                    child: Icon(
                      FontAwesomeIcons.linkedin,
                      size: 30,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  const SizedBox(width: 30),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      try {
                        final snapshot =
                        await FirebaseFirestore.instance
                            .collection('Student')
                            .doc(UserData().id)
                            .get();

                        if (!snapshot.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No user data found')),
                          );
                          return;
                        }

                        final websiteUrl =
                        snapshot.data()?['WEBSITE'] as String?;

                        if (websiteUrl == null || websiteUrl.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No Website URL found')),
                          );
                          return;
                        }

                        await _launchUrl(websiteUrl);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      child: Icon(
                        FontAwesomeIcons.link,
                        color: Theme.of(context).iconTheme.color,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              !adapdf
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) {
                    return SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child:
                  isUploadMode
                      ? Column(
                    key: const ValueKey('upload'),
                    children: [
                      GestureDetector(
                        onTap: () => _pickFile(), // No replacement parameters for new upload
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CupertinoColors.systemGrey,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                CupertinoIcons.cloud_upload,
                                size: 48,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                pickedFileName ??
                                    'Upload File Here',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        child: Text(
                          "Cancel Upload",
                          style: TextStyle(
                            color:
                            MyTheme.getSettingsSectionTitleColor(
                              isDarkMode,
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            isUploadMode = false;
                            pickedFileName = null;
                            replacingDocId = null;
                            replacingFileName = null;
                          });
                        },
                      ),
                    ],
                  )
                      : CupertinoButton(
                    key: const ValueKey('resume'),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        isUploadMode = true;
                        replacingDocId = null;
                        replacingFileName = null;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                        isDarkMode
                            ? Color(0xFF003829)
                            : Color(0xFF87A236),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          "UPLOAD YOUR RESUME",
                          style: TextStyle(
                            color: MyTheme.getSettingsTextColor(
                              isDarkMode,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSection("YOUR RESUME FILES"),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color:
                            isDarkMode ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            _pickFile();
                          },
                        ),
                      ],
                    ),

                    StreamBuilder<QuerySnapshot>(
                      stream:
                      FirebaseFirestore.instance
                          .collection('Student')
                          .doc(UserData().id)
                          .collection('CV')
                          .orderBy('uploaded_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return Text(
                            "No resumes uploaded yet.",
                            style: TextStyle(
                              color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          );
                        }

                        return Column(
                          children:
                          docs.map((doc) {
                            final data =
                            doc.data() as Map<String, dynamic>;
                            final fileName = data['file_name'];
                            final url = data['url'];
                            final docId = doc.id;

                            return Card(
                              color:
                              isDarkMode
                                  ? Colors.white10
                                  : Colors.white,
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  fileName,
                                  style: TextStyle(
                                    color:
                                    isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: TextButton(
                                  onPressed: () => _launchUrl(url),
                                  child: const Text(
                                    "View",
                                    style: TextStyle(
                                      color: CupertinoColors.activeBlue,
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.delete,
                                        color:
                                        isDarkMode
                                            ? Color(0xFF8A3738)
                                            : Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        _showConfirmationDialog(
                                          "Delete $fileName?",
                                              () async {
                                            await FirebaseStorage
                                                .instance
                                                .ref()
                                                .child(
                                              'resumes/${UserData().id}_$fileName',
                                            )
                                                .delete();
                                            await FirebaseFirestore
                                                .instance
                                                .collection('Student')
                                                .doc(UserData().id)
                                                .collection('CV')
                                                .doc(docId)
                                                .delete();
                                            await checkResumeExists();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "File deleted",
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.arrow_up_doc,
                                        color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                      onPressed: () {
                                        _showConfirmationDialog(
                                          "Replace $fileName with a new file?",
                                              () async {
                                            // Directly call _pickFile with replacement parameters
                                            await _pickFile(
                                                replaceDocId: docId,
                                                replaceFileName: fileName
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildSection("NOTIFICATIONS"),

                    _buildSwitch(
                      "Receive Notifications",
                      receiveNotifications,
                          (val) async {
                        await NotificationService.toggleNotifications(val);
                        setState(() => receiveNotifications = val);
                      },
                    ),

                    _buildSection("VISIBILITY"),
                    _buildSwitch("Dark Mode", isDarkMode, _toggleTheme),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        print(UserData().selectedData);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Scaffold(
                              body: SafeArea(
                                child: PreferenceSelector(
                                  onComplete: (
                                      selectedData,
                                      summaries,
                                      ) async {
                                    // Handle selection (save to Firebase, local state, etc.)
                                    print("Selected: $selectedData");
                                    print("Summaries: $summaries");
                                    final docRef = FirebaseFirestore
                                        .instance
                                        .collection('Student')
                                        .doc(UserData().id);
                                    try {
                                      await docRef.update({
                                        'SELECTED': {
                                          'Skills I Am Interested':
                                          selectedData['Skills I Am Interested'] ??
                                              [],
                                          'Jobs I Am Seeking':
                                          selectedData['Jobs I Am Seeking'] ??
                                              [],
                                          'My Priorities':
                                          selectedData['My Priorities'] ??
                                              [],
                                        },
                                      });
                                      await docRef.update({
                                        'PREFERENCES': summaries,
                                      });
                                      UserData().preferences = summaries;
                                      UserData().selectedData =
                                          selectedData;
                                      print("Update successful!");
                                    } catch (e) {
                                      print(
                                        "Update failed: ${e.toString()}",
                                      );
                                      if (e is FirebaseException) {
                                        print(
                                          "Firebase error code: ${e.code}",
                                        );
                                        print(
                                          "Firebase message: ${e.message}",
                                        );
                                      }
                                    }
                                    // Navigate to the next step
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                          isDarkMode
                              ? Color(0xFF003829)
                              : Color(0xFF87A236),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            "CHANGE PREFERENCES",
                            style: TextStyle(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    _buildSection("SEARCH HISTORY"),
                    const SizedBox(height: 12),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () => _showConfirmationDialog(
                        "Clear search history?",
                            () {
                          context
                              .read<SearchHistoryProvider>()
                              .clearHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Search history cleared"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: MyTheme.getSettingsTextColor(isDarkMode),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            "CLEAR SEARCH HISTORY",
                            style: TextStyle(
                              color: MyTheme.getSettingsTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () => _showConfirmationDialog(
                        "Are you sure you want to sign out?",
                            () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                          isDarkMode
                              ? Color(0xFF8A3738)
                              : Color.fromARGB(255, 255, 97, 89),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            "SIGN OUT",
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}