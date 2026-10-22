import 'parent_approval_screen.dart';
import 'package:flutter/material.dart';
import 'parent_pairing_screen.dart';
import '../services/auth_service.dart';
import '../utils/logout_helper.dart';
import 'parent_sos_screen.dart';
import 'children_screen.dart';
import 'parent_location_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF172554);

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(
          color: Color(0xFFE6EAF2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = AuthService.fullName?.trim();

    final name =
    fullName != null && fullName.isNotEmpty
        ? fullName
        : (AuthService.username ?? 'Parent');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: blue),
            SizedBox(width: 8),
            Text(
              'KidGuard',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ),
            onPressed: () =>
                LogoutHelper.signOut(context),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE4EDFF),
                  child: Icon(
                    Icons.person,
                    color: blue,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name!',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const Text(
                        'Parent Account',
                        style: TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1E40AF),
                  ],
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 41,
                    color: Colors.white,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Family Safety Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your children and keep '
                        'your family connected.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Family Management',
              style: TextStyle(
                color: navy,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 13),

            // CRUD VÀ TẠO TÀI KHOẢN CHILD
            _actionCard(
              context: context,
              icon: Icons.supervised_user_circle,
              title: 'Manage Children',
              subtitle: 'Create child accounts, edit profiles',
              color: blue,
              onTap: () => _open(
                context,
                const ChildrenScreen(),
              ),
            ),

            _actionCard(
              context: context,
              icon: Icons.qr_code_2,
              title: 'Pair Child Device',
              subtitle: 'Generate QR to connect a child phone',
              color: Colors.teal,
              onTap: () => _open(
                context,
                const ParentPairingScreen(),
              ),
            ),


            // GPS THẬT
            _actionCard(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Family Location',
              subtitle: 'View location check-ins from your children',
              color: Colors.green,
              onTap: () => _open(
                context,
                const ParentLocationScreen(),
              ),
            ),

            _actionCard(
              context: context,
              icon: Icons.notification_important_outlined,
              title: 'Safety Alerts',
              subtitle: 'View and acknowledge SOS from your children',
              color: Colors.red,
              onTap: () => _open(
                context,
                const ParentSosScreen(),
              ),
            ),

            _actionCard(
              context: context,
              icon: Icons.fact_check_outlined,
              title: 'Parent Approval',
              subtitle: 'Approve or reject your child requests',
              color: Colors.deepPurple,
              onTap: () => _open(
                context,
                const ParentApprovalScreen(),
              ),
            ),



            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: blue,
                    size: 29,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only you can manage the child '
                          'profiles linked to your account.',
                      style: TextStyle(
                        color: navy,
                        height: 1.4,
                      ),
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
}
