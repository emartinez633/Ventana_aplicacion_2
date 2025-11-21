import 'package:flutter/material.dart';

class WindowControlCard extends StatelessWidget {
  // Estado de la Ventana
  final bool isOpen;
  final VoidCallback onWindowToggle;

  // Estado del Modo Automático
  final bool isSwitchOn; 
  final ValueChanged<bool> onSwitchChanged;

  // --- NUEVO: ESTADO DEL BLOQUEO (IS_LOCK) ---
  final bool isLocked;
  final ValueChanged<bool> onLockChanged;

  const WindowControlCard({
    super.key,
    required this.isOpen,
    required this.onWindowToggle,
    required this.isSwitchOn,
    required this.onSwitchChanged,
    required this.isLocked,      // Nuevo parámetro
    required this.onLockChanged, // Nueva función
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220, 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen 
            ? [Colors.cyan.shade400, Colors.blue.shade600] 
            : [Colors.indigo.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? Colors.blue : Colors.deepPurple).withOpacity(0.4), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Column(
        children: [
          // --- ZONA 1: CONTROL DE VENTANA ---
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked ? null : onWindowToggle, // Si está bloqueado, no deja tocar
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? "ABIERTA" : "CERRADA",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isLocked ? "⛔ SISTEMA BLOQUEADO" : "Toca para accionar", // Feedback visual
                          style: TextStyle(color: isLocked ? Colors.orangeAccent : Colors.white70, fontSize: 10, fontWeight: isLocked ? FontWeight.bold : FontWeight.normal),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(
                        isLocked ? Icons.lock : (isOpen ? Icons.sensor_window_outlined : Icons.sensor_window), // Icono cambia si hay candado
                        color: Colors.white, size: 35
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withOpacity(0.3), height: 1),
          ),

          // --- ZONA 2: INTERRUPTORES ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              children: [
                _buildSwitchRow(
                  label: "Modo Automático", 
                  val: isSwitchOn,
                  onChg: onSwitchChanged,
                  icon: Icons.auto_mode
                ),
                // SWITCH 2: BLOQUEO DE SEGURIDAD
                _buildSwitchRow(
                  label: "Bloqueo de Seguridad", 
                  val: isLocked, 
                  onChg: onLockChanged,
                  icon: isLocked ? Icons.lock : Icons.lock_open,
                  activeColor: Colors.orangeAccent
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper widget para no repetir código en los switches
  Widget _buildSwitchRow({
    required String label, 
    required bool val, 
    required ValueChanged<bool> onChg, 
    required IconData icon,
    Color activeColor = const Color(0xFF69F0AE) // Verde por defecto
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
        Transform.scale(
          scale: 0.9, // Un poco más pequeños para que quepan bien
          child: Switch(
            value: val,
            onChanged: onChg,
            activeColor: activeColor,
            activeTrackColor: Colors.white24,
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: Colors.black12,
          ),
        ),
      ],
    );
  }
}