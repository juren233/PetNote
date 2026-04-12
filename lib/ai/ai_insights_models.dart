import 'dart:convert';

import 'package:petnote/state/petnote_store.dart';

class AiGenerationContext {
  const AiGenerationContext({
    required this.title,
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.languageTag,
    required this.pets,
    required this.todos,
    required this.reminders,
    required this.records,
  });

  final String title;
  final String rangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String languageTag;
  final List<Pet> pets;
  final List<TodoItem> todos;
  final List<ReminderItem> reminders;
  final List<PetRecord> records;

  String get cacheKey => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'rangeLabel': rangeLabel,
      'rangeStart': rangeStart.toIso8601String(),
      'rangeEnd': rangeEnd.toIso8601String(),
      'languageTag': languageTag,
      'pets': pets
          .map(
            (pet) => {
              'id': pet.id,
              'name': pet.name,
              'type': petTypeLabel(pet.type),
              'breed': pet.breed,
              'sex': pet.sex,
              'birthday': pet.birthday,
              'ageLabel': pet.ageLabel,
              'weightKg': pet.weightKg,
              'neuterStatus': petNeuterStatusLabel(pet.neuterStatus),
              'feedingPreferences': _compactText(pet.feedingPreferences, 80),
              'allergies': _compactText(pet.allergies, 80),
              'note': _compactText(pet.note, 120),
            },
          )
          .toList(),
      'todos': todos
          .map(
            (todo) => {
              'petId': todo.petId,
              'title': todo.title,
              'dueAt': todo.dueAt.toIso8601String(),
              'status': todo.status.name,
              'notificationLeadTime': todo.notificationLeadTime.name,
              'note': _compactText(todo.note, 120),
            },
          )
          .toList(),
      'reminders': reminders
          .map(
            (reminder) => {
              'petId': reminder.petId,
              'kind': reminder.kind.name,
              'title': reminder.title,
              'scheduledAt': reminder.scheduledAt.toIso8601String(),
              'status': reminder.status.name,
              'recurrence': reminder.recurrence,
              'notificationLeadTime': reminder.notificationLeadTime.name,
              'note': _compactText(reminder.note, 120),
            },
          )
          .toList(),
      'records': records
          .map(
            (record) => {
              'petId': record.petId,
              'type': record.type.name,
              'title': record.title,
              'recordDate': record.recordDate.toIso8601String(),
              'summary': _compactText(record.summary, 120),
              'note': _compactText(record.note, 160),
            },
          )
          .toList(),
    };
  }
}

enum AiScoreConfidence { low, medium, high }

String aiScoreConfidenceLabel(AiScoreConfidence confidence) =>
    switch (confidence) {
      AiScoreConfidence.low => '样本偏少',
      AiScoreConfidence.medium => '可信度中等',
      AiScoreConfidence.high => '可信度较高',
    };

class AiScoreDimension {
  const AiScoreDimension({
    required this.key,
    required this.label,
    required this.score,
    required this.reason,
  });

  final String key;
  final String label;
  final int score;
  final String reason;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'score': score,
      'reason': reason,
    };
  }
}

class AiPetCareScorecard {
  const AiPetCareScorecard({
    required this.petId,
    required this.petName,
    required this.overallScore,
    required this.overallScoreLabel,
    required this.scoreConfidence,
    required this.scoreBreakdown,
    required this.scoreReasons,
    required this.riskCandidates,
    required this.dataQualityNotes,
    required this.recentEventTitles,
  });

  final String petId;
  final String petName;
  final int overallScore;
  final String overallScoreLabel;
  final AiScoreConfidence scoreConfidence;
  final List<AiScoreDimension> scoreBreakdown;
  final List<String> scoreReasons;
  final List<String> riskCandidates;
  final List<String> dataQualityNotes;
  final List<String> recentEventTitles;

  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'petName': petName,
      'overallScore': overallScore,
      'overallScoreLabel': overallScoreLabel,
      'scoreConfidence': scoreConfidence.name,
      'scoreBreakdown': scoreBreakdown.map((item) => item.toJson()).toList(),
      'scoreReasons': scoreReasons,
      'riskCandidates': riskCandidates,
      'dataQualityNotes': dataQualityNotes,
      'recentEventTitles': recentEventTitles,
    };
  }
}

class AiCareScorecard {
  const AiCareScorecard({
    required this.overallScore,
    required this.overallScoreLabel,
    required this.scoreConfidence,
    required this.scoreBreakdown,
    required this.scoreReasons,
    required this.riskCandidates,
    required this.dataQualityNotes,
    required this.petScorecards,
    required this.totalTodos,
    required this.totalReminders,
    required this.totalRecords,
  });

  final int overallScore;
  final String overallScoreLabel;
  final AiScoreConfidence scoreConfidence;
  final List<AiScoreDimension> scoreBreakdown;
  final List<String> scoreReasons;
  final List<String> riskCandidates;
  final List<String> dataQualityNotes;
  final List<AiPetCareScorecard> petScorecards;
  final int totalTodos;
  final int totalReminders;
  final int totalRecords;

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'overallScoreLabel': overallScoreLabel,
      'scoreConfidence': scoreConfidence.name,
      'scoreBreakdown': scoreBreakdown.map((item) => item.toJson()).toList(),
      'scoreReasons': scoreReasons,
      'riskCandidates': riskCandidates,
      'dataQualityNotes': dataQualityNotes,
      'totals': {
        'todos': totalTodos,
        'reminders': totalReminders,
        'records': totalRecords,
      },
      'petScorecards': petScorecards.map((item) => item.toJson()).toList(),
    };
  }
}

