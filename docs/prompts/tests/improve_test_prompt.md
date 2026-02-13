# PROMPT IMPROVEMENT FRAMEWORK

## PHASE 1: CRITICAL PATH ANALYSIS (5 MIN)

### Input Assessment
- **Clarity Score:** Is instruction unambiguous? (0-10)
- **Completeness Score:** Does it cover all edge cases? (0-10)
- **Actionability Score:** Can AI execute without clarifications? (0-10)
- **Halt Conditions:** Does it specify when to STOP vs CONTINUE? (yes/no)

### Output Assessment
- **First-Attempt Success Rate:** What % of executions succeed without revision?
- **Ambiguity Failures:** Which instructions were misinterpreted?
- **Missing Context:** What assumptions was AI forced to make?

---

## PHASE 2: STRUCTURAL OPTIMIZATION

### 1. Constraint Specificity
**Problem:** "Generate tests" → Ambiguous scope
**Solution:** "Generate 12-15 tests for AnnualRevenueGoalRepositoryImpl covering: success paths (3), validation failures (4), exception handling (3), edge cases (2)"

### 2. Halt Conditions (Critical for AI)
**Add explicit STOP triggers:**
```
IF no imports found STOP and ask for clarification
IF compilation fails STOP and show error
IF coverage < 95% STOP and expand test suite
IF lint warnings > 0 STOP and fix
```

### 3. Decision Tree Precision
**Problem:** "If error occurs, fix it"
**Solution:** Branch on EXACT error type with specific recovery:
```
IF "No named parameter 'X'" → Copy exact name from source line Y
IF "Final field not initialized" → Use any(named:) matcher instead
IF "enum value missing" → Use EnumType.values.first
```

### 4. Success Metrics Quantification
**Problem:** "Write good tests"
**Solution:** 
```
✓ 12/12 tests pass
✓ 100% coverage: annual_revenue_goal_repository_impl.dart
✓ 0 lint warnings (dart analyze --fatal-infos)
✓ 0 unused imports
✓ Execution time < 10s
```

---

## PHASE 3: CONTEXT LAYERING

### Layer 1: Foundational Rules (Immutable)
- These never change; bake into prompt
- Example: "All named parameters must use `any(named: 'param')`"
- Enforcement: Every example shows this pattern

### Layer 2: Domain-Specific Patterns (Seasonal)
- Change per project/phase
- Example: "AppVersion uses String constructor, not named params"
- Enforcement: Add to CRITICAL INSTRUCTION section

### Layer 3: Session Learnings (Incremental)
- Add after EACH successful session
- Example: "Model completeness: check for uninitialized fields"
- Enforcement: New "Known Issues" subsection

### Layer 4: Fallback Recovery (Always Include)
- Ordered by frequency (most common first)
- Pattern: Error signature → Root cause → Fix → Verify
- Enforcement: Table format with exact error strings

---

## PHASE 4: EXAMPLE QUALITY STANDARDS

### Bad Example (Ambiguous)
```dart
// Create a mock
class MockRepo extends Mock implements Repo {}

// Create entity
final entity = MyEntity.create(...);

// Test it
expect(result, isNotNull);
```

### Good Example (Precise)
```dart
// MUST: Only one mock per interface
class MockAnnualRevenueGoalRepository extends Mock
    implements AnnualRevenueGoalRepository {}

// MUST: Realistic fixtures matching business rules
final tYear = Year.fromInt(2026);  // Current or future
final tMoney = Money.fromCents(100000);  // Positive, realistic

// MUST: Verify exact method call with named matchers
verify(
  () => mock.createMonthlyGoalsForYear(
    year: any(named: 'year'),
    goals: any(named: 'goals'),
    log: any(named: 'log'),
  ),
).called(1);
```

### Criteria for Every Code Example
- [ ] Copy-pasteable without modification
- [ ] Demonstrates antipattern AND correct pattern
- [ ] Includes line numbers for error messages
- [ ] Shows exact error that occurs if wrong

---

## PHASE 5: INSTRUCTION HIERARCHY

### Tier 1: ABSOLUTE (Non-negotiable)
```
MUST: All imports alphabetically sorted
MUST: One describe/group per entity method
MUST: Mock.foo is NEVER called without verify()
```

