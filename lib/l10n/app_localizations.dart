import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('zh'),
    Locale('zh', 'CN')
  ];

  /// No description provided for @tabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get tabSongs;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get tabAi;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizer;

  /// No description provided for @carMode.
  ///
  /// In en, this message translates to:
  /// **'Car mode'**
  String get carMode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @aiDj.
  ///
  /// In en, this message translates to:
  /// **'AI DJ'**
  String get aiDj;

  /// No description provided for @trendsNow.
  ///
  /// In en, this message translates to:
  /// **'See trends now'**
  String get trendsNow;

  /// No description provided for @batterySaver.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get batterySaver;

  /// No description provided for @screenAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get screenAlwaysOn;

  /// No description provided for @playbackDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Playback diagnostics'**
  String get playbackDiagnostics;

  /// No description provided for @autoDjMode.
  ///
  /// In en, this message translates to:
  /// **'Automatic AI DJ'**
  String get autoDjMode;

  /// No description provided for @seeMyRanking.
  ///
  /// In en, this message translates to:
  /// **'See my ranking'**
  String get seeMyRanking;

  /// No description provided for @countryForTrends.
  ///
  /// In en, this message translates to:
  /// **'Charts country'**
  String get countryForTrends;

  /// No description provided for @thermalProtection.
  ///
  /// In en, this message translates to:
  /// **'Thermal protection'**
  String get thermalProtection;

  /// No description provided for @dailyAlertTime.
  ///
  /// In en, this message translates to:
  /// **'Daily alert time'**
  String get dailyAlertTime;

  /// No description provided for @soundWaves.
  ///
  /// In en, this message translates to:
  /// **'Animated sound waves'**
  String get soundWaves;

  /// No description provided for @notifyTrends.
  ///
  /// In en, this message translates to:
  /// **'Notify me of trends'**
  String get notifyTrends;

  /// No description provided for @voiceDictation.
  ///
  /// In en, this message translates to:
  /// **'Voice dictation'**
  String get voiceDictation;

  /// No description provided for @glassEffect.
  ///
  /// In en, this message translates to:
  /// **'Glass effect (Liquid Glass)'**
  String get glassEffect;

  /// No description provided for @scanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan now'**
  String get scanNow;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @tagWithAi.
  ///
  /// In en, this message translates to:
  /// **'Tag with AI (key required)'**
  String get tagWithAi;

  /// No description provided for @deleteLocalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Delete local library'**
  String get deleteLocalLibrary;

  /// No description provided for @fillGenres.
  ///
  /// In en, this message translates to:
  /// **'Fill missing genres'**
  String get fillGenres;

  /// No description provided for @speakResponses.
  ///
  /// In en, this message translates to:
  /// **'Spoken replies'**
  String get speakResponses;

  /// No description provided for @freeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get freeUpSpace;

  /// No description provided for @importSongs.
  ///
  /// In en, this message translates to:
  /// **'Import songs'**
  String get importSongs;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @noSongsWithoutGenre.
  ///
  /// In en, this message translates to:
  /// **'No songs without genre'**
  String get noSongsWithoutGenre;

  /// No description provided for @restoreTheBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore the backup'**
  String get restoreTheBackup;

  /// No description provided for @exportFailedStorage.
  ///
  /// In en, this message translates to:
  /// **'Export failed: check storage'**
  String get exportFailedStorage;

  /// No description provided for @noCompatibleAudio.
  ///
  /// In en, this message translates to:
  /// **'No compatible audio found'**
  String get noCompatibleAudio;

  /// No description provided for @noBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'No backup saved'**
  String get noBackupSaved;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create new playlist'**
  String get createNewPlaylist;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get editPlaylist;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @playQueue.
  ///
  /// In en, this message translates to:
  /// **'Play queue'**
  String get playQueue;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playing;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing'**
  String get noSongPlaying;

  /// No description provided for @albumLabel.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumLabel;

  /// No description provided for @artistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistLabel;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'The AI history will be deleted.'**
  String get clearHistoryBody;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for music, playlists or ideas…'**
  String get askHint;

  /// No description provided for @promptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied'**
  String get promptCopied;

  /// No description provided for @aiProviders.
  ///
  /// In en, this message translates to:
  /// **'AI providers'**
  String get aiProviders;

  /// No description provided for @aiMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'AI music'**
  String get aiMusicTitle;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get clearConversation;

  /// No description provided for @copyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy prompt'**
  String get copyPrompt;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @createList.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createList;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @shuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleAll;

  /// No description provided for @mostPlayedRanking.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get mostPlayedRanking;

  /// No description provided for @advancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get advancedFilters;

  /// No description provided for @playSelection.
  ///
  /// In en, this message translates to:
  /// **'Play selection'**
  String get playSelection;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @playSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Play something first'**
  String get playSomethingFirst;

  /// No description provided for @songLyrics.
  ///
  /// In en, this message translates to:
  /// **'Song lyrics'**
  String get songLyrics;

  /// No description provided for @editData.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editData;

  /// No description provided for @notifyTop.
  ///
  /// In en, this message translates to:
  /// **'Notify top'**
  String get notifyTop;

  /// No description provided for @addSongs.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get addSongs;

  /// No description provided for @listCopied.
  ///
  /// In en, this message translates to:
  /// **'List copied to clipboard'**
  String get listCopied;

  /// No description provided for @updateTrendsFirst.
  ///
  /// In en, this message translates to:
  /// **'Refresh trends first'**
  String get updateTrendsFirst;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deleteList;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get linkOpenFailed;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get updateAction;

  /// No description provided for @listNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get listNotFound;

  /// No description provided for @editNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit name/description'**
  String get editNameDesc;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get changeCover;

  /// No description provided for @copyList.
  ///
  /// In en, this message translates to:
  /// **'Copy list'**
  String get copyList;

  /// No description provided for @importListJson.
  ///
  /// In en, this message translates to:
  /// **'Import playlist (JSON)'**
  String get importListJson;

  /// No description provided for @trendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trendsTitle;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @subKeepScreen.
  ///
  /// In en, this message translates to:
  /// **'Great for concerts or long videos (reduces AMOLED burn-in).'**
  String get subKeepScreen;

  /// No description provided for @subBatterySaver.
  ///
  /// In en, this message translates to:
  /// **'Reduces animations and progress-bar refresh. Ideal for long sessions.'**
  String get subBatterySaver;

  /// No description provided for @secAi.
  ///
  /// In en, this message translates to:
  /// **'AI models'**
  String get secAi;

  /// No description provided for @secPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get secPlayback;

  /// No description provided for @secPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance and temperature'**
  String get secPerformance;

  /// No description provided for @subSoundWaves.
  ///
  /// In en, this message translates to:
  /// **'Turn them off to save battery during continuous playback.'**
  String get subSoundWaves;

  /// No description provided for @secVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get secVoice;

  /// No description provided for @subTrendsNotify.
  ///
  /// In en, this message translates to:
  /// **'One notification a day with what is trending online.'**
  String get subTrendsNotify;

  /// No description provided for @secAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get secAppearance;

  /// No description provided for @subRanking.
  ///
  /// In en, this message translates to:
  /// **'Your most played songs, artists and genres.'**
  String get subRanking;

  /// No description provided for @subThermal.
  ///
  /// In en, this message translates to:
  /// **'Avoids heavy background work when the device is hot (summer) or extremely cold (winter).'**
  String get subThermal;

  /// No description provided for @subVoice.
  ///
  /// In en, this message translates to:
  /// **'Talk to the AI and search for songs without typing.'**
  String get subVoice;

  /// No description provided for @subLockControls.
  ///
  /// In en, this message translates to:
  /// **'If music stops when you lock the phone or the controls do not appear, grant BotMp3 notification permission and, on HyperOS/MIUI, enable Autostart and set the battery to No restrictions.'**
  String get subLockControls;

  /// No description provided for @secLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library and backup'**
  String get secLibrary;

  /// No description provided for @subDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Check why the lock-screen controls do not respond.'**
  String get subDiagnostics;

  /// No description provided for @menuPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get menuPlayNext;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @djNextUp.
  ///
  /// In en, this message translates to:
  /// **'up next'**
  String get djNextUp;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Set up the API key for'**
  String get apiKeyHint;

  /// No description provided for @menuEditCover.
  ///
  /// In en, this message translates to:
  /// **'Edit cover'**
  String get menuEditCover;

  /// No description provided for @genreLabel.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genreLabel;

  /// No description provided for @menuRemoveFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get menuRemoveFromLibrary;

  /// No description provided for @diagErrorsHere.
  ///
  /// In en, this message translates to:
  /// **'Playback problems will appear here.'**
  String get diagErrorsHere;

  /// No description provided for @menuPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get menuPlayNow;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Type what you are looking for: \"something to work out\", \"2000s rock\"…'**
  String get searchHint;

  /// No description provided for @diagNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No playback errors'**
  String get diagNoErrors;

  /// No description provided for @lockControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock screen controls'**
  String get lockControlsTitle;

  /// No description provided for @autoTheme.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get autoTheme;

  /// No description provided for @aiSpeaks.
  ///
  /// In en, this message translates to:
  /// **'The AI reads its recommendations out loud.'**
  String get aiSpeaks;

  /// No description provided for @glassIntensity.
  ///
  /// In en, this message translates to:
  /// **'Glass intensity'**
  String get glassIntensity;

  /// No description provided for @autoImport.
  ///
  /// In en, this message translates to:
  /// **'Import songs automatically'**
  String get autoImport;

  /// No description provided for @importAppAudio.
  ///
  /// In en, this message translates to:
  /// **'Import app audio and voice notes'**
  String get importAppAudio;

  /// No description provided for @noBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup yet: press Copy first'**
  String get noBackupYet;

  /// No description provided for @djBatch.
  ///
  /// In en, this message translates to:
  /// **'Songs per DJ mode batch'**
  String get djBatch;

  /// No description provided for @eqDesc.
  ///
  /// In en, this message translates to:
  /// **'Opens the 5-band equalizer (native screen)'**
  String get eqDesc;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @importFolder.
  ///
  /// In en, this message translates to:
  /// **'Import a whole folder'**
  String get importFolder;

  /// No description provided for @importFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Adds every supported audio file in the chosen folder'**
  String get importFolderDesc;

  /// No description provided for @noAudioDeleted.
  ///
  /// In en, this message translates to:
  /// **'Does not delete the audio files on your device'**
  String get noAudioDeleted;

  /// No description provided for @menuEditMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata and tags'**
  String get menuEditMetadata;

  /// No description provided for @menuRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get menuRemoveFavorite;

  /// No description provided for @menuMarkFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as favorite'**
  String get menuMarkFavorite;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Restart the app if something looks off ✅'**
  String get backupRestored;

  /// No description provided for @volumeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Volume of the current song'**
  String get volumeCurrent;

  /// No description provided for @dictationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice dictation is not available on this device'**
  String get dictationUnavailable;

  /// No description provided for @songNotFound.
  ///
  /// In en, this message translates to:
  /// **'Song not found'**
  String get songNotFound;

  /// No description provided for @albumCover.
  ///
  /// In en, this message translates to:
  /// **'Album cover'**
  String get albumCover;

  /// No description provided for @writeTags.
  ///
  /// In en, this message translates to:
  /// **'Write tags into the file'**
  String get writeTags;

  /// No description provided for @askingAi.
  ///
  /// In en, this message translates to:
  /// **'Asking the AI for the details…'**
  String get askingAi;

  /// No description provided for @autofillFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not autofill. Check the API key in Settings ▸ AI.'**
  String get autofillFailed;

  /// No description provided for @noCoverOnDevice.
  ///
  /// In en, this message translates to:
  /// **'That album has no cover on this device'**
  String get noCoverOnDevice;

  /// No description provided for @albumCoverApplied.
  ///
  /// In en, this message translates to:
  /// **'Album cover applied 🖼️'**
  String get albumCoverApplied;

  /// No description provided for @listCreated.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" created'**
  String listCreated(String name);

  /// No description provided for @mixtapeToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mixtape: {count} songs 🎧'**
  String mixtapeToday(int count);

  /// No description provided for @coverFound.
  ///
  /// In en, this message translates to:
  /// **'Cover found on {source}: review it and press Apply'**
  String coverFound(String source);

  /// No description provided for @imageProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not process the image: {error}'**
  String imageProcessFailed(String error);

  /// No description provided for @coverEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cover editor'**
  String get coverEditorTitle;

  /// No description provided for @applyCoverToSong.
  ///
  /// In en, this message translates to:
  /// **'Apply cover to the song'**
  String get applyCoverToSong;

  /// No description provided for @exportToGallery.
  ///
  /// In en, this message translates to:
  /// **'Export (gallery / storage)'**
  String get exportToGallery;

  /// No description provided for @imageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the image: {error}'**
  String imageOpenFailed(String error);

  /// No description provided for @coverApplied.
  ///
  /// In en, this message translates to:
  /// **'Cover applied to the song ✅'**
  String get coverApplied;

  /// No description provided for @songsAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'{count} songs added to your library 🎵'**
  String songsAddedToLibrary(int count);

  /// No description provided for @resetRanking.
  ///
  /// In en, this message translates to:
  /// **'Reset ranking'**
  String get resetRanking;

  /// No description provided for @songsImportedFromFolder.
  ///
  /// In en, this message translates to:
  /// **'{count} songs imported from the folder'**
  String songsImportedFromFolder(int count);

  /// No description provided for @modelOf.
  ///
  /// In en, this message translates to:
  /// **'Model: {name}'**
  String modelOf(String name);

  /// No description provided for @chartsIn.
  ///
  /// In en, this message translates to:
  /// **'Charts in {country}'**
  String chartsIn(String country);

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Create one.'**
  String get noPlaylistsYet;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @songsAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'{count} song(s) added to \"{name}\"'**
  String songsAddedToPlaylist(int count, String name);

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerActive.
  ///
  /// In en, this message translates to:
  /// **'On: playback pauses when it ends'**
  String get sleepTimerActive;

  /// No description provided for @sleepTimerCancel.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get sleepTimerCancel;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String sleepTimerMinutes(int count);

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening stats'**
  String get statsTitle;

  /// No description provided for @statsTotalPlays.
  ///
  /// In en, this message translates to:
  /// **'Total plays'**
  String get statsTotalPlays;

  /// No description provided for @playAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play album'**
  String get playAlbum;

  /// No description provided for @playFolder.
  ///
  /// In en, this message translates to:
  /// **'Play folder'**
  String get playFolder;

  /// No description provided for @songUpNext.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is up next'**
  String songUpNext(String title);

  /// No description provided for @deleteSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete song'**
  String get deleteSongTitle;

  /// No description provided for @deleteSongBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from the library. The file stays on your device.'**
  String deleteSongBody(String title);

  /// No description provided for @subImportAppAudio.
  ///
  /// In en, this message translates to:
  /// **'Include WhatsApp, Telegram… audio and voice recordings. Off (recommended) imports music only.'**
  String get subImportAppAudio;

  /// No description provided for @subRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Returns to the last backup (library, playlists, history and chat). Anything done since is lost.'**
  String get subRestoreBackup;

  /// No description provided for @subExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Saves the last backup to a JSON file you choose, to move it to another phone or keep it apart.'**
  String get subExportBackup;

  /// No description provided for @subVolume.
  ///
  /// In en, this message translates to:
  /// **'Balances quieter or louder tracks (±6 dB). Saved per song and applied every time it plays.'**
  String get subVolume;

  /// No description provided for @subFillGenres.
  ///
  /// In en, this message translates to:
  /// **'Fills the genre of songs that have none, using the title and album. No connection, no AI key.'**
  String get subFillGenres;

  /// No description provided for @subBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic every 7 days inside the app (library, playlists, history and chat). Stored on your phone, never in the cloud.'**
  String get subBackup;

  /// No description provided for @exportLibraryJson.
  ///
  /// In en, this message translates to:
  /// **'Export library (JSON)'**
  String get exportLibraryJson;

  /// No description provided for @restoreLibraryJson.
  ///
  /// In en, this message translates to:
  /// **'Restore library (JSON)'**
  String get restoreLibraryJson;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About BotMp3'**
  String get aboutTitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @clearAllWarning.
  ///
  /// In en, this message translates to:
  /// **'All songs and playlists saved in the app will be deleted.'**
  String get clearAllWarning;

  /// No description provided for @replaceKey.
  ///
  /// In en, this message translates to:
  /// **'Replace key…'**
  String get replaceKey;

  /// No description provided for @otherOption.
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get otherOption;

  /// No description provided for @djBatchNow.
  ///
  /// In en, this message translates to:
  /// **'Now asks for {count} each time'**
  String djBatchNow(int count);

  /// No description provided for @keySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {value}'**
  String keySaved(String value);

  /// No description provided for @keyStoredFor.
  ///
  /// In en, this message translates to:
  /// **'{provider} key saved encrypted'**
  String keyStoredFor(String provider);

  /// No description provided for @subAutoImport.
  ///
  /// In en, this message translates to:
  /// **'Scans device music when the app opens and adds anything new.'**
  String get subAutoImport;

  /// No description provided for @editMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata'**
  String get editMetadataTitle;

  /// No description provided for @autofillAi.
  ///
  /// In en, this message translates to:
  /// **'Autofill with AI'**
  String get autofillAi;

  /// No description provided for @titleStar.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleStar;

  /// No description provided for @artistStar.
  ///
  /// In en, this message translates to:
  /// **'Artist *'**
  String get artistStar;

  /// No description provided for @durationStar.
  ///
  /// In en, this message translates to:
  /// **'Duration *'**
  String get durationStar;

  /// No description provided for @detectDuration.
  ///
  /// In en, this message translates to:
  /// **'Detect duration'**
  String get detectDuration;

  /// No description provided for @genreStar.
  ///
  /// In en, this message translates to:
  /// **'Genre *'**
  String get genreStar;

  /// No description provided for @tagsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Tags (advanced search)'**
  String get tagsAdvanced;

  /// No description provided for @addTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag and press +'**
  String get addTagHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @dataFilled.
  ///
  /// In en, this message translates to:
  /// **'Details filled ✨ Review and save'**
  String get dataFilled;

  /// No description provided for @metadataSaved.
  ///
  /// In en, this message translates to:
  /// **'Metadata saved'**
  String get metadataSaved;

  /// No description provided for @playlistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistsEmpty;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty playlist'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add songs with the + button or from the library.'**
  String get playlistEmptyDesc;

  /// No description provided for @resetStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset stats'**
  String get resetStatsTitle;

  /// No description provided for @playTop10.
  ///
  /// In en, this message translates to:
  /// **'Play the top 10'**
  String get playTop10;

  /// No description provided for @searchFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'Title, artist, album, genre, year or #tag'**
  String get searchFieldsHint;

  /// No description provided for @backToNormalSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to normal search'**
  String get backToNormalSearch;

  /// No description provided for @lyricsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found for this song.'**
  String get lyricsNotFound;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery/storage'**
  String get saveToGallery;

  /// No description provided for @coverTextOptional.
  ///
  /// In en, this message translates to:
  /// **'Text on the cover (optional)'**
  String get coverTextOptional;

  /// No description provided for @aiExplains.
  ///
  /// In en, this message translates to:
  /// **'The AI picks and explains the next song while you play.'**
  String get aiExplains;

  /// No description provided for @glassDesc.
  ///
  /// In en, this message translates to:
  /// **'Translucent bars and panels with real background blur.'**
  String get glassDesc;

  /// No description provided for @modelId.
  ///
  /// In en, this message translates to:
  /// **'Model identifier'**
  String get modelId;

  /// No description provided for @songDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from the library (the audio file is not deleted).'**
  String get songDeleteBody;

  /// No description provided for @dialogListName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get dialogListName;

  /// No description provided for @dialogMoodHint.
  ///
  /// In en, this message translates to:
  /// **'What moment is this playlist for…'**
  String get dialogMoodHint;

  /// No description provided for @dialogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search song, artist, album or genre'**
  String get dialogSearchHint;

  /// No description provided for @dialogGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get dialogGenre;

  /// No description provided for @aiDjTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI DJ'**
  String get aiDjTitle;

  /// No description provided for @promptForGenerator.
  ///
  /// In en, this message translates to:
  /// **'Prompt for the generator:'**
  String get promptForGenerator;

  /// No description provided for @actionsRun.
  ///
  /// In en, this message translates to:
  /// **'Actions run'**
  String get actionsRun;

  /// No description provided for @coverSongLine.
  ///
  /// In en, this message translates to:
  /// **'Song: {title} — {artist}'**
  String coverSongLine(String title, String artist);

  /// No description provided for @deleteListBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? The songs stay in your library.'**
  String deleteListBody(String name);

  /// No description provided for @playlistsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Create unlimited playlists with a name and description, or ask the AI for one'**
  String get playlistsEmptyDesc;

  /// No description provided for @resetStatsBody.
  ///
  /// In en, this message translates to:
  /// **'Play counts for all songs will be reset to zero'**
  String get resetStatsBody;

  /// No description provided for @lyricsHowTo.
  ///
  /// In en, this message translates to:
  /// **'Save a .lrc (or .txt) file with the same name as the'**
  String get lyricsHowTo;

  /// No description provided for @carModeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe the bottom bar or use these buttons: they are'**
  String get carModeHint;

  /// No description provided for @noImagePick.
  ///
  /// In en, this message translates to:
  /// **'No image. Pick a photo (PNG/JPG) to start editing the cover.'**
  String get noImagePick;

  /// No description provided for @diagCopyThis.
  ///
  /// In en, this message translates to:
  /// **'If the lock screen buttons do not respond, copy this'**
  String get diagCopyThis;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Your library, playlists, history and chat will be replaced by the'**
  String get restoreWarning;

  /// No description provided for @tagAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses the AI model to tag songs that do not have a genre yet.'**
  String get tagAiDesc;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Local player with multi-model AI (OpenAI, DeepSeek, Gemini, Claude), glass effect, own ranking and trends.'**
  String get aboutBody;

  /// No description provided for @songEditNote.
  ///
  /// In en, this message translates to:
  /// **'BotMp3 stores metadata in its own local database and also'**
  String get songEditNote;

  /// No description provided for @aiAskExamples.
  ///
  /// In en, this message translates to:
  /// **'Ask it things like:'**
  String get aiAskExamples;

  /// No description provided for @aiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Add at least one API key in Settings ▸ AI.'**
  String get aiKeyMissing;

  /// No description provided for @aboutOffline.
  ///
  /// In en, this message translates to:
  /// **'Full offline mode: your music never leaves the device.'**
  String get aboutOffline;

  /// No description provided for @aboutWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new:'**
  String get aboutWhatsNew;

  /// No description provided for @playlistWillBe.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" will be created'**
  String playlistWillBe(String name);

  /// No description provided for @deleteListBodyShort.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteListBodyShort(String name);

  /// No description provided for @dialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get dialogDescription;

  /// No description provided for @songsFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'{count} songs from your library.'**
  String songsFromLibrary(int count);

  /// No description provided for @jsonCopied.
  ///
  /// In en, this message translates to:
  /// **'JSON copied to clipboard'**
  String get jsonCopied;

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Playlist exported to {path}'**
  String exportedTo(String path);

  /// No description provided for @statsUniqueSongs.
  ///
  /// In en, this message translates to:
  /// **'Unique songs'**
  String get statsUniqueSongs;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a visual style. Applies instantly.'**
  String get themeSubtitle;

  /// No description provided for @themeMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get themeMinimal;

  /// No description provided for @themeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon / Cyberpunk'**
  String get themeNeon;

  /// No description provided for @themeRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro / Vintage'**
  String get themeRetro;

  /// No description provided for @themeGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass (default)'**
  String get themeGlass;

  /// No description provided for @themeZen.
  ///
  /// In en, this message translates to:
  /// **'Natural / Zen'**
  String get themeZen;

  /// No description provided for @themeAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get themeAnime;

  /// No description provided for @themeGothic.
  ///
  /// In en, this message translates to:
  /// **'Gothic'**
  String get themeGothic;

  /// No description provided for @themeCinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get themeCinema;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @reduceMotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Turns off theme animations to save battery.'**
  String get reduceMotionDesc;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playAll;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortRecent;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get sortTitle;

  /// No description provided for @sortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// No description provided for @sortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// No description provided for @sortYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get sortYear;

  /// No description provided for @sortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// No description provided for @sortMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get sortMostPlayed;

  /// No description provided for @albumSongsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String albumSongsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'pt',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