class AiPetCareReport {
  const AiPetCareReport({
    required this.petId,
    required this.petName,
    required this.score,
    required this.scoreLabel,
    required this.scoreConfidence,
    required this.summary,
    required this.careFocus,
    required this.keyEvents,
    required this.trendAnalysis,
    required this.riskAssessment,
    required this.recommendedActions,
    required this.followUpFocus,
  });

  final String petId;
  final String petName;
  final int score;
  final String scoreLabel;
  final AiScoreConfidence scoreConfidence;
  final String summary;
  final String careFocus;
  final List<String> keyEvents;
  final List<String> trendAnalysis;
  final List<String> riskAssessment;
  final List<String> recommendedActions;
  final String followUpFocus;

  factory AiPetCareReport.fromJson(
    Map<String, dynamic> json, {
    required AiPetCareScorecard scorecard,
  }) {
    return AiPetCareReport(
      petId: scorecard.petId,
      petName: scorecard.petName,
      score: scorecard.overallScore,
      scoreLabel: scorecard.overallScoreLabel,
      scoreConfidence: scorecard.scoreConfidence,
      summary: _requiredString(json, 'summary'),
      careFocus: _requiredString(json, 'careFocus'),
      keyEvents: _requiredStringList(json, 'keyEvents'),
      trendAnalysis: _requiredStringList(json, 'trendAnalysis'),
      riskAssessment: _requiredStringList(json, 'riskAssessment'),
      recommendedActions: _requiredStringList(json, 'recommendedActions'),
      followUpFocus: _requiredString(json, 'followUpFocus'),
    );
  }
}

class AiCareReport {
  const AiCareReport({
    required this.overallScore,
    required this.overallScoreLabel,
    required this.scoreConfidence,
    required this.scoreBreakdown,
    required this.scoreReasons,
    required this.executiveSummary,
    required this.overallAssessment,
    required this.keyFindings,
    required this.trendAnalysis,
    required this.riskAssessment,
    required this.priorityActions,
    required this.dataQualityNotes,
    required this.perPetReports,
  });

  final int overallScore;
  final String overallScoreLabel;
  final AiScoreConfidence scoreConfidence;
  final List<AiScoreDimension> scoreBreakdown;
  final List<String> scoreReasons;
  final String executiveSummary;
  final List<String> overallAssessment;
  final List<String> keyFindings;
  final List<String> trendAnalysis;
  final List<String> riskAssessment;
  final List<String> priorityActions;
  final List<String> dataQualityNotes;
  final List<AiPetCareReport> perPetReports;

  String get summary => executiveSummary;

  factory AiCareReport.fromJson(
    Map<String, dynamic> json, {
    required AiCareScorecard scorecard,
  }) {
    final rawPetReports = json['perPetReports'];
    if (rawPetReports is! List) {
      throw const AiGenerationException('AI 返回的结构化结果缺少 perPetReports。');
    }
    final reportsByPetId = <String, Map<String, dynamic>>{};
    for (final item in rawPetReports) {
      if (item is! Map) {
        continue;
      }
      final mapped = item.map((key, value) => MapEntry('$key', value));
      final petId = _requiredString(mapped, 'petId');
      reportsByPetId[petId] = mapped;
    }
    final perPetReports = scorecard.petScorecards.map((petScorecard) {
      final rawReport = reportsByPetId[petScorecard.petId];
      if (rawReport == null) {
        throw AiGenerationException(
          'AI 返回的结构化结果缺少 ${petScorecard.petName} 的专项报告。',
        );
      }
      return AiPetCareReport.fromJson(
        rawReport,
        scorecard: petScorecard,
      );
    }).toList(growable: false);

    return AiCareReport(
      overallScore: scorecard.overallScore,
      overallScoreLabel: scorecard.overallScoreLabel,
      scoreConfidence: scorecard.scoreConfidence,
      scoreBreakdown: scorecard.scoreBreakdown,
      scoreReasons: scorecard.scoreReasons,
      executiveSummary: _requiredString(json, 'executiveSummary'),
      overallAssessment: _requiredStringList(json, 'overallAssessment'),
      keyFindings: _requiredStringList(json, 'keyFindings'),
      trendAnalysis: _requiredStringList(json, 'trendAnalysis'),
      riskAssessment: _requiredStringList(json, 'riskAssessment'),
      priorityActions: _requiredStringList(json, 'priorityActions'),
      dataQualityNotes: _requiredStringList(json, 'dataQualityNotes'),
      perPetReports: perPetReports,
    );
  }
}

class AiVisitSummary {
  const AiVisitSummary({
    required this.visitReason,
    required this.timeline,
    required this.medicationsAndTreatments,
    required this.testsAndResults,
    required this.questionsToAskVet,
  });

  final String visitReason;
  final List<String> timeline;
  final List<String> medicationsAndTreatments;
  final List<String> testsAndResults;
  final List<String> questionsToAskVet;

  factory AiVisitSummary.fromJson(Map<String, dynamic> json) {
    return AiVisitSummary(
      visitReason: _requiredString(json, 'visitReason'),
      timeline: _stringList(json['timeline']),
      medicationsAndTreatments: _stringList(json['medicationsAndTreatments']),
      testsAndResults: _stringList(json['testsAndResults']),
      questionsToAskVet: _stringList(json['questionsToAskVet']),
    );
  }
}

class AiGenerationException implements Exception {
  const AiGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _compactText(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxLength)}…';
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value == null || value.isEmpty) {
    throw AiGenerationException('AI 返回的结构化结果缺少 $key。');
  }
  return value;
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final value = _stringList(json[key]);
  if (value.isEmpty) {
    throw AiGenerationException('AI 返回的结构化结果缺少 $key。');
  }
  return value;
}

String? _optionalString(Object? value) {
  final text = value is String ? value.trim() : null;
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
