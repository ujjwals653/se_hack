import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:se_hack/features/calendar/domain/calendar_event_model.dart';

const _calendarEventsScope = 'https://www.googleapis.com/auth/calendar.events';

class CalendarRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [_calendarEventsScope],
  );

  /// Ensures the user has granted Calendar read access.
  /// Returns null if the user denies the scope.
  Future<GoogleSignInAccount?> _ensureCalendarAccess() async {
    // Re-use already signed-in account if it has the scope
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();

    account ??= await _googleSignIn.signIn();

    if (account == null) return null;

    // Request Calendar scope if not yet granted
    final hasScope = await _googleSignIn.requestScopes([_calendarEventsScope]);
    if (!hasScope) return null;

    return _googleSignIn.currentUser;
  }

  Future<gauth.AuthClient> _getAuthClient() async {
    final account = await _ensureCalendarAccess();
    if (account == null) {
      throw CalendarAuthException('Calendar access was not granted.');
    }

    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      throw CalendarAuthException('Could not retrieve access token.');
    }

    final credentials = gauth.AccessCredentials(
      gauth.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      [_calendarEventsScope],
    );

    return gauth.authenticatedClient(http.Client(), credentials);
  }

  /// Fetches events from the user's primary Google Calendar.
  /// [monthsBack] and [monthsAhead] determine the time window.
  Future<List<CalendarEventModel>> fetchEvents({
    int monthsBack = 1,
    int monthsAhead = 2,
  }) async {
    final authClient = await _getAuthClient();

    try {
      final calendarApi = gcal.CalendarApi(authClient);
      final now = DateTime.now().toUtc();
      final timeMin = DateTime(now.year, now.month - monthsBack, 1).toUtc();
      final timeMax = DateTime(
        now.year,
        now.month + monthsAhead + 1,
        0,
      ).toUtc();

      final events = await calendarApi.events.list(
        'primary',
        timeMin: timeMin,
        timeMax: timeMax,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 250,
      );

      return (events.items ?? [])
          .map(_mapEvent)
          .whereType<CalendarEventModel>()
          .toList();
    } finally {
      authClient.close();
    }
  }

  Future<CalendarEventModel> addEvent(CalendarEventModel eventModel) async {
    final authClient = await _getAuthClient();
    try {
      final calendarApi = gcal.CalendarApi(authClient);

      final event = gcal.Event();
      event.summary = eventModel.title;
      event.description = eventModel.description;
      event.location = eventModel.location;

      if (eventModel.isAllDay) {
        event.start = gcal.EventDateTime(date: eventModel.start);
        event.end = gcal.EventDateTime(date: eventModel.end);
      } else {
        event.start = gcal.EventDateTime(
          dateTime: eventModel.start?.toUtc(),
          timeZone: 'UTC',
        );
        event.end = gcal.EventDateTime(
          dateTime: eventModel.end?.toUtc(),
          timeZone: 'UTC',
        );
      }

      if (eventModel.recurrenceRule != null) {
        event.recurrence = eventModel.recurrenceRule;
      }

      final createdEvent = await calendarApi.events.insert(event, 'primary');
      final mapped = _mapEvent(createdEvent);
      if (mapped == null) {
        throw CalendarAuthException('Failed to map created event');
      }
      return mapped;
    } finally {
      authClient.close();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final authClient = await _getAuthClient();
    try {
      final calendarApi = gcal.CalendarApi(authClient);
      await calendarApi.events.delete('primary', eventId);
    } finally {
      authClient.close();
    }
  }

  CalendarEventModel? _mapEvent(gcal.Event e) {
    if (e.id == null) return null;

    final isAllDay = e.start?.date != null;
    DateTime? start;
    DateTime? end;

    if (isAllDay) {
      start = e.start?.date;
      end = e.end?.date;
    } else {
      start = e.start?.dateTime?.toLocal();
      end = e.end?.dateTime?.toLocal();
    }

    // Google Calendar color IDs → hex approximations
    final colorHex = _colorIdToHex(e.colorId);

    return CalendarEventModel(
      id: e.id!,
      title: e.summary ?? '(No title)',
      start: start,
      end: end,
      isAllDay: isAllDay,
      description: e.description,
      location: e.location,
      colorHex: colorHex,
      recurringEventId: e.recurringEventId,
    );
  }

  static String? _colorIdToHex(String? colorId) {
    const map = {
      '1': '#AC725E', // Tomato
      '2': '#D06B64', // Flamingo
      '3': '#F83A22', // Tangerine
      '4': '#FA573C', // Banana
      '5': '#FF7537', // Sage
      '6': '#FFAD46', // Basil
      '7': '#42D692', // Peacock
      '8': '#16A765', // Blueberry
      '9': '#7BD148', // Lavender
      '10': '#B3DC6C', // Grape
      '11': '#9FC6E7', // Graphite
    };
    return colorId != null ? map[colorId] : null;
  }
}

class CalendarAuthException implements Exception {
  final String message;
  const CalendarAuthException(this.message);

  @override
  String toString() => message;
}
