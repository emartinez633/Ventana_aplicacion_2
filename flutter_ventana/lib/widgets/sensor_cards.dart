import 'package:flutter/material.dart';

// --- HEADER DEL SISTEMA ---
class SystemHeader extends StatelessWidget {
  final bool isHot;
  final bool isRaining;
  final bool isDaytime;
  final int luzRaw;

  const SystemHeader({super.key, required this.isHot, required this.isRaining, required this.isDaytime, required this.luzRaw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Icon(isRaining ? Icons.thunderstorm : (isHot ? Icons.thermostat_outlined : Icons.check_circle), color: (isRaining || isHot) ? Colors.orange : Colors.green, size: 35),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Diagnóstico del Sistema", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text(isRaining ? "¡LLUVIA EN CURSO!" : (isHot ? "TEMPERATURA ALTA" : "TODO NORMAL"), style: TextStyle(color: (isRaining || isHot) ? Colors.orange.shade800 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
          ])
        ],
      ),
    );
  }
}

// --- TARJETA DE TEMPERATURA SIMPLE ---
class TempSensorTile extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const TempSensorTile({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        Text("${value.toStringAsFixed(1)}°C", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }
}

// --- TARJETA DE LLUVIA (LÓGICA YL-83) ---
class RainSensorCard extends StatelessWidget {
  final int rawValue;
  
  const RainSensorCard({super.key, required this.rawValue});

  @override
  Widget build(BuildContext context) {
    double percentage = (1.0 - (rawValue / 4095)).clamp(0.0, 1.0);
    String status = rawValue > 3800 ? "Seco" : (rawValue > 2500 ? "Rocío / Húmedo" : (rawValue > 1500 ? "Lluvia Moderada" : "Tormenta"));

    return _BaseEnvCard(
      icon: Icons.water_drop,
      color: percentage > 0.2 ? Colors.blue : Colors.grey.shade400,
      title: "Lluvia",
      status: status,
      percentage: percentage,
      rawVal: rawValue,
    );
  }
}

// --- TARJETA DE LUZ ---
class LightSensorCard extends StatelessWidget {
  final bool isDaytime;
  final int luzRaw;
  static const double maxLux = 20000.0; 

  const LightSensorCard({super.key, required this.isDaytime, required this.luzRaw});

  @override
  Widget build(BuildContext context) {
    return _BaseEnvCard(
      icon: (isDaytime ? Icons.light_mode : Icons.nightlight_round),
      color: (isDaytime ? Colors.amber : Colors.indigo),
      title: "Luminosidad",
      status: "$luzRaw",
      percentage: (luzRaw / maxLux).clamp(0.0, 1.0),
      rawVal: luzRaw,
    );
  }
}

// Widget privado base para no repetir código en Lluvia/Luz
class _BaseEnvCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String status;
  final double percentage;
  final int rawVal;

  const _BaseEnvCard({required this.icon, required this.color, required this.title, required this.status, required this.percentage, required this.rawVal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey.shade100, color: color, minHeight: 8, borderRadius: BorderRadius.circular(5)),
          Text("ADC: $rawVal", style: TextStyle(color: Colors.grey.shade400, fontSize: 10))
        ]))
      ]),
    );
  }
}