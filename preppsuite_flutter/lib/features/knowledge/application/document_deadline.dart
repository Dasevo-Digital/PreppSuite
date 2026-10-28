import 'personal_document_store.dart';

import 'document_calendar.dart';
export 'document_calendar.dart';

enum DocumentDeadlineStatus { expired, expiresToday, reminderDue, current }

DocumentDeadlineStatus documentDeadlineStatus(
  PersonalDocument document, {
  required DateTime now,
}) {
  final today = documentDay(now);
  final until = document.validUntil;
  if (until != null) {
    final day = documentDay(until);
    if (day.isBefore(today)) return DocumentDeadlineStatus.expired;
    if (day == today) return DocumentDeadlineStatus.expiresToday;
  }
  final remind = document.remindOn;
  final reviewed = document.reviewedOn;
  if (remind != null &&
      !documentDay(remind).isAfter(today) &&
      (reviewed == null ||
          documentDay(reviewed).isBefore(documentDay(remind)))) {
    return DocumentDeadlineStatus.reminderDue;
  }
  return DocumentDeadlineStatus.current;
}

class DocumentReminder {
  const DocumentReminder({required this.documentId, required this.fireAt});
  final String documentId;
  final DateTime fireAt;
  int get id => Object.hash('document-deadline', documentId) & 0x7fffffff;
}

List<DocumentReminder> planDocumentReminders(
  Iterable<PersonalDocument> documents, {
  required DateTime now,
  required int limit,
}) {
  final result = <DocumentReminder>[];
  for (final document in documents) {
    final date = document.remindOn;
    if (date == null) continue;
    if (document.validUntil case final until?
        when documentDay(date).isAfter(documentDay(until))) {
      continue;
    }
    final checked = document.reviewedOn;
    if (checked != null && !documentDay(checked).isBefore(documentDay(date))) {
      continue;
    }
    final fireAt = DateTime(date.year, date.month, date.day, 9);
    if (fireAt.isAfter(now)) {
      result.add(DocumentReminder(documentId: document.id, fireAt: fireAt));
    }
  }
  result.sort((a, b) {
    final date = a.fireAt.compareTo(b.fireAt);
    return date != 0 ? date : a.documentId.compareTo(b.documentId);
  });
  return result.take(limit < 0 ? 0 : limit).toList();
}
