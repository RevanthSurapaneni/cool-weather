import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart'; // For RenderAbstractViewport
import 'package:flutter/widgets.dart'; // For BuildContext and RenderObject

/// Utility class for performance optimization
class PerformanceUtils {
  /// Cache for expensive calculations
  static final Map<String, Object> _computeCache = {};

  /// Cache timeout in milliseconds
  static const int _defaultCacheTimeout = 60000; // 1 minute

  /// Compute with memoization to avoid redundant calculations
  static Future<R> memoizedCompute<Q, R>(
    ComputeCallback<Q, R> callback,
    Q message, {
    String? cacheKey,
    int timeoutMs = _defaultCacheTimeout,
  }) async {
    // For web or simple data, don't use isolates
    if (kIsWeb ||
        message is! List &&
            (message is! String || (message as String).length < 50000)) {
      return callback(message);
    }

    final key = cacheKey ?? '${callback.hashCode}_${message.hashCode}';
    final Object? cachedResult = _computeCache[key];

    // Fix: Use proper type casting with as instead of is check to ensure return type safety
    if (cachedResult != null && cachedResult is R) {
      return cachedResult as R; // Explicit cast to ensure type safety
    }

    // Fix: Ensure the result is properly typed
    final R result = await compute<Q, R>(callback, message);
    _computeCache[key] = result as Object;

    // Set up cache expiration
    Timer(Duration(milliseconds: timeoutMs), () {
      _computeCache.remove(key);
    });

    return result;
  }

  /// Debounce function for UI events
  static Function(T) debounce<T>(
    Function(T) callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Timer? timer;

    return (T param) {
      if (timer?.isActive ?? false) timer?.cancel();
      timer = Timer(duration, () => callback(param));
    };
  }

  /// Memory-efficient list pagination
  static List<T> paginateList<T>(List<T> source, int page, int pageSize) {
    final startIndex = page * pageSize;
    if (startIndex >= source.length) return [];

    final endIndex = (startIndex + pageSize) > source.length
        ? source.length
        : startIndex + pageSize;

    return source.sublist(startIndex, endIndex);
  }
}

/// Extension on BuildContext for performance-related utilities
extension PerformanceContext on BuildContext {
  /// Check if a widget is visible in the viewport - FIXED implementation
  bool get isInViewport {
    // Simplified implementation that's more robust
    try {
      final RenderObject? renderObject = findRenderObject();
      if (renderObject == null || !renderObject.attached) {
        return false;
      }

      if (renderObject is! RenderBox) {
        return false;
      }

      final RenderBox box = renderObject;

      // Find if we're in a scrollable
      final scrollableState = Scrollable.maybeOf(this);
      if (scrollableState == null) {
        // Not in a scrollable, assume visible if attached
        return true;
      }

      // Calculate if visible in viewport
      final viewportRenderObject = scrollableState.context.findRenderObject();
      if (viewportRenderObject == null || viewportRenderObject is! RenderBox) {
        return false;
      }

      // Get viewport dimensions
      final viewportBox = viewportRenderObject;

      // Convert the box's position to the viewport's coordinate space
      final position = box.localToGlobal(
        Offset.zero,
        ancestor: viewportRenderObject,
      );

      // Check if any part of the widget is within the viewport bounds
      return position.dy + box.size.height > 0 &&
          position.dy < viewportBox.size.height;
    } catch (e) {
      // Safely handle any errors
      debugPrint('Error checking viewport visibility: $e');
      return false;
    }
  }
}
