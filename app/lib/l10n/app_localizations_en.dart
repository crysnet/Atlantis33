// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ARES PATH';

  @override
  String get siteName => 'Meridiani · Regional context (100 km)';

  @override
  String get navPlan => 'PLAN';

  @override
  String get navSafety => 'SAFETY';

  @override
  String get navScience => 'SCIENCE';

  @override
  String get language => 'Language';

  @override
  String get layersTitle => 'DATA LAYERS';

  @override
  String layersActive(int n) {
    return '$n ACTIVE';
  }

  @override
  String get layersReset => 'RESET';

  @override
  String get layerOptical => 'Optical surface';

  @override
  String get layerHillshade => 'Relief (hillshade)';

  @override
  String get layerSlope => 'Relief';

  @override
  String get layerForbidden => 'Forbidden zones';

  @override
  String get layerCuriosity => 'Curiosity track';

  @override
  String get layerThermal => 'Thermal (THEMIS-IR day)';

  @override
  String get layerMinerals => 'Mineralogy';

  @override
  String get layerRadiation => 'Radiation flux';

  @override
  String get layerNoData => 'No data yet';

  @override
  String get kindMeasured => 'MEASURED';

  @override
  String get kindModeled => 'MODELED';

  @override
  String get kindExample => 'EXAMPLE';

  @override
  String get opacity => 'OPACITY';

  @override
  String get legendTitle => 'SLOPE LEGEND';

  @override
  String get legendNominal => '< 10° nominal';

  @override
  String get legendCaution => '10–20° caution';

  @override
  String get legendHigh => '20–25° high caution';

  @override
  String get legendForbidden => '> 25° forbidden';

  @override
  String get routesTitle => 'ROUTE COMPARISON';

  @override
  String get routeSafe => 'Safest';

  @override
  String get routeFast => 'Fastest';

  @override
  String get routeScience => 'Most science';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricDuration => 'Duration';

  @override
  String get metricMaxSlope => 'Max slope';

  @override
  String get metricClimb => 'Climb';

  @override
  String get metricO2 => 'O₂ at return';

  @override
  String get metricDose => 'Dose';

  @override
  String get metricNoReturn => 'Point of no return';

  @override
  String get metricWalk => 'Walking';

  @override
  String get metricStops => 'Work stops';

  @override
  String get hazardScore => 'HAZARD';

  @override
  String get successScore => 'SUCCESS';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get hzSlope => 'Slope exposure';

  @override
  String get hzTerrain => 'Rough / loose terrain';

  @override
  String get hzWalkback => 'Beyond walk-back range';

  @override
  String get hzConsumables => 'Consumables margin';

  @override
  String get hzRadiation => 'Radiation dose';

  @override
  String get hzDay => 'Day conditions (example)';

  @override
  String get scValue => 'Science value';

  @override
  String get scTime => 'Time factor';

  @override
  String get scConsumables => 'Consumables factor';

  @override
  String get scPenalty => 'Hazard penalty';

  @override
  String get objectivesTitle => 'SCIENCE OBJECTIVES';

  @override
  String get objectivesAdd => 'ADD OBJECTIVE';

  @override
  String get objectivesAddActive => 'TAP THE MAP TO PLACE IT';

  @override
  String get objectivesEmpty => 'No objectives. Add one to plan a route.';

  @override
  String get typeSample => 'Sample';

  @override
  String get typeImage => 'Image';

  @override
  String get typeMeasurement => 'Measurement';

  @override
  String get typeEquipment => 'Equipment';

  @override
  String priorityLabel(int p) {
    return 'Priority $p';
  }

  @override
  String workMinutes(int m) {
    return '$m min';
  }

  @override
  String get objectiveEdit => 'Edit objective';

  @override
  String get objectiveNewName => 'New objective';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldPriority => 'Priority (1 to 5)';

  @override
  String get fieldWork => 'Work time (min)';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get objectiveForbidden => 'In forbidden terrain';

  @override
  String get statusFeasible => 'FEASIBLE';

  @override
  String get statusNotFeasible => 'NOT FEASIBLE';

  @override
  String get statusUnreachable => 'UNREACHABLE';

  @override
  String get statusNoTarget => 'NO TARGET';

  @override
  String get visits => 'Visits';

  @override
  String get skippedLabel => 'Not included';

  @override
  String get reasonBlocked => 'forbidden terrain';

  @override
  String get reasonUnreachable => 'unreachable';

  @override
  String get reasonTime => 'not enough time';

  @override
  String get reasonOxygen => 'not enough oxygen';

  @override
  String get reasonMargin => 'margin too thin';

  @override
  String get reasonNotPrimary => 'not on this route';

  @override
  String get computing => 'COMPUTING ROUTES…';

  @override
  String get assumptionsTitle => 'ASSUMPTIONS';

  @override
  String get assumptionsNote => 'Team assumptions, not NASA standards.';

  @override
  String get assumeSpeed => 'Walking speed on flat ground';

  @override
  String get assumeEva => 'Maximum EVA duration';

  @override
  String get assumeO2 => 'Oxygen capacity';

  @override
  String get assumeReserve => 'Minimum oxygen reserve';

  @override
  String get assumeSlopeLimit => 'Slope limit (safest / others)';

  @override
  String get assumeDose => 'Radiation dose rate (measured, RAD)';

  @override
  String get profileTitle => 'ELEVATION & SLOPE PROFILE';

  @override
  String get habitat => 'HABITAT';

  @override
  String get pnrShort => 'PNR';

  @override
  String get elevation => 'ELEV';

  @override
  String get attribution => 'HiRISE (NASA/JPL/UArizona) · USGS Astrogeology';

  @override
  String get hintDrag =>
      'Drag to pan · scroll to zoom · tap an objective to edit';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomFit => 'Fit to view';

  @override
  String get soon => 'Coming next';

  @override
  String get sciTargetsTitle => 'TARGETS // SORTIE';

  @override
  String get sciDetail => 'TARGET DETAIL';

  @override
  String get sciOrbital => 'ORBITAL · HiRISE';

  @override
  String get sciGround => 'GROUND · ROVER PHOTO';

  @override
  String get sciGroundSoon => 'No rover photo for this objective';

  @override
  String get sciGroundNote => 'Photo from that sol, taken near this stop';

  @override
  String get sciDataStack => 'DATA STACK AT THIS POINT';

  @override
  String get sciPick => 'Select an objective';

  @override
  String get stackOptical => 'Optical imagery';

  @override
  String get stackTopo => 'Topography & slopes';

  @override
  String get stackThermal => 'Thermal (THEMIS-IR day)';

  @override
  String get stackThermalNote =>
      'THEMIS-IR day mosaic · about 100 m/px · relative brightness, not calibrated temperature · source: Mars Trek';

  @override
  String get stackMinerals => 'Mineralogy';

  @override
  String get stackRadiation => 'Radiation';

  @override
  String get stackGeology => 'Geologic unit';

  @override
  String get stackGeologyNote =>
      'Hesperian transition undivided unit · USGS global geologic map (SIM 3292), scale 1:20,000,000, so context only · source: Mars Trek';

  @override
  String get fieldElevation => 'Elevation';

  @override
  String get fieldSlope => 'Local slope';

  @override
  String get fieldRoughness => 'Roughness';

  @override
  String get fieldFromHabitat => 'From habitat';

  @override
  String get fieldDeltaElev => 'vs habitat';

  @override
  String get opsTitle => 'SITE OPERATIONS';

  @override
  String get opsAllot => 'Work time';

  @override
  String get opsVisitedBy => 'Included in routes';

  @override
  String get opsEdit => 'Edit objective';

  @override
  String get opsHere => 'Coordinates';

  @override
  String get priorityHigh => 'HIGH';

  @override
  String get priorityMedium => 'MEDIUM';

  @override
  String get priorityLow => 'LOW';

  @override
  String stackPending(String source) {
    return 'No data yet · pending $source';
  }

  @override
  String get safeOverall => 'OVERALL STATUS';

  @override
  String get safeGo => 'GO';

  @override
  String get safeCaution => 'CAUTION';

  @override
  String get safeNoGo => 'NO-GO';

  @override
  String get safePending => 'PENDING';

  @override
  String get safeIncomplete => 'INCOMPLETE DATA';

  @override
  String safeRealChecks(int n) {
    return '$n of 5 checks use real data';
  }

  @override
  String get checkRad => 'RAD';

  @override
  String get checkWeather => 'WEATHER';

  @override
  String get checkDust => 'DUST';

  @override
  String get checkTerrain => 'TERRAIN';

  @override
  String get checkConsumables => 'CONSUMABLES';

  @override
  String get panelRadiation => 'RADIATION · MSL RAD';

  @override
  String get panelWeather => 'WEATHER · MSL REMS';

  @override
  String get panelDust => 'DUST & OPACITY';

  @override
  String get panelTerrain => 'TERRAIN HAZARD';

  @override
  String get panelConsumables => 'CONSUMABLES & WALK-BACK';

  @override
  String get pendingPhase4 =>
      'NO DATA YET. The RAD and REMS series from the Planetary Data System arrive in phase 4.';

  @override
  String get exampleDose => 'Dose of this route at the example rate';

  @override
  String get exampleRate => 'Example rate';

  @override
  String get terrainByClass => 'Distance by slope class';

  @override
  String get terrainRoughness => 'Mean roughness';

  @override
  String get walkbackTitle => 'Return by stop';

  @override
  String get colStop => 'STOP';

  @override
  String get colAlong => 'ALONG ROUTE';

  @override
  String get colStraight => 'FROM HABITAT';

  @override
  String get colWalkback => 'DIRECT WALK-BACK';

  @override
  String get consO2 => 'Oxygen left at return';

  @override
  String get consReserve => 'Minimum reserve';

  @override
  String get consTime => 'EVA time used';

  @override
  String get consMax => 'Maximum EVA';

  @override
  String get consCompare => 'All routes';

  @override
  String get consNote =>
      'Straight-line walk-back at flat-ground speed. It ignores slope and obstacles.';

  @override
  String get safeSolTitle => 'REFERENCE SOL';

  @override
  String get safeSolNote =>
      'Past-period evaluation: measured data from REMS (up to sol 4843, March 2026) and RAD. It is not a forecast and not today\'s conditions.';

  @override
  String get radRate => 'Dose rate (detector E)';

  @override
  String get radBaseline => 'Baseline (60 sols)';

  @override
  String get radRatio => 'vs baseline';

  @override
  String get radProjected => 'Dose of this route';

  @override
  String get radHistory =>
      'Daily mean dose rate, 60 sols up to the reference sol';

  @override
  String get radUnitNote =>
      'Absorbed dose in tissue-equivalent plastic. It is not dose equivalent (mSv).';

  @override
  String get radSource => 'RAD · NASA SPDF CDAWeb';

  @override
  String get radB => 'Detector B (silicon, no rover source)';

  @override
  String get wxProfile => 'AIR TEMPERATURE BY LOCAL TIME (LMST)';

  @override
  String get wxAir => 'Air temperature';

  @override
  String get wxGround => 'Ground temperature';

  @override
  String get wxPressure => 'Pressure';

  @override
  String get wxUv => 'UV peak (A+B+C)';

  @override
  String get wxHumidity => 'Humidity (max)';

  @override
  String get wxWindow => 'EVA window';

  @override
  String get wxMinWindow => 'Minimum air temperature in the window';

  @override
  String get wxCoverage => 'hours with data';

  @override
  String get wxNoData => 'no data';

  @override
  String get wxSource => 'REMS · NASA PDS Atmospheres';

  @override
  String get dustNone =>
      'The PDS has no REMS dust-opacity product. Pending another source.';

  @override
  String get rulesTitle => 'GO / NO-GO RULES (team assumptions)';

  @override
  String get rulesRad => 'Radiation, multiple of the baseline';

  @override
  String get rulesAir => 'Air temperature in the EVA window';

  @override
  String get rulesStart => 'EVA start (local mean solar time)';

  @override
  String get rulesCrew =>
      'Assumed: the EVA is done by two astronauts; consumables and dose are computed for one. No rover is modeled.';

  @override
  String get rulesNote =>
      'Thresholds are assumptions, not NASA limits. Dust has no data, so the overall status stays incomplete.';

  @override
  String get safeIncomplete2 => 'DUST HAS NO DATA';

  @override
  String get minLabel => 'min';

  @override
  String get maxLabel => 'max';

  @override
  String get utcLabel => 'UTC';

  @override
  String get wxAirShort => 'AIR';

  @override
  String get wxGroundShort => 'GROUND';

  @override
  String get navHelmet => 'HELMET';

  @override
  String get navMission => 'MISSION';

  @override
  String get missionTitle => 'Simulated EVA: suit telemetry';

  @override
  String get missionNote =>
      'Simulation. The astronaut walks the selected route; each reading is computed for that position from the real elevation, slope and REMS data. Elapsed time, oxygen and dose are interpolated from the route totals. There are no vital signs or suit sensors: there is no data for them.';

  @override
  String get missionStatus => 'Status';

  @override
  String get missionNominal => 'NOMINAL';

  @override
  String get missionCaution => 'CAUTION';

  @override
  String get missionAlert => 'ALERT';

  @override
  String get missionPosition => 'Position';

  @override
  String get missionDose => 'Dose so far (est.)';

  @override
  String get missionO2Need => 'Oxygen needed to walk back';

  @override
  String get missionO2Reserve => 'Reserve on return';

  @override
  String get missionSpeed => 'Speed';

  @override
  String get missionReset => 'Back to start';

  @override
  String get missionAlertPnr => 'Past the point of no return';

  @override
  String get missionAlertO2 => 'Oxygen below what the walk back needs';

  @override
  String get missionAlertO2Low => 'Oxygen reserve on return under 10%';

  @override
  String get missionAllClear => 'No alerts at this position';

  @override
  String get missionDone => 'Route finished';

  @override
  String get helmetNoRoute => 'Calculating routes…';

  @override
  String get helmetHabitat => 'HABITAT';

  @override
  String get helmetConcept => 'CONCEPT';

  @override
  String get helmetTitle => 'Helmet visor display (HUD)';

  @override
  String get helmetNote =>
      'Visual concept. The position is simulated along the selected route. Distances, heading, slope and objectives come from the route model; the air temperature comes from REMS. There are no vital signs or suit sensors: there is no data for them.';

  @override
  String helmetBackdrop(String source) {
    return 'Backdrop: real Curiosity photo ($source); it is not the view of this route.';
  }

  @override
  String get helmetNext => 'Next';

  @override
  String helmetSlopeWarn(String deg, String dist) {
    return 'CAUTION: SLOPE $deg° AHEAD ($dist m)';
  }

  @override
  String get helmetReturnTitle => 'RETURN';

  @override
  String get helmetHabDist => 'To habitat (straight line)';

  @override
  String get helmetWalkBack => 'Walk-back time';

  @override
  String get helmetPnr => 'Point of no return at';

  @override
  String get helmetBeyondPnr => 'Past the point';

  @override
  String get helmetYes => 'YES';

  @override
  String get helmetNo => 'NO';

  @override
  String get helmetHereTitle => 'HERE';

  @override
  String get helmetHeading => 'Heading';

  @override
  String get helmetSlopeAhead => 'Slope ahead (90 m)';

  @override
  String get helmetAir => 'Air temperature';

  @override
  String get helmetElapsed => 'Elapsed (est.)';

  @override
  String get helmetO2 => 'Oxygen (est.)';

  @override
  String get helmetPlay => 'Play';

  @override
  String get helmetPause => 'Pause';

  @override
  String get helmetProgress => 'Progress along the route';

  @override
  String get helmetSimulated => 'Simulated position';

  @override
  String get helmetFootnote =>
      'Elapsed time and oxygen are interpolated from the route totals. Air temperature uses the REMS hourly profile of the reference sol at the local time of the simulated position.';

  @override
  String get modeTitle => 'EXIT MODE';

  @override
  String get modeFoot => 'On foot';

  @override
  String get modeRover => 'With rover';

  @override
  String get metricRover => 'Rover';

  @override
  String get metricRoverNone => 'not used';

  @override
  String get assumeRoverTitle => 'ROVER MODE ASSUMPTIONS';

  @override
  String get assumeRoverSpeed => 'Rover speed';

  @override
  String get assumeRoverSlope => 'Rover slope limit';

  @override
  String get assumeRoverRough => 'Rover maximum roughness';

  @override
  String get assumeRoverO2 => 'Oxygen use on the rover';

  @override
  String get assumeRoverTransfer => 'Time to get on or off';

  @override
  String get assumeRoverNote =>
      'The rover is left at one point of the route: it goes out along the first stretch it can drive and comes back along the last one. The rest is on foot. The routes are still optimized for walking. Speed and slope come from the Apollo lunar rover (NASA, NTRS 20250011301); the other values are team assumptions.';

  @override
  String get modeSupport => 'Support';

  @override
  String get metricEmergency => 'Emergency return';

  @override
  String get metricEmergencyFoot => 'On foot';

  @override
  String get assumeDispatch => 'Support rover departure after the alert';

  @override
  String get assumeSupportNote =>
      'A rover waits at the habitat. The crew walks the same route; the rover does not change its time or oxygen. In an emergency it leaves after the alert, drives only where it can, and meets the astronaut on the way (the best meeting point is chosen). It shortens the return time, moves the point of no return and reduces the radius that counts in the hazard score. Speed and slope come from the Apollo lunar rover (NASA, NTRS 20250011301); the other values are team assumptions.';

  @override
  String get modePair => 'Pair';

  @override
  String get routePair1 => 'Astronaut 1';

  @override
  String get routePair2 => 'Astronaut 2';

  @override
  String get reasonOtherAstronaut => 'the other astronaut';

  @override
  String get reasonNotInPair => 'not reached by the pair';

  @override
  String get pairTitle => 'EVA IN A PAIR';

  @override
  String get pairVisits => 'Objectives';

  @override
  String get pairSeparation => 'Max separation';

  @override
  String get pairO2Min => 'Lowest oxygen';

  @override
  String pairNone(String limit) {
    return 'No pair of routes keeps the two astronauts within $limit m of each other.';
  }

  @override
  String get pairNote =>
      'Duration is that of the slower astronaut. Hazard is the higher of the two. Success counts the objectives visited by either one. Each astronaut has their own oxygen.';

  @override
  String get assumePairTitle => 'PAIR MODE ASSUMPTIONS';

  @override
  String get assumePairSep => 'Maximum separation';

  @override
  String get assumePairSample => 'Separation checked every';

  @override
  String get assumePairNote =>
      'Two astronauts leave the habitat together, split the objectives and must stay within the maximum separation (line of sight and communication) at all times. Real NASA EVAs go in pairs and together, so this split is our own extension and the limit is a team assumption without a reference. Each route keeps the science rule: feasible, and with a comfortable margin if it has more than one objective.';

  @override
  String get siteChange => 'Change site';

  @override
  String get sitePending => 'Data in preparation';

  @override
  String get siteLoadError =>
      'Could not load the site. The current one stays open.';

  @override
  String get modeObjective => 'By objective';

  @override
  String get transportTitle => 'Transport';

  @override
  String get transportFoot => 'On foot';

  @override
  String get transportVehicle => 'Vehicle';

  @override
  String get transportHybrid => 'Hybrid';

  @override
  String get transportHint =>
      'Only used in “By objective” mode. Vehicle: drive to the objective. Hybrid: drive as far as the terrain allows, then walk.';

  @override
  String get reasonRover => 'the vehicle would be left behind';

  @override
  String get assumeObjectiveNote =>
      'Each objective brings its own transport. There is one vehicle: it leaves the habitat with the astronaut and stays where it is parked; to use it again, the route has to pass through that point. The way to a “Vehicle” objective is searched only over cells the vehicle can drive. Speed, slope, roughness and transfer values are the rover ones.';

  @override
  String transportNoteNotHere(String name) {
    return '$name: the vehicle is not on this stretch, so it is done on foot.';
  }

  @override
  String transportNoteCannotStart(String name) {
    return '$name: the vehicle cannot start from here, so it is done on foot.';
  }

  @override
  String transportNoteBlocked(String name) {
    return '$name: the vehicle cannot advance on this stretch, so it is done on foot.';
  }

  @override
  String transportNotePartial(String name) {
    return '$name: the vehicle cannot reach it. It goes as far as it can and the rest is on foot.';
  }

  @override
  String transportNoteNoRecovery(String name) {
    return '$name: there is no point on the way back to pick the vehicle up again, so it is done on foot.';
  }

  @override
  String get transportNoteStranded =>
      'The vehicle would be left behind: the way back never passes through where it was parked.';

  @override
  String get msnTitle => 'Missions';

  @override
  String get msnNew => 'New mission';

  @override
  String get msnDuplicate => 'Duplicate';

  @override
  String get msnDelete => 'Delete';

  @override
  String get msnDeleteLast => 'The only mission cannot be deleted.';

  @override
  String get msnDeleteTitle => 'Delete mission?';

  @override
  String msnDeleteBody(String name) {
    return '$name will be deleted from this device. This cannot be undone.';
  }

  @override
  String get msnName => 'Name';

  @override
  String get msnNotes => 'Notes';

  @override
  String get msnSite => 'Site';

  @override
  String msnObjectives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectives',
      one: '1 objective',
      zero: 'No objectives',
    );
    return '$_temp0';
  }

  @override
  String get msnConsumables => 'Consumables';

  @override
  String get msnEquipment => 'Equipment and tools';

  @override
  String get msnAddItem => 'Add';

  @override
  String get msnEmptyItems => 'Nothing added.';

  @override
  String get msnItemName => 'Item';

  @override
  String get msnItemQty => 'Quantity';

  @override
  String get msnItemUnit => 'Unit';

  @override
  String get msnItemMass => 'Mass per unit (kg)';

  @override
  String msnMassTotal(String kg) {
    return 'Declared mass: $kg kg';
  }

  @override
  String get msnAssumeNote =>
      'Consumables and equipment are written by the user. They are not NASA data and do not change the route calculation yet.';

  @override
  String get msnRoutesNote =>
      'The routes are calculated from the objectives of the open mission.';

  @override
  String get msnExport => 'Copy JSON';

  @override
  String get msnCopied => 'Mission copied as JSON.';

  @override
  String get msnOpenError => 'Could not open the site of that mission.';

  @override
  String get msnCurrent => 'Open';

  @override
  String get siteIndicativeTag => 'Indicative';

  @override
  String get siteIndicativeNote =>
      'Indicative routes: the relief comes from a 200 m model, so local slopes are smoothed and the roughness is unknown. Use them as an approximation, not to avoid rocks or small slopes.';

  @override
  String get layerSlope15 => 'Slope above 15 %';

  @override
  String get layerTransit => 'Transit zones (DCI + thermal inertia)';

  @override
  String get layerThermalNight => 'Relative thermal inertia (THEMIS-IR night)';

  @override
  String get layerMineralsPts => 'Aqueous and hydrous minerals';

  @override
  String get layerAqueousPts => 'Aqueous minerals · biosignatures';

  @override
  String get layerHydrousPts => 'Hydrous minerals (CRISM, OMEGA)';

  @override
  String get layerValleys => 'Valley networks (Hynek 2010)';

  @override
  String get legendBiosigTitle => 'Biosignature search (from orbit)';

  @override
  String get legendCarbonate => 'Carbonate';

  @override
  String get legendValleys => 'Valley network (ancient water)';

  @override
  String get legendBiosigNote =>
      'Phyllosilicates and carbonates: ground more likely to preserve biosignatures. Orbital detections from Mars Trek (NASA), not samples. No carbonates are recorded in Meridiani; sulfates are not shown.';

  @override
  String get layerZones => 'Exploration zones';

  @override
  String get legendTransitTitle => 'Transit zones (TES, 3.5 km per pixel)';

  @override
  String get legendTransitGreen => 'Best transit: DCI > 0.96 and inertia > 300';

  @override
  String get legendTransitYellow =>
      'Safe transit: DCI > 0.95 and inertia 180 to 300';

  @override
  String get legendTransitRed => 'Avoid: DCI < 0.94 and inertia < 150';

  @override
  String get legendTransitNone => 'Not classified (outside those rules)';

  @override
  String get legendMineralsTitle => 'Minerals (orbit)';

  @override
  String get legendSulfate => 'Sulfate';

  @override
  String get legendPhyllo => 'Phyllosilicate (clay)';

  @override
  String get legendHydrous => 'Hydrous mineral';

  @override
  String get legendZonesTitle => 'Exploration zones (NASA, 2015)';

  @override
  String get legendHabitation => 'Habitation zone';

  @override
  String get legendLanding => 'Landing site';

  @override
  String get legendEz => 'Exploration zone';

  @override
  String get legendRoi => 'Region of interest';

  @override
  String get legendEzRadius => '100 km radius';

  @override
  String get legendSlope15 => 'Slope above 15 % (avoid for a base)';

  @override
  String get transitNote =>
      'The thresholds are team assumptions without a reference. DCI and thermal inertia come from TES at 3.5 and 7.5 km: in a window of a few kilometres the layer has one or two colours.';

  @override
  String get srcTitle => 'Sources and data';

  @override
  String get srcIntro =>
      'Every value in the app is one of three kinds: real data from NASA, USGS or ASU; a value computed by the team from that data; or a team assumption. Source files and dates are listed in the project notes (RECURSOS.md).';

  @override
  String get srcReal => 'Real data';

  @override
  String get srcModeled => 'Computed by the team';

  @override
  String get srcAssumed => 'Assumptions';

  @override
  String get srcClose => 'Close';

  @override
  String get safeNoEnvData =>
      'No radiation or weather measurements at this site: RAD and REMS are on Curiosity, in Gale crater, so those two checks stay pending. The dose of the routes uses the Gale baseline as an assumption. Meridiani lies higher, with less atmosphere above it, so the real dose is probably larger.';

  @override
  String get doseGaleNote =>
      'This site has no radiation measurements: the dose uses the Gale baseline (assumption).';

  @override
  String get srcLink => 'Sources';

  @override
  String get layerNames => 'Place names (IAU)';

  @override
  String get layerCraters => 'Craters of 1 km and larger';

  @override
  String get layerGeology => 'Geology and dunes';

  @override
  String get routeAreaLabel => 'ROUTE AREA';

  @override
  String get legendGeologyTitle => 'Geology and dunes (USGS, global scale)';

  @override
  String get legendGeologyNote =>
      'The unit code is drawn on each area (for example Htu, mNh). Dune fields appear in amber. The map is global scale: it does not resolve small outcrops.';

  @override
  String get legendCraters => 'Crater of 1 km or more (Robbins database)';

  @override
  String get legendNames => 'Official place name (IAU)';

  @override
  String get contextNote =>
      'Outside the dashed frame there is a coarser image (CTX) for context. Routes are only calculated inside the frame.';

  @override
  String get siteReachTag => 'Long range';

  @override
  String get siteReachNote =>
      'Long-range routes: the grid is 16 m over a real DEM, so it does not see small obstacles and the roughness is unknown. The 4 km site has the detail; this one reaches the whole EVA range (about 12 km).';

  @override
  String mapTraceLegend(
    String viewW,
    String viewH,
    String traceW,
    String traceH,
  ) {
    return 'Current view: $viewW × $viewH km  ·  Available trace: $traceW × $traceH km';
  }

  @override
  String get routeAutoTitle => 'ROUTE & OBJECTIVE';

  @override
  String get routeAutoHint =>
      'Automatic route from the habitat to the selected objective (based on terrain slope, roughness, and distance).';

  @override
  String get routeSelectObjective =>
      'Click an objective on the map or use \"Add objective\" to trace the route and view its real data.';

  @override
  String get objectiveCoords => 'Coordinates';

  @override
  String get objectiveElev => 'Elevation';

  @override
  String get objectiveSlope => 'Local slope';

  @override
  String get metricElevRange => 'Ascent / descent';

  @override
  String get objectiveEditBtn => 'Edit';

  @override
  String get routeStartLabel => 'Starting point';

  @override
  String get routeSetStart => 'Set as start';

  @override
  String get routeActiveStart => 'Active start';

  @override
  String get routeTracedTitle => 'TRACED ROUTES';

  @override
  String get routeBackToHab => 'Trace return to habitat';

  @override
  String get routeNoRoutes => 'No traced routes.';

  @override
  String get routeEndLabel => 'Destination';

  @override
  String get routeSwapTooltip => 'Swap start and destination';

  @override
  String get routeTraceBtn => 'Trace route';

  @override
  String get routeSelectDestHint => 'Select destination...';

  @override
  String get objectivesSelectMode => 'Select';

  @override
  String get objectivesSelectAll => 'All';

  @override
  String get objectivesSelectNone => 'None';

  @override
  String objectivesDeleteSelected(int count) {
    return 'Delete ($count)';
  }

  @override
  String get objectivesCancel => 'Cancel';

  @override
  String get routeTracePickStart => 'Tap starting point (Habitat or objective)';

  @override
  String get routeTracePickEnd => 'Tap destination (Habitat or objective)';

  @override
  String get routeNoneSelected => '—';
}