### Tier 2: CRITICAL (Execution blocker)
```
CRITICAL: Test name matches behavior (should X when Y)
CRITICAL: Fixture validation against business rules
CRITICAL: Value object constructor signatures matched exactly
```

### Tier 3: STRONG (Quality gate)
```
STRONG: No more than 3 assertions per simple test
STRONG: Fallback values registered before any(named:) usage
STRONG: Null safety compliance throughout
```

### Tier 4: RECOMMENDED (Best practice)
```
RECOMMENDED: Group success tests before failure tests
RECOMMENDED: Use factory methods vs direct constructors
RECOMMENDED: Comment non-obvious test decisions
```

---

## PHASE 6: AMBIGUITY ELIMINATION

### Detection Patterns
**Vague:** "Write comprehensive tests"
**Precise:** "Write 4 success tests: one per factory method (create/build/reconstruct/fromJson)"

**Vague:** "Handle all errors"
**Precise:** "Test: conflict (409), permission denied (403), unexpected (500), network timeout (0ms)"

**Vague:** "Verify mocks are called"
**Precise:** "verify(() => mock.method(year: any(named: 'year'), goals: any(named: 'goals'))).called(1);"

### Detection Questions
- Can AI implement this without asking for clarification? (YES/NO)
- Are all parameter types specified? (YES/NO)
- Is success criteria quantified? (YES/NO)
- Is failure mode explicit? (YES/NO)

---

## PHASE 7: CONTEXT INJECTION POINTS

### Before Code Generation
```
SOURCE_FILE: [absolute path]
ENTITY_TYPE: [use_case|entity|repository|service]
FACTORY_SIGNATURES: [exact from source]
VALUE_OBJECTS: [with constructor patterns]
DEPENDENCIES: [mocks needed]
VALIDATION_RULES: [business constraints]
```

### During Code Generation
```
CURRENT_TEST: [test name]
CURRENT_GROUP: [success|validation|error|edge]
MOCK_STATE: [what's been mocked so far]
FIXTURE_STATE: [reusable fixtures defined]
```

### After Code Generation
```
TESTS_PASSED: X/Y
COVERAGE: Z%
LINT_ERRORS: N
NEXT_ACTION: [run|fix|cleanup]
```

---

## PHASE 8: RECOVERY MATURITY LEVELS

### Level 1: Know the Error (Exists)
- Error table with exact signatures
- Frequency ranking (most common first)
- Example: "No named parameter 'X' doesn't exist"

### Level 2: Know the Cause (Why)
- Root cause per error
- Example: "Method signature has {named: Type} but matcher missing `named:`"

### Level 3: Know the Fix (How)
- Exact fix steps
- Example: "Add `any(named: 'X')` to matcher"

### Level 4: Know the Verify (Validation)
- Verification command
- Example: "Re-run test; should pass"

### Level 5: Know the Pattern (Prevention)
- Prevent future occurrence
- Example: "ALWAYS check method signature for named parameters"

---

## PHASE 9: CONSTRAINT FORMALIZATION

### Type Safety Constraints
```
INPUT: Entity source file (Dart)
OUTPUT: Test suite (Dart)
CONSTRAINT: Zero compilation errors on first execution
CONSTRAINT: Zero type mismatches
CONSTRAINT: All imports resolvable
```

### Behavioral Constraints
```
CONSTRAINT: Each test is independent (no test pollution)
CONSTRAINT: Mock setup happens in setUp(), not in test
CONSTRAINT: Exactly one verify() call per test (if any)
CONSTRAINT: No commented-out code
```

### Quality Constraints
```
CONSTRAINT: Line length ≤ 120 characters
CONSTRAINT: Indentation exactly 2 spaces
CONSTRAINT: No unused variables
CONSTRAINT: No underscore-prefixed helper functions
```

---

## PHASE 10: FEEDBACK LOOP FORMALIZATION

### Iteration 1: Baseline
- Execute prompt against 3 diverse examples
- Measure: success rate, revision requests, error patterns
- Target: 70% first-attempt success

