# Project Relay ses varlıkları

`menu_ambient.wav` ve `battle_ambient.wav`, depodaki
`tool/generate_music.dart` aracıyla Project Relay için prosedürel olarak
üretilir. Üçüncü taraf kayıt, örnek (sample) veya lisans bağımlılığı içermez.

Müzik dosyalarını aynı kaynak tanımından yeniden üretmek için `client`
dizininde şu komut çalıştırılır:

```text
dart run tool/generate_music.dart
```

Diğer kısa savaş efektleri ve seviye atlama kutlamasında kullanılan
`level_up.wav`, `tool/generate_sounds.py` kaynağından üretilir.
