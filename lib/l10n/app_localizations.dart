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

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback history'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No playback history yet'**
  String get historyEmpty;

  /// No description provided for @historyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClear;

  /// No description provided for @foldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersTitle;

  /// No description provided for @foldersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Browse your music by folders'**
  String get foldersEmpty;

  /// No description provided for @duplicatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get duplicatesTitle;

  /// No description provided for @duplicatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No duplicates found'**
  String get duplicatesEmpty;

  /// No description provided for @duplicatesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove copies'**
  String get duplicatesRemove;

  /// No description provided for @importM3u.
  ///
  /// In en, this message translates to:
  /// **'Import M3U playlist'**
  String get importM3u;

  /// No description provided for @exportM3u.
  ///
  /// In en, this message translates to:
  /// **'Export library (M3U)'**
  String get exportM3u;

  /// No description provided for @m3uNoSongs.
  ///
  /// In en, this message translates to:
  /// **'None of the songs were found in your library'**
  String get m3uNoSongs;

  /// No description provided for @artistAlbums.
  ///
  /// In en, this message translates to:
  /// **'{count} albums'**
  String artistAlbums(int count);

  /// No description provided for @duplicatesRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The other {count} copies will be removed from the library. The files are not deleted.'**
  String duplicatesRemoveBody(int count);

  /// No description provided for @m3uPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'M3U {day}/{month}'**
  String m3uPlaylistName(int day, int month);

  /// No description provided for @batchEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit selection'**
  String get batchEdit;

  /// No description provided for @batchEditHint.
  ///
  /// In en, this message translates to:
  /// **'Empty fields are left unchanged.'**
  String get batchEditHint;

  /// No description provided for @normalizeVolume.
  ///
  /// In en, this message translates to:
  /// **'Normalize volume'**
  String get normalizeVolume;

  /// No description provided for @normalizeVolumeDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses ReplayGain tags to even out volume between songs.'**
  String get normalizeVolumeDesc;

  /// No description provided for @resumeOnConnect.
  ///
  /// In en, this message translates to:
  /// **'Resume on connect'**
  String get resumeOnConnect;

  /// No description provided for @resumeOnConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Starts playing again when headphones or Bluetooth connect.'**
  String get resumeOnConnectDesc;

  /// No description provided for @pauseOnDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Pause on disconnect'**
  String get pauseOnDisconnect;

  /// No description provided for @pauseOnDisconnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Pauses when headphones or Bluetooth are removed.'**
  String get pauseOnDisconnectDesc;

  /// No description provided for @sqliteTitle.
  ///
  /// In en, this message translates to:
  /// **'Search index (SQLite)'**
  String get sqliteTitle;

  /// No description provided for @fadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fade between songs'**
  String get fadeTitle;

  /// No description provided for @fadeDesc.
  ///
  /// In en, this message translates to:
  /// **'Cross-fades the volume when the track changes.'**
  String get fadeDesc;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add here'**
  String get addBookmark;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks in this song'**
  String get noBookmarks;

  /// No description provided for @volumeDown.
  ///
  /// In en, this message translates to:
  /// **'Lower volume'**
  String get volumeDown;

  /// No description provided for @volumeUp.
  ///
  /// In en, this message translates to:
  /// **'Raise volume'**
  String get volumeUp;

  /// No description provided for @volumeReset.
  ///
  /// In en, this message translates to:
  /// **'Reset volume'**
  String get volumeReset;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get unknownTitle;

  /// No description provided for @untitledPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Untitled playlist'**
  String get untitledPlaylist;

  /// No description provided for @untitledIdea.
  ///
  /// In en, this message translates to:
  /// **'Untitled idea'**
  String get untitledIdea;

  /// No description provided for @relativeNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeNow;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get btnTest;

  /// No description provided for @aiKeyMissingFirst.
  ///
  /// In en, this message translates to:
  /// **'Set up an API key in AI settings first.'**
  String get aiKeyMissingFirst;

  /// No description provided for @aiConnectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK'**
  String get aiConnectionOk;

  /// No description provided for @aiErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get aiErrorConnection;

  /// No description provided for @aiNeedKey.
  ///
  /// In en, this message translates to:
  /// **'Set up an API key to talk to me.'**
  String get aiNeedKey;

  /// No description provided for @aiUnknownCommand.
  ///
  /// In en, this message translates to:
  /// **'I did not understand. Type help to see examples.'**
  String get aiUnknownCommand;

  /// No description provided for @aiCompletingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Completing the song details…'**
  String get aiCompletingMetadata;

  /// No description provided for @aiInterpretingSearch.
  ///
  /// In en, this message translates to:
  /// **'Interpreting your search…'**
  String get aiInterpretingSearch;

  /// No description provided for @aiDjChoosing.
  ///
  /// In en, this message translates to:
  /// **'The DJ is choosing…'**
  String get aiDjChoosing;

  /// No description provided for @scanFreeingSpace.
  ///
  /// In en, this message translates to:
  /// **'Freeing up space…'**
  String get scanFreeingSpace;

  /// No description provided for @scanNothingToFree.
  ///
  /// In en, this message translates to:
  /// **'Nothing to free up'**
  String get scanNothingToFree;

  /// No description provided for @scanFreeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not free up space'**
  String get scanFreeFailed;

  /// No description provided for @scanSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for music on this device…'**
  String get scanSearching;

  /// No description provided for @scanNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Audio permission missing: enable it in Settings'**
  String get scanNoPermission;

  /// No description provided for @scanNotFound.
  ///
  /// In en, this message translates to:
  /// **'No music found on this device'**
  String get scanNotFound;

  /// No description provided for @scanNoNewSongs.
  ///
  /// In en, this message translates to:
  /// **'No new songs added'**
  String get scanNoNewSongs;

  /// No description provided for @aiHintRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended: the fastest and cheapest (great for everything).'**
  String get aiHintRecommended;

  /// No description provided for @aiHintDsPro.
  ///
  /// In en, this message translates to:
  /// **'More capable at reasoning; costs about 4x more per use.'**
  String get aiHintDsPro;

  /// No description provided for @aiHintDsRetired.
  ///
  /// In en, this message translates to:
  /// **'Name retired by DeepSeek: use deepseek-flash or deepseek-v4-pro.'**
  String get aiHintDsRetired;

  /// No description provided for @aiHintBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced and fluent; good value for the price.'**
  String get aiHintBalanced;

  /// No description provided for @aiHintVeryFast.
  ///
  /// In en, this message translates to:
  /// **'Very fast and cheap; enough for metadata and playlists.'**
  String get aiHintVeryFast;

  /// No description provided for @aiHintO1.
  ///
  /// In en, this message translates to:
  /// **'Reasoning: slower and pricier; the app skips JSON mode with these.'**
  String get aiHintO1;

  /// No description provided for @aiHintGoogleFree.
  ///
  /// In en, this message translates to:
  /// **'Fast, with Google\'s generous free tier.'**
  String get aiHintGoogleFree;

  /// No description provided for @aiHintGeminiPro.
  ///
  /// In en, this message translates to:
  /// **'More capable; uses up the free quota faster.'**
  String get aiHintGeminiPro;

  /// No description provided for @aiHintClaudeFast.
  ///
  /// In en, this message translates to:
  /// **'The fastest and cheapest Claude model.'**
  String get aiHintClaudeFast;

  /// No description provided for @aiHintClaudeBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced; excellent writing quality.'**
  String get aiHintClaudeBalanced;

  /// No description provided for @aiHintClaudeOpus.
  ///
  /// In en, this message translates to:
  /// **'The most powerful Claude model and also the priciest.'**
  String get aiHintClaudeOpus;

  /// No description provided for @playLocals.
  ///
  /// In en, this message translates to:
  /// **'Play {count} local songs'**
  String playLocals(Object count);

  /// No description provided for @aiPlaylistDefault.
  ///
  /// In en, this message translates to:
  /// **'AI playlist'**
  String get aiPlaylistDefault;

  /// No description provided for @relativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} min'**
  String relativeMinutes(int count);

  /// No description provided for @relativeHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} h'**
  String relativeHours(int count);

  /// No description provided for @relativeDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} d'**
  String relativeDays(int count);

  /// No description provided for @aiCreatingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Creating a playlist with {count} songs…'**
  String aiCreatingPlaylist(int count);

  /// No description provided for @scanUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Library is up to date ({count} tracks on device)'**
  String scanUpToDate(int count);

  /// No description provided for @scanCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers updated ({count} songs)'**
  String scanCovers(int count);

  /// No description provided for @keyRemovedFor.
  ///
  /// In en, this message translates to:
  /// **'{provider} key removed'**
  String keyRemovedFor(String provider);

  /// No description provided for @aiNoKeyBadge.
  ///
  /// In en, this message translates to:
  /// **'{provider} (no key)'**
  String aiNoKeyBadge(String provider);

  /// No description provided for @setupApiKeys.
  ///
  /// In en, this message translates to:
  /// **'Set up API keys'**
  String get setupApiKeys;

  /// No description provided for @sessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session: {session}'**
  String sessionLabel(String session);

  /// No description provided for @sessionNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get sessionNone;

  /// No description provided for @sessionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Session disabled'**
  String get sessionDisabled;

  /// No description provided for @sessionNotice.
  ///
  /// In en, this message translates to:
  /// **'Session: {session} (DJ and playlists will respect it)'**
  String sessionNotice(String session);

  /// No description provided for @mixtapeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Daily mixtape'**
  String get mixtapeOfDay;

  /// No description provided for @recommendMe.
  ///
  /// In en, this message translates to:
  /// **'Recommend'**
  String get recommendMe;

  /// No description provided for @createSong.
  ///
  /// In en, this message translates to:
  /// **'Create song'**
  String get createSong;

  /// No description provided for @copyBtn.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyBtn;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created on device ✅'**
  String get backupSuccess;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Could not create backup'**
  String get backupError;

  /// No description provided for @cacheDetail.
  ///
  /// In en, this message translates to:
  /// **'{size} in cache (temporary, safe to clear)'**
  String cacheDetail(String size);

  /// No description provided for @cleanBtn.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get cleanBtn;

  /// No description provided for @freedSpaceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Freed {size} 🧹'**
  String freedSpaceSuccess(String size);

  /// No description provided for @importFormatsDesc.
  ///
  /// In en, this message translates to:
  /// **'MP3, M4A, OGG, FLAC, WAV… select files or paths'**
  String get importFormatsDesc;

  /// No description provided for @exportSummary.
  ///
  /// In en, this message translates to:
  /// **'{songs} songs · {playlists} playlists'**
  String exportSummary(int songs, int playlists);

  /// No description provided for @jsonCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'JSON copied to clipboard'**
  String get jsonCopiedClipboard;

  /// No description provided for @exportSuccessClipboard.
  ///
  /// In en, this message translates to:
  /// **'Library exported and copied to clipboard'**
  String get exportSuccessClipboard;

  /// No description provided for @songsRestored.
  ///
  /// In en, this message translates to:
  /// **'{count} songs restored'**
  String songsRestored(int count);

  /// No description provided for @apiKeysKeystoreNotice.
  ///
  /// In en, this message translates to:
  /// **'API keys are stored encrypted with Android Keystore.'**
  String get apiKeysKeystoreNotice;

  /// No description provided for @formatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Formats: {formats}'**
  String formatsLabel(String formats);

  /// No description provided for @licensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licensesTitle;

  /// No description provided for @gplNotice.
  ///
  /// In en, this message translates to:
  /// **'BotMp3 is Free Software under GPL-3.0. Source code available on GitHub.'**
  String get gplNotice;

  /// No description provided for @viewSourceCode.
  ///
  /// In en, this message translates to:
  /// **'View Source Code'**
  String get viewSourceCode;

  /// No description provided for @sessionFiesta.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get sessionFiesta;

  /// No description provided for @sessionRelax.
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get sessionRelax;

  /// No description provided for @sessionGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get sessionGym;

  /// No description provided for @sessionStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get sessionStudy;

  /// No description provided for @sessionSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sessionSleep;

  /// No description provided for @librarySummary.
  ///
  /// In en, this message translates to:
  /// **'{songs} songs · {genres} genres · {playlists} playlists'**
  String librarySummary(int songs, int genres, int playlists);

  /// No description provided for @structureLabel.
  ///
  /// In en, this message translates to:
  /// **'Structure: {value}'**
  String structureLabel(String value);

  /// No description provided for @aiCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by AI'**
  String get aiCreatedBy;

  /// No description provided for @aiCreatedByRequest.
  ///
  /// In en, this message translates to:
  /// **'Created by AI: {request}'**
  String aiCreatedByRequest(String request);

  /// No description provided for @actPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actPlay;

  /// No description provided for @actPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actPause;

  /// No description provided for @actNext.
  ///
  /// In en, this message translates to:
  /// **'Next song'**
  String get actNext;

  /// No description provided for @actPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous song'**
  String get actPrevious;

  /// No description provided for @actStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actStop;

  /// No description provided for @actVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume {value}'**
  String actVolume(String value);

  /// No description provided for @actVolumeUp.
  ///
  /// In en, this message translates to:
  /// **'Raise volume'**
  String get actVolumeUp;

  /// No description provided for @actVolumeDown.
  ///
  /// In en, this message translates to:
  /// **'Lower volume'**
  String get actVolumeDown;

  /// No description provided for @actSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed {value}x'**
  String actSpeed(String value);

  /// No description provided for @actShuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on'**
  String get actShuffleOn;

  /// No description provided for @actShuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle off'**
  String get actShuffleOff;

  /// No description provided for @actRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get actRepeatOff;

  /// No description provided for @actRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat whole queue'**
  String get actRepeatAll;

  /// No description provided for @actRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat this song'**
  String get actRepeatOne;

  /// No description provided for @actSeek.
  ///
  /// In en, this message translates to:
  /// **'Jump to {value}'**
  String actSeek(String value);

  /// No description provided for @actPlayQuery.
  ///
  /// In en, this message translates to:
  /// **'Play \"{query}\"'**
  String actPlayQuery(String query);

  /// No description provided for @actPlayPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Play playlist \"{list}\"'**
  String actPlayPlaylist(String list);

  /// No description provided for @actCreatePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create playlist \"{list}\"'**
  String actCreatePlaylist(String list);

  /// No description provided for @actAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to \"{list}\"'**
  String actAddToPlaylist(String list);

  /// No description provided for @actSearch.
  ///
  /// In en, this message translates to:
  /// **'Search \"{query}\"'**
  String actSearch(String query);

  /// No description provided for @actEditMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit {field} of \"{query}\"'**
  String actEditMetadata(String field, String query);

  /// No description provided for @actSetCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover of \"{query}\"'**
  String actSetCover(String query);

  /// No description provided for @actFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite: \"{query}\"'**
  String actFavorite(String query);

  /// No description provided for @actRescan.
  ///
  /// In en, this message translates to:
  /// **'Update library'**
  String get actRescan;

  /// No description provided for @actNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'What is playing?'**
  String get actNowPlaying;

  /// No description provided for @actStats.
  ///
  /// In en, this message translates to:
  /// **'Library stats'**
  String get actStats;

  /// No description provided for @actHelp.
  ///
  /// In en, this message translates to:
  /// **'Command help'**
  String get actHelp;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get fieldTitle;

  /// No description provided for @fieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'album'**
  String get fieldAlbum;

  /// No description provided for @fieldYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get fieldYear;

  /// No description provided for @fieldGenre.
  ///
  /// In en, this message translates to:
  /// **'genre'**
  String get fieldGenre;

  /// No description provided for @fieldData.
  ///
  /// In en, this message translates to:
  /// **'data'**
  String get fieldData;

  /// No description provided for @msgNext.
  ///
  /// In en, this message translates to:
  /// **'Next song ⏭️'**
  String get msgNext;

  /// No description provided for @msgPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous song ⏮️'**
  String get msgPrevious;

  /// No description provided for @msgStopped.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped'**
  String get msgStopped;

  /// No description provided for @msgSeeked.
  ///
  /// In en, this message translates to:
  /// **'Jumped to {time}'**
  String msgSeeked(String time);

  /// No description provided for @msgRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get msgRepeatOff;

  /// No description provided for @msgRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeating this song 🔂'**
  String get msgRepeatOne;

  /// No description provided for @msgNotFoundQuery.
  ///
  /// In en, this message translates to:
  /// **'I could not find \"{query}\" in your library. Try another title or update the library.'**
  String msgNotFoundQuery(String query);

  /// No description provided for @msgPlaylistEmpty.
  ///
  /// In en, this message translates to:
  /// **'The playlist \"{list}\" is empty.'**
  String msgPlaylistEmpty(String list);

  /// No description provided for @msgNoSongsToAdd.
  ///
  /// In en, this message translates to:
  /// **'I found no songs to add.'**
  String get msgNoSongsToAdd;

  /// No description provided for @msgAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'{count} song(s) added to \"{list}\" ✅'**
  String msgAddedToPlaylist(String count, String list);

  /// No description provided for @msgSearchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results for \"{query}\" — you have them in the Songs tab 🔍'**
  String msgSearchResults(String count, String query);

  /// No description provided for @msgSongNotFound.
  ///
  /// In en, this message translates to:
  /// **'I could not find the song \"{query}\".'**
  String msgSongNotFound(String query);

  /// No description provided for @msgSongNotFoundShort.
  ///
  /// In en, this message translates to:
  /// **'I could not find the song.'**
  String get msgSongNotFoundShort;

  /// No description provided for @msgCoverSongNotFound.
  ///
  /// In en, this message translates to:
  /// **'I could not find the song to change its cover.'**
  String get msgCoverSongNotFound;

  /// No description provided for @msgChooseCover.
  ///
  /// In en, this message translates to:
  /// **'Choose the new cover for \"{title}\" 🖼️'**
  String msgChooseCover(String title);

  /// No description provided for @msgLibraryUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Library up to date: no new songs ({total} total) 📚'**
  String msgLibraryUpToDate(String total);

  /// No description provided for @msgLibraryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {count} new songs added 📚'**
  String msgLibraryUpdated(String count);

  /// No description provided for @msgGenreDominant.
  ///
  /// In en, this message translates to:
  /// **'Dominant genre: {genre} 📊'**
  String msgGenreDominant(String genre);

  /// No description provided for @msgHelpText.
  ///
  /// In en, this message translates to:
  /// **'Examples:\n• \"play some 90s rock\"\n• \"add this song to the Party playlist\"\n• \"change this song\'s genre to Rock\"\n• \"update my library\", \"what is playing?\", \"how many songs do I have\"'**
  String get msgHelpText;

  /// No description provided for @msgPlayingNow.
  ///
  /// In en, this message translates to:
  /// **'Playing ▶️'**
  String get msgPlayingNow;

  /// No description provided for @msgPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Playing \"{title}\" — {artist}{extra} 🎵'**
  String msgPlayingTitle(String title, String artist, String extra);

  /// No description provided for @msgAndMore.
  ///
  /// In en, this message translates to:
  /// **' (and {more} more)'**
  String msgAndMore(String more);

  /// No description provided for @msgPlaylistNotFound.
  ///
  /// In en, this message translates to:
  /// **'There is no playlist called \"{list}\".'**
  String msgPlaylistNotFound(String list);

  /// No description provided for @msgNothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing right now.'**
  String get msgNothingPlaying;

  /// No description provided for @msgNowPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'Playing \"{title}\" by {artist} ({genre}) 🎧'**
  String msgNowPlayingTitle(String title, String artist, String genre);

  /// No description provided for @fieldArtist.
  ///
  /// In en, this message translates to:
  /// **'artist'**
  String get fieldArtist;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get fieldTags;

  /// No description provided for @msgLibraryStats.
  ///
  /// In en, this message translates to:
  /// **'You have {songs} songs, {playlists} playlists and {favorites} favorites. Dominant genre: {genre} 📊'**
  String msgLibraryStats(
      String songs, String playlists, String favorites, String genre);

  /// No description provided for @msgAddedFavorite.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to favorites ❤️'**
  String msgAddedFavorite(String title);

  /// No description provided for @msgRemovedFavorite.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is no longer a favorite'**
  String msgRemovedFavorite(String title);

  /// No description provided for @refreshModels.
  ///
  /// In en, this message translates to:
  /// **'Refresh models'**
  String get refreshModels;

  /// No description provided for @modelsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'{count} models updated'**
  String modelsRefreshed(String count);

  /// No description provided for @modelsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch models: check the API key or the connection.'**
  String get modelsRefreshFailed;

  /// No description provided for @freeBadge.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeBadge;

  /// No description provided for @getApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get API key'**
  String get getApiKey;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied: {url}'**
  String linkCopied(String url);

  /// No description provided for @modelIdExample.
  ///
  /// In en, this message translates to:
  /// **'E.g.: gemini-2.5-flash, gpt-4o-mini, deepseek-flash…'**
  String get modelIdExample;

  /// No description provided for @useModel.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useModel;

  /// No description provided for @modelsAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Free models first. They refresh automatically every 3 days.'**
  String get modelsAutoHint;

  /// No description provided for @aiHintGeminiNew.
  ///
  /// In en, this message translates to:
  /// **'Newest Gemini, free tier included. Recommended.'**
  String get aiHintGeminiNew;

  /// No description provided for @aiHintGeminiLite.
  ///
  /// In en, this message translates to:
  /// **'Lightweight Gemini: very fast and almost unlimited for free.'**
  String get aiHintGeminiLite;

  /// No description provided for @diagStatsLine.
  ///
  /// In en, this message translates to:
  /// **'Log: {log} · Today: {today}'**
  String diagStatsLine(String log, String today);

  /// No description provided for @diagNoCounts.
  ///
  /// In en, this message translates to:
  /// **'No playback counted yet in this session.'**
  String get diagNoCounts;

  /// No description provided for @rankEmptyPeriod.
  ///
  /// In en, this message translates to:
  /// **'No plays in this period yet.\nListen to music and the ranking builds itself.'**
  String get rankEmptyPeriod;

  /// No description provided for @rankEmptyData.
  ///
  /// In en, this message translates to:
  /// **'No {what} data in this period yet.'**
  String rankEmptyData(String what);

  /// No description provided for @trendsError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch trends. Check your connection.'**
  String get trendsError;

  /// No description provided for @trendsNotifSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent with the top of {country}'**
  String trendsNotifSent(String country);

  /// No description provided for @trendsNotifFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not show the notification (check the permission)'**
  String get trendsNotifFailed;

  /// No description provided for @trendsSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for the most played songs…'**
  String get trendsSearching;

  /// No description provided for @trendsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to see what is playing on the internet right now.'**
  String get trendsHint;

  /// No description provided for @changelogLatest.
  ///
  /// In en, this message translates to:
  /// **'Stats fixed: every play counts, even repeating the same song. Safer signing and saving.'**
  String get changelogLatest;

  /// No description provided for @trendsAlertAt.
  ///
  /// In en, this message translates to:
  /// **'I will notify you every day at {hour}:00'**
  String trendsAlertAt(String hour);

  /// No description provided for @voiceGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, I am BotMp3. Ready to play your music.'**
  String get voiceGreeting;

  /// No description provided for @importMediaYes.
  ///
  /// In en, this message translates to:
  /// **'App audios and voice notes will be included'**
  String get importMediaYes;

  /// No description provided for @importMediaNo.
  ///
  /// In en, this message translates to:
  /// **'Only music will be shown'**
  String get importMediaNo;

  /// No description provided for @scanNowDesc.
  ///
  /// In en, this message translates to:
  /// **'Look for new music on this device'**
  String get scanNowDesc;

  /// No description provided for @songsAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs added'**
  String songsAddedCount(String count);

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @aiNoGenresReturned.
  ///
  /// In en, this message translates to:
  /// **'The AI returned no genres (is a key configured?)'**
  String get aiNoGenresReturned;

  /// No description provided for @noGenresToFill.
  ///
  /// In en, this message translates to:
  /// **'There were no genres to fill'**
  String get noGenresToFill;

  /// No description provided for @diagYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get diagYes;

  /// No description provided for @diagNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get diagNo;

  /// No description provided for @diagNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get diagNone;

  /// No description provided for @diagGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get diagGranted;

  /// No description provided for @diagDenied.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get diagDenied;

  /// No description provided for @diagNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get diagNotifications;

  /// No description provided for @diagNotifHelp.
  ///
  /// In en, this message translates to:
  /// **'Without this permission Android cannot show the playback notification and the lock screen loses its controls.'**
  String get diagNotifHelp;

  /// No description provided for @diagBattery.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted battery'**
  String get diagBattery;

  /// No description provided for @diagBatteryHelp.
  ///
  /// In en, this message translates to:
  /// **'On HyperOS/MIUI enable Auto-start and remove the battery restriction so the service is not killed.'**
  String get diagBatteryHelp;

  /// No description provided for @diagMediaSession.
  ///
  /// In en, this message translates to:
  /// **'Media session'**
  String get diagMediaSession;

  /// No description provided for @diagSources.
  ///
  /// In en, this message translates to:
  /// **'Sources loaded in the session'**
  String get diagSources;

  /// No description provided for @diagSourcesHelp.
  ///
  /// In en, this message translates to:
  /// **'It must match the songs in the queue ({count}). If not, the lock screen cannot change track.'**
  String diagSourcesHelp(String count);

  /// No description provided for @diagIndexNow.
  ///
  /// In en, this message translates to:
  /// **'Current index'**
  String get diagIndexNow;

  /// No description provided for @diagPlayingF.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get diagPlayingF;

  /// No description provided for @diagStateF.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get diagStateF;

  /// No description provided for @diagSongF.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get diagSongF;

  /// No description provided for @diagRecentErrors.
  ///
  /// In en, this message translates to:
  /// **'Recent errors'**
  String get diagRecentErrors;

  /// No description provided for @diagPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get diagPermissions;

  /// No description provided for @diagCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get diagCopyReport;

  /// No description provided for @diagReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get diagReportCopied;

  /// No description provided for @diagRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get diagRefresh;

  /// No description provided for @diagReportTitle.
  ///
  /// In en, this message translates to:
  /// **'BotMp3 · playback diagnostics'**
  String get diagReportTitle;

  /// No description provided for @settingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// No description provided for @settingsSearchNone.
  ///
  /// In en, this message translates to:
  /// **'No matching section'**
  String get settingsSearchNone;

  /// No description provided for @backupToFolder.
  ///
  /// In en, this message translates to:
  /// **'Save a backup copy…'**
  String get backupToFolder;

  /// No description provided for @backupToFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose where to store it (Downloads, Drive, SD…)'**
  String get backupToFolderDesc;

  /// No description provided for @backupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {path}'**
  String backupSavedTo(String path);

  /// No description provided for @rankPlays.
  ///
  /// In en, this message translates to:
  /// **'{count} plays'**
  String rankPlays(String count);

  /// No description provided for @rankPlaySomething.
  ///
  /// In en, this message translates to:
  /// **'Play random'**
  String get rankPlaySomething;

  /// No description provided for @rankSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter this ranking'**
  String get rankSearchHint;

  /// No description provided for @rankOpenArtist.
  ///
  /// In en, this message translates to:
  /// **'Open artist'**
  String get rankOpenArtist;

  /// No description provided for @rankSeeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Open album'**
  String get rankSeeAlbum;

  /// No description provided for @rankLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'last played {when}'**
  String rankLastPlayed(String when);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @addSongsCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String addSongsCount(String count);

  /// No description provided for @settingsGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get settingsGoTo;

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before using AI'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To answer you, BotMp3 sends what you type and the title, artist, album, genre and year of your songs to the AI provider you choose (OpenAI, DeepSeek, Google Gemini or Anthropic Claude), using your own API key.\n\nYour audio files never leave your device. AI answers can be wrong.\n\nYou can withdraw this consent at any time from the AI menu.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get aiConsentAccept;

  /// No description provided for @aiConsentRevoke.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get aiConsentRevoke;

  /// No description provided for @aiConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept the AI privacy notice to use this feature.'**
  String get aiConsentRequired;

  /// No description provided for @aiPrivacyMenu.
  ///
  /// In en, this message translates to:
  /// **'AI privacy'**
  String get aiPrivacyMenu;

  /// No description provided for @aiReport.
  ///
  /// In en, this message translates to:
  /// **'Report response'**
  String get aiReport;

  /// No description provided for @aiReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Response copied. Email it to us to report it.'**
  String get aiReportCopied;

  /// No description provided for @aiReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the report. It helps us improve.'**
  String get aiReportThanks;

  /// No description provided for @aiGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'AI-generated · may be inaccurate'**
  String get aiGeneratedLabel;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get aiRecommendations;

  /// No description provided for @aiBadgeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get aiBadgeLibrary;

  /// No description provided for @aiBadgeExternal.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get aiBadgeExternal;

  /// No description provided for @aiPlayLocal.
  ///
  /// In en, this message translates to:
  /// **'Play {count} from library'**
  String aiPlayLocal(int count);

  /// No description provided for @aiHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get aiHide;

  /// No description provided for @aiStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get aiStructure;

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud'**
  String get aiVoiceOn;

  /// No description provided for @aiVoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off voice'**
  String get aiVoiceOff;

  /// No description provided for @aiConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get aiConnectionError;

  /// No description provided for @aiCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiCopy;

  /// No description provided for @aiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiCopied;

  /// No description provided for @playerVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get playerVolume;

  /// No description provided for @playerInfo.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get playerInfo;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @onlyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get onlyFavorites;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @importNoneNew.
  ///
  /// In en, this message translates to:
  /// **'No new songs were added'**
  String get importNoneNew;

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs imported'**
  String importedCount(int count);

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsLabel;

  /// No description provided for @exitLabel.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitLabel;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing'**
  String get nothingPlaying;

  /// No description provided for @playSomething.
  ///
  /// In en, this message translates to:
  /// **'Play something'**
  String get playSomething;

  /// No description provided for @formatSizeLine.
  ///
  /// In en, this message translates to:
  /// **'Format: {format} · {size}'**
  String formatSizeLine(String format, String size);

  /// No description provided for @djNoSong.
  ///
  /// In en, this message translates to:
  /// **'The DJ couldn\'t find a suitable song'**
  String get djNoSong;

  /// No description provided for @nextUpSpoken.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String nextUpSpoken(String title);

  /// No description provided for @favoritesChip.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesChip;

  /// No description provided for @interpreting.
  ///
  /// In en, this message translates to:
  /// **'Interpreting…'**
  String get interpreting;

  /// No description provided for @smartSearch.
  ///
  /// In en, this message translates to:
  /// **'Smart search'**
  String get smartSearch;

  /// No description provided for @noSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get noSongsTitle;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResultsTitle;

  /// No description provided for @searchImportHint.
  ///
  /// In en, this message translates to:
  /// **'Import music to be able to search it.'**
  String get searchImportHint;

  /// No description provided for @searchNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try other words, remove filters or use smart search.'**
  String get searchNoResultsHint;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'The search couldn\'t be completed'**
  String get searchFailed;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Import your songs (MP3, M4A, OGG, FLAC, WAV…) with the button below.\nBotMp3 also works 100% offline.'**
  String get libraryEmptyBody;

  /// No description provided for @filtersNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try other filters or search terms.'**
  String get filtersNoResultsHint;

  /// No description provided for @allFilters.
  ///
  /// In en, this message translates to:
  /// **'All filters'**
  String get allFilters;

  /// No description provided for @songsAndDuration.
  ///
  /// In en, this message translates to:
  /// **'{count} songs · {duration}'**
  String songsAndDuration(int count, String duration);

  /// No description provided for @playlistIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'The playlist is empty'**
  String get playlistIsEmpty;

  /// No description provided for @playlistExportedCopied.
  ///
  /// In en, this message translates to:
  /// **'Playlist exported and JSON copied to the clipboard'**
  String get playlistExportedCopied;

  /// No description provided for @invalidPlaylistFile.
  ///
  /// In en, this message translates to:
  /// **'The file is not a valid BotMp3 playlist'**
  String get invalidPlaylistFile;

  /// No description provided for @playlistImported.
  ///
  /// In en, this message translates to:
  /// **'Playlist “{name}” imported ({count} songs)'**
  String playlistImported(String name, int count);

  /// No description provided for @rankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get rankingTitle;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetBtn;

  /// No description provided for @rankingWasReset.
  ///
  /// In en, this message translates to:
  /// **'Ranking reset'**
  String get rankingWasReset;

  /// No description provided for @rankingError.
  ///
  /// In en, this message translates to:
  /// **'Ranking error: {error}'**
  String rankingError(String error);

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAll;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodMonth;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get periodWeek;

  /// No description provided for @playsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String playsCount(int count);

  /// No description provided for @trendsIn.
  ///
  /// In en, this message translates to:
  /// **'🔥 Trending in {country}'**
  String trendsIn(String country);

  /// No description provided for @trendsShareHeader.
  ///
  /// In en, this message translates to:
  /// **'Music trends 🔥'**
  String get trendsShareHeader;

  /// No description provided for @trendsChannelName.
  ///
  /// In en, this message translates to:
  /// **'Music trends'**
  String get trendsChannelName;

  /// No description provided for @alreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'{artist} · already in your library'**
  String alreadyInLibrary(String artist);

  /// No description provided for @undoChanges.
  ///
  /// In en, this message translates to:
  /// **'Undo changes'**
  String get undoChanges;

  /// No description provided for @pickImagePngJpg.
  ///
  /// In en, this message translates to:
  /// **'Choose image (PNG/JPG)'**
  String get pickImagePngJpg;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @rotate90.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90°'**
  String get rotate90;

  /// No description provided for @enhanceImage.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get enhanceImage;

  /// No description provided for @originalImage.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalImage;

  /// No description provided for @rotationFraming.
  ///
  /// In en, this message translates to:
  /// **'Rotation and framing'**
  String get rotationFraming;

  /// No description provided for @zoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoomLabel;

  /// No description provided for @framingHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal framing'**
  String get framingHorizontal;

  /// No description provided for @framingVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical framing'**
  String get framingVertical;

  /// No description provided for @imageAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Image adjustments'**
  String get imageAdjustments;

  /// No description provided for @brightnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightnessLabel;

  /// No description provided for @contrastLabel.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrastLabel;

  /// No description provided for @saturationLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturationLabel;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature (cool ↔ warm)'**
  String get temperatureLabel;

  /// No description provided for @fadeVeil.
  ///
  /// In en, this message translates to:
  /// **'Veil / fade'**
  String get fadeVeil;

  /// No description provided for @textOrLogo.
  ///
  /// In en, this message translates to:
  /// **'Text or logo'**
  String get textOrLogo;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @changeBaseImage.
  ///
  /// In en, this message translates to:
  /// **'Change base image'**
  String get changeBaseImage;

  /// No description provided for @coverExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Cover exported to {path}'**
  String coverExportedTo(String path);

  /// No description provided for @testVoice.
  ///
  /// In en, this message translates to:
  /// **'Test voice'**
  String get testVoice;

  /// No description provided for @restoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreBtn;

  /// No description provided for @deleteLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete library'**
  String get deleteLibraryTitle;

  /// No description provided for @deleteAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllBtn;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @artistRequired.
  ///
  /// In en, this message translates to:
  /// **'Artist is required'**
  String get artistRequired;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get invalidYear;

  /// No description provided for @tagsWrittenToFile.
  ///
  /// In en, this message translates to:
  /// **'Tags written to the file'**
  String get tagsWrittenToFile;

  /// No description provided for @tagsAppOnly.
  ///
  /// In en, this message translates to:
  /// **'This format doesn\'t allow writing tags; they were saved in the app only'**
  String get tagsAppOnly;

  /// No description provided for @msgPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused ⏸️'**
  String get msgPaused;

  /// No description provided for @msgVolumeAt.
  ///
  /// In en, this message translates to:
  /// **'Volume at {percent}%'**
  String msgVolumeAt(int percent);

  /// No description provided for @msgSpeedAt.
  ///
  /// In en, this message translates to:
  /// **'Speed {speed}x ⏩'**
  String msgSpeedAt(String speed);

  /// No description provided for @msgShuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on 🔀'**
  String get msgShuffleOn;

  /// No description provided for @msgShuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle off'**
  String get msgShuffleOff;

  /// No description provided for @msgRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat the whole queue 🔁'**
  String get msgRepeatAll;

  /// No description provided for @aiPlaylistDated.
  ///
  /// In en, this message translates to:
  /// **'AI playlist {date}'**
  String aiPlaylistDated(String date);

  /// No description provided for @msgPlaylistCreatedWith.
  ///
  /// In en, this message translates to:
  /// **'Playlist “{name}” created with {count} songs 📝'**
  String msgPlaylistCreatedWith(String name, int count);

  /// No description provided for @msgNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”.'**
  String msgNoResultsFor(String query);

  /// No description provided for @msgSongUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated “{title}”: {field} = {value} ✏️'**
  String msgSongUpdated(String title, String field, String value);

  /// No description provided for @msgActionFailed.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t run “{action}”: {error}'**
  String msgActionFailed(String action, String error);

  /// No description provided for @aiErrNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to {provider} ({error})'**
  String aiErrNoConnection(String provider, String error);

  /// No description provided for @aiErrUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from {provider}'**
  String aiErrUnexpected(String provider);

  /// No description provided for @aiErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'{provider} returned an invalid response'**
  String aiErrInvalid(String provider);

  /// No description provided for @aiErrNoReply.
  ///
  /// In en, this message translates to:
  /// **'{provider} didn\'t return any answer'**
  String aiErrNoReply(String provider);

  /// No description provided for @aiErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'{provider} returned an empty answer'**
  String aiErrEmpty(String provider);

  /// No description provided for @aiErrRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected by {provider}: {detail}'**
  String aiErrRejected(String provider, String detail);

  /// No description provided for @aiErrAuth.
  ///
  /// In en, this message translates to:
  /// **'{provider} API key is invalid or lacks permissions.'**
  String aiErrAuth(String provider);

  /// No description provided for @aiErrBalance.
  ///
  /// In en, this message translates to:
  /// **'Not enough credit on {provider}. Top up your account.'**
  String aiErrBalance(String provider);

  /// No description provided for @aiErrModel.
  ///
  /// In en, this message translates to:
  /// **'Model “{model}” isn\'t available on {provider}.'**
  String aiErrModel(String model, String provider);

  /// No description provided for @aiErrRate.
  ///
  /// In en, this message translates to:
  /// **'Too many requests to {provider}. Wait a few seconds.'**
  String aiErrRate(String provider);

  /// No description provided for @aiErrStatus.
  ///
  /// In en, this message translates to:
  /// **'{provider} error {status}: {detail}'**
  String aiErrStatus(int status, String provider, String detail);

  /// No description provided for @aiMissingKey.
  ///
  /// In en, this message translates to:
  /// **'The {provider} API key is missing.'**
  String aiMissingKey(String provider);

  /// No description provided for @aiTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing {provider}…'**
  String aiTesting(String provider);

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'{provider} is thinking…'**
  String aiThinking(String provider);

  /// No description provided for @aiUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String aiUnexpectedError(String error);

  /// No description provided for @aiExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing: {text}'**
  String aiExecuting(String text);

  /// No description provided for @aiLookingRecs.
  ///
  /// In en, this message translates to:
  /// **'Looking for recommendations…'**
  String get aiLookingRecs;

  /// No description provided for @aiComposingIdea.
  ///
  /// In en, this message translates to:
  /// **'Composing an idea…'**
  String get aiComposingIdea;

  /// No description provided for @aiIdeaCreated.
  ///
  /// In en, this message translates to:
  /// **'🎼 Idea created: **{title}** ({genre}, {bpm} BPM)'**
  String aiIdeaCreated(String title, String genre, int bpm);

  /// No description provided for @aiGeneratorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt for a generator'**
  String get aiGeneratorPrompt;

  /// No description provided for @aiGeneratedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Generated by AI'**
  String get aiGeneratedPlaylist;

  /// No description provided for @chatExportHeader.
  ///
  /// In en, this message translates to:
  /// **'BotMp3 AI conversation'**
  String get chatExportHeader;

  /// No description provided for @chatMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get chatMe;

  /// No description provided for @chatAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get chatAi;

  /// No description provided for @inYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'It\'s in your library'**
  String get inYourLibrary;

  /// No description provided for @freedSpace.
  ///
  /// In en, this message translates to:
  /// **'{size} freed'**
  String freedSpace(String size);

  /// No description provided for @copiesReplaced.
  ///
  /// In en, this message translates to:
  /// **' · {count} copies replaced with the original'**
  String copiesReplaced(int count);

  /// No description provided for @newSongsOf.
  ///
  /// In en, this message translates to:
  /// **'{added} new songs out of {found}'**
  String newSongsOf(int added, int found);

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'The library couldn\'t be scanned'**
  String get scanFailed;

  /// No description provided for @importingProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing {done}/{total}…'**
  String importingProgress(int done, int total);

  /// No description provided for @libraryStatsLine.
  ///
  /// In en, this message translates to:
  /// **'{songs} songs · {genres} genres · {lists} playlists'**
  String libraryStatsLine(int songs, int genres, int lists);

  /// No description provided for @saveFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {file}'**
  String saveFileTitle(String file);

  /// No description provided for @widgetNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get widgetNowPlaying;

  /// No description provided for @widgetPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get widgetPaused;

  /// No description provided for @aspectRatioTitle.
  ///
  /// In en, this message translates to:
  /// **'Aspect ratio'**
  String get aspectRatioTitle;

  /// No description provided for @coverFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get coverFiltersTitle;

  /// No description provided for @filterBlackWhite.
  ///
  /// In en, this message translates to:
  /// **'Black & white'**
  String get filterBlackWhite;

  /// No description provided for @filterVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get filterVintage;

  /// No description provided for @filterWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get filterWarm;

  /// No description provided for @filterCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get filterCool;

  /// No description provided for @filterDramatic.
  ///
  /// In en, this message translates to:
  /// **'Dramatic'**
  String get filterDramatic;

  /// No description provided for @filterFaded.
  ///
  /// In en, this message translates to:
  /// **'Faded'**
  String get filterFaded;

  /// No description provided for @filterVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get filterVivid;

  /// No description provided for @positionTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get positionTop;

  /// No description provided for @positionCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get positionCenter;

  /// No description provided for @positionBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get positionBottom;

  /// No description provided for @aiSelectionBelow.
  ///
  /// In en, this message translates to:
  /// **'Here\'s the selection below.'**
  String get aiSelectionBelow;

  /// No description provided for @aiNoClearSelection.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t get a clear selection this time. Try again in a moment.'**
  String get aiNoClearSelection;

  /// No description provided for @aiProposeOne.
  ///
  /// In en, this message translates to:
  /// **'I suggest {title}{by}.'**
  String aiProposeOne(String title, String by);

  /// No description provided for @aiProposeMany.
  ///
  /// In en, this message translates to:
  /// **'I put together {count} tracks; we start with {title}{by}.'**
  String aiProposeMany(int count, String title, String by);

  /// No description provided for @aiByArtist.
  ///
  /// In en, this message translates to:
  /// **' by {artist}'**
  String aiByArtist(String artist);

  /// No description provided for @djKeepLine.
  ///
  /// In en, this message translates to:
  /// **'Keeping the same vibe: {title}.'**
  String djKeepLine(String title);

  /// No description provided for @djReasonSameGenre.
  ///
  /// In en, this message translates to:
  /// **'Same genre ({genre}) to keep the mood going.'**
  String djReasonSameGenre(String genre);

  /// No description provided for @djReasonSameArtist.
  ///
  /// In en, this message translates to:
  /// **'Same artist, without repeating the song.'**
  String get djReasonSameArtist;

  /// No description provided for @djReasonChange.
  ///
  /// In en, this message translates to:
  /// **'A change of pace without leaving your library.'**
  String get djReasonChange;

  /// No description provided for @searchFoundMatches.
  ///
  /// In en, this message translates to:
  /// **'You do have them: I found {count} matches in your library.'**
  String searchFoundMatches(int count);

  /// No description provided for @djModeTitle.
  ///
  /// In en, this message translates to:
  /// **'DJ mode'**
  String get djModeTitle;

  /// No description provided for @eqDescGlass.
  ///
  /// In en, this message translates to:
  /// **'Bass, mids and treble with genre presets'**
  String get eqDescGlass;

  /// No description provided for @eqEnabled.
  ///
  /// In en, this message translates to:
  /// **'Equalizer on'**
  String get eqEnabled;

  /// No description provided for @eqPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get eqPresetsTitle;

  /// No description provided for @eqCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get eqCustom;

  /// No description provided for @eqWaitingSong.
  ///
  /// In en, this message translates to:
  /// **'Play a song to activate the equalizer: the phone reports its bands once audio starts.'**
  String get eqWaitingSong;

  /// No description provided for @eqNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'The equalizer is only available on Android.'**
  String get eqNotAvailable;

  /// No description provided for @eqBandsInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} bands · {min} to {max} dB'**
  String eqBandsInfo(int count, String min, String max);

  /// No description provided for @eqpFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get eqpFlat;

  /// No description provided for @eqpRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get eqpRock;

  /// No description provided for @eqpPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get eqpPop;

  /// No description provided for @eqpJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get eqpJazz;

  /// No description provided for @eqpClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get eqpClassical;

  /// No description provided for @eqpRap.
  ///
  /// In en, this message translates to:
  /// **'Rap'**
  String get eqpRap;

  /// No description provided for @eqpReggaeton.
  ///
  /// In en, this message translates to:
  /// **'Reggaeton'**
  String get eqpReggaeton;

  /// No description provided for @eqpCumbia.
  ///
  /// In en, this message translates to:
  /// **'Cumbia'**
  String get eqpCumbia;

  /// No description provided for @eqpElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get eqpElectronic;

  /// No description provided for @eqpHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy rock'**
  String get eqpHeavy;

  /// No description provided for @eqpVocal.
  ///
  /// In en, this message translates to:
  /// **'Vocal'**
  String get eqpVocal;

  /// No description provided for @eqpBass.
  ///
  /// In en, this message translates to:
  /// **'Bass boost'**
  String get eqpBass;

  /// No description provided for @eqpTreble.
  ///
  /// In en, this message translates to:
  /// **'Treble boost'**
  String get eqpTreble;
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
