import 'package:flutter/material.dart';

import '../../../core/constants/challenge_templates.dart';
import '../../../core/services/challenge_service.dart';
import '../../../models/user_model.dart';

Future<bool?> showChallengeTemplateSheet({
  required BuildContext context,
  required UserModel challenger,
  required UserModel opponent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      String selectedType = ChallengeTemplates.all.first.id;
      bool localSubmitting = false;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_kabaddi_rounded, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thách đấu ${opponent.displayName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          ...ChallengeTemplates.all.map((template) {
                            final isSelected = selectedType == template.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: RadioListTile<String>(
                                value: template.id,
                                groupValue: selectedType,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setModalState(() => selectedType = value);
                                },
                                title: Text('${template.emoji} ${template.title}'),
                                subtitle: Text(
                                  template.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                dense: true,
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: localSubmitting
                              ? null
                              : () async {
                                  setModalState(() => localSubmitting = true);
                                  final template = ChallengeTemplates.byId(selectedType);
                                  final success = await ChallengeService.createChallenge(
                                    challengerId: challenger.uid,
                                    challengerName: challenger.displayName,
                                    opponentId: opponent.uid,
                                    opponentName: opponent.displayName,
                                    challengeType: selectedType,
                                    metadata: template.toMetadata(),
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    Navigator.of(context).pop(true);
                                  } else {
                                    setModalState(() => localSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể tạo thách đấu. Vui lòng thử lại.'),
                                      ),
                                    );
                                  }
                                },
                          icon: localSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.flag_rounded),
                          label: Text(localSubmitting ? 'Đang tạo...' : 'Gửi lời thách đấu'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