### Iteration 2: Error Mapping
- Collect all failures
- Categorize by type (5-10 categories)
- Add to error table with fixes
- Target: 85% first-attempt success

### Iteration 3: Pattern Extraction
- Identify common misinterpretations
- Add clarifying examples
- Tighten decision trees
- Target: 95% first-attempt success

### Iteration 4: Maturity
- Expand edge case handling
- Add domain-specific patterns
- Integrate session learnings
- Target: 99% first-attempt success

---

## PHASE 11: INSTRUCTION ORDERING (Cognitive Load)

### Order by Impact (Highest First)
1. CRITICAL: What will break if wrong? (Tier 1)
2. COMMON: What fails 80% of the time? (Tier 2)
3. DOMAIN: What's specific to this codebase? (Tier 3)
4. EDGE: What's rare but important? (Tier 4)

### Order by Sequence (Dependency)
1. Setup (mocks, fixtures, imports)
2. Execution (test structure, assertions)
3. Verification (coverage, linting, cleanup)
4. Validation (quality gates, final checks)

### Order by Complexity (Cognitive)
1. Simple rules first (e.g., "one describe per method")
2. Examples next (e.g., correct mock setup pattern)
3. Decision trees (e.g., "if error X, do Y")
4. Advanced patterns (e.g., fallback value registration)

---

## PHASE 12: MACHINE READABILITY

### Schema Definition
```yaml
prompt:
  version: "2.1"
  domain: "flutter_testing"
  target_ai: "claude-haiku-4.5"
  
critical_rules:
  - id: "named_parameters"
    priority: 1
    rule: "All named parameters in mock matchers require `named:` keyword"
    example_wrong: "mock.method(any(), any())"
    example_right: "mock.method(any(named: 'x'), any(named: 'y'))"
    
  - id: "model_completeness"
    priority: 2
    rule: "Check Model implementations for uninitialized final fields"
    detection: "Error: Final field 'X' is not initialized"
    recovery: "Use any(named:) instead of entity instantiation"

error_patterns:
  - error_id: "named_param_001"
    signature: "No named parameter"
    frequency: 1  (most common)
    root_cause: "Method has {param: Type} but matcher missing named:"
    fix: "Add any(named: 'param') to matcher"
    verify: "flutter test; should pass"
```

---

## PHASE 13: ANTI-PATTERNS (What NOT to do)

### Red Flags in Prompts
```
❌ "Use your best judgment" → Ambiguous; AI guesses
❌ "Handle errors gracefully" → Vague; no spec
❌ "Write good tests" → Subjective; no criteria
❌ "Follow best practices" → Which ones? List explicitly
❌ "If something goes wrong, fix it" → How? Specify recovery
```

### How to Fix
```
✓ "Use factory method matching source signature exactly"
✓ "Handle ServerException with reason==conflict by throwing RepositoryFailure with annualGoalForYearAlreadyExists"
✓ "Write 12 tests: 3 success, 4 validation, 3 error, 2 edge case"
✓ "Follow: (1) MUST rules, (2) CRITICAL rules, (3) STRONG rules"
✓ "IF error X, THEN apply fix Y, THEN verify with command Z"
```

---

## PHASE 14: PROMPT VALIDATION CHECKLIST

### Before Deployment
- [ ] **Clarity:** Can AI implement without clarifications? (ask 5 test questions)
- [ ] **Completeness:** Does it cover all paths? (test with 3+ examples)
- [ ] **Consistency:** Are rules consistent across sections? (check for contradictions)
- [ ] **Precision:** Are all examples copy-pasteable? (run each one)
- [ ] **Fallbacks:** Are all errors recoverable? (test each error path)
- [ ] **Metrics:** Are success criteria quantified? (check every assertion)
- [ ] **Ordering:** Are instructions in dependency order? (trace execution flow)
- [ ] **Machine-Readable:** Can systems parse it? (schema validation)

### During First Use
- [ ] **Execution:** Does it work on first try? (measure: Y/N)
- [ ] **Errors:** What failures occurred? (capture and classify)
- [ ] **Revisions:** How many iterations needed? (track count)
- [ ] **Feedback:** What clarifications were requested? (document)

