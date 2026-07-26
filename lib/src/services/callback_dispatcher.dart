import '../models/review_kit_callback.dart';

/// Small event bus for [ReviewKitCallback] handlers.
///
/// Kept separate from [ReviewViewModel] so callback wiring stays testable and
/// the ViewModel stays focused on orchestration.
class CallbackDispatcher {
  final Map<ReviewKitCallback, List<void Function(dynamic)>> _handlers = {};

  /// Register a handler for [callback]. Multiple handlers are allowed.
  void on(ReviewKitCallback callback, void Function(dynamic) handler) {
    _handlers.putIfAbsent(callback, () => []);
    _handlers[callback]!.add(handler);
  }

  /// Remove a handler, or all handlers for [callback] when [handler] is null.
  void off(ReviewKitCallback callback, [void Function(dynamic)? handler]) {
    if (handler != null) {
      _handlers[callback]?.remove(handler);
    } else {
      _handlers.remove(callback);
    }
  }

  /// Invoke all handlers registered for [callback].
  void emit(ReviewKitCallback callback, [dynamic data]) {
    final handlers = _handlers[callback];
    if (handlers == null) return;
    for (final handler in List<void Function(dynamic)>.from(handlers)) {
      handler(data);
    }
  }

  /// Remove every registered handler.
  void clear() => _handlers.clear();
}
