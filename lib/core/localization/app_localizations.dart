import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final result =
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );

    return result ?? const AppLocalizations(Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  String get dashboard => _t(
        en: 'Dashboard',
        ar: 'لوحة التحكم',
        fr: 'Tableau de bord',
        zh: '仪表板',
      );

  String get projects => _t(
        en: 'Projects',
        ar: 'المشروعات',
        fr: 'Projets',
        zh: '项目',
      );

  String get tasks => _t(
        en: 'Tasks',
        ar: 'المهام',
        fr: 'Tâches',
        zh: '任务',
      );

  String get team => _t(
        en: 'Team',
        ar: 'الفريق',
        fr: 'Équipe',
        zh: '团队',
      );

  String get calendar => _t(
        en: 'Calendar',
        ar: 'التقويم',
        fr: 'Calendrier',
        zh: '日历',
      );

  String get documents => _t(
        en: 'Documents',
        ar: 'المستندات',
        fr: 'Documents',
        zh: '文件',
      );

  String get attendance => _t(
        en: 'Attendance',
        ar: 'الحضور والانصراف',
        fr: 'Présence',
        zh: '考勤',
      );

  String get attendanceManagement => _t(
        en: 'Attendance Management',
        ar: 'إدارة الحضور',
        fr: 'Gestion de présence',
        zh: '考勤管理',
      );

  String get reports => _t(
        en: 'Reports',
        ar: 'التقارير',
        fr: 'Rapports',
        zh: '报告',
      );

  String get aiAssistant => _t(
        en: 'StructFlow Intelligence',
        ar: 'ذكاء StructFlow',
        fr: 'Intelligence StructFlow',
        zh: 'StructFlow 智能助手',
      );

  String get settings => _t(
        en: 'Settings',
        ar: 'الإعدادات',
        fr: 'Paramètres',
        zh: '设置',
      );

  String get searchHint => _t(
        en: 'Search projects, drawings, BOQ...',
        ar: 'ابحث عن المشروعات والرسومات و BOQ...',
        fr: 'Rechercher des projets, plans, BOQ...',
        zh: '搜索项目、图纸、BOQ...',
      );

  String get language => _t(
        en: 'Language',
        ar: 'اللغة',
        fr: 'Langue',
        zh: '语言',
      );

  String get theme => _t(
        en: 'Theme',
        ar: 'المظهر',
        fr: 'Thème',
        zh: '主题',
      );

  String get notifications => _t(
        en: 'Notifications',
        ar: 'الإشعارات',
        fr: 'Notifications',
        zh: '通知',
      );

  String get close => _t(
        en: 'Close',
        ar: 'إغلاق',
        fr: 'Fermer',
        zh: '关闭',
      );

  String get administrator => _t(
        en: 'Administrator',
        ar: 'مسؤول النظام',
        fr: 'Administrateur',
        zh: '管理员',
      );

  String get activeProjects => _t(
        en: 'Active Projects',
        ar: 'المشروعات النشطة',
        fr: 'Projets actifs',
        zh: '进行中的项目',
      );

  String get upcomingTasks => _t(
        en: 'Upcoming Tasks',
        ar: 'المهام القادمة',
        fr: 'Tâches à venir',
        zh: '即将到来的任务',
      );

  String get completed => _t(
        en: 'Completed',
        ar: 'المكتملة',
        fr: 'Terminées',
        zh: '已完成',
      );

  String get taskProgress => _t(
        en: 'Task Progress',
        ar: 'تقدم المهام',
        fr: 'Progression des tâches',
        zh: '任务进度',
      );

  String get noUpcomingTasks => _t(
        en: 'No upcoming tasks.',
        ar: 'لا توجد مهام قادمة.',
        fr: 'Aucune tâche à venir.',
        zh: '没有即将到来的任务。',
      );

  String get boqApproved => _t(
        en: 'BOQ Approved',
        ar: 'تم اعتماد الـ BOQ',
        fr: 'BOQ approuvé',
        zh: 'BOQ 已批准',
      );

  String get newDrawingUploaded => _t(
        en: 'New Drawing Uploaded',
        ar: 'تم رفع رسمة جديدة',
        fr: 'Nouveau plan chargé',
        zh: '已上传新图纸',
      );

  String get rfiNeedsResponse => _t(
        en: 'RFI Needs Response',
        ar: 'RFI يحتاج إلى رد',
        fr: 'RFI nécessite une réponse',
        zh: 'RFI 需要回复',
      );

  String get newEngineerAdded => _t(
        en: 'New Engineer Added',
        ar: 'تمت إضافة مهندس جديد',
        fr: 'Nouvel ingénieur ajouté',
        zh: '已添加新工程师',
      );

  String get fiveMinutesAgo => _t(
        en: '5 min ago',
        ar: 'منذ 5 دقائق',
        fr: 'Il y a 5 min',
        zh: '5分钟前',
      );

  String get eighteenMinutesAgo => _t(
        en: '18 min ago',
        ar: 'منذ 18 دقيقة',
        fr: 'Il y a 18 min',
        zh: '18分钟前',
      );

  String get fortyMinutesAgo => _t(
        en: '40 min ago',
        ar: 'منذ 40 دقيقة',
        fr: 'Il y a 40 min',
        zh: '40分钟前',
      );

  String get oneHourAgo => _t(
        en: '1 hour ago',
        ar: 'منذ ساعة',
        fr: 'Il y a 1 heure',
        zh: '1小时前',
      );

  String noResultFound(String value) {
    return _t(
      en: 'No result found for "$value"',
      ar: 'لا توجد نتيجة لـ "$value"',
      fr: 'Aucun résultat pour "$value"',
      zh: '没有找到 "$value" 的结果',
    );
  }

  String due(String date) {
    return _t(
      en: 'Due $date',
      ar: 'الاستحقاق $date',
      fr: 'Échéance $date',
      zh: '截止日期 $date',
    );
  }

  String _t({
    required String en,
    required String ar,
    required String fr,
    required String zh,
  }) {
    switch (locale.languageCode) {
      case 'ar':
        return ar;
      case 'fr':
        return fr;
      case 'zh':
        return zh;
      case 'en':
      default:
        return en;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return const [
      'en',
      'ar',
      'fr',
      'zh',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) {
    return false;
  }
}