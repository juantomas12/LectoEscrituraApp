import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('fr'),
  ];

  /// No description provided for @activityAnswer_step.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get activityAnswer_step;

  /// No description provided for @activityCards.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas'**
  String get activityCards;

  /// No description provided for @activityCards_step.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas'**
  String get activityCards_step;

  /// No description provided for @activityDiscriminationInstruction.
  ///
  /// In es, this message translates to:
  /// **'Toca la imagen correcta'**
  String get activityDiscriminationInstruction;

  /// No description provided for @activityDiscriminationTitle.
  ///
  /// In es, this message translates to:
  /// **'Discriminación visual'**
  String get activityDiscriminationTitle;

  /// No description provided for @activityDrag_here.
  ///
  /// In es, this message translates to:
  /// **'Suelta aquí'**
  String get activityDrag_here;

  /// No description provided for @activityExact_changeInstruction.
  ///
  /// In es, this message translates to:
  /// **'Elige monedas hasta llegar al precio exacto'**
  String get activityExact_changeInstruction;

  /// No description provided for @activityExact_changeTitle.
  ///
  /// In es, this message translates to:
  /// **'La tienda de chuches'**
  String get activityExact_changeTitle;

  /// No description provided for @activityGenerated_gameInstruction.
  ///
  /// In es, this message translates to:
  /// **'Responde cada pregunta seleccionando la opción correcta'**
  String get activityGenerated_gameInstruction;

  /// No description provided for @activityGenerated_gameTitle.
  ///
  /// In es, this message translates to:
  /// **'Juego generado'**
  String get activityGenerated_gameTitle;

  /// No description provided for @activityInverse_discriminationInstruction.
  ///
  /// In es, this message translates to:
  /// **'Toca el elemento diferente'**
  String get activityInverse_discriminationInstruction;

  /// No description provided for @activityInverse_discriminationTitle.
  ///
  /// In es, this message translates to:
  /// **'Discriminación inversa'**
  String get activityInverse_discriminationTitle;

  /// No description provided for @activityLetter_vowelsContains.
  ///
  /// In es, this message translates to:
  /// **'Contiene'**
  String get activityLetter_vowelsContains;

  /// No description provided for @activityLetter_vowelsDrag_instruction.
  ///
  /// In es, this message translates to:
  /// **'Arrastra a la caja correcta'**
  String get activityLetter_vowelsDrag_instruction;

  /// No description provided for @activityLetter_vowelsHeadline.
  ///
  /// In es, this message translates to:
  /// **'Arrastra a la caja correcta'**
  String get activityLetter_vowelsHeadline;

  /// No description provided for @activityLetter_vowelsNot_contains.
  ///
  /// In es, this message translates to:
  /// **'No contiene'**
  String get activityLetter_vowelsNot_contains;

  /// No description provided for @activityLetter_vowelsQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué objetos tienen el sonido de la letra?'**
  String get activityLetter_vowelsQuestion;

  /// No description provided for @activityLetter_vowelsTitle.
  ///
  /// In es, this message translates to:
  /// **'Letras y vocales'**
  String get activityLetter_vowelsTitle;

  /// No description provided for @activityMatch_image_phraseInstruction.
  ///
  /// In es, this message translates to:
  /// **'Arrastra la frase hasta la imagen correcta'**
  String get activityMatch_image_phraseInstruction;

  /// No description provided for @activityMatch_image_phraseTitle.
  ///
  /// In es, this message translates to:
  /// **'Relacionar frases con imágenes'**
  String get activityMatch_image_phraseTitle;

  /// No description provided for @activityMatch_image_wordInstruction.
  ///
  /// In es, this message translates to:
  /// **'Arrastra la palabra hasta la imagen correcta'**
  String get activityMatch_image_wordInstruction;

  /// No description provided for @activityMatch_image_wordTitle.
  ///
  /// In es, this message translates to:
  /// **'Relacionar imágenes con palabras'**
  String get activityMatch_image_wordTitle;

  /// No description provided for @activityMatch_word_wordInstruction.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una palabra en columna A y luego su pareja'**
  String get activityMatch_word_wordInstruction;

  /// No description provided for @activityMatch_word_wordTitle.
  ///
  /// In es, this message translates to:
  /// **'Relacionar palabras con palabras'**
  String get activityMatch_word_wordTitle;

  /// No description provided for @activityNext_step.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get activityNext_step;

  /// No description provided for @activityNo_available_content.
  ///
  /// In es, this message translates to:
  /// **'No hay contenido disponible'**
  String get activityNo_available_content;

  /// No description provided for @activityNo_content_for_category.
  ///
  /// In es, this message translates to:
  /// **'No hay contenido para esta categoría'**
  String get activityNo_content_for_category;

  /// No description provided for @activityNo_words_for_level.
  ///
  /// In es, this message translates to:
  /// **'No hay palabras suficientes para este nivel'**
  String get activityNo_words_for_level;

  /// No description provided for @activityObjective.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get activityObjective;

  /// No description provided for @activityReinforcement_round.
  ///
  /// In es, this message translates to:
  /// **'Mini-ronda de refuerzo en marcha'**
  String get activityReinforcement_round;

  /// No description provided for @activityRemaining.
  ///
  /// In es, this message translates to:
  /// **'Quedan'**
  String get activityRemaining;

  /// No description provided for @activityRouletteInstruction_level.
  ///
  /// In es, this message translates to:
  /// **'Gira la ruleta y practica por nivel'**
  String get activityRouletteInstruction_level;

  /// No description provided for @activityRouletteInstruction_vowel.
  ///
  /// In es, this message translates to:
  /// **'Gira la ruleta y practica por vocal'**
  String get activityRouletteInstruction_vowel;

  /// No description provided for @activityRouletteTitle.
  ///
  /// In es, this message translates to:
  /// **'Ruleta de objetos y vocales'**
  String get activityRouletteTitle;

  /// No description provided for @activityWrite_wordCopy.
  ///
  /// In es, this message translates to:
  /// **'Copia'**
  String get activityWrite_wordCopy;

  /// No description provided for @activityWrite_wordDictation.
  ///
  /// In es, this message translates to:
  /// **'Dictado'**
  String get activityWrite_wordDictation;

  /// No description provided for @activityWrite_wordInstruction.
  ///
  /// In es, this message translates to:
  /// **'Observa la imagen y escribe la palabra'**
  String get activityWrite_wordInstruction;

  /// No description provided for @activityWrite_wordSemi_copy.
  ///
  /// In es, this message translates to:
  /// **'Semicopia'**
  String get activityWrite_wordSemi_copy;

  /// No description provided for @activityWrite_wordSyllables.
  ///
  /// In es, this message translates to:
  /// **'Sílabas'**
  String get activityWrite_wordSyllables;

  /// No description provided for @activityWrite_wordTitle.
  ///
  /// In es, this message translates to:
  /// **'Imagen con palabra para escribir'**
  String get activityWrite_wordTitle;

  /// No description provided for @activity_selectionAuto_start.
  ///
  /// In es, this message translates to:
  /// **'Inicio automático'**
  String get activity_selectionAuto_start;

  /// No description provided for @activity_selectionGame_levels.
  ///
  /// In es, this message translates to:
  /// **'Niveles del juego'**
  String get activity_selectionGame_levels;

  /// No description provided for @activity_selectionGame_modes.
  ///
  /// In es, this message translates to:
  /// **'Modos del juego'**
  String get activity_selectionGame_modes;

  /// No description provided for @activity_selectionSingle_level_autostart.
  ///
  /// In es, this message translates to:
  /// **'Juego de nivel único'**
  String get activity_selectionSingle_level_autostart;

  /// No description provided for @activity_selectionStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar juego'**
  String get activity_selectionStart;

  /// No description provided for @activity_selectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Selección de juego'**
  String get activity_selectionTitle;

  /// No description provided for @aiGenerate_button.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get aiGenerate_button;

  /// No description provided for @aiGenerate_instruction.
  ///
  /// In es, this message translates to:
  /// **'Escribe una instrucción para crear el juego'**
  String get aiGenerate_instruction;

  /// No description provided for @aiGenerate_title.
  ///
  /// In es, this message translates to:
  /// **'Generar actividad con IA'**
  String get aiGenerate_title;

  /// No description provided for @aiGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando...'**
  String get aiGenerating;

  /// No description provided for @aiPlay_generated.
  ///
  /// In es, this message translates to:
  /// **'Jugar recurso generado'**
  String get aiPlay_generated;

  /// No description provided for @aiSave_resource.
  ///
  /// In es, this message translates to:
  /// **'Guardar recurso'**
  String get aiSave_resource;

  /// No description provided for @aiSaved_resources.
  ///
  /// In es, this message translates to:
  /// **'Recursos guardados'**
  String get aiSaved_resources;

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'EduMundo'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Alfabetización'**
  String get appSubtitle;

  /// No description provided for @categoryAnimals.
  ///
  /// In es, this message translates to:
  /// **'Animales'**
  String get categoryAnimals;

  /// No description provided for @categoryBathroom.
  ///
  /// In es, this message translates to:
  /// **'Baño'**
  String get categoryBathroom;

  /// No description provided for @categoryColors.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get categoryColors;

  /// No description provided for @categoryEmotions.
  ///
  /// In es, this message translates to:
  /// **'Emociones'**
  String get categoryEmotions;

  /// No description provided for @categoryFood.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get categoryFood;

  /// No description provided for @categoryHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get categoryHealth;

  /// No description provided for @categoryHome_objects.
  ///
  /// In es, this message translates to:
  /// **'Cosas de casa'**
  String get categoryHome_objects;

  /// No description provided for @categoryMixed.
  ///
  /// In es, this message translates to:
  /// **'Mix de cosas'**
  String get categoryMixed;

  /// No description provided for @categoryMoney.
  ///
  /// In es, this message translates to:
  /// **'Dinero'**
  String get categoryMoney;

  /// No description provided for @categoryNature.
  ///
  /// In es, this message translates to:
  /// **'Naturaleza'**
  String get categoryNature;

  /// No description provided for @categoryProfessions.
  ///
  /// In es, this message translates to:
  /// **'Profesiones'**
  String get categoryProfessions;

  /// No description provided for @categorySchool.
  ///
  /// In es, this message translates to:
  /// **'Escuela'**
  String get categorySchool;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get commonCompleted;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonCorrect.
  ///
  /// In es, this message translates to:
  /// **'Correcto'**
  String get commonCorrect;

  /// No description provided for @commonCorrect_answers.
  ///
  /// In es, this message translates to:
  /// **'Aciertos'**
  String get commonCorrect_answers;

  /// No description provided for @commonFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get commonFinish;

  /// No description provided for @commonHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get commonHelp;

  /// No description provided for @commonHint.
  ///
  /// In es, this message translates to:
  /// **'Pista'**
  String get commonHint;

  /// No description provided for @commonIncorrect.
  ///
  /// In es, this message translates to:
  /// **'Incorrecto'**
  String get commonIncorrect;

  /// No description provided for @commonLesson.
  ///
  /// In es, this message translates to:
  /// **'Lección'**
  String get commonLesson;

  /// No description provided for @commonLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get commonLevel;

  /// No description provided for @commonListen_instruction.
  ///
  /// In es, this message translates to:
  /// **'Escuchar instrucción'**
  String get commonListen_instruction;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNo_content.
  ///
  /// In es, this message translates to:
  /// **'No hay contenido disponible'**
  String get commonNo_content;

  /// No description provided for @commonPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get commonPending;

  /// No description provided for @commonPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get commonPrevious;

  /// No description provided for @commonProgress.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get commonProgress;

  /// No description provided for @commonQuestion.
  ///
  /// In es, this message translates to:
  /// **'Pregunta'**
  String get commonQuestion;

  /// No description provided for @commonRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get commonRepeat;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get commonRetry;

  /// No description provided for @commonRound.
  ///
  /// In es, this message translates to:
  /// **'Ronda'**
  String get commonRound;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get commonSaved;

  /// No description provided for @commonStart_game.
  ///
  /// In es, this message translates to:
  /// **'Iniciar juego'**
  String get commonStart_game;

  /// No description provided for @commonTechnical_aids.
  ///
  /// In es, this message translates to:
  /// **'Ayuda técnica'**
  String get commonTechnical_aids;

  /// No description provided for @commonTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonWords.
  ///
  /// In es, this message translates to:
  /// **'Palabras'**
  String get commonWords;

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @homeAi_screen_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea actividades personalizadas con IA.'**
  String get homeAi_screen_subtitle;

  /// No description provided for @homeAi_screen_title.
  ///
  /// In es, this message translates to:
  /// **'Pantalla IA'**
  String get homeAi_screen_title;

  /// No description provided for @homeCurrent_category.
  ///
  /// In es, this message translates to:
  /// **'Categoría actual'**
  String get homeCurrent_category;

  /// No description provided for @homeLearn_playing.
  ///
  /// In es, this message translates to:
  /// **'¡Aprende Jugando!'**
  String get homeLearn_playing;

  /// No description provided for @homeProgress_message.
  ///
  /// In es, this message translates to:
  /// **'¡Estás a 2 juegos del nivel 5!'**
  String get homeProgress_message;

  /// No description provided for @homeProgress_title.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso'**
  String get homeProgress_title;

  /// No description provided for @homeSaved_ai.
  ///
  /// In es, this message translates to:
  /// **'Guardados IA'**
  String get homeSaved_ai;

  /// No description provided for @homeWhat_practice_today.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres practicar hoy?'**
  String get homeWhat_practice_today;

  /// No description provided for @navAi.
  ///
  /// In es, this message translates to:
  /// **'IA'**
  String get navAi;

  /// No description provided for @navCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get navCategories;

  /// No description provided for @navGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get navGames;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navLearn.
  ///
  /// In es, this message translates to:
  /// **'Aprender'**
  String get navLearn;

  /// No description provided for @navPlay.
  ///
  /// In es, this message translates to:
  /// **'Jugar'**
  String get navPlay;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @resultsBest_streak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get resultsBest_streak;

  /// No description provided for @resultsCorrect.
  ///
  /// In es, this message translates to:
  /// **'Aciertos'**
  String get resultsCorrect;

  /// No description provided for @resultsDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get resultsDuration;

  /// No description provided for @resultsIncorrect.
  ///
  /// In es, this message translates to:
  /// **'Errores'**
  String get resultsIncorrect;

  /// No description provided for @resultsReinforce_errors.
  ///
  /// In es, this message translates to:
  /// **'Reforzar errores'**
  String get resultsReinforce_errors;

  /// No description provided for @resultsRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get resultsRepeat;

  /// No description provided for @resultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Resultados'**
  String get resultsTitle;

  /// No description provided for @resultsView_dashboard.
  ///
  /// In es, this message translates to:
  /// **'Ver progreso'**
  String get resultsView_dashboard;

  /// No description provided for @sessionEnd_session.
  ///
  /// In es, this message translates to:
  /// **'Finalizar sesión'**
  String get sessionEnd_session;

  /// No description provided for @sessionStart_session.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get sessionStart_session;

  /// No description provided for @sessionWorkspace_title.
  ///
  /// In es, this message translates to:
  /// **'Espacio de sesión'**
  String get sessionWorkspace_title;

  /// No description provided for @settingsAccent_tolerance.
  ///
  /// In es, this message translates to:
  /// **'Tolerancia de acentos'**
  String get settingsAccent_tolerance;

  /// No description provided for @settingsAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsAuto_adjust_level.
  ///
  /// In es, this message translates to:
  /// **'Ajustar nivel automático'**
  String get settingsAuto_adjust_level;

  /// No description provided for @settingsDefault_difficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad por defecto'**
  String get settingsDefault_difficulty;

  /// No description provided for @settingsDyslexia_mode.
  ///
  /// In es, this message translates to:
  /// **'Modo dislexia'**
  String get settingsDyslexia_mode;

  /// No description provided for @settingsHigh_contrast.
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get settingsHigh_contrast;

  /// No description provided for @settingsImage_editor.
  ///
  /// In es, this message translates to:
  /// **'Editar imágenes'**
  String get settingsImage_editor;

  /// No description provided for @settingsOpenai_key.
  ///
  /// In es, this message translates to:
  /// **'Clave API OpenAI'**
  String get settingsOpenai_key;

  /// No description provided for @settingsOpenai_model.
  ///
  /// In es, this message translates to:
  /// **'Modelo OpenAI'**
  String get settingsOpenai_model;

  /// No description provided for @settingsShow_hints.
  ///
  /// In es, this message translates to:
  /// **'Mostrar pistas'**
  String get settingsShow_hints;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;
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
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
