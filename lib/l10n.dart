import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A STRK fala português de Portugal. Sem isto, os seletores de data e de
/// hora, os botões "OK/Cancel" e os textos de acessibilidade do Flutter
/// apareciam em inglês, e as horas em formato de 12h ("8:30 PM").
const strkLocale = Locale('pt', 'PT');

const strkSupportedLocales = [strkLocale];

const strkLocalizationsDelegates = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
