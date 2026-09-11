import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_context_model.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_context_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  final _organization = TextEditingController();
  final _admin = TextEditingController();
  final _user = TextEditingController();
  final _projects = TextEditingController();
  final _allowedProjects = TextEditingController();
  final _project = TextEditingController();

  String _role = 'Employee';

  double _radius = 100;

  bool _locationEnabled = true;
  bool _geofenceEnabled = true;

  bool _gettingLocation = false;

  final MapController _mapController = MapController();

  LatLng _mapCenter = const LatLng(
    30.0444,
    31.2357,
  );

  LatLng? _selectedLocation;

  final Map<String, bool> _permissions = {
    'projects': false,
    'documents': false,
    'drawings': false,
    'tasks': false,
    'reports': false,
    'team': false,
    'calendar': false,
  };

  @override
  void initState() {
    super.initState();

    final session = AttendanceContextRepository.instance.context;

    _organization.text = session.organizationId;
    _admin.text = session.userId;
    _user.text = session.userId;
    _project.text = session.projectId;

    if (session.latitude != null && session.longitude != null) {
      final location = LatLng(
        session.latitude!,
        session.longitude!,
      );

      _selectedLocation = location;
      _mapCenter = location;
    }
  }

  @override
  void dispose() {
    _organization.dispose();
    _admin.dispose();
    _user.dispose();
    _projects.dispose();
    _allowedProjects.dispose();
    _project.dispose();

    super.dispose();
  }

  AttendancePermissionModel? get _actor {
    return AttendancePermissionRepository.instance.getForUser(
      organizationId: _organization.text.trim(),
      userId: _admin.text.trim(),
    );
  }

  Future<void> _bootstrapOwner() async {
    if (!_required([
      _organization,
      _admin,
    ])) {
      return;
    }

    final owner = AttendancePermissionModel.owner(
      id: 'ATT-PERM-${_admin.text.trim()}',
      organizationId: _organization.text.trim(),
      userId: _admin.text.trim(),
    );

    await AttendancePermissionRepository.instance.seedSuperAdmin(
      owner,
    );

    await _useAsCurrentUser(
      _admin.text.trim(),
    );

    _message(
      'Owner access is ready.',
    );
  }

  Future<void> _loadUser() async {
    if (!_required([
      _organization,
      _user,
    ])) {
      return;
    }

    final permission =
        AttendancePermissionRepository.instance.getForUser(
      organizationId: _organization.text.trim(),
      userId: _user.text.trim(),
    );

    if (permission == null) {
      setState(() {
        _role = 'Employee';
        _locationEnabled = true;

        for (final key in _permissions.keys) {
          _permissions[key] = false;
        }

        _projects.clear();
        _allowedProjects.clear();
      });

      _message(
        'No permission record found. Create it below.',
      );

      return;
    }

    setState(() {
      _role = permission.role == 'Super Admin'
          ? 'Owner'
          : permission.role;

      _locationEnabled =
          permission.locationAttendanceEnabled;

      _projects.text =
          permission.managedProjectIds.join(', ');

      _allowedProjects.text =
          permission.allowedProjectIds.join(', ');

      for (final key in _permissions.keys) {
        _permissions[key] =
            permission.permissions.contains(key);
      }
    });

    _message(
      'User permissions loaded.',
    );
  }

  Future<void> _savePermission() async {
    if (!_required([
      _organization,
      _admin,
      _user,
    ])) {
      return;
    }

    final actor = _actor;

    if (actor == null || !actor.canManageUsers) {
      _message(
        'The current manager is not authorized to change permissions.',
      );

      return;
    }

    final managedProjects =
        _csv(_projects.text);

    final allowedProjects =
        _csv(_allowedProjects.text);

    final selectedPermissions =
        _permissions.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    final canManageGeofences =
        _role == 'Owner' ||
        _role == 'Consultant Manager' ||
        _role == 'Owner HR Manager' ||
        _role == 'Consultant HR Manager';

    final permission =
        AttendancePermissionModel(
      id: 'ATT-PERM-${_user.text.trim()}',
      organizationId:
          _organization.text.trim(),
      userId:
          _user.text.trim(),
      role: _role,
      locationAttendanceEnabled:
          _locationEnabled,
      canManageProjectGeofences:
          canManageGeofences,
      canViewProjectAttendance:
          canManageGeofences,
      canViewOrganizationAttendance:
          _role == 'Owner' ||
          _role == 'Owner HR Manager' ||
          _role == 'Consultant HR Manager',
      permissions: _role == 'Owner'
          ? AttendancePermissionModel
              .modulePermissions
          : selectedPermissions,
      managedProjectIds:
          managedProjects,
      allowedProjectIds:
          allowedProjects,
      updatedAt:
          DateTime.now(),
    );

    final saved =
        await AttendancePermissionRepository
            .instance
            .save(
      actorUserId:
          _admin.text.trim(),
      permission:
          permission,
    );

    _message(
      saved
          ? 'User permissions saved successfully.'
          : 'Permission update was rejected.',
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _message(
          'Location service is disabled. Please enable GPS.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _message(
          'Location permission was denied.',
        );
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _message(
          'Location permission is permanently denied. Enable it from device settings.',
        );
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = location;
        _mapCenter = location;
      });

      _mapController.move(location, 17);

      _message(
        'Current location selected.',
      );
    } catch (e) {
      _message(
        'Unable to get current location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  void _selectMapLocation(
    LatLng location,
  ) {
    setState(() {
      _selectedLocation = location;
      _mapCenter = location;
    });

    _message(
      'Project location selected.',
    );
  }

  Future<void> _saveGeofence() async {
    if (!_required([
      _organization,
      _admin,
      _project,
    ])) {
      return;
    }

    if (_selectedLocation == null) {
      _message(
        'Select the project location on the map first.',
      );
      return;
    }

    final latitude =
        _selectedLocation!.latitude;

    final longitude =
        _selectedLocation!.longitude;

    final saved =
        await ProjectGeofenceRepository
            .instance
            .save(
      actorUserId:
          _admin.text.trim(),
      geofence:
          ProjectGeofenceModel(
        id:
            'GEOFENCE-${_project.text.trim()}',
        organizationId:
            _organization.text.trim(),
        projectId:
            _project.text.trim(),
        latitude:
            latitude,
        longitude:
            longitude,
        radiusMeters:
            _radius,
        attendanceEnabled:
            _geofenceEnabled,
        updatedByUserId:
            _admin.text.trim(),
        updatedAt:
            DateTime.now(),
      ),
    );

    if (saved) {
      await AttendanceContextRepository.instance.save(
        AttendanceContextModel(
          organizationId: _organization.text.trim(),
          projectId: _project.text.trim(),
          userId: _admin.text.trim(),
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    _message(
      saved
          ? 'Project location and attendance radius saved.'
          : 'This manager cannot manage this project location.',
    );
  }

  Future<void> _useAsCurrentUser(
    String userId,
  ) async {
    final trimmedUserId =
        userId.trim();

    if (trimmedUserId.isEmpty) {
      _message(
        'Enter a user ID first.',
      );
      return;
    }

    final current =
        AttendanceContextRepository.instance.context;

    await AttendanceContextRepository.instance.save(
      AttendanceContextModel(
        organizationId:
            _organization.text.trim(),
        projectId:
            current.projectId,
        userId:
            trimmedUserId,
        latitude:
            current.latitude,
        longitude:
            current.longitude,
      ),
    );

    if (mounted) {
      setState(() {});
    }

    _message(
      'Current demo user changed to $trimmedUserId.',
    );
  }

  Widget _buildMap() {
    final selected = _selectedLocation ?? _mapCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 420,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selected,
                initialZoom: 15,
                onTap: (_, point) => _selectMapLocation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.structflow.app',
                ),
                if (_selectedLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _selectedLocation!,
                        radius: _radius,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: .15),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 50,
                        height: 60,
                        child: const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  tooltip: 'Center on selected location',
                  onPressed: () {
                    _mapController.move(selected, 16);
                  },
                  icon: const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _csv(
    String value,
  ) {
    return value
        .split(',')
        .map(
          (item) =>
              item.trim(),
        )
        .where(
          (item) =>
              item.isNotEmpty,
        )
        .toList();
  }

  bool _required(
    List<TextEditingController>
        controllers,
  ) {
    if (controllers.every(
      (controller) =>
          controller.text
              .trim()
              .isNotEmpty,
    )) {
      return true;
    }

    _message(
      'Complete all required fields.',
    );

    return false;
  }

  void _message(
    String text,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(text),
        ),
      );
  }

  String _pretty(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),
      appBar:
          AppBar(
        title:
            const Text(
          'Access & Attendance Management',
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            AppColors.textDark,
        elevation:
            0,
        leading:
            IconButton(
          icon:
              const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed:
              () => context.go('/'),
        ),
      ),
      body:
          ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const Text(
            'Employee access control',
            style:
                TextStyle(
              fontSize:
                  24,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Attendance is always available. Other modules appear only after the employee receives permission.',
            style:
                TextStyle(
              color:
                  AppColors.textLight,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          _card(
            'Organization & manager',
            [
              _field(
                _organization,
                'Organization ID',
              ),

              _field(
                _admin,
                'Manager / Owner User ID',
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        FilledButton.icon(
                      onPressed:
                          _bootstrapOwner,
                      icon:
                          const Icon(
                        Icons
                            .verified_user_rounded,
                      ),
                      label:
                          const Text(
                        'Initialize Owner',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          _card(
            'Employee permissions',
            [
              _field(
                _user,
                'Employee User ID',
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _loadUser,
                      icon:
                          const Icon(
                        Icons.refresh_rounded,
                      ),
                      label:
                          const Text(
                        'Load user',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          () => _useAsCurrentUser(
                        _user.text,
                      ),
                      icon:
                          const Icon(
                        Icons.login_rounded,
                      ),
                      label:
                          const Text(
                        'Use as current user',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    _role,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Role',
                  border:
                      OutlineInputBorder(),
                ),
                items:
                    AttendancePermissionModel
                        .roles
                        .map(
                  (role) =>
                      DropdownMenuItem<String>(
                    value:
                        role,
                    child:
                        Text(role),
                  ),
                ).toList(),
                onChanged:
                    (value) {
                  setState(() {
                    _role =
                        value ??
                            'Employee';
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'Location attendance',
                ),
                subtitle:
                    const Text(
                  'Employee can check in/out using the project geofence.',
                ),
                value:
                    _locationEnabled,
                onChanged:
                    (value) {
                  setState(() {
                    _locationEnabled =
                        value;
                  });
                },
              ),

              const Divider(),

              const Text(
                'Modules',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              ..._permissions.keys.map(
                (key) =>
                    CheckboxListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  value:
                      _role ==
                              'Owner'
                          ? true
                          : _permissions[key],
                  title:
                      Text(
                    _pretty(key),
                  ),
                  onChanged:
                      _role ==
                              'Owner'
                          ? null
                          : (value) {
                              setState(
                                () {
                                  _permissions[
                                          key] =
                                      value ??
                                          false;
                                },
                              );
                            },
                ),
              ),

              _field(
                _allowedProjects,
                'Allowed project IDs (comma-separated)',
              ),

              _field(
                _projects,
                'Managed project IDs (for managers)',
              ),

              FilledButton.icon(
                onPressed:
                    _savePermission,
                icon:
                    const Icon(
                  Icons.save_rounded,
                ),
                label:
                    const Text(
                  'Save permissions',
                ),
              ),
            ],
          ),

          _card(
            'Project attendance location',
            [
              _field(
                _project,
                'Project ID',
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Select the project location directly from the map.',
                style:
                    TextStyle(
                  color:
                      AppColors.textLight,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              _buildMap(),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _gettingLocation
                              ? null
                              : _useCurrentLocation,
                      icon:
                          _gettingLocation
                              ? const SizedBox(
                                  width:
                                      18,
                                  height:
                                      18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .my_location_rounded,
                                ),
                      label:
                          Text(
                        _gettingLocation
                            ? 'Getting location...'
                            : 'Use my current location',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              if (_selectedLocation !=
                  null)
                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border:
                        Border.all(
                      color:
                          Colors.black12,
                    ),
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected location',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                      ),
                      Text(
                        'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 12,
              ),

              DropdownButtonFormField<double>(
                initialValue:
                    _radius,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Attendance radius',
                  border:
                      OutlineInputBorder(),
                ),
                items:
                    ProjectGeofenceModel
                        .allowedRadiusMeters
                        .map(
                  (radius) =>
                      DropdownMenuItem<double>(
                    value:
                        radius,
                    child:
                        Text(
                      '${radius.toInt()} meters',
                    ),
                  ),
                ).toList(),
                onChanged:
                    (value) {
                  setState(() {
                    _radius =
                        value ??
                            100;
                  });
                },
              ),

              const SizedBox(
                height: 8,
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'Enable attendance at this project',
                ),
                value:
                    _geofenceEnabled,
                onChanged:
                    (value) {
                  setState(() {
                    _geofenceEnabled =
                        value;
                  });
                },
              ),

              FilledButton.icon(
                onPressed:
                    _saveGeofence,
                icon:
                    const Icon(
                  Icons.location_on_rounded,
                ),
                label:
                    const Text(
                  'Save project location',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(
    String title,
    List<Widget> children,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(18),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            ...children.map(
              (child) =>
                  Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child:
                    child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return TextField(
      controller:
          controller,
      keyboardType:
          number
              ? const TextInputType.numberWithOptions(
                  decimal:
                      true,
                  signed:
                      true,
                )
              : TextInputType.text,
      decoration:
          InputDecoration(
        labelText:
            label,
        border:
            const OutlineInputBorder(),
      ),
    );
  }
}