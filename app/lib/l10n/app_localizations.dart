import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ARES PATH'**
  String get appName;

  /// No description provided for @siteName.
  ///
  /// In en, this message translates to:
  /// **'Meridiani · Regional context (100 km)'**
  String get siteName;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get navPlan;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get navSafety;

  /// No description provided for @navScience.
  ///
  /// In en, this message translates to:
  /// **'SCIENCE'**
  String get navScience;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @layersTitle.
  ///
  /// In en, this message translates to:
  /// **'DATA LAYERS'**
  String get layersTitle;

  /// No description provided for @layersActive.
  ///
  /// In en, this message translates to:
  /// **'{n} ACTIVE'**
  String layersActive(int n);

  /// No description provided for @layersReset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get layersReset;

  /// No description provided for @layerOptical.
  ///
  /// In en, this message translates to:
  /// **'Optical surface'**
  String get layerOptical;

  /// No description provided for @layerHillshade.
  ///
  /// In en, this message translates to:
  /// **'Relief (hillshade)'**
  String get layerHillshade;

  /// No description provided for @layerSlope.
  ///
  /// In en, this message translates to:
  /// **'Relief'**
  String get layerSlope;

  /// No description provided for @layerForbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden zones'**
  String get layerForbidden;

  /// No description provided for @layerCuriosity.
  ///
  /// In en, this message translates to:
  /// **'Curiosity track'**
  String get layerCuriosity;

  /// No description provided for @layerThermal.
  ///
  /// In en, this message translates to:
  /// **'Thermal (THEMIS-IR day)'**
  String get layerThermal;

  /// No description provided for @layerMinerals.
  ///
  /// In en, this message translates to:
  /// **'Mineralogy'**
  String get layerMinerals;

  /// No description provided for @layerRadiation.
  ///
  /// In en, this message translates to:
  /// **'Radiation flux'**
  String get layerRadiation;

  /// No description provided for @layerNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get layerNoData;

  /// No description provided for @kindMeasured.
  ///
  /// In en, this message translates to:
  /// **'MEASURED'**
  String get kindMeasured;

  /// No description provided for @kindModeled.
  ///
  /// In en, this message translates to:
  /// **'MODELED'**
  String get kindModeled;

  /// No description provided for @kindExample.
  ///
  /// In en, this message translates to:
  /// **'EXAMPLE'**
  String get kindExample;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'OPACITY'**
  String get opacity;

  /// No description provided for @legendTitle.
  ///
  /// In en, this message translates to:
  /// **'SLOPE LEGEND'**
  String get legendTitle;

  /// No description provided for @legendNominal.
  ///
  /// In en, this message translates to:
  /// **'< 10° nominal'**
  String get legendNominal;

  /// No description provided for @legendCaution.
  ///
  /// In en, this message translates to:
  /// **'10–12° caution'**
  String get legendCaution;

  /// No description provided for @legendHigh.
  ///
  /// In en, this message translates to:
  /// **'12–15° high caution'**
  String get legendHigh;

  /// No description provided for @legendForbidden.
  ///
  /// In en, this message translates to:
  /// **'> 15° forbidden'**
  String get legendForbidden;

  /// No description provided for @routesTitle.
  ///
  /// In en, this message translates to:
  /// **'ROUTE COMPARISON'**
  String get routesTitle;

  /// No description provided for @routeSafe.
  ///
  /// In en, this message translates to:
  /// **'Safest'**
  String get routeSafe;

  /// No description provided for @routeFast.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get routeFast;

  /// No description provided for @routeScience.
  ///
  /// In en, this message translates to:
  /// **'Most science'**
  String get routeScience;

  /// No description provided for @metricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get metricDistance;

  /// No description provided for @metricDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get metricDuration;

  /// No description provided for @metricMaxSlope.
  ///
  /// In en, this message translates to:
  /// **'Max slope'**
  String get metricMaxSlope;

  /// No description provided for @metricClimb.
  ///
  /// In en, this message translates to:
  /// **'Climb'**
  String get metricClimb;

  /// No description provided for @metricO2.
  ///
  /// In en, this message translates to:
  /// **'O₂ at return'**
  String get metricO2;

  /// No description provided for @metricDose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get metricDose;

  /// No description provided for @metricNoReturn.
  ///
  /// In en, this message translates to:
  /// **'Point of no return'**
  String get metricNoReturn;

  /// No description provided for @metricWalk.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get metricWalk;

  /// No description provided for @metricStops.
  ///
  /// In en, this message translates to:
  /// **'Work stops'**
  String get metricStops;

  /// No description provided for @hazardScore.
  ///
  /// In en, this message translates to:
  /// **'HAZARD'**
  String get hazardScore;

  /// No description provided for @successScore.
  ///
  /// In en, this message translates to:
  /// **'SUCCESS'**
  String get successScore;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @hzSlope.
  ///
  /// In en, this message translates to:
  /// **'Slope exposure'**
  String get hzSlope;

  /// No description provided for @hzTerrain.
  ///
  /// In en, this message translates to:
  /// **'Rough / loose terrain'**
  String get hzTerrain;

  /// No description provided for @hzWalkback.
  ///
  /// In en, this message translates to:
  /// **'Beyond walk-back range'**
  String get hzWalkback;

  /// No description provided for @hzConsumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables margin'**
  String get hzConsumables;

  /// No description provided for @hzRadiation.
  ///
  /// In en, this message translates to:
  /// **'Radiation dose'**
  String get hzRadiation;

  /// No description provided for @hzDay.
  ///
  /// In en, this message translates to:
  /// **'Day conditions (example)'**
  String get hzDay;

  /// No description provided for @scValue.
  ///
  /// In en, this message translates to:
  /// **'Science value'**
  String get scValue;

  /// No description provided for @scTime.
  ///
  /// In en, this message translates to:
  /// **'Time factor'**
  String get scTime;

  /// No description provided for @scConsumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables factor'**
  String get scConsumables;

  /// No description provided for @scPenalty.
  ///
  /// In en, this message translates to:
  /// **'Hazard penalty'**
  String get scPenalty;

  /// No description provided for @objectivesTitle.
  ///
  /// In en, this message translates to:
  /// **'SCIENCE OBJECTIVES'**
  String get objectivesTitle;

  /// No description provided for @objectivesAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD OBJECTIVE'**
  String get objectivesAdd;

  /// No description provided for @objectivesAddActive.
  ///
  /// In en, this message translates to:
  /// **'TAP THE MAP TO PLACE IT'**
  String get objectivesAddActive;

  /// No description provided for @objectivesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No objectives. Add one to plan a route.'**
  String get objectivesEmpty;

  /// No description provided for @typeSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get typeSample;

  /// No description provided for @typeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get typeImage;

  /// No description provided for @typeMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get typeMeasurement;

  /// No description provided for @typeEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get typeEquipment;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority {p}'**
  String priorityLabel(int p);

  /// No description provided for @workMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String workMinutes(int m);

  /// No description provided for @objectiveEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit objective'**
  String get objectiveEdit;

  /// No description provided for @objectiveNewName.
  ///
  /// In en, this message translates to:
  /// **'New objective'**
  String get objectiveNewName;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority (1 to 5)'**
  String get fieldPriority;

  /// No description provided for @fieldWork.
  ///
  /// In en, this message translates to:
  /// **'Work time (min)'**
  String get fieldWork;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @objectiveForbidden.
  ///
  /// In en, this message translates to:
  /// **'In forbidden terrain'**
  String get objectiveForbidden;

  /// No description provided for @statusFeasible.
  ///
  /// In en, this message translates to:
  /// **'FEASIBLE'**
  String get statusFeasible;

  /// No description provided for @statusNotFeasible.
  ///
  /// In en, this message translates to:
  /// **'NOT FEASIBLE'**
  String get statusNotFeasible;

  /// No description provided for @statusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'UNREACHABLE'**
  String get statusUnreachable;

  /// No description provided for @statusNoTarget.
  ///
  /// In en, this message translates to:
  /// **'NO TARGET'**
  String get statusNoTarget;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visits;

  /// No description provided for @skippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get skippedLabel;

  /// No description provided for @reasonBlocked.
  ///
  /// In en, this message translates to:
  /// **'forbidden terrain'**
  String get reasonBlocked;

  /// No description provided for @reasonUnreachable.
  ///
  /// In en, this message translates to:
  /// **'unreachable'**
  String get reasonUnreachable;

  /// No description provided for @reasonTime.
  ///
  /// In en, this message translates to:
  /// **'not enough time'**
  String get reasonTime;

  /// No description provided for @reasonOxygen.
  ///
  /// In en, this message translates to:
  /// **'not enough oxygen'**
  String get reasonOxygen;

  /// No description provided for @reasonMargin.
  ///
  /// In en, this message translates to:
  /// **'margin too thin'**
  String get reasonMargin;

  /// No description provided for @reasonNotPrimary.
  ///
  /// In en, this message translates to:
  /// **'not on this route'**
  String get reasonNotPrimary;

  /// No description provided for @computing.
  ///
  /// In en, this message translates to:
  /// **'COMPUTING ROUTES…'**
  String get computing;

  /// No description provided for @assumptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'ASSUMPTIONS'**
  String get assumptionsTitle;

  /// No description provided for @assumptionsNote.
  ///
  /// In en, this message translates to:
  /// **'Team assumptions, not NASA standards.'**
  String get assumptionsNote;

  /// No description provided for @assumeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Walking speed on flat ground'**
  String get assumeSpeed;

  /// No description provided for @assumeEva.
  ///
  /// In en, this message translates to:
  /// **'Maximum EVA duration'**
  String get assumeEva;

  /// No description provided for @assumeO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen capacity'**
  String get assumeO2;

  /// No description provided for @assumeReserve.
  ///
  /// In en, this message translates to:
  /// **'Minimum oxygen reserve'**
  String get assumeReserve;

  /// No description provided for @assumeSlopeLimit.
  ///
  /// In en, this message translates to:
  /// **'Slope limit (safest / others)'**
  String get assumeSlopeLimit;

  /// No description provided for @assumeDose.
  ///
  /// In en, this message translates to:
  /// **'Radiation dose rate (measured, RAD)'**
  String get assumeDose;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION & SLOPE PROFILE'**
  String get profileTitle;

  /// No description provided for @habitat.
  ///
  /// In en, this message translates to:
  /// **'HABITAT'**
  String get habitat;

  /// No description provided for @pnrShort.
  ///
  /// In en, this message translates to:
  /// **'PNR'**
  String get pnrShort;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'ELEV'**
  String get elevation;

  /// No description provided for @attribution.
  ///
  /// In en, this message translates to:
  /// **'HiRISE (NASA/JPL/UArizona) · USGS Astrogeology'**
  String get attribution;

  /// No description provided for @hintDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to pan · scroll to zoom · tap an objective to edit'**
  String get hintDrag;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @zoomFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to view'**
  String get zoomFit;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Coming next'**
  String get soon;

  /// No description provided for @sciTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'TARGETS // SORTIE'**
  String get sciTargetsTitle;

  /// No description provided for @sciDetail.
  ///
  /// In en, this message translates to:
  /// **'TARGET DETAIL'**
  String get sciDetail;

  /// No description provided for @sciOrbital.
  ///
  /// In en, this message translates to:
  /// **'ORBITAL · HiRISE'**
  String get sciOrbital;

  /// No description provided for @sciGround.
  ///
  /// In en, this message translates to:
  /// **'GROUND · ROVER PHOTO'**
  String get sciGround;

  /// No description provided for @sciGroundSoon.
  ///
  /// In en, this message translates to:
  /// **'No rover photo for this objective'**
  String get sciGroundSoon;

  /// No description provided for @sciGroundNote.
  ///
  /// In en, this message translates to:
  /// **'Photo from that sol, taken near this stop'**
  String get sciGroundNote;

  /// No description provided for @sciDataStack.
  ///
  /// In en, this message translates to:
  /// **'DATA STACK AT THIS POINT'**
  String get sciDataStack;

  /// No description provided for @sciPick.
  ///
  /// In en, this message translates to:
  /// **'Select an objective'**
  String get sciPick;

  /// No description provided for @stackOptical.
  ///
  /// In en, this message translates to:
  /// **'Optical imagery'**
  String get stackOptical;

  /// No description provided for @stackTopo.
  ///
  /// In en, this message translates to:
  /// **'Topography & slopes'**
  String get stackTopo;

  /// No description provided for @stackThermal.
  ///
  /// In en, this message translates to:
  /// **'Thermal (THEMIS-IR day)'**
  String get stackThermal;

  /// No description provided for @stackThermalNote.
  ///
  /// In en, this message translates to:
  /// **'THEMIS-IR day mosaic · about 100 m/px · relative brightness, not calibrated temperature · source: Mars Trek'**
  String get stackThermalNote;

  /// No description provided for @stackMinerals.
  ///
  /// In en, this message translates to:
  /// **'Mineralogy'**
  String get stackMinerals;

  /// No description provided for @stackRadiation.
  ///
  /// In en, this message translates to:
  /// **'Radiation'**
  String get stackRadiation;

  /// No description provided for @stackGeology.
  ///
  /// In en, this message translates to:
  /// **'Geologic unit'**
  String get stackGeology;

  /// No description provided for @stackGeologyNote.
  ///
  /// In en, this message translates to:
  /// **'Hesperian transition undivided unit · USGS global geologic map (SIM 3292), scale 1:20,000,000, so context only · source: Mars Trek'**
  String get stackGeologyNote;

  /// No description provided for @fieldElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get fieldElevation;

  /// No description provided for @fieldSlope.
  ///
  /// In en, this message translates to:
  /// **'Local slope'**
  String get fieldSlope;

  /// No description provided for @fieldRoughness.
  ///
  /// In en, this message translates to:
  /// **'Roughness'**
  String get fieldRoughness;

  /// No description provided for @fieldFromHabitat.
  ///
  /// In en, this message translates to:
  /// **'From habitat'**
  String get fieldFromHabitat;

  /// No description provided for @fieldDeltaElev.
  ///
  /// In en, this message translates to:
  /// **'vs habitat'**
  String get fieldDeltaElev;

  /// No description provided for @opsTitle.
  ///
  /// In en, this message translates to:
  /// **'SITE OPERATIONS'**
  String get opsTitle;

  /// No description provided for @opsAllot.
  ///
  /// In en, this message translates to:
  /// **'Work time'**
  String get opsAllot;

  /// No description provided for @opsVisitedBy.
  ///
  /// In en, this message translates to:
  /// **'Included in routes'**
  String get opsVisitedBy;

  /// No description provided for @opsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit objective'**
  String get opsEdit;

  /// No description provided for @opsHere.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get opsHere;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get priorityLow;

  /// No description provided for @stackPending.
  ///
  /// In en, this message translates to:
  /// **'No data yet · pending {source}'**
  String stackPending(String source);

  /// No description provided for @safeOverall.
  ///
  /// In en, this message translates to:
  /// **'OVERALL STATUS'**
  String get safeOverall;

  /// No description provided for @safeGo.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get safeGo;

  /// No description provided for @safeCaution.
  ///
  /// In en, this message translates to:
  /// **'CAUTION'**
  String get safeCaution;

  /// No description provided for @safeNoGo.
  ///
  /// In en, this message translates to:
  /// **'NO-GO'**
  String get safeNoGo;

  /// No description provided for @safePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get safePending;

  /// No description provided for @safeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'INCOMPLETE DATA'**
  String get safeIncomplete;

  /// No description provided for @safeRealChecks.
  ///
  /// In en, this message translates to:
  /// **'{n} of 5 checks use real data'**
  String safeRealChecks(int n);

  /// No description provided for @checkRad.
  ///
  /// In en, this message translates to:
  /// **'RAD'**
  String get checkRad;

  /// No description provided for @checkWeather.
  ///
  /// In en, this message translates to:
  /// **'WEATHER'**
  String get checkWeather;

  /// No description provided for @checkDust.
  ///
  /// In en, this message translates to:
  /// **'DUST'**
  String get checkDust;

  /// No description provided for @checkTerrain.
  ///
  /// In en, this message translates to:
  /// **'TERRAIN'**
  String get checkTerrain;

  /// No description provided for @checkConsumables.
  ///
  /// In en, this message translates to:
  /// **'CONSUMABLES'**
  String get checkConsumables;

  /// No description provided for @panelRadiation.
  ///
  /// In en, this message translates to:
  /// **'RADIATION · MSL RAD'**
  String get panelRadiation;

  /// No description provided for @panelWeather.
  ///
  /// In en, this message translates to:
  /// **'WEATHER · MSL REMS'**
  String get panelWeather;

  /// No description provided for @panelDust.
  ///
  /// In en, this message translates to:
  /// **'DUST & OPACITY'**
  String get panelDust;

  /// No description provided for @panelTerrain.
  ///
  /// In en, this message translates to:
  /// **'TERRAIN HAZARD'**
  String get panelTerrain;

  /// No description provided for @panelConsumables.
  ///
  /// In en, this message translates to:
  /// **'CONSUMABLES & WALK-BACK'**
  String get panelConsumables;

  /// No description provided for @pendingPhase4.
  ///
  /// In en, this message translates to:
  /// **'NO DATA YET. The RAD and REMS series from the Planetary Data System arrive in phase 4.'**
  String get pendingPhase4;

  /// No description provided for @exampleDose.
  ///
  /// In en, this message translates to:
  /// **'Dose of this route at the example rate'**
  String get exampleDose;

  /// No description provided for @exampleRate.
  ///
  /// In en, this message translates to:
  /// **'Example rate'**
  String get exampleRate;

  /// No description provided for @terrainByClass.
  ///
  /// In en, this message translates to:
  /// **'Distance by slope class'**
  String get terrainByClass;

  /// No description provided for @terrainRoughness.
  ///
  /// In en, this message translates to:
  /// **'Mean roughness'**
  String get terrainRoughness;

  /// No description provided for @walkbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Return by stop'**
  String get walkbackTitle;

  /// No description provided for @colStop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get colStop;

  /// No description provided for @colAlong.
  ///
  /// In en, this message translates to:
  /// **'ALONG ROUTE'**
  String get colAlong;

  /// No description provided for @colStraight.
  ///
  /// In en, this message translates to:
  /// **'FROM HABITAT'**
  String get colStraight;

  /// No description provided for @colWalkback.
  ///
  /// In en, this message translates to:
  /// **'DIRECT WALK-BACK'**
  String get colWalkback;

  /// No description provided for @consO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen left at return'**
  String get consO2;

  /// No description provided for @consReserve.
  ///
  /// In en, this message translates to:
  /// **'Minimum reserve'**
  String get consReserve;

  /// No description provided for @consTime.
  ///
  /// In en, this message translates to:
  /// **'EVA time used'**
  String get consTime;

  /// No description provided for @consMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum EVA'**
  String get consMax;

  /// No description provided for @consCompare.
  ///
  /// In en, this message translates to:
  /// **'All routes'**
  String get consCompare;

  /// No description provided for @consNote.
  ///
  /// In en, this message translates to:
  /// **'Straight-line walk-back at flat-ground speed. It ignores slope and obstacles.'**
  String get consNote;

  /// No description provided for @safeSolTitle.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE SOL'**
  String get safeSolTitle;

  /// No description provided for @safeSolNote.
  ///
  /// In en, this message translates to:
  /// **'Past-period evaluation: measured data from REMS (up to sol 4843, March 2026) and RAD. It is not a forecast and not today\'s conditions.'**
  String get safeSolNote;

  /// No description provided for @radRate.
  ///
  /// In en, this message translates to:
  /// **'Dose rate (detector E)'**
  String get radRate;

  /// No description provided for @radBaseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline (60 sols)'**
  String get radBaseline;

  /// No description provided for @radRatio.
  ///
  /// In en, this message translates to:
  /// **'vs baseline'**
  String get radRatio;

  /// No description provided for @radProjected.
  ///
  /// In en, this message translates to:
  /// **'Dose of this route'**
  String get radProjected;

  /// No description provided for @radHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily mean dose rate, 60 sols up to the reference sol'**
  String get radHistory;

  /// No description provided for @radUnitNote.
  ///
  /// In en, this message translates to:
  /// **'Absorbed dose in tissue-equivalent plastic. It is not dose equivalent (mSv).'**
  String get radUnitNote;

  /// No description provided for @radSource.
  ///
  /// In en, this message translates to:
  /// **'RAD · NASA SPDF CDAWeb'**
  String get radSource;

  /// No description provided for @radB.
  ///
  /// In en, this message translates to:
  /// **'Detector B (silicon, no rover source)'**
  String get radB;

  /// No description provided for @wxProfile.
  ///
  /// In en, this message translates to:
  /// **'AIR TEMPERATURE BY LOCAL TIME (LMST)'**
  String get wxProfile;

  /// No description provided for @wxAir.
  ///
  /// In en, this message translates to:
  /// **'Air temperature'**
  String get wxAir;

  /// No description provided for @wxGround.
  ///
  /// In en, this message translates to:
  /// **'Ground temperature'**
  String get wxGround;

  /// No description provided for @wxPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get wxPressure;

  /// No description provided for @wxUv.
  ///
  /// In en, this message translates to:
  /// **'UV peak (A+B+C)'**
  String get wxUv;

  /// No description provided for @wxHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity (max)'**
  String get wxHumidity;

  /// No description provided for @wxWindow.
  ///
  /// In en, this message translates to:
  /// **'EVA window'**
  String get wxWindow;

  /// No description provided for @wxMinWindow.
  ///
  /// In en, this message translates to:
  /// **'Minimum air temperature in the window'**
  String get wxMinWindow;

  /// No description provided for @wxCoverage.
  ///
  /// In en, this message translates to:
  /// **'hours with data'**
  String get wxCoverage;

  /// No description provided for @wxNoData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get wxNoData;

  /// No description provided for @wxSource.
  ///
  /// In en, this message translates to:
  /// **'REMS · NASA PDS Atmospheres'**
  String get wxSource;

  /// No description provided for @dustNone.
  ///
  /// In en, this message translates to:
  /// **'The PDS has no REMS dust-opacity product. Pending another source.'**
  String get dustNone;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'GO / NO-GO RULES (team assumptions)'**
  String get rulesTitle;

  /// No description provided for @rulesRad.
  ///
  /// In en, this message translates to:
  /// **'Radiation, multiple of the baseline'**
  String get rulesRad;

  /// No description provided for @rulesAir.
  ///
  /// In en, this message translates to:
  /// **'Air temperature in the EVA window'**
  String get rulesAir;

  /// No description provided for @rulesStart.
  ///
  /// In en, this message translates to:
  /// **'EVA start (local mean solar time)'**
  String get rulesStart;

  /// No description provided for @rulesCrew.
  ///
  /// In en, this message translates to:
  /// **'Assumed: the EVA is done by two astronauts; consumables and dose are computed for one. No rover is modeled.'**
  String get rulesCrew;

  /// No description provided for @rulesNote.
  ///
  /// In en, this message translates to:
  /// **'Thresholds are assumptions, not NASA limits. Dust has no data, so the overall status stays incomplete.'**
  String get rulesNote;

  /// No description provided for @safeIncomplete2.
  ///
  /// In en, this message translates to:
  /// **'DUST HAS NO DATA'**
  String get safeIncomplete2;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minLabel;

  /// No description provided for @maxLabel.
  ///
  /// In en, this message translates to:
  /// **'max'**
  String get maxLabel;

  /// No description provided for @utcLabel.
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get utcLabel;

  /// No description provided for @wxAirShort.
  ///
  /// In en, this message translates to:
  /// **'AIR'**
  String get wxAirShort;

  /// No description provided for @wxGroundShort.
  ///
  /// In en, this message translates to:
  /// **'GROUND'**
  String get wxGroundShort;

  /// No description provided for @navHelmet.
  ///
  /// In en, this message translates to:
  /// **'HELMET'**
  String get navHelmet;

  /// No description provided for @navMission.
  ///
  /// In en, this message translates to:
  /// **'MISSION'**
  String get navMission;

  /// No description provided for @missionTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulated EVA: suit telemetry'**
  String get missionTitle;

  /// No description provided for @missionNote.
  ///
  /// In en, this message translates to:
  /// **'Simulation. The astronaut walks the selected route; each reading is computed for that position from the real elevation, slope and REMS data. Elapsed time, oxygen and dose are interpolated from the route totals. There are no vital signs or suit sensors: there is no data for them.'**
  String get missionNote;

  /// No description provided for @missionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get missionStatus;

  /// No description provided for @missionNominal.
  ///
  /// In en, this message translates to:
  /// **'NOMINAL'**
  String get missionNominal;

  /// No description provided for @missionCaution.
  ///
  /// In en, this message translates to:
  /// **'CAUTION'**
  String get missionCaution;

  /// No description provided for @missionAlert.
  ///
  /// In en, this message translates to:
  /// **'ALERT'**
  String get missionAlert;

  /// No description provided for @missionPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get missionPosition;

  /// No description provided for @missionDose.
  ///
  /// In en, this message translates to:
  /// **'Dose so far (est.)'**
  String get missionDose;

  /// No description provided for @missionO2Need.
  ///
  /// In en, this message translates to:
  /// **'Oxygen needed to walk back'**
  String get missionO2Need;

  /// No description provided for @missionO2Reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve on return'**
  String get missionO2Reserve;

  /// No description provided for @missionSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get missionSpeed;

  /// No description provided for @missionReset.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get missionReset;

  /// No description provided for @missionAlertPnr.
  ///
  /// In en, this message translates to:
  /// **'Past the point of no return'**
  String get missionAlertPnr;

  /// No description provided for @missionAlertO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen below what the walk back needs'**
  String get missionAlertO2;

  /// No description provided for @missionAlertO2Low.
  ///
  /// In en, this message translates to:
  /// **'Oxygen reserve on return under 10%'**
  String get missionAlertO2Low;

  /// No description provided for @missionAllClear.
  ///
  /// In en, this message translates to:
  /// **'No alerts at this position'**
  String get missionAllClear;

  /// No description provided for @missionDone.
  ///
  /// In en, this message translates to:
  /// **'Route finished'**
  String get missionDone;

  /// No description provided for @helmetNoRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating routes…'**
  String get helmetNoRoute;

  /// No description provided for @helmetHabitat.
  ///
  /// In en, this message translates to:
  /// **'HABITAT'**
  String get helmetHabitat;

  /// No description provided for @helmetConcept.
  ///
  /// In en, this message translates to:
  /// **'CONCEPT'**
  String get helmetConcept;

  /// No description provided for @helmetTitle.
  ///
  /// In en, this message translates to:
  /// **'Helmet visor display (HUD)'**
  String get helmetTitle;

  /// No description provided for @helmetNote.
  ///
  /// In en, this message translates to:
  /// **'Visual concept. The position is simulated along the selected route. Distances, heading, slope and objectives come from the route model; the air temperature comes from REMS. There are no vital signs or suit sensors: there is no data for them.'**
  String get helmetNote;

  /// No description provided for @helmetBackdrop.
  ///
  /// In en, this message translates to:
  /// **'Backdrop: real Curiosity photo ({source}); it is not the view of this route.'**
  String helmetBackdrop(String source);

  /// No description provided for @helmetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get helmetNext;

  /// No description provided for @helmetSlopeWarn.
  ///
  /// In en, this message translates to:
  /// **'CAUTION: SLOPE {deg}° AHEAD ({dist} m)'**
  String helmetSlopeWarn(String deg, String dist);

  /// No description provided for @helmetReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'RETURN'**
  String get helmetReturnTitle;

  /// No description provided for @helmetHabDist.
  ///
  /// In en, this message translates to:
  /// **'To habitat (straight line)'**
  String get helmetHabDist;

  /// No description provided for @helmetWalkBack.
  ///
  /// In en, this message translates to:
  /// **'Walk-back time'**
  String get helmetWalkBack;

  /// No description provided for @helmetPnr.
  ///
  /// In en, this message translates to:
  /// **'Point of no return at'**
  String get helmetPnr;

  /// No description provided for @helmetBeyondPnr.
  ///
  /// In en, this message translates to:
  /// **'Past the point'**
  String get helmetBeyondPnr;

  /// No description provided for @helmetYes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get helmetYes;

  /// No description provided for @helmetNo.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get helmetNo;

  /// No description provided for @helmetHereTitle.
  ///
  /// In en, this message translates to:
  /// **'HERE'**
  String get helmetHereTitle;

  /// No description provided for @helmetHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get helmetHeading;

  /// No description provided for @helmetSlopeAhead.
  ///
  /// In en, this message translates to:
  /// **'Slope ahead (90 m)'**
  String get helmetSlopeAhead;

  /// No description provided for @helmetAir.
  ///
  /// In en, this message translates to:
  /// **'Air temperature'**
  String get helmetAir;

  /// No description provided for @helmetElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed (est.)'**
  String get helmetElapsed;

  /// No description provided for @helmetO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen (est.)'**
  String get helmetO2;

  /// No description provided for @helmetPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get helmetPlay;

  /// No description provided for @helmetPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get helmetPause;

  /// No description provided for @helmetProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress along the route'**
  String get helmetProgress;

  /// No description provided for @helmetSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated position'**
  String get helmetSimulated;

  /// No description provided for @helmetFootnote.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time and oxygen are interpolated from the route totals. Air temperature uses the REMS hourly profile of the reference sol at the local time of the simulated position.'**
  String get helmetFootnote;

  /// No description provided for @modeTitle.
  ///
  /// In en, this message translates to:
  /// **'EXIT MODE'**
  String get modeTitle;

  /// No description provided for @modeFoot.
  ///
  /// In en, this message translates to:
  /// **'On foot'**
  String get modeFoot;

  /// No description provided for @modeRover.
  ///
  /// In en, this message translates to:
  /// **'With rover'**
  String get modeRover;

  /// No description provided for @metricRover.
  ///
  /// In en, this message translates to:
  /// **'Rover'**
  String get metricRover;

  /// No description provided for @metricRoverNone.
  ///
  /// In en, this message translates to:
  /// **'not used'**
  String get metricRoverNone;

  /// No description provided for @assumeRoverTitle.
  ///
  /// In en, this message translates to:
  /// **'ROVER MODE ASSUMPTIONS'**
  String get assumeRoverTitle;

  /// No description provided for @assumeRoverSpeed.
  ///
  /// In en, this message translates to:
  /// **'Rover speed'**
  String get assumeRoverSpeed;

  /// No description provided for @assumeRoverSlope.
  ///
  /// In en, this message translates to:
  /// **'Rover slope limit'**
  String get assumeRoverSlope;

  /// No description provided for @assumeRoverRough.
  ///
  /// In en, this message translates to:
  /// **'Rover maximum roughness'**
  String get assumeRoverRough;

  /// No description provided for @assumeRoverO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen use on the rover'**
  String get assumeRoverO2;

  /// No description provided for @assumeRoverTransfer.
  ///
  /// In en, this message translates to:
  /// **'Time to get on or off'**
  String get assumeRoverTransfer;

  /// No description provided for @assumeRoverNote.
  ///
  /// In en, this message translates to:
  /// **'The rover is left at one point of the route: it goes out along the first stretch it can drive and comes back along the last one. The rest is on foot. The routes are still optimized for walking. Speed and slope come from the Apollo lunar rover (NASA, NTRS 20250011301); the other values are team assumptions.'**
  String get assumeRoverNote;

  /// No description provided for @modeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get modeSupport;

  /// No description provided for @metricEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency return'**
  String get metricEmergency;

  /// No description provided for @metricEmergencyFoot.
  ///
  /// In en, this message translates to:
  /// **'On foot'**
  String get metricEmergencyFoot;

  /// No description provided for @assumeDispatch.
  ///
  /// In en, this message translates to:
  /// **'Support rover departure after the alert'**
  String get assumeDispatch;

  /// No description provided for @assumeSupportNote.
  ///
  /// In en, this message translates to:
  /// **'A rover waits at the habitat. The crew walks the same route; the rover does not change its time or oxygen. In an emergency it leaves after the alert, drives only where it can, and meets the astronaut on the way (the best meeting point is chosen). It shortens the return time, moves the point of no return and reduces the radius that counts in the hazard score. Speed and slope come from the Apollo lunar rover (NASA, NTRS 20250011301); the other values are team assumptions.'**
  String get assumeSupportNote;

  /// No description provided for @modePair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get modePair;

  /// No description provided for @routePair1.
  ///
  /// In en, this message translates to:
  /// **'Astronaut 1'**
  String get routePair1;

  /// No description provided for @routePair2.
  ///
  /// In en, this message translates to:
  /// **'Astronaut 2'**
  String get routePair2;

  /// No description provided for @reasonOtherAstronaut.
  ///
  /// In en, this message translates to:
  /// **'the other astronaut'**
  String get reasonOtherAstronaut;

  /// No description provided for @reasonNotInPair.
  ///
  /// In en, this message translates to:
  /// **'not reached by the pair'**
  String get reasonNotInPair;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'EVA IN A PAIR'**
  String get pairTitle;

  /// No description provided for @pairVisits.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get pairVisits;

  /// No description provided for @pairSeparation.
  ///
  /// In en, this message translates to:
  /// **'Max separation'**
  String get pairSeparation;

  /// No description provided for @pairO2Min.
  ///
  /// In en, this message translates to:
  /// **'Lowest oxygen'**
  String get pairO2Min;

  /// No description provided for @pairNone.
  ///
  /// In en, this message translates to:
  /// **'No pair of routes keeps the two astronauts within {limit} m of each other.'**
  String pairNone(String limit);

  /// No description provided for @pairNote.
  ///
  /// In en, this message translates to:
  /// **'Duration is that of the slower astronaut. Hazard is the higher of the two. Success counts the objectives visited by either one. Each astronaut has their own oxygen.'**
  String get pairNote;

  /// No description provided for @assumePairTitle.
  ///
  /// In en, this message translates to:
  /// **'PAIR MODE ASSUMPTIONS'**
  String get assumePairTitle;

  /// No description provided for @assumePairSep.
  ///
  /// In en, this message translates to:
  /// **'Maximum separation'**
  String get assumePairSep;

  /// No description provided for @assumePairSample.
  ///
  /// In en, this message translates to:
  /// **'Separation checked every'**
  String get assumePairSample;

  /// No description provided for @assumePairNote.
  ///
  /// In en, this message translates to:
  /// **'Two astronauts leave the habitat together, split the objectives and must stay within the maximum separation (line of sight and communication) at all times. Real NASA EVAs go in pairs and together, so this split is our own extension and the limit is a team assumption without a reference. Each route keeps the science rule: feasible, and with a comfortable margin if it has more than one objective.'**
  String get assumePairNote;

  /// No description provided for @siteChange.
  ///
  /// In en, this message translates to:
  /// **'Change site'**
  String get siteChange;

  /// No description provided for @sitePending.
  ///
  /// In en, this message translates to:
  /// **'Data in preparation'**
  String get sitePending;

  /// No description provided for @siteLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the site. The current one stays open.'**
  String get siteLoadError;

  /// No description provided for @modeObjective.
  ///
  /// In en, this message translates to:
  /// **'By objective'**
  String get modeObjective;

  /// No description provided for @transportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportTitle;

  /// No description provided for @transportFoot.
  ///
  /// In en, this message translates to:
  /// **'On foot'**
  String get transportFoot;

  /// No description provided for @transportVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get transportVehicle;

  /// No description provided for @transportHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get transportHybrid;

  /// No description provided for @transportHint.
  ///
  /// In en, this message translates to:
  /// **'Only used in “By objective” mode. Vehicle: drive to the objective. Hybrid: drive as far as the terrain allows, then walk.'**
  String get transportHint;

  /// No description provided for @reasonRover.
  ///
  /// In en, this message translates to:
  /// **'the vehicle would be left behind'**
  String get reasonRover;

  /// No description provided for @assumeObjectiveNote.
  ///
  /// In en, this message translates to:
  /// **'Each objective brings its own transport. There is one vehicle: it leaves the habitat with the astronaut and stays where it is parked; to use it again, the route has to pass through that point. The way to a “Vehicle” objective is searched only over cells the vehicle can drive. Speed, slope, roughness and transfer values are the rover ones.'**
  String get assumeObjectiveNote;

  /// No description provided for @transportNoteNotHere.
  ///
  /// In en, this message translates to:
  /// **'{name}: the vehicle is not on this stretch, so it is done on foot.'**
  String transportNoteNotHere(String name);

  /// No description provided for @transportNoteCannotStart.
  ///
  /// In en, this message translates to:
  /// **'{name}: the vehicle cannot start from here, so it is done on foot.'**
  String transportNoteCannotStart(String name);

  /// No description provided for @transportNoteBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name}: the vehicle cannot advance on this stretch, so it is done on foot.'**
  String transportNoteBlocked(String name);

  /// No description provided for @transportNotePartial.
  ///
  /// In en, this message translates to:
  /// **'{name}: the vehicle cannot reach it. It goes as far as it can and the rest is on foot.'**
  String transportNotePartial(String name);

  /// No description provided for @transportNoteNoRecovery.
  ///
  /// In en, this message translates to:
  /// **'{name}: there is no point on the way back to pick the vehicle up again, so it is done on foot.'**
  String transportNoteNoRecovery(String name);

  /// No description provided for @transportNoteStranded.
  ///
  /// In en, this message translates to:
  /// **'The vehicle would be left behind: the way back never passes through where it was parked.'**
  String get transportNoteStranded;

  /// No description provided for @msnTitle.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get msnTitle;

  /// No description provided for @msnNew.
  ///
  /// In en, this message translates to:
  /// **'New mission'**
  String get msnNew;

  /// No description provided for @msnDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get msnDuplicate;

  /// No description provided for @msnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get msnDelete;

  /// No description provided for @msnDeleteLast.
  ///
  /// In en, this message translates to:
  /// **'The only mission cannot be deleted.'**
  String get msnDeleteLast;

  /// No description provided for @msnDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete mission?'**
  String get msnDeleteTitle;

  /// No description provided for @msnDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be deleted from this device. This cannot be undone.'**
  String msnDeleteBody(String name);

  /// No description provided for @msnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get msnName;

  /// No description provided for @msnNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get msnNotes;

  /// No description provided for @msnSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get msnSite;

  /// No description provided for @msnObjectives.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No objectives} =1{1 objective} other{{count} objectives}}'**
  String msnObjectives(int count);

  /// No description provided for @msnConsumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get msnConsumables;

  /// No description provided for @msnEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment and tools'**
  String get msnEquipment;

  /// No description provided for @msnAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get msnAddItem;

  /// No description provided for @msnEmptyItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing added.'**
  String get msnEmptyItems;

  /// No description provided for @msnItemName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get msnItemName;

  /// No description provided for @msnItemQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get msnItemQty;

  /// No description provided for @msnItemUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get msnItemUnit;

  /// No description provided for @msnItemMass.
  ///
  /// In en, this message translates to:
  /// **'Mass per unit (kg)'**
  String get msnItemMass;

  /// No description provided for @msnMassTotal.
  ///
  /// In en, this message translates to:
  /// **'Declared mass: {kg} kg'**
  String msnMassTotal(String kg);

  /// No description provided for @msnAssumeNote.
  ///
  /// In en, this message translates to:
  /// **'Consumables and equipment are written by the user. They are not NASA data and do not change the route calculation yet.'**
  String get msnAssumeNote;

  /// No description provided for @msnRoutesNote.
  ///
  /// In en, this message translates to:
  /// **'The routes are calculated from the objectives of the open mission.'**
  String get msnRoutesNote;

  /// No description provided for @msnExport.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get msnExport;

  /// No description provided for @msnCopied.
  ///
  /// In en, this message translates to:
  /// **'Mission copied as JSON.'**
  String get msnCopied;

  /// No description provided for @msnOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the site of that mission.'**
  String get msnOpenError;

  /// No description provided for @msnCurrent.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get msnCurrent;

  /// No description provided for @siteIndicativeTag.
  ///
  /// In en, this message translates to:
  /// **'Indicative'**
  String get siteIndicativeTag;

  /// No description provided for @siteIndicativeNote.
  ///
  /// In en, this message translates to:
  /// **'Indicative routes: the relief comes from a 200 m model, so local slopes are smoothed and the roughness is unknown. Use them as an approximation, not to avoid rocks or small slopes.'**
  String get siteIndicativeNote;

  /// No description provided for @layerSlope15.
  ///
  /// In en, this message translates to:
  /// **'Slope above 15 %'**
  String get layerSlope15;

  /// No description provided for @layerTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit zones (DCI + thermal inertia)'**
  String get layerTransit;

  /// No description provided for @layerThermalNight.
  ///
  /// In en, this message translates to:
  /// **'Relative thermal inertia (THEMIS-IR night)'**
  String get layerThermalNight;

  /// No description provided for @layerMineralsPts.
  ///
  /// In en, this message translates to:
  /// **'Aqueous and hydrous minerals'**
  String get layerMineralsPts;

  /// No description provided for @layerAqueousPts.
  ///
  /// In en, this message translates to:
  /// **'Aqueous minerals · biosignatures'**
  String get layerAqueousPts;

  /// No description provided for @layerHydrousPts.
  ///
  /// In en, this message translates to:
  /// **'Hydrous minerals (CRISM, OMEGA)'**
  String get layerHydrousPts;

  /// No description provided for @layerValleys.
  ///
  /// In en, this message translates to:
  /// **'Valley networks (Hynek 2010)'**
  String get layerValleys;

  /// No description provided for @legendBiosigTitle.
  ///
  /// In en, this message translates to:
  /// **'Biosignature search (from orbit)'**
  String get legendBiosigTitle;

  /// No description provided for @legendCarbonate.
  ///
  /// In en, this message translates to:
  /// **'Carbonate'**
  String get legendCarbonate;

  /// No description provided for @legendValleys.
  ///
  /// In en, this message translates to:
  /// **'Valley network (ancient water)'**
  String get legendValleys;

  /// No description provided for @legendBiosigNote.
  ///
  /// In en, this message translates to:
  /// **'Phyllosilicates and hydrous minerals: ground more likely to preserve biosignatures. Orbital detections from Mars Trek (NASA), not in-situ samples.'**
  String get legendBiosigNote;

  /// No description provided for @layerZones.
  ///
  /// In en, this message translates to:
  /// **'Exploration zones'**
  String get layerZones;

  /// No description provided for @legendTransitTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit zones (TES, 3.5 km per pixel)'**
  String get legendTransitTitle;

  /// No description provided for @legendTransitGreen.
  ///
  /// In en, this message translates to:
  /// **'Best transit: DCI > 0.96 and inertia > 300'**
  String get legendTransitGreen;

  /// No description provided for @legendTransitYellow.
  ///
  /// In en, this message translates to:
  /// **'Safe transit: DCI > 0.95 and inertia 180 to 300'**
  String get legendTransitYellow;

  /// No description provided for @legendTransitRed.
  ///
  /// In en, this message translates to:
  /// **'Avoid: DCI < 0.94 and inertia < 150'**
  String get legendTransitRed;

  /// No description provided for @legendTransitNone.
  ///
  /// In en, this message translates to:
  /// **'Not classified (outside those rules)'**
  String get legendTransitNone;

  /// No description provided for @legendMineralsTitle.
  ///
  /// In en, this message translates to:
  /// **'Minerals (orbit)'**
  String get legendMineralsTitle;

  /// No description provided for @legendSulfate.
  ///
  /// In en, this message translates to:
  /// **'Sulfate'**
  String get legendSulfate;

  /// No description provided for @legendPhyllo.
  ///
  /// In en, this message translates to:
  /// **'Phyllosilicate (clay)'**
  String get legendPhyllo;

  /// No description provided for @legendHydrous.
  ///
  /// In en, this message translates to:
  /// **'Hydrous mineral'**
  String get legendHydrous;

  /// No description provided for @legendZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exploration zones (NASA, 2015)'**
  String get legendZonesTitle;

  /// No description provided for @legendHabitation.
  ///
  /// In en, this message translates to:
  /// **'Habitation zone'**
  String get legendHabitation;

  /// No description provided for @legendLanding.
  ///
  /// In en, this message translates to:
  /// **'Landing site'**
  String get legendLanding;

  /// No description provided for @legendEz.
  ///
  /// In en, this message translates to:
  /// **'Exploration zone'**
  String get legendEz;

  /// No description provided for @legendRoi.
  ///
  /// In en, this message translates to:
  /// **'Region of interest'**
  String get legendRoi;

  /// No description provided for @legendEzRadius.
  ///
  /// In en, this message translates to:
  /// **'100 km radius'**
  String get legendEzRadius;

  /// No description provided for @legendSlope15.
  ///
  /// In en, this message translates to:
  /// **'Slope above 15 % (avoid for a base)'**
  String get legendSlope15;

  /// No description provided for @transitNote.
  ///
  /// In en, this message translates to:
  /// **'Measured by MGS-TES (NASA/ASU) at 3.5 km/px (DCI) and 7.5 km/px (thermal inertia). The red zone (DCI < 0.94 and inertia < 150) is automatically blocked as a dust trap in route calculation.'**
  String get transitNote;

  /// No description provided for @srcTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources and data'**
  String get srcTitle;

  /// No description provided for @srcIntro.
  ///
  /// In en, this message translates to:
  /// **'Every value in the app is one of three kinds: real data from NASA, USGS or ASU; a value computed by the team from that data; or a team assumption. Source files and dates are listed in the project notes (RECURSOS.md).'**
  String get srcIntro;

  /// No description provided for @srcReal.
  ///
  /// In en, this message translates to:
  /// **'Real data'**
  String get srcReal;

  /// No description provided for @srcModeled.
  ///
  /// In en, this message translates to:
  /// **'Computed by the team'**
  String get srcModeled;

  /// No description provided for @srcAssumed.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get srcAssumed;

  /// No description provided for @srcClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get srcClose;

  /// No description provided for @safeNoEnvData.
  ///
  /// In en, this message translates to:
  /// **'No radiation or weather measurements at this site: RAD and REMS are on Curiosity, in Gale crater, so those two checks stay pending. The dose of the routes uses the Gale baseline as an assumption. Meridiani lies higher, with less atmosphere above it, so the real dose is probably larger.'**
  String get safeNoEnvData;

  /// No description provided for @doseGaleNote.
  ///
  /// In en, this message translates to:
  /// **'This site has no radiation measurements: the dose uses the Gale baseline (assumption).'**
  String get doseGaleNote;

  /// No description provided for @srcLink.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get srcLink;

  /// No description provided for @layerNames.
  ///
  /// In en, this message translates to:
  /// **'Place names (IAU)'**
  String get layerNames;

  /// No description provided for @layerCraters.
  ///
  /// In en, this message translates to:
  /// **'Craters of 1 km and larger'**
  String get layerCraters;

  /// No description provided for @layerGeology.
  ///
  /// In en, this message translates to:
  /// **'Geology and dunes'**
  String get layerGeology;

  /// No description provided for @routeAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'ROUTE AREA'**
  String get routeAreaLabel;

  /// No description provided for @legendGeologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Geology and dunes (USGS, global scale)'**
  String get legendGeologyTitle;

  /// No description provided for @legendGeologyNote.
  ///
  /// In en, this message translates to:
  /// **'The unit code is drawn on each area (for example Htu, mNh). Dune fields appear in amber. The map is global scale: it does not resolve small outcrops.'**
  String get legendGeologyNote;

  /// No description provided for @legendCraters.
  ///
  /// In en, this message translates to:
  /// **'Crater of 1 km or more (Robbins database)'**
  String get legendCraters;

  /// No description provided for @legendNames.
  ///
  /// In en, this message translates to:
  /// **'Official place name (IAU)'**
  String get legendNames;

  /// No description provided for @contextNote.
  ///
  /// In en, this message translates to:
  /// **'Outside the dashed frame there is a coarser image (CTX) for context. Routes are only calculated inside the frame.'**
  String get contextNote;

  /// No description provided for @siteReachTag.
  ///
  /// In en, this message translates to:
  /// **'Long range'**
  String get siteReachTag;

  /// No description provided for @siteReachNote.
  ///
  /// In en, this message translates to:
  /// **'Long-range routes: the grid is 16 m over a real DEM, so it does not see small obstacles and the roughness is unknown. The 4 km site has the detail; this one reaches the whole EVA range (about 12 km).'**
  String get siteReachNote;

  /// No description provided for @mapTraceLegend.
  ///
  /// In en, this message translates to:
  /// **'Current view: {viewW} × {viewH} km  ·  Available trace: {traceW} × {traceH} km'**
  String mapTraceLegend(
    String viewW,
    String viewH,
    String traceW,
    String traceH,
  );

  /// No description provided for @routeAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'ROUTE & OBJECTIVE'**
  String get routeAutoTitle;

  /// No description provided for @routeAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Automatic route from the habitat to the selected objective (based on terrain slope, roughness, and distance).'**
  String get routeAutoHint;

  /// No description provided for @routeSelectObjective.
  ///
  /// In en, this message translates to:
  /// **'Click an objective on the map or use \"Add objective\" to trace the route and view its real data.'**
  String get routeSelectObjective;

  /// No description provided for @objectiveCoords.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get objectiveCoords;

  /// No description provided for @objectiveElev.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get objectiveElev;

  /// No description provided for @objectiveSlope.
  ///
  /// In en, this message translates to:
  /// **'Local slope'**
  String get objectiveSlope;

  /// No description provided for @metricElevRange.
  ///
  /// In en, this message translates to:
  /// **'Ascent / descent'**
  String get metricElevRange;

  /// No description provided for @objectiveEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get objectiveEditBtn;

  /// No description provided for @routeStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting point'**
  String get routeStartLabel;

  /// No description provided for @routeSetStart.
  ///
  /// In en, this message translates to:
  /// **'Set as start'**
  String get routeSetStart;

  /// No description provided for @routeActiveStart.
  ///
  /// In en, this message translates to:
  /// **'Active start'**
  String get routeActiveStart;

  /// No description provided for @routeTracedTitle.
  ///
  /// In en, this message translates to:
  /// **'TRACED ROUTES'**
  String get routeTracedTitle;

  /// No description provided for @routeBackToHab.
  ///
  /// In en, this message translates to:
  /// **'Trace return to habitat'**
  String get routeBackToHab;

  /// No description provided for @routeNoRoutes.
  ///
  /// In en, this message translates to:
  /// **'No traced routes.'**
  String get routeNoRoutes;

  /// No description provided for @routeEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get routeEndLabel;

  /// No description provided for @routeSwapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap start and destination'**
  String get routeSwapTooltip;

  /// No description provided for @routeTraceBtn.
  ///
  /// In en, this message translates to:
  /// **'Trace route'**
  String get routeTraceBtn;

  /// No description provided for @routeSelectDestHint.
  ///
  /// In en, this message translates to:
  /// **'Select destination...'**
  String get routeSelectDestHint;

  /// No description provided for @objectivesSelectMode.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get objectivesSelectMode;

  /// No description provided for @objectivesSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get objectivesSelectAll;

  /// No description provided for @objectivesSelectNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get objectivesSelectNone;

  /// No description provided for @objectivesDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String objectivesDeleteSelected(int count);

  /// No description provided for @objectivesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get objectivesCancel;

  /// No description provided for @routeTracePickStart.
  ///
  /// In en, this message translates to:
  /// **'Tap starting point (Habitat or objective)'**
  String get routeTracePickStart;

  /// No description provided for @routeTracePickEnd.
  ///
  /// In en, this message translates to:
  /// **'Tap destination (Habitat or objective)'**
  String get routeTracePickEnd;

  /// No description provided for @routeNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get routeNoneSelected;

  /// No description provided for @navRouteCalc.
  ///
  /// In en, this message translates to:
  /// **'ROUTE CALCULATION'**
  String get navRouteCalc;

  /// No description provided for @rcTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety model & A* routing criteria'**
  String get rcTitle;

  /// No description provided for @rcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real NASA/USGS/ASU datasets and thresholds used by the Meridiani Planum pathfinder to keep astronauts safe.'**
  String get rcSubtitle;

  /// No description provided for @rcFormulaSection.
  ///
  /// In en, this message translates to:
  /// **'A* COST FUNCTION (SAFEST PROFILE)'**
  String get rcFormulaSection;

  /// No description provided for @rcFormulaDesc.
  ///
  /// In en, this message translates to:
  /// **'Each step between adjacent cells weighs real ground distance in meters, a quadratic slope penalty from the smoothed orbital DEM, and a normalized surface dust-trap index (40% DCI + 40% TI + 20% THEMIS-IR Night). Cells outside the valid CTX footprint, steeper than 15°, or inside critical dust traps are blocked.'**
  String get rcFormulaDesc;

  /// No description provided for @rcHardConstraintsSection.
  ///
  /// In en, this message translates to:
  /// **'HARD CONSTRAINTS (NO-GO)'**
  String get rcHardConstraintsSection;

  /// No description provided for @rcHardSlopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum passable slope: ≤ 15.0° (caution ≥ 12.0°)'**
  String get rcHardSlopeTitle;

  /// No description provided for @rcHardSlopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Project safety margin on NASA baseline: NASA operational rover/EVA limits (Apollo LRV & Artemis mobility studies) allow up to ~20° on locally surveyed ground. Because our HRSC+MOLA orbital DEM is 200 m/px and smooths sub-pixel scarps, we apply a conservative 15.0° hard cutoff (caution above 12.0°). Areas outside valid CTX mosaic coverage are also blocked.'**
  String get rcHardSlopeDesc;

  /// No description provided for @rcHardDustTitle.
  ///
  /// In en, this message translates to:
  /// **'Critical dust & soft-soil traps: DCI < 0.94 and TI < 150'**
  String get rcHardDustTitle;

  /// No description provided for @rcHardDustDesc.
  ///
  /// In en, this message translates to:
  /// **'Cells combining heavy dust cover (Dust Cover Index < 0.94) and very low thermal inertia (TI < 150 J·m⁻²·K⁻¹·s⁻¹/²) indicate unconsolidated fine silt with high sinkage/entrapment hazard (analogous to Meridiani dunes that bogged MER Opportunity) and are marked impassable.'**
  String get rcHardDustDesc;

  /// No description provided for @rcCriteriaSection.
  ///
  /// In en, this message translates to:
  /// **'SCIENTIFIC CRITERIA & DATA SOURCES'**
  String get rcCriteriaSection;

  /// No description provided for @rcCritSlopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Topographic slope & elevation (DEM)'**
  String get rcCritSlopeTitle;

  /// No description provided for @rcCritSlopeSource.
  ///
  /// In en, this message translates to:
  /// **'MEASURED · USGS Astrogeology HRSC+MOLA 200 m/px · weight w_slope = 2.5'**
  String get rcCritSlopeSource;

  /// No description provided for @rcCritSlopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Surface gradient computed with a Gaussian filter (σ = 1.5 cells at 640 m grid spacing) from the 200 m/px HRSC+MOLA orbital DEM. Enters A* cost as (slope / 15°)² × 2.5 and forbids any cell exceeding 15.0°.'**
  String get rcCritSlopeDesc;

  /// No description provided for @rcCritDciTitle.
  ///
  /// In en, this message translates to:
  /// **'Dust Cover Index (DCI)'**
  String get rcCritDciTitle;

  /// No description provided for @rcCritDciSource.
  ///
  /// In en, this message translates to:
  /// **'MEASURED · NASA / ASU Mars Global Surveyor TES 16 ppd · 40% of surface index'**
  String get rcCritDciSource;

  /// No description provided for @rcCritDciDesc.
  ///
  /// In en, this message translates to:
  /// **'Ruff & Christensen (2002) spectral emissivity index across 1350–1400 cm⁻¹. Low values (< 0.94) reveal thick mantling dust; high values (≥ 0.98) indicate dust-free bedrock or firm coarse sand.'**
  String get rcCritDciDesc;

  /// No description provided for @rcCritTiTitle.
  ///
  /// In en, this message translates to:
  /// **'Thermal Inertia (TI)'**
  String get rcCritTiTitle;

  /// No description provided for @rcCritTiSource.
  ///
  /// In en, this message translates to:
  /// **'MEASURED · NASA / ASU TES Meridiani 0.125°/px · 40% of surface index'**
  String get rcCritTiSource;

  /// No description provided for @rcCritTiDesc.
  ///
  /// In en, this message translates to:
  /// **'Bulk thermal inertia of the upper few centimeters (J·m⁻²·K⁻¹·s⁻¹/²). Low inertia (< 150) signals loose fine dust with poor bearing strength; higher inertia (250–350+) reflects indurated regolith or exposed bedrock.'**
  String get rcCritTiDesc;

  /// No description provided for @rcCritThemisTitle.
  ///
  /// In en, this message translates to:
  /// **'Nighttime Thermal Infrared brightness (THEMIS-IR)'**
  String get rcCritThemisTitle;

  /// No description provided for @rcCritThemisSource.
  ///
  /// In en, this message translates to:
  /// **'MEASURED · NASA / Mars Odyssey THEMIS via Mars Trek ~100 m/px · 20% of surface index'**
  String get rcCritThemisSource;

  /// No description provided for @rcCritThemisDesc.
  ///
  /// In en, this message translates to:
  /// **'Normalized nighttime infrared mosaic (2–98% stretch). Fine loose dust cools rapidly overnight (dark = higher penalty) whereas competent rock retains daytime heat (bright = lower penalty). Relative brightness only, not calibrated Kelvin temperature.'**
  String get rcCritThemisDesc;

  /// No description provided for @rcCritMobilityTitle.
  ///
  /// In en, this message translates to:
  /// **'EVA pacing & traversal effort model'**
  String get rcCritMobilityTitle;

  /// No description provided for @rcCritMobilitySource.
  ///
  /// In en, this message translates to:
  /// **'MODELED · Tobler (1993) hiking function + NASA EVA limit · surface weight w_rough = 4.0'**
  String get rcCritMobilitySource;

  /// No description provided for @rcCritMobilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Estimates sortie travel time using Tobler\'s slope-dependent walking curve anchored at 4.0 km/h flat speed (0.95× uphill) combined with the composite dust/surface index across the 512×512 grid.'**
  String get rcCritMobilityDesc;

  /// No description provided for @rcActiveRouteSection.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE ROUTE AUDIT'**
  String get rcActiveRouteSection;

  /// No description provided for @rcCellsEvaluated.
  ///
  /// In en, this message translates to:
  /// **'A* cells evaluated'**
  String get rcCellsEvaluated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
