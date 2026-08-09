// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get myHabits => '내 습관';

  @override
  String get export => '내보내기';

  @override
  String get exportFailed => '내보내기 실패';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get languageUpdated => '언어가 변경되었습니다';

  @override
  String get selectTheme => '테마 선택';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get themeUpdated => '테마가 변경되었습니다';

  @override
  String get userGuide => '사용설명서';

  @override
  String get userGuideContent =>
      '1) 습관을 탭하여 체크/해제합니다.\n2) 날짜 선택으로 다른 날짜 기록을 확인/수정합니다.\n3) 드로어 → 와이드 체크에서 월별 표시를 봅니다.\n4) 내보내기를 눌러 CSV를 문서 폴더에 저장합니다.';

  @override
  String get appInfoDescription => '심플한 습관 체크 앱.';

  @override
  String get addHabit => '습관 추가';

  @override
  String get habitName => '습관 이름';

  @override
  String get color => '색상';

  @override
  String get add => '추가';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get ok => '확인';

  @override
  String get selectHabitToEdit => '편집할 습관 선택';

  @override
  String get noHabitsToEdit => '편집할 습관이 없습니다';

  @override
  String get uncheckHabit => '체크 해제';

  @override
  String get checkHabit => '체크하기';

  @override
  String get editHabit => '습관 편집';

  @override
  String get editHabitTitle => '습관 편집';

  @override
  String get deleteHabit => '습관 삭제';

  @override
  String get deleteHabitTitle => '습관 삭제';

  @override
  String get deleteHabitConfirm => '이 습관을 삭제하시겠습니까?';

  @override
  String get details => '자세히 보기';

  @override
  String get comingSoon => '준비 중입니다';

  @override
  String get thisWeek => '이번 주 기록';

  @override
  String get thisWeekTitle => '이번 주 기록';

  @override
  String get changeLanguage => '언어 변경';

  @override
  String get changeTheme => '테마 변경';

  @override
  String get badges => '뱃지 보기';

  @override
  String get wideChecker => '와이드 체크';

  @override
  String get editHabits => '습관 편집하기';

  @override
  String get appInfo => '앱 정보';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get ad => '광고';

  @override
  String get longPressTip => 'Tip: 목록을 꾹 누르면 편집할 수 있어요';

  @override
  String get noHabitsYet => '습관이 없습니다';

  @override
  String get noBadgesYet => '아직 뱃지가 없습니다';

  @override
  String weeklyBestTotal(int best, int total) {
    return '주간 최고: $best일  ·  총: $total';
  }

  @override
  String streakCount(int count) {
    return '$count일';
  }

  @override
  String get badgeDay1Title => 'Day 1';

  @override
  String get badgeDay1Subtitle => '첫 시작';

  @override
  String get badge3DaysTitle => '3 Days';

  @override
  String get badge3DaysSubtitle => '연속 3일';

  @override
  String get badge7DaysTitle => '7 Days';

  @override
  String get badge7DaysSubtitle => '1주 연속';

  @override
  String get badge14DaysTitle => '14 Days';

  @override
  String get badge14DaysSubtitle => '2주 연속';

  @override
  String get badge30DaysTitle => '30 Days';

  @override
  String get badge30DaysSubtitle => '한 달 연속';

  @override
  String get badge60DaysTitle => '60 Days';

  @override
  String get badge60DaysSubtitle => '두 달 연속';

  @override
  String get badge90DaysTitle => '90 Days';

  @override
  String get badge90DaysSubtitle => '세 달 연속';

  @override
  String get badge180DaysTitle => '180 Days';

  @override
  String get badge180DaysSubtitle => '반 년 연속';

  @override
  String get badge365DaysTitle => '365 Days';

  @override
  String get badge365DaysSubtitle => '1년 연속';
}
