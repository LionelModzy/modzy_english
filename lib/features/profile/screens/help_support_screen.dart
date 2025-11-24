import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _buildSection(
              title: 'Frequently Asked Questions',
              icon: Icons.quiz_rounded,
              children: [
                _buildFAQItem(
                  'How do I track my learning progress?',
                  'Go to your profile and tap on "Learning History" to see detailed progress of lessons, quizzes, and vocabulary practice.',
                ),
                _buildFAQItem(
                  'How do I practice vocabulary?',
                  'Navigate to the Vocabulary section and select practice mode. You can practice with flashcards, multiple choice, or typing exercises.',
                ),
                _buildFAQItem(
                  'Can I download lessons for offline use?',
                  'Currently, lessons require an internet connection. Offline functionality is planned for future updates.',
                ),
                _buildFAQItem(
                  'How are quiz scores calculated?',
                  'Quiz scores are based on correct answers out of total questions. Time bonuses may apply for quick responses.',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Contact Section
            _buildSection(
              title: 'Liên hệ hỗ trợ',
              icon: Icons.contact_support_rounded,
              children: [
                _buildContactItem(
                  icon: Icons.email_rounded,    
                  title: 'Hỗ trợ qua email',
                  subtitle: 'lionelmodzy@gmail.com',
                  onTap: () => _launchEmail(context),
                ),
                _buildContactItem(
                  icon: Icons.phone_rounded,
                  title: 'Hỗ trợ qua điện thoại',
                  subtitle: '+84 0100 000 000',
                  onTap: () => _launchPhone(context),
                ),
                _buildContactItem(
                  icon: Icons.chat_rounded,
                  title: 'Hỗ trợ qua live chat',
                  subtitle: 'Khả dụng 8 AM - 5 PM, Thứ Hai - Thứ Sáu',
                  onTap: () => _showLiveChatDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // App Info Section
            _buildSection(
              title: 'Thông tin ứng dụng',
              icon: Icons.info_rounded,
              children: [
                _buildInfoItem('Phiên bản', '1.0.0'),
                _buildInfoItem('Ngày cập nhật', 'Tháng 10 2025'),
                _buildInfoItem('Platform', 'Flutter'),
                _buildInfoItem('Developer', 'Modzy English Team'),
              ],
            ),
            const SizedBox(height: 32),

            // Feedback Section
            _buildSection(
              title: 'Send Feedback',
              icon: Icons.feedback_rounded,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chúng tôi cảm ơn phản hồi của bạn!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy giúp chúng tôi cải thiện Modzy English bằng cách chia sẻ những suy nghĩ và đề xuất của bạn.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showFeedbackDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Gửi phản hồi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    const String email = 'lionelmodzy@gmail.com';
    const String subject = 'Modzy English Support Request';
    const String body = 'Hello Modzy English Team,\n\nI need support with:\n\n\n\nThank you!';
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Check if we can launch the URL
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        // Try to launch with mode selection
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          // If launch failed, show fallback
          _showEmailFallbackDialog(context);
        }
      } else {
        // Fallback: Show dialog with email info if email app is not available
        _showEmailFallbackDialog(context);
      }
    } catch (e) {
      // Show error dialog with more specific error info
      _showEmailErrorDialog(context, e.toString());
    }
  }

  void _showEmailFallbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liên hệ hỗ trợ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gửi email cho chúng tôi tại:'),
            SizedBox(height: 8),
            SelectableText(
              'lionelmodzy@gmail.com',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text('Chủ đề: Modzy English Support Request'),
            SizedBox(height: 16),
            Text(
              'Hoặc bạn có thể sử dụng Gmail web để gửi email.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchGmailWeb(context);
            },
            child: const Text('Mở Gmail Web'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGmailWeb(BuildContext context) async {
    const String email = 'lionelmodzy@gmail.com';
    const String subject = 'Modzy English Support Request';
    const String body = 'Hello Modzy English Team,\n\nI need support with:\n\n\n\nThank you!';
    
    final Uri gmailUri = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã mở Gmail Web!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showEmailErrorDialog(context, 'Cannot open Gmail Web');
      }
    } catch (e) {
      _showEmailErrorDialog(context, e.toString());
    }
  }

  void _showEmailErrorDialog(BuildContext context, [String? error]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Không thể mở ứng dụng email. Vui lòng thử lại hoặc liên hệ trực tiếp qua email:'),
            const SizedBox(height: 8),
            const SelectableText(
              'lionelmodzy@gmail.com',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              const Text('Chi tiết lỗi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEmailFallbackDialog(context);
            },
            child: const Text('Xem thông tin email'),
          ),
        ],
      ),
    );
  }

  void _launchPhone(BuildContext context) {
    // Show phone information dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hỗ trợ qua điện thoại'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gọi cho chúng tôi tại:'),
            SizedBox(height: 8),
            SelectableText(
              '+84 0100 000 000',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text('Khả dụng: 8 AM - 5 PM, Thứ Hai - Thứ Sáu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hỗ trợ qua live chat'),
          content: const Text(
            'Hỗ trợ qua live chat hiện không khả dụng. Vui lòng liên hệ chúng tôi qua email hoặc điện thoại để nhận hỗ trợ ngay lập tức.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchEmail(context);
              },
              child: const Text('Gửi email'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gửi phản hồi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chúng tôi cảm ơn phản hồi của bạn! Vui lòng chia sẻ những suy nghĩ của bạn dưới đây:'),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Nhập phản hồi của bạn ở đây...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập phản hồi trước khi gửi!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                await _sendFeedbackEmail(context, feedback);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFeedbackEmail(BuildContext context, String feedback) async {
    const String email = 'lionelmodzy@gmail.com';
    final String subject = 'Modzy English - User Feedback';
    final String body = 'Hello Modzy English Team,\n\n'
        'I would like to share my feedback about the app:\n\n'
        '$feedback\n\n'
        'Thank you for your time!\n\n'
        'Best regards,\n'
        'A Modzy English User';
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã mở ứng dụng email để gửi phản hồi!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          _showEmailFallbackDialog(context);
        }
      } else {
        _showEmailFallbackDialog(context);
      }
    } catch (e) {
      _showEmailErrorDialog(context, e.toString());
    }
  }
}
