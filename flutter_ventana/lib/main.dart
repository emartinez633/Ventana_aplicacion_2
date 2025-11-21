import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/window_card.dart';
import 'widgets/sensor_cards.dart';
import 'widgets/sound_card.dart';
import 'widgets/automation_logic.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Master Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      ),
      home: const MainDashboardPage(),
    );
  }
}

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Variables de Estado
  bool _isWindowOpen = false;
  double _tempExt = 0.0;
  double _tempInt = 0.0;
  int _lluviaRaw = 4095;
  int _luzRaw = 0;
  int _sonidoExt = 0;
  int _sonidoInt = 0;

  bool _isAutoMode = false;
  bool _isLocked = false;

  StreamSubscription<DatabaseEvent>? _globalSub;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  void _initListeners() {
    _globalSub = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final map = data as Map<dynamic, dynamic>;

        if (mounted) {
          setState(() {
            // --- PARSEO DE DATOS (Igual que antes) ---
            if (map['posicion'] is Map) {
              _isWindowOpen = (map['posicion']['is_open'] as bool?) ?? false;
            }

            if (map['sistema'] is Map) {
              final sistemaData = map['sistema'] as Map;
              // Modo
              final modoVal = sistemaData['modo'];
              if (modoVal is bool) {
                _isAutoMode = modoVal;
              } else if (modoVal is String) {
                String modoStr = modoVal.toUpperCase();
                _isAutoMode = (modoStr == "AUTOMATICO" || modoStr == "ON");
              } else {
                _isAutoMode = false;
              }
              // Lock
              _isLocked = (sistemaData['is_lock'] as bool?) ?? false;
            }

            if (map['temperatura'] is Map) {
              _tempExt =
                  (map['temperatura']['exterior'] as num?)?.toDouble() ?? 0.0;
              _tempInt =
                  (map['temperatura']['interior'] as num?)?.toDouble() ?? 0.0;
            }
            if (map.containsKey('lluvia'))
              _lluviaRaw = (map['lluvia'] as num).toInt();
            if (map.containsKey('luminosidad'))
              _luzRaw = (map['luminosidad'] as num).toInt();
            if (map['sonido'] is Map) {
              _sonidoExt = (map['sonido']['exterior'] as num?)?.toInt() ?? 0;
              _sonidoInt = (map['sonido']['interior'] as num?)?.toInt() ?? 0;
            }

            // ---------------------------------------------------------
            // EJECUCIÓN DEL CEREBRO AUTOMÁTICO
            // ---------------------------------------------------------
            if (_isAutoMode && !_isLocked) {
              bool? action = AutomationBrain.computeAction(
                tempInt: _tempInt,
                tempExt: _tempExt,
                lluviaRaw: _lluviaRaw,
                luzRaw: _luzRaw,
                isWindowOpen: _isWindowOpen,
              );

              if (action != null) {
                if (action != _isWindowOpen) {
                  _dbRef.child('posicion/is_open').set(action);
                  print(
                    "🤖 AUTOMATIZACIÓN EJECUTADA: ${action ? 'ABRIR' : 'CERRAR'}",
                  );
                }
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _globalSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isHot = _tempInt > 25.0;
    bool isRaining = _lluviaRaw < 2500;
    bool isDaytime = _luzRaw > 5000;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monitor De Ventana Inteligente",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Sistema Bloqueado por Seguridad"),
              ),
            );
          } else if (_isAutoMode) {
            // Aviso extra si intenta operar manual estando en automático
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("ℹ️ Cambie a modo MANUAL para operar"),
              ),
            );
          } else {
            _dbRef.child('posicion/is_open').set(!_isWindowOpen);
          }
        },
        backgroundColor: _isLocked
            ? Colors.grey
            : (_isWindowOpen
                  ? const Color(0xFF5C6BC0)
                  : const Color(0xFF4CA9F6)),
        icon: Icon(
          _isLocked
              ? Icons.lock
              : (_isWindowOpen
                    ? Icons.sensor_window
                    : Icons.sensor_window_outlined),
          color: Colors.white,
        ),
        label: Text(
          _isWindowOpen ? "CERRAR" : "ABRIR",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SystemHeader(
              isHot: isHot,
              isRaining: isRaining,
              isDaytime: isDaytime,
              luzRaw: _luzRaw,
            ),
            const SizedBox(height: 25),

            _sectionTitle("CONTROL DE ACCESO"),

            WindowControlCard(
              isOpen: _isWindowOpen,
              onWindowToggle: () {
                if (!_isLocked) {
                  // Permitimos control manual, pero si está en auto, el sistema podría corregirlo al segundo.
                  // Lo ideal es desactivar el Auto al tocar manual, o advertir.
                  if (_isAutoMode) {
                    // Opción A: Apagar modo automático automáticamente
                    // _dbRef.child('sistema/modo').set("MANUAL");

                    // Opción B: Solo advertir (Elegida aquí)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "⚠️ Sistema en Automático. Podría revertirse su acción.",
                        ),
                      ),
                    );
                  }
                  _dbRef.child('posicion/is_open').set(!_isWindowOpen);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("⚠️ Sistema Bloqueado")),
                  );
                }
              },

              isSwitchOn: _isAutoMode,
              onSwitchChanged: (newValue) {
                setState(() {
                  _isAutoMode = newValue;
                  String stringToSend = newValue ? "AUTOMATICO" : "MANUAL";
                  _dbRef.child('sistema/modo').set(stringToSend);
                });
              },

              isLocked: _isLocked,
              onLockChanged: (newValue) {
                setState(() {
                  _isLocked = newValue;
                  _dbRef.child('sistema/is_lock').set(newValue);
                });
              },
            ),

            const SizedBox(height: 25),
            _sectionTitle("CLIMATIZACIÓN"),
            Row(
              children: [
                Expanded(
                  child: TempSensorTile(
                    title: "Interior",
                    value: _tempInt,
                    icon: Icons.home,
                    color: isHot ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TempSensorTile(
                    title: "Exterior",
                    value: _tempExt,
                    icon: Icons.wb_sunny,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            _sectionTitle("AMBIENTE EXTERIOR"),
            RainSensorCard(rawValue: _lluviaRaw),
            const SizedBox(height: 15),
            LightSensorCard(luzRaw: _luzRaw, isDaytime: isDaytime),

            const SizedBox(height: 25),
            _sectionTitle("NIVEL DE RUIDO (%)"),
            SoundSensorCard(
              title: "Ruido Exterior",
              rawValue: _sonidoExt,
              color: Colors.purple,
            ),
            const SizedBox(height: 10),
            SoundSensorCard(
              title: "Ruido Interior",
              rawValue: _sonidoInt,
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
