import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt'),
  ];

  /// No description provided for @adminMenuHeader.
  ///
  /// In pt, this message translates to:
  /// **'Vet Route Admin'**
  String get adminMenuHeader;

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso Vet Route'**
  String get appTitle;

  /// No description provided for @cliniCorrierSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Motoboy solicitado! Aguardando aceite.'**
  String get cliniCorrierSuccess;

  /// No description provided for @clinicMarkerSelf.
  ///
  /// In pt, this message translates to:
  /// **'Sua Clínica'**
  String get clinicMarkerSelf;

  /// No description provided for @clinicScheduleMock.
  ///
  /// In pt, this message translates to:
  /// **'Abrindo calendário para agendamento...'**
  String get clinicScheduleMock;

  /// No description provided for @clinicTrackingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhamento em Tempo Real'**
  String get clinicTrackingTitle;

  /// No description provided for @clinics.
  ///
  /// In pt, this message translates to:
  /// **'Clínicas'**
  String get clinics;

  /// No description provided for @couriers.
  ///
  /// In pt, this message translates to:
  /// **'Motoboys'**
  String get couriers;

  /// No description provided for @delivery.
  ///
  /// In pt, this message translates to:
  /// **'Entrega'**
  String get delivery;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @emailError.
  ///
  /// In pt, this message translates to:
  /// **'Digite o e-mail'**
  String get emailError;

  /// No description provided for @errorEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha todos os campos.'**
  String get errorEmpty;

  /// No description provided for @errorPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao entrar:'**
  String get errorPrefix;

  /// No description provided for @finished.
  ///
  /// In pt, this message translates to:
  /// **'Finalizadas'**
  String get finished;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// No description provided for @immediate.
  ///
  /// In pt, this message translates to:
  /// **'Imediata'**
  String get immediate;

  /// No description provided for @lab.
  ///
  /// In pt, this message translates to:
  /// **'Laboratório'**
  String get lab;

  /// No description provided for @labBtnReceiveProduct.
  ///
  /// In pt, this message translates to:
  /// **'RECEBER PACOTE'**
  String get labBtnReceiveProduct;

  /// No description provided for @labReceiveInit.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando recebimento... Escaneie o pacote.'**
  String get labReceiveInit;

  /// No description provided for @labs.
  ///
  /// In pt, this message translates to:
  /// **'Laboratórios'**
  String get labs;

  /// No description provided for @loginBtn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginBtn;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair do Aplicativo'**
  String get logout;

  /// No description provided for @markerSelf.
  ///
  /// In pt, this message translates to:
  /// **'Seu Laboratório'**
  String get markerSelf;

  /// No description provided for @markerWaiting.
  ///
  /// In pt, this message translates to:
  /// **'Coleta Aguardando'**
  String get markerWaiting;

  /// No description provided for @motoboyEmptyRadar.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma coleta no radar no momento.'**
  String get motoboyEmptyRadar;

  /// No description provided for @motoboyRadarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Coletas no seu Radar'**
  String get motoboyRadarTitle;

  /// No description provided for @motoboyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Área do Motoboy'**
  String get motoboyTitle;

  /// No description provided for @nameError.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome'**
  String get nameError;

  /// No description provided for @nameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get nameLabel;

  /// No description provided for @noAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não tem uma conta?'**
  String get noAccount;

  /// No description provided for @onWay.
  ///
  /// In pt, this message translates to:
  /// **'A Caminho'**
  String get onWay;

  /// No description provided for @open.
  ///
  /// In pt, this message translates to:
  /// **'Em Aberto'**
  String get open;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @passwordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter no mínimo 6 caracteres'**
  String get passwordError;

  /// No description provided for @pickup.
  ///
  /// In pt, this message translates to:
  /// **'Coleta'**
  String get pickup;

  /// No description provided for @profileLabel.
  ///
  /// In pt, this message translates to:
  /// **'Perfil: Laboratório'**
  String get profileLabel;

  /// No description provided for @radarText.
  ///
  /// In pt, this message translates to:
  /// **'Radar do Laboratório: Acompanhando motoboys a caminho em tempo real.'**
  String get radarText;

  /// No description provided for @reception.
  ///
  /// In pt, this message translates to:
  /// **'Recepção'**
  String get reception;

  /// No description provided for @regError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao cadastrar:'**
  String get regError;

  /// No description provided for @regHeader.
  ///
  /// In pt, this message translates to:
  /// **'Painel Vet Route - Cadastro de Usuário'**
  String get regHeader;

  /// No description provided for @register.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre-se'**
  String get register;

  /// No description provided for @regSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Usuário cadastrado com sucesso!'**
  String get regSuccess;

  /// No description provided for @regTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro de Usuários'**
  String get regTitle;

  /// No description provided for @saveBtn.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR USUÁRIO'**
  String get saveBtn;

  /// No description provided for @scheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendada'**
  String get scheduled;

  /// No description provided for @sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando'**
  String get sending;

  /// No description provided for @users.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get users;

  /// No description provided for @waitCourier.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando Motoboy'**
  String get waitCourier;

  /// No description provided for @labEmptyFinished.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma coleta finalizada hoje.'**
  String get labEmptyFinished;

  /// No description provided for @labEmptyWaiting.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma clínica aguardando no momento.'**
  String get labEmptyWaiting;

  /// No description provided for @emptyFinished.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma coleta finalizada hoje.'**
  String get emptyFinished;

  /// No description provided for @emptyWaiting.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma clínica aguardando no momento.'**
  String get emptyWaiting;

  /// No description provided for @history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Coletas'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @profileClinic.
  ///
  /// In pt, this message translates to:
  /// **'Perfil: Clínica'**
  String get profileClinic;

  /// No description provided for @entregadorRadarTitle.
  ///
  /// In pt, this message translates to:
  /// **'Radar de Entregadores'**
  String get entregadorRadarTitle;

  /// No description provided for @profileEntregador.
  ///
  /// In pt, this message translates to:
  /// **'Perfil: Entregador'**
  String get profileEntregador;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
