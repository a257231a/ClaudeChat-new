class ToolPreferences {
  const ToolPreferences._();

  static bool isEnabled(Map<String, Object?> settings, String name) {
    if (name == 'web_search' && settings['webSearchEnabled'] != true) {
      return false;
    }
    if (name == 'fetch_url' && settings['fetchUrlEnabled'] != true) {
      return false;
    }
    // Defaults to off now that "常态化时间戳" gives passive time-awareness
    // without a tool call — opt back in via the toolbox if the AI should
    // still be able to actively read the clock.
    if (name == 'get_time' && settings['getTimeEnabled'] != true) {
      return false;
    }
    final rawOverrides = settings['toolOverrides'];
    if (rawOverrides is! Map) return true;
    final rawTool = rawOverrides[name];
    if (rawTool is! Map) return true;
    return rawTool['enabled'] != false;
  }

  static Map<String, Object?> withEnabled(
    Object? rawOverrides,
    String name,
    bool enabled,
  ) {
    final output = <String, Object?>{};
    if (rawOverrides is Map) {
      for (final entry in rawOverrides.entries) {
        output['${entry.key}'] = entry.value;
      }
    }
    final current = <String, Object?>{};
    final rawCurrent = output[name];
    if (rawCurrent is Map) {
      for (final entry in rawCurrent.entries) {
        current['${entry.key}'] = entry.value;
      }
    }
    output[name] = <String, Object?>{...current, 'enabled': enabled};
    return output;
  }
}
