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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'REPX - Contador de Flexiones'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @personalTrainer.
  ///
  /// In es, this message translates to:
  /// **'Entrenador Personal IA'**
  String get personalTrainer;

  /// No description provided for @startPushups.
  ///
  /// In es, this message translates to:
  /// **'Empezar Flexiones'**
  String get startPushups;

  /// No description provided for @startPullups.
  ///
  /// In es, this message translates to:
  /// **'Empezar Dominadas'**
  String get startPullups;

  /// No description provided for @viewHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver Historial'**
  String get viewHistory;

  /// No description provided for @configure.
  ///
  /// In es, this message translates to:
  /// **'Configurar'**
  String get configure;

  /// No description provided for @chatWithAI.
  ///
  /// In es, this message translates to:
  /// **'Chatea con IA'**
  String get chatWithAI;

  /// No description provided for @visualization.
  ///
  /// In es, this message translates to:
  /// **'Visualización'**
  String get visualization;

  /// No description provided for @showSkeleton.
  ///
  /// In es, this message translates to:
  /// **'Mostrar Skeleton'**
  String get showSkeleton;

  /// No description provided for @showSkeletonDesc.
  ///
  /// In es, this message translates to:
  /// **'Dibuja los puntos clave y conexiones'**
  String get showSkeletonDesc;

  /// No description provided for @showAngles.
  ///
  /// In es, this message translates to:
  /// **'Mostrar Ángulos'**
  String get showAngles;

  /// No description provided for @showAnglesDesc.
  ///
  /// In es, this message translates to:
  /// **'Indica los ángulos de codos en tiempo real'**
  String get showAnglesDesc;

  /// No description provided for @showQualityBar.
  ///
  /// In es, this message translates to:
  /// **'Barra de Calidad'**
  String get showQualityBar;

  /// No description provided for @showQualityBarDesc.
  ///
  /// In es, this message translates to:
  /// **'Muestra la calidad de forma en vivo'**
  String get showQualityBarDesc;

  /// No description provided for @audio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @sounds.
  ///
  /// In es, this message translates to:
  /// **'Sonidos'**
  String get sounds;

  /// No description provided for @soundsDesc.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de audio al completar reps'**
  String get soundsDesc;

  /// No description provided for @sensitivity.
  ///
  /// In es, this message translates to:
  /// **'Sensibilidad'**
  String get sensitivity;

  /// No description provided for @angleThreshold.
  ///
  /// In es, this message translates to:
  /// **'Umbral de Ángulo'**
  String get angleThreshold;

  /// No description provided for @angleThresholdDesc.
  ///
  /// In es, this message translates to:
  /// **'Ángulo mínimo para contar flexión (DOWN)'**
  String get angleThresholdDesc;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageDesc.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el idioma de la aplicación'**
  String get languageDesc;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get english;

  /// No description provided for @systemInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del Sistema'**
  String get systemInfo;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @mlModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo ML'**
  String get mlModel;

  /// No description provided for @developer.
  ///
  /// In es, this message translates to:
  /// **'Desarrollador'**
  String get developer;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verifica tu conexión a internet e intenta de nuevo.'**
  String get connectionError;

  /// No description provided for @typeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @reps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @quality.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get quality;

  /// No description provided for @calories.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get calories;

  /// No description provided for @duration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get duration;

  /// No description provided for @noDataAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay datos disponibles'**
  String get noDataAvailable;

  /// No description provided for @excellent.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get good;

  /// No description provided for @regular.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @poor.
  ///
  /// In es, this message translates to:
  /// **'Pobre'**
  String get poor;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @pushups.
  ///
  /// In es, this message translates to:
  /// **'Flexiones'**
  String get pushups;

  /// No description provided for @pullups.
  ///
  /// In es, this message translates to:
  /// **'Dominadas'**
  String get pullups;

  /// No description provided for @noSessions.
  ///
  /// In es, this message translates to:
  /// **'No hay sesiones'**
  String get noSessions;

  /// No description provided for @startFirstWorkout.
  ///
  /// In es, this message translates to:
  /// **'Comienza tu primer entrenamiento'**
  String get startFirstWorkout;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @min.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @series.
  ///
  /// In es, this message translates to:
  /// **'series'**
  String get series;

  /// No description provided for @january.
  ///
  /// In es, this message translates to:
  /// **'Enero'**
  String get january;

  /// No description provided for @february.
  ///
  /// In es, this message translates to:
  /// **'Febrero'**
  String get february;

  /// No description provided for @march.
  ///
  /// In es, this message translates to:
  /// **'Marzo'**
  String get march;

  /// No description provided for @april.
  ///
  /// In es, this message translates to:
  /// **'Abril'**
  String get april;

  /// No description provided for @may.
  ///
  /// In es, this message translates to:
  /// **'Mayo'**
  String get may;

  /// No description provided for @june.
  ///
  /// In es, this message translates to:
  /// **'Junio'**
  String get june;

  /// No description provided for @july.
  ///
  /// In es, this message translates to:
  /// **'Julio'**
  String get july;

  /// No description provided for @august.
  ///
  /// In es, this message translates to:
  /// **'Agosto'**
  String get august;

  /// No description provided for @september.
  ///
  /// In es, this message translates to:
  /// **'Septiembre'**
  String get september;

  /// No description provided for @october.
  ///
  /// In es, this message translates to:
  /// **'Octubre'**
  String get october;

  /// No description provided for @november.
  ///
  /// In es, this message translates to:
  /// **'Noviembre'**
  String get november;

  /// No description provided for @december.
  ///
  /// In es, this message translates to:
  /// **'Diciembre'**
  String get december;

  /// No description provided for @aiPoweredTraining.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento con IA'**
  String get aiPoweredTraining;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'COMENZAR'**
  String get start;

  /// No description provided for @realTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo Real'**
  String get realTime;

  /// No description provided for @validation.
  ///
  /// In es, this message translates to:
  /// **'Validación'**
  String get validation;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @systemReady.
  ///
  /// In es, this message translates to:
  /// **'Sistema listo'**
  String get systemReady;

  /// No description provided for @positionDeviceAndStart.
  ///
  /// In es, this message translates to:
  /// **'Posiciona tu dispositivo y comienza'**
  String get positionDeviceAndStart;

  /// No description provided for @selectExercise.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONA'**
  String get selectExercise;

  /// No description provided for @yourExercise.
  ///
  /// In es, this message translates to:
  /// **'TU EJERCICIO'**
  String get yourExercise;

  /// No description provided for @chestPushups.
  ///
  /// In es, this message translates to:
  /// **'Flexiones de pecho'**
  String get chestPushups;

  /// No description provided for @barPullUps.
  ///
  /// In es, this message translates to:
  /// **'Dominadas en barra'**
  String get barPullUps;

  /// No description provided for @configureWorkout.
  ///
  /// In es, this message translates to:
  /// **'Configura tu entrenamiento'**
  String get configureWorkout;

  /// No description provided for @repsPerSet.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones por serie'**
  String get repsPerSet;

  /// No description provided for @repsPerSetDesc.
  ///
  /// In es, this message translates to:
  /// **'Define cuántas pull-ups harás por serie'**
  String get repsPerSetDesc;

  /// No description provided for @numberOfSets.
  ///
  /// In es, this message translates to:
  /// **'Número de series'**
  String get numberOfSets;

  /// No description provided for @numberOfSetsDesc.
  ///
  /// In es, this message translates to:
  /// **'Total de series que completarás'**
  String get numberOfSetsDesc;

  /// No description provided for @restBetweenSets.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre series'**
  String get restBetweenSets;

  /// No description provided for @restBetweenSetsDesc.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de recuperación'**
  String get restBetweenSetsDesc;

  /// No description provided for @repsUnit.
  ///
  /// In es, this message translates to:
  /// **'reps'**
  String get repsUnit;

  /// No description provided for @seriesUnit.
  ///
  /// In es, this message translates to:
  /// **'series'**
  String get seriesUnit;

  /// No description provided for @secondsUnit.
  ///
  /// In es, this message translates to:
  /// **'segundos'**
  String get secondsUnit;

  /// No description provided for @workoutSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen del Entrenamiento'**
  String get workoutSummary;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @time.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get time;

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String get minutes;

  /// No description provided for @initializingAI.
  ///
  /// In es, this message translates to:
  /// **'Inicializando IA...'**
  String get initializingAI;

  /// No description provided for @preparingPoseDetection.
  ///
  /// In es, this message translates to:
  /// **'Preparando detección de pose'**
  String get preparingPoseDetection;

  /// No description provided for @couldNotInitCamera.
  ///
  /// In es, this message translates to:
  /// **'No se pudo inicializar la cámara'**
  String get couldNotInitCamera;

  /// No description provided for @goBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get goBack;

  /// No description provided for @formQuality.
  ///
  /// In es, this message translates to:
  /// **'CALIDAD'**
  String get formQuality;

  /// No description provided for @badReps.
  ///
  /// In es, this message translates to:
  /// **'MALAS'**
  String get badReps;

  /// No description provided for @set.
  ///
  /// In es, this message translates to:
  /// **'SERIE'**
  String get set;

  /// No description provided for @rest.
  ///
  /// In es, this message translates to:
  /// **'DESCANSO'**
  String get rest;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'COMPLETADO'**
  String get completed;

  /// No description provided for @congratulations.
  ///
  /// In es, this message translates to:
  /// **'¡Felicidades!'**
  String get congratulations;

  /// No description provided for @skipRest.
  ///
  /// In es, this message translates to:
  /// **'SALTAR RECESO'**
  String get skipRest;

  /// No description provided for @finishSession.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR SESIÓN'**
  String get finishSession;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'FINALIZAR'**
  String get finish;

  /// No description provided for @finishSessionQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar sesión?'**
  String get finishSessionQuestion;

  /// No description provided for @previousSet.
  ///
  /// In es, this message translates to:
  /// **'Serie anterior'**
  String get previousSet;

  /// No description provided for @setsCompleted.
  ///
  /// In es, this message translates to:
  /// **'series completadas'**
  String get setsCompleted;

  /// No description provided for @continueButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @deleteSession.
  ///
  /// In es, this message translates to:
  /// **'Eliminar sesión'**
  String get deleteSession;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @sessionDeleted.
  ///
  /// In es, this message translates to:
  /// **'Sesión eliminada'**
  String get sessionDeleted;

  /// No description provided for @finishWorkoutQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas finalizar esta sesión de entrenamiento?'**
  String get finishWorkoutQuestion;

  /// No description provided for @durationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get durationLabel;

  /// No description provided for @fitnessTest.
  ///
  /// In es, this message translates to:
  /// **'PRUEBA DE FITNESS'**
  String get fitnessTest;

  /// No description provided for @fitnessTestCard.
  ///
  /// In es, this message translates to:
  /// **'TEST DE FITNESS'**
  String get fitnessTestCard;

  /// No description provided for @fitnessTestDetails.
  ///
  /// In es, this message translates to:
  /// **'3 ejercicios • 3 minutos'**
  String get fitnessTestDetails;

  /// No description provided for @fitnessTestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Evalúa tu nivel'**
  String get fitnessTestSubtitle;

  /// No description provided for @instructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones'**
  String get instructions;

  /// No description provided for @instructionsDesc.
  ///
  /// In es, this message translates to:
  /// **'Esta prueba mide tu nivel físico en 3 minutos, evaluando 3 ejercicios consecutivos con períodos de descanso entre cada uno.'**
  String get instructionsDesc;

  /// No description provided for @pushupExercise.
  ///
  /// In es, this message translates to:
  /// **'FLEXIONES (Push-ups)'**
  String get pushupExercise;

  /// No description provided for @squatExercise.
  ///
  /// In es, this message translates to:
  /// **'SENTADILLAS (Squats)'**
  String get squatExercise;

  /// No description provided for @abdominalExercise.
  ///
  /// In es, this message translates to:
  /// **'ABDOMINALES (Crunches)'**
  String get abdominalExercise;

  /// No description provided for @maxReps60Seconds.
  ///
  /// In es, this message translates to:
  /// **'60 segundos - Máximo de reps'**
  String get maxReps60Seconds;

  /// No description provided for @pushupTechnique.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo recto, brazos flexionados 90°'**
  String get pushupTechnique;

  /// No description provided for @squatTechnique.
  ///
  /// In es, this message translates to:
  /// **'Cadera hacia atrás, rodillas paralelas'**
  String get squatTechnique;

  /// No description provided for @abdominalTechnique.
  ///
  /// In es, this message translates to:
  /// **'Levanta hombros hacia caderas, cuello recto'**
  String get abdominalTechnique;

  /// No description provided for @restBreak.
  ///
  /// In es, this message translates to:
  /// **'RECESO - 30 segundos'**
  String get restBreak;

  /// No description provided for @important.
  ///
  /// In es, this message translates to:
  /// **'IMPORTANTE'**
  String get important;

  /// No description provided for @goodLighting.
  ///
  /// In es, this message translates to:
  /// **'Asegúrate de tener buena iluminación'**
  String get goodLighting;

  /// No description provided for @faceCamera.
  ///
  /// In es, this message translates to:
  /// **'Colócate de frente a la cámara'**
  String get faceCamera;

  /// No description provided for @fullBodyVisible.
  ///
  /// In es, this message translates to:
  /// **'Todo tu cuerpo debe ser visible'**
  String get fullBodyVisible;

  /// No description provided for @comfortableClothing.
  ///
  /// In es, this message translates to:
  /// **'Usa ropa cómoda para hacer ejercicio'**
  String get comfortableClothing;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'ENTENDIDO'**
  String get understood;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'ACEPTAR'**
  String get accept;

  /// No description provided for @preparingFitnessTest.
  ///
  /// In es, this message translates to:
  /// **'Preparando Fitness Test...'**
  String get preparingFitnessTest;

  /// No description provided for @restAndStretch.
  ///
  /// In es, this message translates to:
  /// **'DESCANSA Y ESTIRA'**
  String get restAndStretch;

  /// No description provided for @restStretchArms.
  ///
  /// In es, this message translates to:
  /// **'Descansa, estira tus brazos'**
  String get restStretchArms;

  /// No description provided for @restStretchLegs.
  ///
  /// In es, this message translates to:
  /// **'Descansa, estira tus piernas'**
  String get restStretchLegs;

  /// No description provided for @preparingNextExercise.
  ///
  /// In es, this message translates to:
  /// **'Preparándote para el siguiente ejercicio...'**
  String get preparingNextExercise;

  /// No description provided for @preparingLastExercise.
  ///
  /// In es, this message translates to:
  /// **'Preparándote para el último ejercicio...'**
  String get preparingLastExercise;

  /// No description provided for @nextExercise.
  ///
  /// In es, this message translates to:
  /// **'Siguiente: '**
  String get nextExercise;

  /// No description provided for @repetitions.
  ///
  /// In es, this message translates to:
  /// **'REPETICIONES'**
  String get repetitions;

  /// No description provided for @state.
  ///
  /// In es, this message translates to:
  /// **'ESTADO'**
  String get state;

  /// No description provided for @lastExerciseMotivation.
  ///
  /// In es, this message translates to:
  /// **'¡ÚLTIMO EJERCICIO - TÚ PUEDES!'**
  String get lastExerciseMotivation;

  /// No description provided for @results.
  ///
  /// In es, this message translates to:
  /// **'RESULTADOS'**
  String get results;

  /// No description provided for @level.
  ///
  /// In es, this message translates to:
  /// **'NIVEL'**
  String get level;

  /// No description provided for @flexiones.
  ///
  /// In es, this message translates to:
  /// **'FLEXIONES'**
  String get flexiones;

  /// No description provided for @sentadillas.
  ///
  /// In es, this message translates to:
  /// **'SENTADILLAS'**
  String get sentadillas;

  /// No description provided for @abdominales.
  ///
  /// In es, this message translates to:
  /// **'ABDOMINALES'**
  String get abdominales;

  /// No description provided for @qualityLabel.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get qualityLabel;

  /// No description provided for @statusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get statusLabel;

  /// No description provided for @totalLabel.
  ///
  /// In es, this message translates to:
  /// **'TOTAL'**
  String get totalLabel;

  /// No description provided for @levelLabel.
  ///
  /// In es, this message translates to:
  /// **'NIVEL'**
  String get levelLabel;

  /// No description provided for @dateLabel.
  ///
  /// In es, this message translates to:
  /// **'FECHA'**
  String get dateLabel;

  /// No description provided for @suggestionsToImprove.
  ///
  /// In es, this message translates to:
  /// **'SUGERENCIAS PARA MEJORAR'**
  String get suggestionsToImprove;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR'**
  String get save;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'COMPARTIR'**
  String get share;

  /// No description provided for @resultSaved.
  ///
  /// In es, this message translates to:
  /// **'Resultado guardado'**
  String get resultSaved;

  /// No description provided for @shareComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Función de compartir próximamente'**
  String get shareComingSoon;

  /// No description provided for @testCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Test completado!'**
  String get testCompleted;

  /// No description provided for @excellentStatus.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get excellentStatus;

  /// No description provided for @veryGoodStatus.
  ///
  /// In es, this message translates to:
  /// **'Muy Bien'**
  String get veryGoodStatus;

  /// No description provided for @goodStatus.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get goodStatus;

  /// No description provided for @squats.
  ///
  /// In es, this message translates to:
  /// **'Sentadillas'**
  String get squats;

  /// No description provided for @abdominals.
  ///
  /// In es, this message translates to:
  /// **'Abdominales'**
  String get abdominals;

  /// No description provided for @personalizedTraining.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento Personalizado'**
  String get personalizedTraining;

  /// No description provided for @personalizedTrainingDesc.
  ///
  /// In es, this message translates to:
  /// **'Encuentra ejercicios para músculos específicos'**
  String get personalizedTrainingDesc;

  /// No description provided for @calibrateBar.
  ///
  /// In es, this message translates to:
  /// **'CALIBRAR BARRA'**
  String get calibrateBar;

  /// No description provided for @alignLine.
  ///
  /// In es, this message translates to:
  /// **'Alinea la línea cyan con tu barra'**
  String get alignLine;

  /// No description provided for @adjustBar.
  ///
  /// In es, this message translates to:
  /// **'AJUSTAR BARRA'**
  String get adjustBar;

  /// No description provided for @confirmPosition.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR POSICIÓN'**
  String get confirmPosition;

  /// No description provided for @adjustUp.
  ///
  /// In es, this message translates to:
  /// **'SUBIR'**
  String get adjustUp;

  /// No description provided for @adjustDown.
  ///
  /// In es, this message translates to:
  /// **'BAJAR'**
  String get adjustDown;

  /// No description provided for @recalibrateBar.
  ///
  /// In es, this message translates to:
  /// **'Recalibrar barra'**
  String get recalibrateBar;

  /// No description provided for @hangFromBar.
  ///
  /// In es, this message translates to:
  /// **'Cuélgate de la barra'**
  String get hangFromBar;

  /// No description provided for @startTraining.
  ///
  /// In es, this message translates to:
  /// **'COMENZAR ENTRENAMIENTO'**
  String get startTraining;

  /// No description provided for @continueToCalibration.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR A CALIBRACIÓN'**
  String get continueToCalibration;

  /// No description provided for @phaseUp.
  ///
  /// In es, this message translates to:
  /// **'ARRIBA'**
  String get phaseUp;

  /// No description provided for @phaseDown.
  ///
  /// In es, this message translates to:
  /// **'ABAJO'**
  String get phaseDown;

  /// No description provided for @phaseRising.
  ///
  /// In es, this message translates to:
  /// **'SUBIENDO'**
  String get phaseRising;

  /// No description provided for @phaseLowering.
  ///
  /// In es, this message translates to:
  /// **'BAJANDO'**
  String get phaseLowering;

  /// No description provided for @phaseTransition.
  ///
  /// In es, this message translates to:
  /// **'TRANSICIÓN'**
  String get phaseTransition;

  /// No description provided for @tempo.
  ///
  /// In es, this message translates to:
  /// **'RITMO'**
  String get tempo;

  /// No description provided for @form.
  ///
  /// In es, this message translates to:
  /// **'FORMA'**
  String get form;
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
      'that was used.');
}
