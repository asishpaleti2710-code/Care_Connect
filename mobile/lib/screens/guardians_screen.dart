import 'package:flutter/material.dart';

class GuardiansScreen extends StatelessWidget {
  const GuardiansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final guardians = [
      {
        'name': 'Sarah Vance',
        'relation': 'Daughter / Primary Next of Kin',
        'phone': '+1 (555) 234-5678',
        'email': 'sarah.vance@example.com',
        'status': 'Notifications Active'
      },
      {
        'name': 'Dr. Robert Miller',
        'relation': 'Attending Physician',
        'phone': '+1 (555) 876-5432',
        'email': 'dr.miller@careclinic.org',
        'status': 'Emergency Contact Only'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Guardians Directory'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: guardians.length,
          itemBuilder: (context, index) {
            final g = guardians[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.contact_phone_rounded, color: colorScheme.onPrimaryContainer),
                ),
                title: Text(g['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Relation: ${g['relation']}'),
                    Text('Phone: ${g['phone']}'),
                    Text('Email: ${g['email']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.phone_forwarded_rounded, color: Colors.green),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing emergency contact: ${g['phone']}')),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
