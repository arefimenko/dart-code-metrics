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

class NoEqualArgumentsRule extends CommonRule {
  static const String ruleId = 'no-equal-arguments';

  static const _warningMessage = 'The argument has already been passed.';

  final Iterable<String> _ignoredParameters;

  NoEqualArgumentsRule([Map<String, Object> config = const {}])
      : _ignoredParameters = _ConfigParser.parseIgnoredParameters(config),
        super(
          id: ruleId,
          severity: readSeverity(config, Severity.warning),
          excludes: readExcludes(config),
          includes: readIncludes(config),
        );

  @override
  Map<String, Object?> toJson() {
    final json = super.toJson();
    json[_ConfigParser._ignoredParametersConfig] = _ignoredParameters.toList();

    return json;
  }

  @override
  Iterable<Issue> check(InternalResolvedUnitResult source) {
    final visitor = _Visitor(_ignoredParameters);

    source.unit.visitChildren(visitor);

    return visitor.arguments
        .map((argument) => createIssue(
              rule: this,
              location: nodeLocation(node: argument, source: source),
              message: _warningMessage,
            ))
        .toList(growable: false);
  }
}
