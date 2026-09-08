import 'package:claudechat/services/tool_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tools are enabled by default except explicitly gated web/time tools',
    () {
      // get_time defaults off now that "常态化时间戳" gives passive
      // time-awareness without a tool call — same opt-in shape as the web
      // tools, via a dedicated settings key rather than the generic
      // toolOverrides map.
      expect(
        ToolPreferences.isEnabled(<String, Object?>{}, 'get_time'),
        isFalse,
      );
      expect(
        ToolPreferences.isEnabled(<String, Object?>{
          'getTimeEnabled': true,
        }, 'get_time'),
        isTrue,
      );
      expect(
        ToolPreferences.isEnabled(<String, Object?>{}, 'web_search'),
        isFalse,
      );
      expect(
        ToolPreferences.isEnabled(<String, Object?>{}, 'search_memory'),
        isTrue,
      );
    },
  );

  test('legacy per-tool overrides survive an individual toggle', () {
    final updated = ToolPreferences.withEnabled(
      <String, Object?>{
        'create_memory': <String, Object?>{'enabled': false, 'note': 'keep-me'},
      },
      'create_memory',
      true,
    );
    expect(updated['create_memory'], <String, Object?>{
      'enabled': true,
      'note': 'keep-me',
    });
  });

  test('explicit override disables a normally available tool', () {
    expect(
      ToolPreferences.isEnabled(<String, Object?>{
        'toolOverrides': <String, Object?>{
          'read_file': <String, Object?>{'enabled': false},
        },
      }, 'read_file'),
      isFalse,
    );
  });
}
