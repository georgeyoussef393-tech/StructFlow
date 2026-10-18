import 'package:flutter/material.dart';

const List<IconData> _supportedMaterialIcons = [
  Icons.account_balance_rounded,
  Icons.account_tree_rounded,
  Icons.air_rounded,
  Icons.alt_route_rounded,
  Icons.apartment_rounded,
  Icons.architecture_rounded,
  Icons.assignment_rounded,
  Icons.bolt_rounded,
  Icons.business_rounded,
  Icons.construction_rounded,
  Icons.directions_rounded,
  Icons.description,
  Icons.electrical_services_rounded,
  Icons.engineering_rounded,
  Icons.factory_rounded,
  Icons.fact_check_rounded,
  Icons.groups_rounded,
  Icons.hotel_rounded,
  Icons.inventory_2_rounded,
  Icons.local_fire_department_rounded,
  Icons.local_hospital_rounded,
  Icons.location_city_rounded,
  Icons.manage_accounts_rounded,
  Icons.notifications_active_rounded,
  Icons.person_rounded,
  Icons.question_answer_rounded,
  Icons.request_quote_rounded,
  Icons.report_problem_rounded,
  Icons.schema_rounded,
  Icons.settings_rounded,
  Icons.storefront_rounded,
  Icons.straighten_rounded,
  Icons.terrain_rounded,
  Icons.videocam_rounded,
  Icons.villa_rounded,
  Icons.water_drop_rounded,
  Icons.water_rounded,
];

IconData materialIconFromCodePoint(
  int codePoint, {
  required IconData fallback,
}) {
  for (final icon in _supportedMaterialIcons) {
    if (icon.codePoint == codePoint) {
      return icon;
    }
  }
  return fallback;
}
