class EngineeringDocumentType {
  final String name;
  final String abbreviation;
  final String discipline;
  final String category;
  final List<String> aliases;

  const EngineeringDocumentType({
    required this.name,
    required this.abbreviation,
    required this.discipline,
    required this.category,
    this.aliases = const [],
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return false;
    }

    final values = [
      name,
      abbreviation,
      discipline,
      category,
      ...aliases,
    ];

    return values.any(
      (value) =>
          value.toLowerCase().contains(q),
    );
  }
}

class EngineeringDocumentCatalog {
  EngineeringDocumentCatalog._();

  static const List<EngineeringDocumentType> all = [
    // ============================================================
    // GENERAL / PROJECT DOCUMENTS
    // ============================================================

    EngineeringDocumentType(
      name: 'General Arrangement',
      abbreviation: 'GA',
      discipline: 'General',
      category: 'Drawings',
      aliases: [
        'general arrangement drawing',
        'arrangement',
        'general',
      ],
    ),

    EngineeringDocumentType(
      name: 'General Layout',
      abbreviation: 'GL',
      discipline: 'General',
      category: 'Drawings',
      aliases: [
        'layout',
        'general layout drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Key Plan',
      abbreviation: 'KP',
      discipline: 'General',
      category: 'Drawings',
      aliases: [
        'keyplan',
        'location plan',
      ],
    ),

    EngineeringDocumentType(
      name: 'Site Plan',
      abbreviation: 'SP',
      discipline: 'General',
      category: 'Drawings',
      aliases: [
        'site layout',
        'site drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Typical Detail',
      abbreviation: 'TD',
      discipline: 'General',
      category: 'Details',
      aliases: [
        'typical details',
        'detail',
      ],
    ),

    EngineeringDocumentType(
      name: 'As-Built Drawing',
      abbreviation: 'AS-BUILT',
      discipline: 'General',
      category: 'Drawings',
      aliases: [
        'as built',
        'asbuilt',
        'record drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Shop Drawing',
      abbreviation: 'SD',
      discipline: 'General',
      category: 'Shop Drawings',
      aliases: [
        'shop',
        'fabrication drawing',
        'construction drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Issued For Construction',
      abbreviation: 'IFC',
      discipline: 'General',
      category: 'Issue Status',
      aliases: [
        'construction',
        'issued for construction',
      ],
    ),

    EngineeringDocumentType(
      name: 'Issued For Approval',
      abbreviation: 'IFA',
      discipline: 'General',
      category: 'Issue Status',
      aliases: [
        'approval',
        'issued for approval',
      ],
    ),

    EngineeringDocumentType(
      name: 'Issued For Tender',
      abbreviation: 'IFT',
      discipline: 'General',
      category: 'Issue Status',
      aliases: [
        'tender',
        'issued for tender',
      ],
    ),

    // ============================================================
    // ARCHITECTURE
    // ============================================================

    EngineeringDocumentType(
      name: 'Architectural Drawing',
      abbreviation: 'AR',
      discipline: 'Architecture',
      category: 'Drawings',
      aliases: [
        'architectural',
        'architecture',
        'arch',
      ],
    ),

    EngineeringDocumentType(
      name: 'Architectural Floor Plan',
      abbreviation: 'AFP',
      discipline: 'Architecture',
      category: 'Drawings',
      aliases: [
        'floor plan',
        'floor',
        'plan',
      ],
    ),

    EngineeringDocumentType(
      name: 'Architectural Elevation',
      abbreviation: 'AE',
      discipline: 'Architecture',
      category: 'Drawings',
      aliases: [
        'elevation',
        'facade',
        'facade drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Architectural Section',
      abbreviation: 'AS',
      discipline: 'Architecture',
      category: 'Drawings',
      aliases: [
        'section',
        'architectural section',
      ],
    ),

    EngineeringDocumentType(
      name: 'Reflected Ceiling Plan',
      abbreviation: 'RCP',
      discipline: 'Architecture',
      category: 'Drawings',
      aliases: [
        'ceiling plan',
        'reflected ceiling',
      ],
    ),

    EngineeringDocumentType(
      name: 'Door Schedule',
      abbreviation: 'DS',
      discipline: 'Architecture',
      category: 'Schedules',
      aliases: [
        'doors',
        'door',
      ],
    ),

    EngineeringDocumentType(
      name: 'Window Schedule',
      abbreviation: 'WS',
      discipline: 'Architecture',
      category: 'Schedules',
      aliases: [
        'windows',
        'window',
      ],
    ),

    EngineeringDocumentType(
      name: 'Finishing Schedule',
      abbreviation: 'FS',
      discipline: 'Architecture',
      category: 'Schedules',
      aliases: [
        'finishes',
        'finishing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Room Finish Schedule',
      abbreviation: 'RFS',
      discipline: 'Architecture',
      category: 'Schedules',
      aliases: [
        'room finish',
      ],
    ),

    // ============================================================
    // STRUCTURAL / CIVIL STRUCTURES
    // ============================================================

    EngineeringDocumentType(
      name: 'Structural Drawing',
      abbreviation: 'ST',
      discipline: 'Structural',
      category: 'Drawings',
      aliases: [
        'structural',
        'structure',
        'struct',
      ],
    ),

    EngineeringDocumentType(
      name: 'Reinforced Concrete Drawing',
      abbreviation: 'RC',
      discipline: 'Structural',
      category: 'Drawings',
      aliases: [
        'reinforced concrete',
        'concrete',
        'rc drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Foundation Plan',
      abbreviation: 'FP',
      discipline: 'Structural',
      category: 'Drawings',
      aliases: [
        'foundation',
        'foundations',
        'footing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Column Schedule',
      abbreviation: 'CS',
      discipline: 'Structural',
      category: 'Schedules',
      aliases: [
        'column',
        'columns',
      ],
    ),

    EngineeringDocumentType(
      name: 'Beam Schedule',
      abbreviation: 'BS',
      discipline: 'Structural',
      category: 'Schedules',
      aliases: [
        'beam',
        'beams',
      ],
    ),

    EngineeringDocumentType(
      name: 'Slab Schedule',
      abbreviation: 'SS',
      discipline: 'Structural',
      category: 'Schedules',
      aliases: [
        'slab',
        'slabs',
      ],
    ),

    EngineeringDocumentType(
      name: 'Foundation Schedule',
      abbreviation: 'FS',
      discipline: 'Structural',
      category: 'Schedules',
      aliases: [
        'foundation schedule',
        'footing schedule',
      ],
    ),

    EngineeringDocumentType(
      name: 'Structural Detail',
      abbreviation: 'STD',
      discipline: 'Structural',
      category: 'Details',
      aliases: [
        'structural detail',
        'structure detail',
      ],
    ),

    EngineeringDocumentType(
      name: 'Rebar Detail',
      abbreviation: 'RD',
      discipline: 'Structural',
      category: 'Details',
      aliases: [
        'reinforcement',
        'rebar',
        'reinforcement detail',
      ],
    ),

    EngineeringDocumentType(
      name: 'Steel Structure Drawing',
      abbreviation: 'SSD',
      discipline: 'Structural',
      category: 'Drawings',
      aliases: [
        'steel',
        'steel structure',
        'structural steel',
      ],
    ),

    // ============================================================
    // ROADS
    // ============================================================

    EngineeringDocumentType(
      name: 'Road Layout',
      abbreviation: 'RL',
      discipline: 'Roads',
      category: 'Drawings',
      aliases: [
        'road',
        'roads',
        'road plan',
      ],
    ),

    EngineeringDocumentType(
      name: 'Road Alignment',
      abbreviation: 'RA',
      discipline: 'Roads',
      category: 'Drawings',
      aliases: [
        'alignment',
        'horizontal alignment',
      ],
    ),

    EngineeringDocumentType(
      name: 'Horizontal Alignment',
      abbreviation: 'HA',
      discipline: 'Roads',
      category: 'Drawings',
      aliases: [
        'horizontal',
        'alignment',
      ],
    ),

    EngineeringDocumentType(
      name: 'Vertical Alignment',
      abbreviation: 'VA',
      discipline: 'Roads',
      category: 'Drawings',
      aliases: [
        'vertical',
        'profile',
        'road profile',
      ],
    ),

    EngineeringDocumentType(
      name: 'Road Longitudinal Profile',
      abbreviation: 'LP',
      discipline: 'Roads',
      category: 'Profiles',
      aliases: [
        'long profile',
        'longitudinal profile',
        'profile',
      ],
    ),

    EngineeringDocumentType(
      name: 'Typical Road Cross Section',
      abbreviation: 'TRCS',
      discipline: 'Roads',
      category: 'Sections',
      aliases: [
        'road cross section',
        'cross section',
        'typical road',
      ],
    ),

    EngineeringDocumentType(
      name: 'Pavement Design',
      abbreviation: 'PD',
      discipline: 'Roads',
      category: 'Design',
      aliases: [
        'pavement',
        'pavement drawing',
      ],
    ),

    // ============================================================
    // BRIDGES
    // ============================================================

    EngineeringDocumentType(
      name: 'Bridge General Arrangement',
      abbreviation: 'BGA',
      discipline: 'Bridges',
      category: 'Drawings',
      aliases: [
        'bridge',
        'bridge ga',
      ],
    ),

    EngineeringDocumentType(
      name: 'Bridge Elevation',
      abbreviation: 'BE',
      discipline: 'Bridges',
      category: 'Drawings',
      aliases: [
        'bridge elevation',
      ],
    ),

    EngineeringDocumentType(
      name: 'Bridge Section',
      abbreviation: 'BS',
      discipline: 'Bridges',
      category: 'Sections',
      aliases: [
        'bridge section',
      ],
    ),

    EngineeringDocumentType(
      name: 'Abutment Drawing',
      abbreviation: 'AD',
      discipline: 'Bridges',
      category: 'Drawings',
      aliases: [
        'abutment',
      ],
    ),

    EngineeringDocumentType(
      name: 'Pier Drawing',
      abbreviation: 'PIER',
      discipline: 'Bridges',
      category: 'Drawings',
      aliases: [
        'pier',
        'bridge pier',
      ],
    ),

    EngineeringDocumentType(
      name: 'Bridge Deck Drawing',
      abbreviation: 'BDD',
      discipline: 'Bridges',
      category: 'Drawings',
      aliases: [
        'deck',
        'bridge deck',
      ],
    ),

    // ============================================================
    // DRAINAGE / STORM WATER
    // ============================================================

    EngineeringDocumentType(
      name: 'Drainage Drawing',
      abbreviation: 'DR',
      discipline: 'Drainage',
      category: 'Drawings',
      aliases: [
        'drainage',
        'drain',
      ],
    ),

    EngineeringDocumentType(
      name: 'Storm Water Drainage',
      abbreviation: 'SWD',
      discipline: 'Drainage',
      category: 'Drawings',
      aliases: [
        'storm water',
        'stormwater',
        'rain water',
      ],
    ),

    EngineeringDocumentType(
      name: 'Drainage Profile',
      abbreviation: 'DP',
      discipline: 'Drainage',
      category: 'Profiles',
      aliases: [
        'drainage profile',
      ],
    ),

    EngineeringDocumentType(
      name: 'Manhole Schedule',
      abbreviation: 'MHS',
      discipline: 'Drainage',
      category: 'Schedules',
      aliases: [
        'manhole',
        'manholes',
      ],
    ),

    // ============================================================
    // WATER / SEWER
    // ============================================================

    EngineeringDocumentType(
      name: 'Water Supply Drawing',
      abbreviation: 'WS',
      discipline: 'Water',
      category: 'Drawings',
      aliases: [
        'water',
        'water supply',
      ],
    ),

    EngineeringDocumentType(
      name: 'Water Network Layout',
      abbreviation: 'WNL',
      discipline: 'Water',
      category: 'Drawings',
      aliases: [
        'water network',
      ],
    ),

    EngineeringDocumentType(
      name: 'Sewerage Drawing',
      abbreviation: 'SEW',
      discipline: 'Sewerage',
      category: 'Drawings',
      aliases: [
        'sewer',
        'sewerage',
        'sewage',
      ],
    ),

    EngineeringDocumentType(
      name: 'Sewer Network Layout',
      abbreviation: 'SNL',
      discipline: 'Sewerage',
      category: 'Drawings',
      aliases: [
        'sewer network',
      ],
    ),

    // ============================================================
    // ELECTRICAL
    // ============================================================

    EngineeringDocumentType(
      name: 'Electrical Drawing',
      abbreviation: 'EL',
      discipline: 'Electrical',
      category: 'Drawings',
      aliases: [
        'electrical',
        'electric',
      ],
    ),

    EngineeringDocumentType(
      name: 'Single Line Diagram',
      abbreviation: 'SLD',
      discipline: 'Electrical',
      category: 'Diagrams',
      aliases: [
        'single line',
        'one line diagram',
      ],
    ),

    EngineeringDocumentType(
      name: 'Electrical Layout',
      abbreviation: 'ELL',
      discipline: 'Electrical',
      category: 'Drawings',
      aliases: [
        'electrical layout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Lighting Layout',
      abbreviation: 'LL',
      discipline: 'Electrical',
      category: 'Drawings',
      aliases: [
        'lighting',
        'light',
      ],
    ),

    EngineeringDocumentType(
      name: 'Power Layout',
      abbreviation: 'PL',
      discipline: 'Electrical',
      category: 'Drawings',
      aliases: [
        'power',
        'power drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Distribution Board Schedule',
      abbreviation: 'DBS',
      discipline: 'Electrical',
      category: 'Schedules',
      aliases: [
        'distribution board',
        'db schedule',
        'db',
      ],
    ),

    EngineeringDocumentType(
      name: 'Cable Schedule',
      abbreviation: 'CS',
      discipline: 'Electrical',
      category: 'Schedules',
      aliases: [
        'cable',
        'cables',
      ],
    ),

    EngineeringDocumentType(
      name: 'Load Schedule',
      abbreviation: 'LS',
      discipline: 'Electrical',
      category: 'Schedules',
      aliases: [
        'electrical load',
        'load',
      ],
    ),

    // ============================================================
    // MECHANICAL / HVAC
    // ============================================================

    EngineeringDocumentType(
      name: 'Mechanical Drawing',
      abbreviation: 'ME',
      discipline: 'Mechanical',
      category: 'Drawings',
      aliases: [
        'mechanical',
        'mech',
      ],
    ),

    EngineeringDocumentType(
      name: 'HVAC Drawing',
      abbreviation: 'HVAC',
      discipline: 'Mechanical',
      category: 'Drawings',
      aliases: [
        'hvac',
        'air conditioning',
        'ac',
        'ventilation',
      ],
    ),

    EngineeringDocumentType(
      name: 'HVAC Layout',
      abbreviation: 'HVL',
      discipline: 'Mechanical',
      category: 'Drawings',
      aliases: [
        'hvac layout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Duct Layout',
      abbreviation: 'DL',
      discipline: 'Mechanical',
      category: 'Drawings',
      aliases: [
        'duct',
        'ductwork',
      ],
    ),

    EngineeringDocumentType(
      name: 'Equipment Layout',
      abbreviation: 'EL',
      discipline: 'Mechanical',
      category: 'Drawings',
      aliases: [
        'equipment',
        'equipment drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Mechanical Equipment Schedule',
      abbreviation: 'MES',
      discipline: 'Mechanical',
      category: 'Schedules',
      aliases: [
        'equipment schedule',
      ],
    ),

    // ============================================================
    // PLUMBING
    // ============================================================

    EngineeringDocumentType(
      name: 'Plumbing Drawing',
      abbreviation: 'PL',
      discipline: 'Plumbing',
      category: 'Drawings',
      aliases: [
        'plumbing',
        'sanitary',
        'sanitary drawing',
      ],
    ),

    EngineeringDocumentType(
      name: 'Plumbing Layout',
      abbreviation: 'PLL',
      discipline: 'Plumbing',
      category: 'Drawings',
      aliases: [
        'plumbing layout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Sanitary Drainage Layout',
      abbreviation: 'SDL',
      discipline: 'Plumbing',
      category: 'Drawings',
      aliases: [
        'sanitary drainage',
        'sanitary',
      ],
    ),

    // ============================================================
    // FIRE FIGHTING / FIRE ALARM
    // ============================================================

    EngineeringDocumentType(
      name: 'Fire Fighting Drawing',
      abbreviation: 'FF',
      discipline: 'Fire Fighting',
      category: 'Drawings',
      aliases: [
        'fire fighting',
        'firefighting',
        'fire',
      ],
    ),

    EngineeringDocumentType(
      name: 'Fire Protection Drawing',
      abbreviation: 'FP',
      discipline: 'Fire Fighting',
      category: 'Drawings',
      aliases: [
        'fire protection',
      ],
    ),

    EngineeringDocumentType(
      name: 'Fire Alarm Drawing',
      abbreviation: 'FA',
      discipline: 'Fire Alarm',
      category: 'Drawings',
      aliases: [
        'fire alarm',
        'alarm',
      ],
    ),

    // ============================================================
    // ELV / TELECOM / SECURITY
    // ============================================================

    EngineeringDocumentType(
      name: 'ELV Drawing',
      abbreviation: 'ELV',
      discipline: 'ELV',
      category: 'Drawings',
      aliases: [
        'extra low voltage',
        'low current',
        'low current system',
      ],
    ),

    EngineeringDocumentType(
      name: 'CCTV Layout',
      abbreviation: 'CCTV',
      discipline: 'ELV',
      category: 'Drawings',
      aliases: [
        'cctv',
        'camera',
        'security camera',
      ],
    ),

    EngineeringDocumentType(
      name: 'Access Control Drawing',
      abbreviation: 'ACS',
      discipline: 'ELV',
      category: 'Drawings',
      aliases: [
        'access control',
        'access',
      ],
    ),

    EngineeringDocumentType(
      name: 'Telecom Drawing',
      abbreviation: 'TEL',
      discipline: 'Telecom',
      category: 'Drawings',
      aliases: [
        'telecom',
        'telecommunication',
      ],
    ),

    // ============================================================
    // PETROCHEMICAL / OIL & GAS / PROCESS
    // ============================================================

    EngineeringDocumentType(
      name: 'Piping & Instrumentation Diagram',
      abbreviation: 'P&ID',
      discipline: 'Process',
      category: 'Diagrams',
      aliases: [
        'pid',
        'p and id',
        'piping instrumentation',
        'piping and instrumentation',
      ],
    ),

    EngineeringDocumentType(
      name: 'Process Flow Diagram',
      abbreviation: 'PFD',
      discipline: 'Process',
      category: 'Diagrams',
      aliases: [
        'pfd',
        'process flow',
      ],
    ),

    EngineeringDocumentType(
      name: 'Utility Flow Diagram',
      abbreviation: 'UFD',
      discipline: 'Process',
      category: 'Diagrams',
      aliases: [
        'ufd',
        'utility flow',
      ],
    ),

    EngineeringDocumentType(
      name: 'Piping Layout',
      abbreviation: 'PL',
      discipline: 'Piping',
      category: 'Drawings',
      aliases: [
        'piping',
        'pipe layout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Piping Isometric',
      abbreviation: 'ISO',
      discipline: 'Piping',
      category: 'Isometrics',
      aliases: [
        'isometric',
        'iso',
        'pipe iso',
      ],
    ),

    EngineeringDocumentType(
      name: 'Piping General Arrangement',
      abbreviation: 'PGA',
      discipline: 'Piping',
      category: 'Drawings',
      aliases: [
        'piping ga',
      ],
    ),

    EngineeringDocumentType(
      name: 'Equipment Arrangement',
      abbreviation: 'EA',
      discipline: 'Process',
      category: 'Drawings',
      aliases: [
        'equipment arrangement',
      ],
    ),

    EngineeringDocumentType(
      name: 'Plot Plan',
      abbreviation: 'PP',
      discipline: 'Process',
      category: 'Drawings',
      aliases: [
        'plot',
        'plant layout',
        'site layout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Instrument Diagram',
      abbreviation: 'ID',
      discipline: 'Instrumentation',
      category: 'Diagrams',
      aliases: [
        'instrumentation',
        'instrument',
      ],
    ),

    EngineeringDocumentType(
      name: 'Instrument Loop Diagram',
      abbreviation: 'ILD',
      discipline: 'Instrumentation',
      category: 'Diagrams',
      aliases: [
        'loop diagram',
        'instrument loop',
      ],
    ),

    // ============================================================
    // SURVEY / GEOTECHNICAL
    // ============================================================

    EngineeringDocumentType(
      name: 'Topographical Survey',
      abbreviation: 'TS',
      discipline: 'Survey',
      category: 'Survey',
      aliases: [
        'topographic',
        'topography',
        'survey',
      ],
    ),

    EngineeringDocumentType(
      name: 'Setting Out Drawing',
      abbreviation: 'SO',
      discipline: 'Survey',
      category: 'Survey',
      aliases: [
        'setting out',
        'setout',
      ],
    ),

    EngineeringDocumentType(
      name: 'Coordinate Drawing',
      abbreviation: 'CD',
      discipline: 'Survey',
      category: 'Survey',
      aliases: [
        'coordinates',
        'coordinate',
      ],
    ),

    EngineeringDocumentType(
      name: 'Geotechnical Drawing',
      abbreviation: 'GT',
      discipline: 'Geotechnical',
      category: 'Drawings',
      aliases: [
        'geotechnical',
        'geotech',
      ],
    ),

    EngineeringDocumentType(
      name: 'Borehole Location Plan',
      abbreviation: 'BLP',
      discipline: 'Geotechnical',
      category: 'Drawings',
      aliases: [
        'borehole',
        'soil investigation',
      ],
    ),

    // ============================================================
    // LANDSCAPE
    // ============================================================

    EngineeringDocumentType(
      name: 'Landscape Drawing',
      abbreviation: 'LS',
      discipline: 'Landscape',
      category: 'Drawings',
      aliases: [
        'landscape',
        'landscaping',
      ],
    ),

    EngineeringDocumentType(
      name: 'Hardscape Layout',
      abbreviation: 'HL',
      discipline: 'Landscape',
      category: 'Drawings',
      aliases: [
        'hardscape',
      ],
    ),

    // ============================================================
    // QA / QC / ENGINEERING DOCUMENTS
    // ============================================================

    EngineeringDocumentType(
      name: 'Request for Information',
      abbreviation: 'RFI',
      discipline: 'Technical',
      category: 'Correspondence',
      aliases: [
        'request for information',
        'information request',
      ],
    ),

    EngineeringDocumentType(
      name: 'Material Submittal',
      abbreviation: 'MS',
      discipline: 'Technical',
      category: 'Submittals',
      aliases: [
        'material submission',
        'material submittal',
        'material',
      ],
    ),

    EngineeringDocumentType(
      name: 'Material Inspection Request',
      abbreviation: 'MIR',
      discipline: 'QA/QC',
      category: 'Inspection',
      aliases: [
        'material inspection',
        'mir',
      ],
    ),

    EngineeringDocumentType(
      name: 'Work Inspection Request',
      abbreviation: 'WIR',
      discipline: 'QA/QC',
      category: 'Inspection',
      aliases: [
        'work inspection',
        'wir',
      ],
    ),

    EngineeringDocumentType(
      name: 'Inspection and Test Plan',
      abbreviation: 'ITP',
      discipline: 'QA/QC',
      category: 'Quality',
      aliases: [
        'inspection test plan',
        'inspection plan',
      ],
    ),

    EngineeringDocumentType(
      name: 'Non-Conformance Report',
      abbreviation: 'NCR',
      discipline: 'QA/QC',
      category: 'Quality',
      aliases: [
        'nonconformance',
        'non conformity',
        'non-conformance',
      ],
    ),

    EngineeringDocumentType(
      name: 'Method Statement',
      abbreviation: 'MS',
      discipline: 'Technical',
      category: 'Methodology',
      aliases: [
        'method',
        'methodology',
      ],
    ),

    EngineeringDocumentType(
      name: 'Technical Query',
      abbreviation: 'TQ',
      discipline: 'Technical',
      category: 'Correspondence',
      aliases: [
        'technical question',
        'query',
      ],
    ),

    EngineeringDocumentType(
      name: 'Site Inspection Report',
      abbreviation: 'SIR',
      discipline: 'QA/QC',
      category: 'Reports',
      aliases: [
        'site inspection',
        'inspection report',
      ],
    ),

    // ============================================================
    // COMMERCIAL / CONTRACTUAL
    // ============================================================

    EngineeringDocumentType(
      name: 'Bill of Quantities',
      abbreviation: 'BOQ',
      discipline: 'Commercial',
      category: 'Commercial',
      aliases: [
        'bill of quantity',
        'quantity',
        'quantities',
      ],
    ),

    EngineeringDocumentType(
      name: 'Quantity Takeoff',
      abbreviation: 'QTO',
      discipline: 'Commercial',
      category: 'Commercial',
      aliases: [
        'takeoff',
        'quantity takeoff',
      ],
    ),

    EngineeringDocumentType(
      name: 'Variation Order',
      abbreviation: 'VO',
      discipline: 'Commercial',
      category: 'Commercial',
      aliases: [
        'variation',
        'change order',
      ],
    ),

    EngineeringDocumentType(
      name: 'Payment Application',
      abbreviation: 'PA',
      discipline: 'Commercial',
      category: 'Commercial',
      aliases: [
        'payment',
        'payment certificate',
      ],
    ),

    EngineeringDocumentType(
      name: 'Contract',
      abbreviation: 'CON',
      discipline: 'Contractual',
      category: 'Contracts',
      aliases: [
        'contract document',
        'agreement',
      ],
    ),

    EngineeringDocumentType(
      name: 'Letter',
      abbreviation: 'LTR',
      discipline: 'Correspondence',
      category: 'Correspondence',
      aliases: [
        'letter',
        'official letter',
      ],
    ),

    EngineeringDocumentType(
      name: 'Meeting Minutes',
      abbreviation: 'MOM',
      discipline: 'General',
      category: 'Meetings',
      aliases: [
        'minutes',
        'minutes of meeting',
        'meeting',
      ],
    ),

    // ============================================================
    // HSE
    // ============================================================

    EngineeringDocumentType(
      name: 'Health Safety and Environment Document',
      abbreviation: 'HSE',
      discipline: 'HSE',
      category: 'HSE',
      aliases: [
        'health safety environment',
        'safety',
        'health and safety',
      ],
    ),

    EngineeringDocumentType(
      name: 'Risk Assessment',
      abbreviation: 'RA',
      discipline: 'HSE',
      category: 'HSE',
      aliases: [
        'risk',
        'risk assessment',
      ],
    ),

    EngineeringDocumentType(
      name: 'Permit to Work',
      abbreviation: 'PTW',
      discipline: 'HSE',
      category: 'HSE',
      aliases: [
        'permit',
        'work permit',
      ],
    ),
  ];

  static List<EngineeringDocumentType> search(
    String query,
  ) {
    final q = query.trim();

    if (q.isEmpty) {
      return const [];
    }

    final results = all
        .where(
          (document) =>
              document.matches(q),
        )
        .toList();

    results.sort(
      (a, b) {
        final queryLower =
            q.toLowerCase();

        final aAbbreviation =
            a.abbreviation.toLowerCase();

        final bAbbreviation =
            b.abbreviation.toLowerCase();

        final aName =
            a.name.toLowerCase();

        final bName =
            b.name.toLowerCase();

        final aExact =
            aAbbreviation == queryLower;

        final bExact =
            bAbbreviation == queryLower;

        if (aExact && !bExact) {
          return -1;
        }

        if (!aExact && bExact) {
          return 1;
        }

        final aStarts =
            aAbbreviation
                    .startsWith(queryLower) ||
                aName.startsWith(queryLower);

        final bStarts =
            bAbbreviation
                    .startsWith(queryLower) ||
                bName.startsWith(queryLower);

        if (aStarts && !bStarts) {
          return -1;
        }

        if (!aStarts && bStarts) {
          return 1;
        }

        return a.name.compareTo(
          b.name,
        );
      },
    );

    return results;
  }
}