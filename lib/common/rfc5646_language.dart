/// Enum representing RFC 5646 language codes.
///
/// This enum contains language codes following the RFC 5646 standard
/// for identifying languages and language variants.
enum Rfc5646Language {
  /// Afrikaans language.
  afrikaans('af'),

  /// Afrikaans as spoken in South Africa.
  afrikaansSouthAfrica('af-ZA'),

  /// Arabic language.
  arabic('ar'),

  /// Arabic as spoken in United Arab Emirates.
  arabicUae('ar-AE'),

  /// Arabic as spoken in Bahrain.
  arabicBahrain('ar-BH'),

  /// Arabic as spoken in Algeria.
  arabicAlgeria('ar-DZ'),

  /// Arabic as spoken in Egypt.
  arabicEgypt('ar-EG'),

  /// Arabic as spoken in Iraq.
  arabicIraq('ar-IQ'),

  /// Arabic as spoken in Jordan.
  arabicJordan('ar-JO'),

  /// Arabic as spoken in Kuwait.
  arabicKuwait('ar-KW'),

  /// Arabic as spoken in Lebanon.
  arabicLebanon('ar-LB'),

  /// Arabic as spoken in Libya.
  arabicLibya('ar-LY'),

  /// Arabic as spoken in Morocco.
  arabicMorocco('ar-MA'),

  /// Arabic as spoken in Oman.
  arabicOman('ar-OM'),

  /// Arabic as spoken in Qatar.
  arabicQatar('ar-QA'),

  /// Arabic as spoken in Saudi Arabia.
  arabicSaudiArabia('ar-SA'),

  /// Arabic as spoken in Syria.
  arabicSyria('ar-SY'),

  /// Arabic as spoken in Tunisia.
  arabicTunisia('ar-TN'),

  /// Arabic as spoken in Yemen.
  arabicYemen('ar-YE'),

  /// Azeri Latin script.
  azeriLatin('az'),

  /// Azeri Latin script as used in Azerbaijan.
  azeriLatinAzerbaijan('az-AZ'),

  /// Azeri Cyrillic script as used in Azerbaijan.
  azeriCyrillicAzerbaijan('az-Cyrl-AZ'),

  /// Belarusian language.
  belarusian('be'),

  /// Belarusian as spoken in Belarus.
  belarusianBelarus('be-BY'),

  /// Bulgarian language.
  bulgarian('bg'),

  /// Bulgarian as spoken in Bulgaria.
  bulgarianBulgaria('bg-BG'),

  /// Bosnian as spoken in Bosnia and Herzegovina.
  bosnianBosniaAndHerzegovina('bs-BA'),

  /// Catalan language.
  catalan('ca'),

  /// Catalan as spoken in Spain.
  catalanSpain('ca-ES'),

  /// Czech language.
  czech('cs'),

  /// Czech as spoken in Czech Republic.
  czechCzechRepublic('cs-CZ'),

  /// Welsh language.
  welsh('cy'),

  /// Welsh as spoken in United Kingdom.
  welshUnitedKingdom('cy-GB'),

  /// Danish language.
  danish('da'),

  /// Danish as spoken in Denmark.
  danishDenmark('da-DK'),

  /// German language.
  german('de'),

  /// German as spoken in Austria.
  germanAustria('de-AT'),

  /// German as spoken in Switzerland.
  germanSwitzerland('de-CH'),

  /// German as spoken in Germany.
  germanGermany('de-DE'),

  /// German as spoken in Liechtenstein.
  germanLiechtenstein('de-LI'),

  /// German as spoken in Luxembourg.
  germanLuxembourg('de-LU'),

  /// Divehi language.
  divehi('dv'),

  /// Divehi as spoken in Maldives.
  divehiMaldives('dv-MV'),

  /// Greek language.
  greek('el'),

  /// Greek as spoken in Greece.
  greekGreece('el-GR'),

  /// English language.
  english('en'),

  /// English as spoken in Australia.
  englishAustralia('en-AU'),

  /// English as spoken in Belize.
  englishBelize('en-BZ'),

  /// English as spoken in Canada.
  englishCanada('en-CA'),

  /// English as spoken in Caribbean.
  englishCaribbean('en-CB'),

