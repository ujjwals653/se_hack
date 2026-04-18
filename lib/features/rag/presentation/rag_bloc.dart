import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/rag/data/models/rag_document.dart';
import 'package:se_hack/features/rag/domain/rag_service.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class RagEvent {}

class RagIngestFile extends RagEvent {
  final File file;
  final bool isPdf;
  RagIngestFile(this.file, {this.isPdf = false});
}

class RagAskQuestion extends RagEvent {
  final String question;
  RagAskQuestion(this.question);
}

class RagDeleteDocument extends RagEvent {
  final String docId;
  RagDeleteDocument(this.docId);
}

class RagLoadDocuments extends RagEvent {}

// ── States ──────────────────────────────────────────────────────────────────

abstract class RagState {
  final List<RagDocument> documents;
  final List<RagMessage> messages;
  const RagState({required this.documents, required this.messages});
}

class RagMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  const RagMessage({required this.text, required this.isUser, this.sources = const []});
}

class RagIdle extends RagState {
  const RagIdle({required super.documents, required super.messages});
}

class RagIngesting extends RagState {
  final int done;
  final int total;
  final String fileName;
  const RagIngesting({
    required super.documents,
    required super.messages,
    required this.done,
    required this.total,
    required this.fileName,
  });
  double get progress => total == 0 ? 0 : done / total;
}

class RagAnswering extends RagState {
  const RagAnswering({required super.documents, required super.messages});
}

class RagError extends RagState {
  final String message;
  const RagError({required super.documents, required super.messages, required this.message});
}

// ── BLoC ────────────────────────────────────────────────────────────────────

class RagBloc extends Bloc<RagEvent, RagState> {
  final RagService _service;

  RagBloc(this._service) : super(const RagIdle(documents: [], messages: [])) {
    on<RagLoadDocuments>(_onLoad);
    on<RagIngestFile>(_onIngest);
    on<RagAskQuestion>(_onAsk);
    on<RagDeleteDocument>(_onDelete);
  }

  Future<void> _onLoad(RagLoadDocuments event, Emitter<RagState> emit) async {
    final docs = await _service.getDocuments();
    emit(RagIdle(documents: docs, messages: state.messages));
  }

  Future<void> _onIngest(RagIngestFile event, Emitter<RagState> emit) async {
    final fileName = event.file.path.split(Platform.pathSeparator).last;

    try {
      emit(RagIngesting(
        documents: state.documents,
        messages: state.messages,
        done: 0,
        total: 1,
        fileName: fileName,
      ));

      final doc = await _service.ingestFile(
        event.file,
        isPdf: event.isPdf,
        onProgress: (done, total) {
          // Emit progress if we're still in a stream context
          if (!isClosed) {
            add(_ProgressUpdate(done, total, fileName));
          }
        },
      );

      final docs = await _service.getDocuments();
      final newMsg = RagMessage(
        text: '📄 "$fileName" ingested — ${ doc.chunkCount} chunks indexed.',
        isUser: false,
      );
      emit(RagIdle(documents: docs, messages: [...state.messages, newMsg]));
    } catch (e) {
      emit(RagError(
        documents: state.documents,
        messages: state.messages,
        message: 'Failed to ingest "$fileName": $e',
      ));
    }
  }

  Future<void> _onAsk(RagAskQuestion event, Emitter<RagState> emit) async {
    final userMsg = RagMessage(text: event.question, isUser: true);
    final withUser = [...state.messages, userMsg];

    emit(RagAnswering(documents: state.documents, messages: withUser));

    try {
      final answer = await _service.query(event.question);
      final botMsg = RagMessage(
        text: answer.text,
        isUser: false,
        sources: answer.sources,
      );
      emit(RagIdle(documents: state.documents, messages: [...withUser, botMsg]));
    } catch (e) {
      emit(RagError(
        documents: state.documents,
        messages: withUser,
        message: 'Query failed: $e',
      ));
    }
  }

  Future<void> _onDelete(RagDeleteDocument event, Emitter<RagState> emit) async {
    await _service.deleteDocument(event.docId);
    final docs = await _service.getDocuments();
    emit(RagIdle(documents: docs, messages: state.messages));
  }
}

// Internal progress event
class _ProgressUpdate extends RagEvent {
  final int done;
  final int total;
  final String fileName;
  _ProgressUpdate(this.done, this.total, this.fileName);
}
