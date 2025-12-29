import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Auth

class SosPage extends StatefulWidget {
  const SosPage({Key? key}) : super(key: key);

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  List<Contact>? _emergencyContacts;
  bool _isLoading = false;
  String? _errorMessage;

  final Color primaryOrange = const Color(0xFFDE9243);
  final Color deepBrown = const Color(0xFFC4561D);
  final Color backgroundWhite = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _fetchAndSyncContacts();
  }

  Future<void> _fetchAndSyncContacts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (await FlutterContacts.requestPermission()) {
        final allContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: true,
          withGroups: true,
        );

        final filtered = allContacts.where((contact) {
          bool hasEmergencyLabel = contact.phones.any(
            (phone) =>
                phone.customLabel?.toLowerCase().contains('emergency') == true,
          );
          bool isInEmergencyGroup = contact.groups.any(
            (group) =>
                group.name.toLowerCase().contains('emergency') ||
                group.name.toLowerCase() == 'ice',
          );
          bool hasIceInName =
              contact.displayName.toLowerCase().contains('ice') ||
              contact.displayName.toLowerCase().contains('emergency');
          return hasEmergencyLabel || isInEmergencyGroup || hasIceInName;
        }).toList();

        if (mounted) {
          setState(() {
            _emergencyContacts = filtered;
          });
        }

        // Sync to Firebase using the logged-in User's ID
        if (filtered.isNotEmpty) {
          await _uploadToFirebase(filtered);
        }

        if (mounted) setState(() => _isLoading = false);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Permission denied. Please enable contacts in settings.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadToFirebase(List<Contact> contacts) async {
    try {
      // 2. Get the current logged-in user's UID
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = FirebaseFirestore.instance.batch();

      // Save under the user's specific document
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final collectionRef = userDoc.collection('emergency_contacts');

      // Save each contact in the emergency_contacts subcollection
      for (var contact in contacts) {
        final docRef = collectionRef.doc(contact.id);
        batch.set(docRef, {
          'contact_id': contact.id,
          'name': contact.displayName,
          'phones': contact.phones.map((p) => p.number).toList(),
          'emails': contact.emails.map((e) => e.address).toList(),
          'last_synced': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Also save a summary in the user's profile document
      final List<Map<String, dynamic>> summary = contacts
          .map(
            (c) => {
              'contact_id': c.id,
              'name': c.displayName,
              'phones': c.phones.map((p) => p.number).toList(),
            },
          )
          .toList();
      batch.set(userDoc, {
        'profile': {'emergency_contacts_summary': summary},
        'last_emergency_contacts_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint("Successfully synced to Firebase for user: ${user.uid}");
    } catch (e) {
      debugPrint("Firebase Upload Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: deepBrown),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'SOS',
                style: TextStyle(
                  color: primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              TextSpan(
                text: ' Contacts',
                style: TextStyle(
                  color: deepBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchAndSyncContacts,
            icon: const Icon(Icons.sync_rounded),
            tooltip: "Sync with Cloud",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryOrange))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildCenteredMessage(Icons.error_outline_rounded, _errorMessage!);
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "TRUSTED CONTACTS (CLOUD SYNCED)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        _emergencyContacts == null || _emergencyContacts!.isEmpty
            ? SliverFillRemaining(
                child: _buildCenteredMessage(
                  Icons.contact_support_rounded,
                  'No Emergency Contacts found.',
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final contact = _emergencyContacts![index];
                    return _buildContactTile(contact);
                  }, childCount: _emergencyContacts!.length),
                ),
              ),
      ],
    );
  }

  Widget _buildContactTile(Contact contact) {
    final phone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : "No number";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryOrange.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(contact),
        title: Text(
          contact.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: deepBrown,
            fontSize: 16,
          ),
        ),
        subtitle: Text(phone, style: const TextStyle(color: Colors.black54)),
        onTap: () => _showInAppDetails(contact),
      ),
    );
  }

  void _showInAppDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildAvatar(contact, radius: 45),
            const SizedBox(height: 15),
            Text(
              contact.displayName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: deepBrown,
              ),
            ),
            const Divider(height: 40, indent: 40, endIndent: 40),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ...contact.phones.map(
                    (p) => ListTile(
                      leading: Icon(Icons.phone_rounded, color: primaryOrange),
                      title: Text(p.number),
                      subtitle: Text(p.label.name.toUpperCase()),
                      onTap: () => FlutterContacts.openExternalView(contact.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Contact contact, {double radius = 28}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: primaryOrange.withOpacity(0.1),
      backgroundImage: contact.thumbnail != null
          ? MemoryImage(contact.thumbnail!)
          : null,
      child: contact.thumbnail == null
          ? Text(
              contact.displayName.isNotEmpty
                  ? contact.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(color: deepBrown, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildCenteredMessage(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: primaryOrange.withOpacity(0.4)),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