  /// English as spoken in United Kingdom.
  englishUnitedKingdom('en-GB'),

  /// English as spoken in Ireland.
  englishIreland('en-IE'),

  /// English as spoken in Jamaica.
  englishJamaica('en-JM'),

  /// English as spoken in New Zealand.
  englishNewZealand('en-NZ'),

  /// English as spoken in Republic of the Philippines.
  englishRepublicOfThePhilippines('en-PH'),

  /// English as spoken in Trinidad and Tobago.
  englishTrinidadAndTobago('en-TT'),

  /// English as spoken in United States.
  englishUnitedStates('en-US'),

  /// English as spoken in South Africa.
  englishSouthAfrica('en-ZA'),

  /// English as spoken in Zimbabwe.
  englishZimbabwe('en-ZW'),

  /// Esperanto language.
  esperanto('eo'),

  /// Spanish language.
  spanish('es'),

  /// Spanish as spoken in Argentina.
  spanishArgentina('es-AR'),

  /// Spanish as spoken in Bolivia.
  spanishBolivia('es-BO'),

  /// Spanish as spoken in USA.
  spanishEua('es-US'),

  /// Spanish as spoken in Chile.
  spanishChile('es-CL'),

  /// Spanish as spoken in Colombia.
  spanishColombia('es-CO'),
  spanishCostaRica('es-CR'),
  spanishDominicanRepublic('es-DO'),
  spanishEcuador('es-EC'),
  spanishSpain('es-ES'),
  spanishGuatemala('es-GT'),
  spanishHonduras('es-HN'),
  spanishMexico('es-MX'),
  spanishNicaragua('es-NI'),
  spanishPanama('es-PA'),
  spanishPeru('es-PE'),
  spanishPuertoRico('es-PR'),
  spanishParaguay('es-PY'),
  spanishElSalvador('es-SV'),
  spanishUruguay('es-UY'),
  spanishVenezuela('es-VE'),
  estonian('et'),
  estonianEstonia('et-EE'),
  basque('eu'),
  basqueSpain('eu-ES'),
  farsi('fa'),
  farsiIran('fa-IR'),
  finnish('fi'),
  finnishFinland('fi-FI'),
  faroese('fo'),
  faroeseFaroeIslands('fo-FO'),
  french('fr'),
  frenchBelgium('fr-BE'),
  frenchCanada('fr-CA'),
  frenchSwitzerland('fr-CH'),
  frenchFrance('fr-FR'),
  frenchLuxembourg('fr-LU'),
  frenchPrincipalityOfMonaco('fr-MC'),
  galician('gl'),
  galicianSpain('gl-ES'),
  gujarati('gu'),
  gujaratiIndia('gu-IN'),
  hebrew('he'),
  hebrewIsrael('he-IL'),
  hindi('hi'),
  hindiIndia('hi-IN'),
  croatian('hr'),
  croatianBosniaAndHerzegovina('hr-BA'),
  croatianCroatia('hr-HR'),
  hungarian('hu'),
  hungarianHungary('hu-HU'),
  armenian('hy'),
  armenianArmenia('hy-AM'),
  indonesian('id'),
  indonesianIndonesia('id-ID'),
  icelandic('is'),
  icelandicIceland('is-IS'),
  italian('it'),
  italianSwitzerland('it-CH'),
  italianItaly('it-IT'),
  japanese('ja'),
  japaneseJapan('ja-JP'),
  georgian('ka'),
  georgianGeorgia('ka-GE'),
  kazakh('kk'),
  kazakhKazakhstan('kk-KZ'),
  kannada('kn'),
  kannadaIndia('kn-IN'),
  korean('ko'),
  koreanKorea('ko-KR'),
  konkani('kok'),
  konkaniIndia('kok-IN'),
  kyrgyz('ky'),
  kyrgyzKyrgyzstan('ky-KG'),
  lithuanian('lt'),
  lithuanianLithuania('lt-LT'),
  latvian('lv'),
  latvianLatvia('lv-LV'),
  maori('mi'),
  maoriNewZealand('mi-NZ'),
  fyroMacedonian('mk'),
  fyroMacedonianFormerYugoslavRepublicOfMacedonia('mk-MK'),
  mongolian('mn'),
  mongolianMongolia('mn-MN'),
  marathi('mr'),
  marathiIndia('mr-IN'),
  malay('ms'),
  malayBruneiDarussalam('ms-BN'),
  malayMalaysia('ms-MY'),
  maltese('mt'),
  malteseMalta('mt-MT'),
  norwegianBokml('nb'),
  norwegianBokmlNorway('nb-NO'),
  dutch('nl'),
  dutchBelgium('nl-BE'),
  dutchNetherlands('nl-NL'),
  norwegianNynorskNorway('nn-NO'),
  northernSotho('ns'),
  northernSothoSouthAfrica('ns-ZA'),
  punjabi('pa'),
  punjabiIndia('pa-IN'),
  polish('pl'),
  polishPoland('pl-PL'),
  pashto('ps'),
  pashtoAfghanistan('ps-AR'),
  portuguese('pt'),
  portugueseBrazil('pt-BR'),
  portuguesePortugal('pt-PT'),
  quechua('qu'),
  quechuaBolivia('qu-BO'),
  quechuaEcuador('qu-EC'),
  quechuaPeru('qu-PE'),
  romanian('ro'),
  romanianRomania('ro-RO'),
  russian('ru'),
  russianRussia('ru-RU'),
  sanskrit('sa'),
  sanskritIndia('sa-IN'),
  sami('se'),
  samiFinland('se-FI'),
  samiNorway('se-NO'),
  samiSweden('se-SE'),
  slovak('sk'),
  slovakSlovakia('sk-SK'),
  slovenian('sl'),
  slovenianSlovenia('sl-SI'),
  albanian('sq'),
  albanianAlbania('sq-AL'),
  serbianLatinBosniaAndHerzegovina('sr-BA'),
  serbianCyrillicBosniaAndHerzegovina('sr-Cyrl-BA'),
  serbianLatinSerbiaAndMontenegro('sr-SP'),
  serbianCyrillicSerbiaAndMontenegro('sr-Cyrl-SP'),
  swedish('sv'),
  swedishFinland('sv-FI'),
  swedishSweden('sv-SE'),
  swahili('sw'),
  swahiliKenya('sw-KE'),
  syriac('syr'),
  syriacSyria('syr-SY'),
  tamil('ta'),
  tamilIndia('ta-IN'),
  telugu('te'),
  teluguIndia('te-IN'),
  thai('th'),
  thaiThailand('th-TH'),
  tagalog('tl'),
  tagalogPhilippines('tl-PH'),
  tswana('tn'),
  tswanaSouthAfrica('tn-ZA'),
  turkish('tr'),
  turkishTurkey('tr-TR'),
  tatar('tt'),
  tatarRussia('tt-RU'),
  tsonga('ts'),
  ukrainian('uk'),
  ukrainianUkraine('uk-UA'),
  urdu('ur'),
  urduIslamicRepublicOfPakistan('ur-PK'),
  uzbekLatin('uz'),
  uzbekLatinUzbekistan('uz-UZ'),
  uzbekCyrillicUzbekistan('uz-Cyrl-UZ'),
  vietnamese('vi'),
  vietnameseVietNam('vi-VN'),
  xhosa('xh'),
  xhosaSouthAfrica('xh-ZA'),
  chinese('zh'),
  chineseS('zh-CN'),
  chineseHongKong('zh-HK'),
  chineseMacau('zh-MO'),
  chineseSingapore('zh-SG'),
  chineseT('zh-TW'),
  zulu('zu'),
  zuluSouthAfrica('zu-ZA');

  /// The string value representing the language code.
  final String value;

  /// Creates a [Rfc5646Language] with the given [value].
  const Rfc5646Language(this.value);

  @override
  String toString() {
    return value;
  }

  /// Creates a [Rfc5646Language] from a string value.
  ///
  /// [value] - The string representation of the language code.
  ///
  /// Returns the corresponding [Rfc5646Language] enum value.
  /// Throws a [StateError] if no matching language code is found.
  factory Rfc5646Language.fromMap(String value) {
    return values.firstWhere((element) => element.toString() == value);
  }
}