### After First 3 Uses
- [ ] **Success Rate:** % of first-attempt success? (target: ≥85%)
- [ ] **Common Failures:** What's the top error? (frequency rank)
- [ ] **Patterns:** What instruction is unclear? (identify section)
- [ ] **Improvement:** What single change helps most? (implement)

---

## PHASE 15: KNOWLEDGE GRAPH (Dependencies)

```
Prompt Instruction A
├─ Requires: Instruction B context
├─ Blocks: Instruction C if omitted
└─ Enhanced by: Instruction D examples

Example:
"Named parameter matching" instruction
├─ Requires: "Mock setup" foundation
├─ Blocks: "Test execution" if wrong
└─ Enhanced by: "Mocktail patterns" examples
```

### Circular Dependency Detection
```
If: A requires B AND B requires A → BREAK CYCLE
Solution: Restructure into layers (foundational → advanced)
```

### Missing Prerequisite Detection
```
If: Instruction A mentioned but not defined → ADD DEFINITION
If: Term X used without explanation → DEFINE TERM
If: Example references unknown pattern → LINK TO PATTERN
```

---

## PHASE 16: ADAPTATION MECHANICS

### By Domain Swap
Template → Remove domain-specific sections
Instantiate → Replace [DOMAIN] placeholders with new domain
Validate → Test on 3 examples in new domain

### By Complexity Level
Basic → Keep Tier 1 only
Advanced → Add Tier 2-4
Expert → All tiers + custom patterns

### By Tool/Framework Swap
mocktail → Replace with mockito equivalents
flutter_test → Replace with test framework equivalents
Dart → Replace with language equivalents

---

## PHASE 17: EXECUTION GUARDRAILS

### Hard Stops (MUST)
```
STOP if: Compilation errors present
STOP if: Coverage < 95%
STOP if: Lint warnings > 0
STOP if: Test suite has flaky tests
STOP if: Mock methods uncalled (dead mocks)
```

### Soft Stops (SHOULD)
```
WARN if: Test execution > 10s
WARN if: More than 20 tests per file
WARN if: Fixture complexity high
WARN if: Mock nesting > 2 levels
```

### Auto-Continue (KEEP GOING)
```
Continue if: Test passes on first try
Continue if: All lint checks pass
Continue if: Coverage metric improving
Continue if: No user interruption requested
```

---

## PHASE 18: QUALITY SIGNALS (Maturity Index)

### Signal 1: First-Attempt Success Rate
```
< 50%: Prompt is broken; rewrite
50-75%: Prompt unclear; add examples
75-90%: Prompt good; add edge cases
90-99%: Prompt excellent; maintain
99%+: Prompt optimal; use as template
```

### Signal 2: Ambiguity Resolution Time
```
< 1 min: User understands immediately
1-5 min: Clear but needs examples
5-15 min: Needs clarification session
> 15 min: Fundamentally unclear
```

### Signal 3: Revision Requests
```
0 revisions: Perfect clarity
1-2 revisions: Minor tweaks
3-5 revisions: Moderate improvements
> 5 revisions: Major restructuring needed
```

### Signal 4: Error Pattern Entropy
```
1-2 error types: Prompt targets known domain well
3-5 error types: Prompt covers main cases
6-10 error types: Prompt needs edge case coverage
> 10 error types: Prompt is incomplete
```

---

## PHASE 19: SESSION LEARNING INTEGRATION

### Capture Format
```
SESSION_ID: [unique_id]
DATE: [YYYY-MM-DD]
PRODUCTION_FAILURES: [count]
NEW_PATTERNS: [list]
ROOT_CAUSES: [categorized]
FIXES_ADDED: [to which sections]
VALIDATION: [before/after success rate]
```

### Integration Steps
1. Categorize failure by existing section (if applicable)
2. If new category, create new section
3. Add to error table with fix
4. Add example showing pattern
5. Re-validate on 3+ examples
6. Update success rate metric

### Prevent Regression
```
Add test case for each learned pattern
If pattern recurs, flag as "design issue"
Track false positive rate of checks
Adjust thresholds based on real-world data
```

## PHASE 20: OUTPUTS
1. Do not generate any file, just improve the existing prompt