import '../../models/week_summary.dart';

/// Zip tarzı duygusal özet başlıkları (görev sayısına göre).
(String headline, String subtitle) summaryHeroCopy(WeekSummary summary) {
  if (summary.totalTasks == 0) {
    return (
      'Planlama zamanı ☕',
      'Havuzdan başla — küçük adımlar büyük haftalar yapar.',
    );
  }
  final taskPct = summary.totalTasks == 0
      ? 0
      : (summary.completedTasks * 100 / summary.totalTasks).round();
  if (taskPct >= 80) {
    return (
      'Efsanevi ilerleme! 🌟',
      '${summary.completedTasks}/${summary.totalTasks} görev tamam — dinlenmeyi hak ettin.',
    );
  }
  if (taskPct >= 50) {
    return (
      'Yarı yolu aştınız ⚡',
      'Momentum seninle; kalan görevlere odaklan.',
    );
  }
  if (summary.skippedTasks > 0 &&
      summary.skippedTasks >= summary.completedTasks) {
    return (
      'Nefes al 🌿',
      'Atlanan görevler de planın parçası — yarın için alan açtın.',
    );
  }
  return (
    'Odaklanmaya hazır 🎯',
    '${summary.completedMinutes} dk tamamlandı — sıradaki blok seni bekliyor.',
  );
}
