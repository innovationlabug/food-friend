import 'package:flutter/material.dart';

/// Shared route observer used so root screens (e.g., HomeScreen) refresh
/// dynamic state whenever any route above them is popped.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

