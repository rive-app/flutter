import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/token.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/scanner/reader.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/scanner/scanner.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/parser.dart';
// ignore: implementation_imports
import 'package:analyzer/src/string_source.dart';
import 'package:dart_style/dart_style.dart';
// ignore: implementation_imports
import 'package:dart_style/src/error_listener.dart';

class Mutation {
  final String from;
  final String to;

  Mutation(this.from, this.to);
}

class RuntimeMutator {
  /// The string that newlines should use.
  ///
  /// If not explicitly provided, this is inferred from the source text. If the
  /// first newline is `\r\n` (Windows), it will use that. Otherwise, it uses
  /// Unix-style line endings (`\n`).
  String lineEnding;

  /// The number of characters allowed in a single line.
  final int pageWidth;

  /// The number of characters of indentation to prefix the output lines with.
  final int indent;

  // final Set<StyleFix> fixes = Set();

  /// Creates a new formatter for Dart code.
  ///
  /// If [lineEnding] is given, that will be used for any newlines in the
  /// output. Otherwise, the line separator will be inferred from the line
  /// endings in the source file.
  ///
  /// If [indent] is given, that many levels of indentation will be prefixed
  /// before each resulting line in the output.
  ///
  /// While formatting, also applies any of the given [fixes].
  RuntimeMutator({this.lineEnding, int pageWidth, int indent})
      : pageWidth = pageWidth ?? 80,
        indent = indent ?? 0;

  /// Formats the given [source] string containing an entire Dart compilation
  /// unit.
  ///
  /// If [uri] is given, it is a [String] or [Uri] used to identify the file
  /// being formatted in error messages.
  String mutate(String source, Iterable<Mutation> mutations) {
    return mutateSource(SourceCode(source, isCompilationUnit: true), mutations);
  }

  /// Formats the given [source].
  ///
  /// Returns a new [SourceCode] containing the formatted code and the resulting
  /// selection, if any.
  String mutateSource(SourceCode source, Iterable<Mutation> mutations) {
    var errorListener = ErrorListener();

    var featureSet = FeatureSet.fromEnableFlags([
      "extension-methods",
      "non-nullable",
    ]);

    // Tokenize the source.
    var reader = CharSequenceReader(source.text);
    var stringSource = StringSource(source.text, source.uri);
    var scanner = Scanner(stringSource, reader, errorListener);
    scanner.configureFeatures(featureSet);
    var startToken = scanner.tokenize();

    // Infer the line ending if not given one. Do it here since now we know
    // where the lines start.
    if (lineEnding == null) {
      // If the first newline is "\r\n", use that. Otherwise, use "\n".
      if (scanner.lineStarts.length > 1 &&
          scanner.lineStarts[1] >= 2 &&
          source.text[scanner.lineStarts[1] - 2] == '\r') {
        lineEnding = "\r\n";
      } else {
        lineEnding = "\n";
      }
    }

    errorListener.throwIfErrors();

    // Parse it.
    var parser = Parser(stringSource, errorListener, featureSet: featureSet);
    parser.enableOptionalNewAndConst = true;
    parser.enableSetLiterals = true;

    AstNode node;
    if (source.isCompilationUnit) {
      node = parser.parseCompilationUnit(startToken);
    } else {
      node = parser.parseStatement(startToken);

      // Make sure we consumed all of the source.
      var token = node.endToken.next;
      if (token.type != TokenType.EOF) {
        var error = AnalysisError(
            stringSource,
            token.offset,
            math.max(token.length, 1),
            ParserErrorCode.UNEXPECTED_TOKEN,
            [token.lexeme]);

        throw FormatterException([error]);
      }
    }
    visitAllChildren(node, mutations);
    return node.toString();
  }

  /// Formats the given [source] string containing a single Dart statement.
  String mutateStatement(String source, Iterable<Mutation> mutations) {
    return mutateSource(
        SourceCode(source, isCompilationUnit: false), mutations);
  }

  void visitAllChildren(AstNode node, Iterable<Mutation> mutations) {
    // If a node is a MethodInvocation, the typeArguments aren't part of the
    // regular AST tree structure. They're stored in a special field, make sure
    // we iterate that one too.
    if (node is MethodInvocationImpl && node.typeArguments != null) {
      visitAllChildren(node.typeArguments, mutations);
    }
    for (final mutation in mutations) {
      if (node.toString() == mutation.from) {
        if (node is SimpleIdentifier) {
          node.token = StringToken(node.token.type, mutation.to, 0);
        }
        break;
      }
    }
    for (final child in node.childEntities) {
      if (child is AstNode) {
        visitAllChildren(child, mutations);
      }
    }
  }
}
