import 'package:web/web.dart' as web;

/// Pone el idioma de la interfaz en `<html lang>` (lectores de pantalla y traductor del navegador).
void setHtmlLang(String code) {
  web.document.documentElement?.setAttribute('lang', code);
}
