import 'package:flutter/foundation.dart';

class AutomationBrain {
  static bool? computeAction({
    required double tempInt,
    required double tempExt,
    required int lluviaRaw,
    required int luzRaw,
    required bool isWindowOpen,
  }) {
    
    // --- PRIORIDAD 1: SEGURIDAD (LLUVIA) ---
    bool isRaining = lluviaRaw < 2500;
    if (isRaining) {
      if (isWindowOpen) {
        debugPrint("🌧️ AUTOMATIZACIÓN: Detectada lluvia -> CERRANDO");
        return false; // Orden: Cerrar
      }
      return null; // Ya está cerrada, no hacer nada
    }

    // --- PRIORIDAD 2: CONFORT TÉRMICO ---
    bool shouldVentilate = (tempInt >= 25.0 && tempInt > tempExt);
    bool shouldConserveHeat = (tempInt < 25.0 && tempInt < tempExt);

    if (shouldVentilate) {
      if (!isWindowOpen) {
        debugPrint("🔥 AUTOMATIZACIÓN: Calor detectado -> ABRIENDO");
        return true; // Orden: Abrir
      }
      return null; 
    }

    if (shouldConserveHeat) {
      if (isWindowOpen) {
        debugPrint("❄️ AUTOMATIZACIÓN: Frío detectado -> CERRANDO");
        return false; // Orden: Cerrar
      }
      return null;
    }

    // --- PRIORIDAD 3: ILUMINACIÓN (DÍA/NOCHE) ---
    // Solo actúa si la temperatura no obligó a cerrar/abrir antes.
    bool isDaytime = luzRaw > 5000;
    
    if (isDaytime && !isWindowOpen) {
      debugPrint("☀️ AUTOMATIZACIÓN: Es de día -> ABRIENDO");
      return true; // Orden: Abrir
    } 
    // Opcional: Si es de noche y quieres cerrar
    else if (!isDaytime && isWindowOpen) {
       debugPrint("🌑 AUTOMATIZACIÓN: Es de noche -> CERRANDO");
       return false;
    }

    return null; // Ninguna condición crítica, mantener estado actual
  }
}