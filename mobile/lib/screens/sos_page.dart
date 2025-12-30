import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  List<Contact>? _emergencyContacts;
  bool _isLoading = false;
  String? _errorMessage;

  // THEME COLORS (matches Home + Reminder)
  static const Color primaryOrange = Color(0xFFE85D32);
  static const Color deepBrown = Color(0xFF7A2E0E);
  static const Color backgroundWhite = Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    _fetchAndSyncContacts();
  }

  // ---------------- FETCH & SYNC ----------------
  Future<void> _fetchAndSyncContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await FlutterContacts.requestPermission()) {
        setState(() {
          _errorMessage =
              'Permission denied. Please enable contacts access in settings.';
          _isLoading = false;
        });
        return;
      }

      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
        withGroups: true,
      );

      final filtered = allContacts.where((contact) {
        final hasEmergencyLabel = contact.phones.any(
          (p) => p.customLabel?.toLowerCase().contains('emergency') == true,
        );
        final isEmergencyGroup = contact.groups.any(
          (g) =>
              g.name.toLowerCase().contains('emergency') ||
              g.name.toLowerCase() == 'ice',
        );
        final hasEmergencyName =
            contact.displayName.toLowerCase().contains('ice') ||
            contact.displayName.toLowerCase().contains('emergency');

        return hasEmergencyLabel || isEmergencyGroup || hasEmergencyName;
      }).toList();

      setState(() {
        _emergencyContacts = filtered;
        _isLoading = false;
      });

      if (filtered.isNotEmpty) {
        await _uploadToFirebase(filtered);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ---------------- FIREBASE UPLOAD ----------------
  Future<void> _uploadToFirebase(List<Contact> contacts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final contactsRef = userDoc.collection('emergency_contacts');

    for (final contact in contacts) {
      batch.set(contactsRef.doc(contact.id), {
        'name': contact.displayName,
        'phones': contact.phones.map((e) => e.number).toList(),
        'last_synced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: PreferredSize(
        // Increase the height (default is kToolbarHeight, which is 56.0)
        preferredSize: const Size.fromHeight(80.0),
        child: Padding(
          // Add margin/padding to the top and bottom
          padding: const EdgeInsets.only(top: 10, bottom: 5),
          child: AppBar(
            backgroundColor: backgroundWhite,
            elevation: 0,
            centerTitle: false, // Ensures title stays left
            iconTheme: const IconThemeData(color: deepBrown),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Keep it compact
              children: const [
                Text(
                  'SOS Contacts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryOrange,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trusted emergency contacts',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _fetchAndSyncContacts,
                icon: const Icon(Icons.sync_rounded),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _centerMessage(Icons.error_outline, _errorMessage!);
    }

    if (_emergencyContacts == null || _emergencyContacts!.isEmpty) {
      return _centerMessage(
        Icons.contact_support_rounded,
        'No emergency contacts found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _emergencyContacts!.length,
      itemBuilder: (context, index) {
        return _contactCard(_emergencyContacts![index]);
      },
    );
  }

  // ---------------- CONTACT CARD ----------------
  Widget _contactCard(Contact contact) {
    final phone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : 'No number';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: _avatar(contact),
        title: Text(
          contact.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(phone, style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openDetails(contact),
      ),
    );
  }

  // ---------------- DETAILS SHEET ----------------
  void _openDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _avatar(contact, radius: 42),
            const SizedBox(height: 12),
            Text(
              contact.displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Emergency Contact',
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 20),
            const Divider(indent: 32, endIndent: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: contact.phones.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.phone_rounded,
                        color: primaryOrange,
                      ),
                      title: Text(
                        p.number,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(p.label.name.toUpperCase()),
                      onTap: () => FlutterContacts.openExternalView(contact.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _avatar(Contact contact, {double radius = 30}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryOrange.withOpacity(0.15),
      backgroundImage: contact.thumbnail != null
          ? MemoryImage(contact.thumbnail!)
          : null,
      child: contact.thumbnail == null
          ? Text(
              contact.displayName.isNotEmpty
                  ? contact.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: deepBrown,
              ),
            )
          : null,
    );
  }

  Widget _centerMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: primaryOrange.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
