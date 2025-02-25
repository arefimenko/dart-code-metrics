// ignore_for_file: public_member_api_docs

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../../../../../utils/node_utils.dart';
import '../../../lint_utils.dart';
import '../../../models/internal_resolved_unit_result.dart';
import '../../../models/issue.dart';
import '../../../models/severity.dart';
import '../../models/common_rule.dart';
import '../../rule_utils.dart';

part 'config_parser.dart';
part 'visitor.dart';

class NoMagicNumberRule extends CommonRule {
  static const String ruleId = 'no-magic-number';

  static const _warningMessage =
      'Avoid using magic numbers. Extract them to named constants or variables.';

  final Iterable<num> _allowedMagicNumbers;

  NoMagicNumberRule([Map<String, Object> config = const {}])
      : _allowedMagicNumbers = _ConfigParser.parseAllowedNumbers(config),
        super(
          id: ruleId,
          severity: readSeverity(config, Severity.warning),
          excludes: readExcludes(config),
          includes: readIncludes(config),
        );

  @override
  Map<String, Object?> toJson() {
    final json = super.toJson();
    json[_ConfigParser._allowedConfigName] = _allowedMagicNumbers.toList();

    return json;
  }

  @override
  Iterable<Issue> check(InternalResolvedUnitResult source) {
    final visitor = _Visitor();

    source.unit.visitChildren(visitor);

    return visitor.literals
        .where(_isMagicNumber)
        .where(_isNotInsideVariable)
        .where(_isNotInsideCollectionLiteral)
        .where(_isNotInsideConstMap)
        .where(_isNotInsideConstConstructor)
        .where(_isNotInDateTime)
        .where(_isNotInsideIndexExpression)
        .where(_isNotInsideEnumConstantArguments)
        .map((lit) => createIssue(
              rule: this,
              location: nodeLocation(node: lit, source: source),
              message: _warningMessage,
            ))
        .toList(growable: false);
  }

  bool _isMagicNumber(Literal l) =>
      (l is DoubleLiteral && !_allowedMagicNumbers.contains(l.value)) ||
      (l is IntegerLiteral && !_allowedMagicNumbers.contains(l.value));

  bool _isNotInsideVariable(Literal l) =>
      l.thisOrAncestorMatching(
        (ancestor) => ancestor is VariableDeclaration,
      ) ==
      null;

  bool _isNotInDateTime(Literal l) =>
      l.thisOrAncestorMatching(
        (a) =>
            a is InstanceCreationExpression &&
            a.staticType?.getDisplayString(withNullability: false) ==
                'DateTime',
      ) ==
      null;

  bool _isNotInsideEnumConstantArguments(Literal l) {
    final node = l.thisOrAncestorMatching(
      (ancestor) => ancestor is EnumConstantArguments,
    );

    return node == null;
  }

  bool _isNotInsideCollectionLiteral(Literal l) => l.parent is! TypedLiteral;

  bool _isNotInsideConstMap(Literal l) {
    final grandParent = l.parent?.parent;

    return !(grandParent is SetOrMapLiteral && grandParent.isConst);
  }

  bool _isNotInsideConstConstructor(Literal l) =>
      l.thisOrAncestorMatching((ancestor) =>
          ancestor is InstanceCreationExpression && ancestor.isConst) ==
      null;

  bool _isNotInsideIndexExpression(Literal l) => l.parent is! IndexExpression;
}
