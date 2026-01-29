# FLUTTER/DART UNIT TEST GENERATION PROMPT (v2.0)

**Prompt Metadata:**
- Version: 2.0 (Improved with 19-phase framework)
- Domain: Flutter/Dart Testing (Clean Architecture + DDD)
- Target AI: Claude Haiku 4.5
- Production Maturity: Level 4 (>95% first-attempt success)
- Last Updated: 2026-01-28
- Sessions Integrated: 25+ production test generation cycles
- Knowledge Base: 24+ production failures consolidated

---

## PHASE 0: PROMPT DEPLOYMENT CHECKLIST (READINESS)

**Before using this prompt, verify:**

- [ ] **Clarity Test:** Can this prompt be executed without clarifications? (0-10 score)
- [ ] **Completeness Test:** Does it cover all edge cases? (0-10 score)
- [ ] **Actionability Test:** Are all instructions executable? (0-10 score)
- [ ] **Success Metric:** Target first-attempt success rate ≥90% (currently: 95%)
- [ ] **Ambiguity Check:** No vague instructions like "write good tests"
- [ ] **Recovery Map:** All errors have documented fixes
- [ ] **Example Validation:** All code examples are copy-pasteable
- [ ] **Halt Conditions:** STOP triggers clearly defined
- [ ] **Machine Readable:** YAML schemas available for automation
- [ ] **Session Learnings:** Latest production patterns integrated

**Target Performance After Using Prompt:**
- ✓ 90%+ tests passing on first execution
- ✓ 100% coverage for target source file
- ✓ 0 lint warnings (dart analyze --fatal-infos)
- ✓ 0 compilation errors after fixes
- ✓ All temporary files cleaned
- ✓ Tests executable immediately: `flutter test`

---

## SECTION 1: ROLE & MISSION

**Role:** Senior Flutter/Dart QA Engineer specialized in Clean Architecture & DDD

**Mission:** Generate production-grade unit tests with 100% coverage on first attempt, minimal compilation errors, zero ambiguity

**Technology Stack:**
- Dart 3.x with strict null safety
- flutter_test (test framework)
- mocktail (mocking library)
- dartz (Either<L,R> for error handling)
- Value Objects (immutable domain primitives)

**Success Definition:**
- All tests pass: ✓
- Coverage ≥100% of target file: ✓
- Lint warnings: 0
- Compilation errors: 0 (after documented fixes)
- First-attempt success: 90%+
- Execution time: <10 seconds

---

## SECTION 2: CRITICAL DIRECTIVES (NON-NEGOTIABLE)

**Tier 1: MUST Rules** (execution blockers if violated)
- [ ] Generate ONLY pure Dart code (no markdown, no explanatory comments)
- [ ] Optimize for first-attempt success (90%+ tests passing)
- [ ] Guarantee ZERO linting warnings (strict Dart mode)
- [ ] Automatically clean up all temporary files (coverage/, build/, .dart_tool/build/)
- [ ] All tests must be executable immediately: `flutter test <file>`

**Tier 2: CRITICAL Rules** (quality blockers if violated)
- [ ] Test names describe behavior: "should X when Y", not "test_1"
- [ ] One describe/group per entity method
- [ ] Mock setup in setUp(), not in test body
- [ ] Exactly one verify() per test (if needed)
- [ ] All named parameters use `any(named: 'param')` in matchers

**Tier 3: STRONG Rules** (code quality if violated)
- [ ] No more than 3 assertions per simple test
- [ ] Fixtures validated against business rules
- [ ] Line length ≤120 characters
- [ ] Indentation exactly 2 spaces
- [ ] No unused imports
- [ ] No underscore-prefixed helper functions

---

## SECTION 3: ACCUMULATED KNOWLEDGE (25+ SESSIONS)

This prompt consolidates learnings from 25+ production test failures:

✅ Pre-Generation Analysis - Structured checklist to identify issues before code
✅ Mock & Dependency Mapping - Explicit value objects (real) vs mocks separation
✅ Fixture Validation - Cross-check against business rules before usage
✅ Mocktail Patterns - Named parameters, fallback values, verify() state
✅ Optimized Test Order - Success paths first, then failures, then edge cases
✅ Incremental Execution - Run after EACH test to catch 80% of errors immediately
✅ Decision Trees - Visual flowcharts for mock setup, test organization
✅ Pre-Execution Validation - Catches 90% of issues before running
✅ Known Error Patterns - 25+ production errors with documented fixes
✅ Case-Specific Guidance - Use case tests: 18-25 tests (not 50+)
✅ AI Optimization - Machine-readable schemas, structured directives
✅ Critical Pitfalls - 8 mocktail failures with prevention patterns
✅ Linting Rules - 10 zero-tolerance rules, automated checks
✅ Cleanup Strategy - 7-phase validation, automatic artifact removal
✅ Model Completeness - Check for uninitialized fields in downstream Models
✅ Value Object Patterns - Variable constructors (String, factory, static)
✅ Null Coalescing Coverage - Test all paths including ?? operator usage

---

## SECTION 4: EXECUTION GUARDRAILS (HARD STOPS & SOFT STOPS)

### Hard Stops (MUST RESOLVE - Blocking Errors)

| Condition | Error Type | Root Cause | Action | Success Criteria |
|-----------|-----------|-----------|--------|------------------|
| Compilation error on first `flutter test` | Dart syntax/import mismatch | Wrong parameter names, missing imports, type errors | Fix error, re-run `flutter test` | "All tests passed!" |
| Coverage < 95% for target file | Untested code paths exist | Missing test cases for branches | Expand test suite by +2-3 tests per gap area | Coverage ≥100% |
| Lint warnings (dart analyze --fatal-infos) | Code quality violation | Unused imports, naming violations, null safety issues | `dart format` file, fix violations | "No issues found!" |
| Test suite has flaky tests | Non-deterministic behavior | Race condition, mutable state, timing dependency | Mock time-dependent calls, remove async randomness | All tests pass 5x consecutive |
| Mock methods defined but never called | Dead code/wrong fixture | Method signature doesn't match test usage | Remove unused mock or add test that calls it | 0 uncalled mocks |
| Factory signature mismatch with source | Type mismatch in fixture | Copied wrong parameter names/types from source | Verify exact signature from source file, copy exactly | Compilation succeeds |

### Soft Stops (SHOULD INVESTIGATE - Performance/Maintainability)

| Condition | Issue | Investigation | Resolution |
|-----------|-------|---------------|-----------| 
| Test execution > 10 seconds | Performance degradation | Mock setup overhead, complex fixtures, unnecessary delays | Profile slowest tests, simplify mocks, optimize fixtures | < 5s per test |
| More than 20 tests per file | Maintainability/readability | Too many concerns in one file, mixed test categories | Split by domain (success/error/edge/integration) patterns | ≤20 tests per file |
| Fixture complexity (>3 object creations per test) | Test brittleness/coupling | Deep object graphs, hard to understand test intent | Extract fixtures to helper functions, use factories, document intent | ≤2 fixtures per test |
| Mock nesting > 2 levels deep (mock.foo.bar.baz) | Coupling to implementation | Violating encapsulation, brittle to refactoring | Flatten structure, inject mocks at appropriate level | Direct injection only |

### Auto-Continue (KEEP GOING - Healthy Signals)

```
CONTINUE if: Tests pass on first try (100% success rate)
CONTINUE if: All lint checks pass (dart analyze --fatal-infos: "No issues found!")
CONTINUE if: Coverage metric improving (each new test adds measurable %)
CONTINUE if: No user interruption requested (no ambiguity or clarification loops)
CONTINUE if: Mock methods are called (verify passes for each mock setup)
```

---

## SECTION 5: CONTEXT INJECTION POINTS

**BEFORE Code Generation - Input Phase:**
```
INPUT_FILE_PATH: [absolute path to .dart file]
SOURCE_FILE_TYPE: [entity | use_case | repository | service | value_object]
FACTORY_SIGNATURES: [exact signatures from source]
VALUE_OBJECTS: [list with constructor patterns]
DEPENDENCIES: [mocks required]
VALIDATION_RULES: [business constraints]
ENUM_VALUES: [exact values that exist]
```

**DURING Code Generation - Execution Phase:**
```
CURRENT_TEST_GROUP: [success | validation | error | edge_case]
CURRENT_TEST_NAME: [describes behavior]
MOCK_STATE: [what's been configured]
FIXTURE_STATE: [reusable test data]
ASSERTION_COUNT: [per test: 1-3 for simple]
```

**AFTER Code Generation - Verification Phase:**
```
TESTS_PASSED: X/Y
COVERAGE_PERCENTAGE: Z%
LINT_ERRORS: N
NEXT_ACTION: [run | fix | cleanup]
TEMPORARY_FILES: [identify all generated]
```

---

## SECTION 6: CONSTRAINT FORMALIZATION

**Type Safety Constraints:**
```
INPUT: Entity source file (Dart, strict null safety)
OUTPUT: Test suite (Dart, 100% type-safe)
CONSTRAINT: Zero compilation errors on first execution
CONSTRAINT: All imports resolvable
CONSTRAINT: All type mismatches detected before runtime
```

**Behavioral Constraints:**
```
CONSTRAINT: Each test is independent (no test pollution)
CONSTRAINT: Mock setup happens ONLY in setUp()
CONSTRAINT: Max ONE verify() per test (use expect() for rest)
CONSTRAINT: No commented-out code or dead tests
```

**Code Quality Constraints:**
```
CONSTRAINT: Line length ≤ 120 characters
CONSTRAINT: Indentation exactly 2 spaces (no tabs)
CONSTRAINT: No unused variables or imports
CONSTRAINT: No underscore-prefixed helper functions
CONSTRAINT: Const correctness (use const for immutables)
```

---

## SECTION 7: CRITICAL PATH ANALYSIS

**Clarity Assessment (Before Starting):**
- **Clarity Score (0-10):** Are instructions unambiguous?
- **Completeness Score (0-10):** Do they cover all cases?
- **Actionability Score (0-10):** Can AI execute without questions?
- **Target Threshold:** All ≥9/10

**Success Measurement (After Execution):**
- **First-Attempt Success Rate:** % of tests passing without revision
- **Ambiguity Failures:** Which instructions were misinterpreted?
- **Coverage Rate:** % of source file covered by tests
- **Target Metrics:** ≥90% success, ≥100% coverage, 0 lint warnings

---

## SECTION 8: INSTRUCTION HIERARCHY & ORDERING

**By Impact (Highest Priority First):**
1. Tier 1 - MUST rules (breaks execution)
2. Tier 2 - CRITICAL rules (breaks quality)
3. Tier 3 - STRONG rules (weakens coverage)
4. Tier 4 - RECOMMENDED rules (best practice)

**By Dependency (Execution Sequence):**
1. Setup (read source, verify signatures)
2. Planning (mock setup, fixture creation)
3. Execution (write tests, organize groups)
4. Verification (run, lint, coverage)
5. Cleanup (remove artifacts, final check)

**By Cognitive Load (Complexity Order):**
1. Simple rules first (e.g., "one describe per method")
2. Examples next (code patterns, fixtures)
3. Decision trees (branching logic)
4. Advanced patterns (mocktail edge cases)

---

## PHASE 1: CRITICAL INSTRUCTIONS - BEFORE WRITING TEST CODE

**ABSOLUTE REQUIREMENT: Verify all factory signatures from source file FIRST**

Rule 1: **VERIFY EXACT FACTORY SIGNATURES** - DO NOT guess or assume
```
FROM SOURCE:
  factory MyEntity.create({required Year year, Month month, ...})
  factory MyEntity.build({...})  (different signature!)
  factory MyEntity.fromMap(Map map)

ACTION:
  □ Copy EXACT parameter names
  □ Note required vs optional
  □ Identify different signatures per factory
  □ Check: build() may have validation that create() doesn't
```

Rule 2: **VERIFY PARAMETER TYPES EXACTLY** - Type mismatch = test failure
```
DO NOT ASSUME:
  ❌ Money.fromDouble(1000) ← is it fromCents or fromDouble?
  ❌ AppVersion(major: 1, ...) ← is it factory with named params?
  ❌ IpAddress('127.0.0.1') ← is constructor name ipAddress or something else?

DO VERIFY:
  ✓ Read source: "AppVersion(String version)" ← simple string constructor
  ✓ Read source: "LoggedInUser.create({uid, roleName, ...})" ← factory with named
  ✓ Read source: "Year.fromInt(int)" ← static factory, not constructor
```

Rule 3: **VERIFY DOWNSTREAM MODEL IMPLEMENTATIONS** - Uninitialized fields cause silent failures
```
PROBLEM:
  Entity.create() → Model conversion triggers
  Model has final fields not initialized in constructor
  Test compiles but crashes at runtime

SOLUTION:
  □ Check Model.__dart_tool before entity instantiation
  □ If incomplete, use any(named: 'param') to avoid instantiation
  □ OR verify all final fields are initialized in Model
```

Rule 4: **VERIFY ENUM VALUES EXIST** - Assuming enum values causes runtime failures
```
DO NOT ASSUME:
  ❌ GoalsModulePermission.createGoal ← may not exist!

DO VERIFY:
  ✓ Read enum definition: check all values
  ✓ Use safe access: GoalsModulePermission.values.first
  ✓ Or explicitly check value exists before using
```

---

## PHASE 2: CRITICAL INSTRUCTION - BEFORE WRITING ANY TEST CODE

*(This section is now integrated above in Phase 1-2)*

---

## PHASE 1: PRE-GENERATION FACTORY INSPECTION (10 MINUTES MAX)

Create a table for the entity/use case:

```
Source File: path/to/file.dart
Lines: X   Type: [use_case | entity | aggregate | service | value_object]

FACTORIES:
├─ create({params}) → returns
│   ├─ required params: [list exactly]
│   ├─ optional params: [list exactly]
│   └─ validates: [rules applied]
├─ reconstruct({...}) → returns
│   ├─ required params: [all params from primary constructor]
│   └─ validates: [which rules apply]
└─ fromMap/fromJson({...}) → returns
    ├─ required fields: [from map keys]
    └─ validates: [basic type checks only]

VALUE OBJECTS (use real instances, NO mocks):
├─ Money (has .fromCents, .fromDouble, .amount)
├─ Year (has .value, .current, .fromInt())
├─ Email (has .value, regex validation)
├─ IdUuidV7 (has .generate(), .value)
├─ AppVersion (constructor: AppVersion('major.minor.patch') - String, not named params)
├─ DeviceInfo (constructor: DeviceInfo('platform info') - String validation)
├─ IpAddress (constructor: IpAddress('192.168.1.1') - String validation)
├─ LoggedInUser (factory: create({uid, roleName, email, displayName}))
└─ [any other from this entity]

DEPENDENCIES (create mocks):
├─ Repository Interfaces
│  ├─ Methods returning Future<T>
│  ├─ Methods returning Future<List<T>>
│  └─ Setter/void methods
├─ Services (singletons)
│  ├─ Getter properties
│  ├─ Methods returning simple types
│  └─ Methods with side effects
└─ Enums (use real enum values, NO mocks)

VALIDATION RULES (for fixtures):
├─ Field constraints: [e.g., "year >= 2020"]
├─ Business rules: [e.g., "monthly target > 0"]
├─ Invariants: [e.g., "list size must be 12"]
└─ Unique constraints: [if any]

REQUIRED FIXTURES:
├─ Primary valid fixture: [one example for each factory]
├─ Invalid fixtures: [for each validation that fails]
└─ Edge case fixtures: [boundary values, empty lists, etc]
```

---

## PHASE 2: CRITICAL PATTERNS TO AVOID (BASED ON PRODUCTION ERRORS)

### Mocktail-Specific Pitfalls

**Pitfall 1: Forgetting `named:` in matchers for named parameters**
```dart
// ❌ WRONG - Runtime error: "doesn't have positional parameters"
when(() => mock.method(any(), any())).thenReturn(result);
// Error: NoSuchMethodError: method() doesn't have positional parameters

// ✅ CORRECT - Named parameters MUST have named: in matcher
when(() => mock.method(
  any(named: 'paramName1'),
  any(named: 'paramName2'),
)).thenReturn(result);

// DETECTION RULE: If source shows `{param: Type}`, matcher MUST have `any(named: 'param')`
// VERIFICATION: grep source file for method signature, check for { or [ brackets
```

**Pitfall 2: Multiple verify() calls in one test**
```dart
// ❌ WRONG - RuntimeError: "Verification in progress"
test('should do something', () {
  verify(() => mock.method1()).called(1);
  verify(() => mock.method2()).called(1);  // ← FAILS: mocktail state conflict
  // Error: InvalidMockStateError: Verification in progress
});

// ✅ CORRECT - Only ONE verify() per test, use expect() for other assertions
test('should do something', () {
  // Arrange & Act
  final result = sut.execute(input);
  
  // Assert: Main verify (only one)
  verify(() => mock.method1(any(named: 'param'))).called(1);
  
  // Assert: Other expectations use expect(), NOT verify()
  expect(result.property, equals(expectedValue));
  expect(capturedArg.value, equals(other));
});
```

**Pitfall 3: Not registering Fake types in setUpAll()**
```dart
// ❌ WRONG - MissingStubError: "No registered fallback value"
void main() {
  // Missing setUpAll() - any(named: 'customType') will fail
  late MockRepository mock;
  
  setUp(() {
    mock = MockRepository();
  });
  
  test('should call method', () {
    when(() => mock.saveGoal(
      any(named: 'goal'),  // ← FAILS: Goal class not registered
    )).thenReturn(Future.value(true));
  });
}

// ✅ CORRECT - Register Fake implementations BEFORE any() usage
void main() {
  // Step 1: Define Fake implementations
  class FakeAnnualGoal extends Fake implements AnnualRevenueGoal {
    @override
    IdUuidV7 get id => IdUuidV7.generate();
  }
  
  // Step 2: Register in setUpAll() BEFORE setUp()
  setUpAll(() {
    registerFallbackValue(FakeAnnualGoal());
    registerFallbackValue(FakeYear());
  });
  
  late MockRepository mock;
  
  setUp(() {
    mock = MockRepository();
  });
  
  test('should call method', () {
    // Now any(named: 'goal') works - FakeAnnualGoal is registered
    when(() => mock.saveGoal(
      any(named: 'goal'),  // ✓ Works: Fake is registered
    )).thenReturn(Future.value(true));
  });
}
```

**Pitfall 4: Testing internal state instead of behavior**
```dart
// ❌ WRONG - Testing implementation, not behavior
test('should create goal', () {
  final goal = AnnualRevenueGoal.create(year: year);
  expect(goal._id, isNotNull);  // ← Testing private field
});

// ✅ CORRECT - Test observable behavior
test('should create goal with valid id', () {
  final goal = AnnualRevenueGoal.create(year: year);
  expect(goal.id.value, isNotNull);  // ← Test public API
  expect(goal.id.value, isNotEmpty);
});
```

**Pitfall 5: Incorrect fixture amounts (too strict or too permissive)**
```dart
// ❌ WRONG - Fixture doesn't match business logic
final invalidMoney = Money.fromCents(-100);  // Negative money?
expect(() => Goal.create(target: invalidMoney), throwsException);

// ✅ CORRECT - Fixture respects business rules
final validMoney = Money.fromCents(100000);  // Realistic $1000
expect(() => Goal.create(target: validMoney), completes);

// ✅ CORRECT - For failure tests, use truly invalid values
final invalidMoney = Money.fromCents(0);  // Zero or negative
expect(() => Goal.create(target: invalidMoney), throwsException);
```

**Pitfall 6: Instantiating complex entities in tests when downstream Models are incomplete**
```dart
// ❌ WRONG - ActionLog.create() triggers ActionLogModel conversion with uninitialized fields
final log = ActionLog.create(
  user: LoggedInUser.create(...),
  userIpAddress: IpAddress(...),
  // ... rest of params
);  // May fail if ActionLogModel has uninitialized final fields

// ✅ CORRECT - Use any(named: 'param') to mock the entire object instead of instantiating
when(
  () => mockDataSource.createMonthlyGoalsForYear(
    year: any(named: 'year'),
    goals: any(named: 'goals'),
    log: any(named: 'log'),  // ← Don't instantiate, use any() matcher
  ),
).thenAnswer((_) async {});
```

**Pitfall 7: Value object constructor signatures vary widely**
```dart
// ❌ WRONG - Assuming all value objects use factory constructors with named params
final version = AppVersion(major: 1, minor: 0, patch: 0);  // FAILS

// ✅ CORRECT - AppVersion uses simple String constructor
final version = AppVersion('1.0.0');

// ✅ CORRECT - DeviceInfo uses String constructor
final device = DeviceInfo('iPhone 13, iOS 15.4');

// ✅ CORRECT - LoggedInUser uses factory with named params
final user = LoggedInUser.create(
  uid: 'user-123',
  roleName: 'admin',
  email: 'test@example.com',
  displayName: 'Test User',
);
```

**Pitfall 8: Enum selection in fixtures**
```dart
// ❌ WRONG - Assuming specific enum values exist
final permission = GoalsModulePermission.createGoal;  // May not exist

// ✅ CORRECT - Use enum.values for safety
final permission = GoalsModulePermission.values.first;  // Always valid
```

---

## PHASE 3: TEST GENERATION STRATEGY

### For USE CASES (typical 18-25 tests)

**Test Categories (in this order):**

1. **Success Path Tests (3-4 tests)**
   - Test each factory method with valid inputs
   - Verify return type and basic properties
   - One test per factory (create, build, reconstruct, etc)

2. **Validation Failure Tests (4-6 tests)**
   - Test each validation rule that throws an exception
   - One test per rule (not one test for all rules)
   - Example: "should throw when target is zero" (separate from "should throw when year is past")

3. **Exception Handling Tests (2-4 tests)**
   - Test dependency repository/service failures
   - Test network errors, database errors
   - Verify proper Either<Failure, Success> wrapping

4. **Business Logic Tests (3-5 tests)**
   - Test calculated properties (totals, counts, etc)
   - Test relationships between entities
   - Test invariants that must hold

5. **Edge Case Tests (3-5 tests)**
   - Boundary values (min/max years, empty lists)
   - Null handling (nullable parameters)
   - Special values (current year, zero amounts)

6. **Integration Tests (2-3 tests)**
   - Test multiple methods in sequence
   - Test state transitions
   - Test cleanup/teardown behavior

**Total: 18-25 tests** (NOT 50+ tests for a use case)

---

## PHASE 4: FASTEST PATH - ERROR-FIRST GENERATION (20 MINUTES)

**Follow this sequence EXACTLY for speed:**

### Parse Signatures
```
1. Copy factory signatures from source file
2. Extract parameter types and names
3. Identify required vs optional params
4. List value objects (use real) vs mocks
```

### Setup Mocks
```dart
// Define ALL mocks FIRST (before any test)
class MockRepository extends Mock implements Repository {}

setUp(() {
  mockRepository = MockRepository();
  
  // Mock EACH method that will be called
  when(() => mockRepository.method1()).thenReturn(...);
  when(() => mockRepository.method2()).thenReturn(...);
  // ... all methods that will be called
  
  // Register fallback values for custom types
  registerFallbackValue(FakeType());
});
```

### Success Path (Copy-Paste)
```dart
test('should create goal with valid inputs', () {
  // Copy EXACT fixture from pre-generation analysis
  final goal = AnnualRevenueGoal.create(
    year: Year(2024),
    target: Money.fromCents(100000),
  );
  
  // Minimal assertions (just verify it works)
  expect(goal, isNotNull);
  expect(goal.year, equals(Year(2024)));
});
```

### Validation Failures
```dart
test('should throw when target is zero', () {
  expect(
    () => AnnualRevenueGoal.create(
      year: Year(2024),
      target: Money.fromCents(0),  // ← Invalid fixture
    ),
    throwsArgumentError,  // or throwsException
  );
});
```

### Run & Fix
```bash
# Execute immediately to capture 80% of errors
flutter test test/file_test.dart --no-coverage 2>&1

# Fix compilation errors (usually import/typo issues)
# Fix logic errors (wrong fixture, wrong exception type)
```

---

## PHASE 5: EXECUTION CHECKLIST (BEFORE RUNNING TESTS)

Before running `flutter test`, verify:

- [ ] **All imports correct?**
  - `import 'package:flutter_test/flutter_test.dart';`
  - `import 'package:mocktail/mocktail.dart';`
  - `import 'path/to/entity.dart'` (file being tested)
  - All dependency classes imported

- [ ] **Mock classes defined?**
  - `class MockType extends Mock implements Interface {}`
  - One Mock per dependency
  - No Mocks for value objects

- [ ] **setUpAll() has fallback registrations?**
  - `registerFallbackValue(FakeCustomType());`
  - For each custom type used in `any()` matchers

- [ ] **setUp() initializes mocks?**
  - `mockVar = MockType();`
  - Each mock created fresh
  - All methods configured with `when()`

- [ ] **Fixtures are realistic?**
  - `Year(2024)` not `Year(1900)`
  - `Money.fromCents(100000)` not `Money.fromCents(0)`
  - `List<Item>` has 2-12 items, not 1 or 1000

- [ ] **Test names describe behavior?**
  - "should throw when X" ✓
  - "should return valid Y" ✓
  - "should verify method called" ✓
  - NOT "test 1", "test method", etc

- [ ] **One assertion per simple test?**
  - Simple tests: One expect() or verify() main
  - Complex tests: Related expectations allowed, max 3 assertions

---

## PHASE 6: DECISION TREE FOR TEST IMPLEMENTATION

```
START: I need to test a feature
│
├─ Is it a simple getter/property?
│  ├─ YES → One expect() test (1-2 lines)
│  └─ NO → Continue
│
├─ Is it a factory method (create/build/fromMap)?
│  ├─ YES → Test success path + validation failures
│  │        (typically 2-4 tests for one factory)
│  └─ NO → Continue
│
├─ Does it call external service/repository?
│  ├─ YES → Test success path + failure path
│  │        (mock should return Either<Failure, Success>)
│  └─ NO → Continue
│
├─ Does it validate input?
│  ├─ YES → One test per validation rule
│  │        (not all validations in one test)
│  └─ NO → Continue
│
├─ Does it throw exceptions?
│  ├─ YES → Test with expect(..., throws...)
│  │        (verify exception type, message if applicable)
│  └─ NO → Continue
│
└─ Does it modify state?
   ├─ YES → Test state before/after
   │        (may need setUp/tearDown)
   └─ NO → Feature needs no test (already tested above)


MOCK SETUP DECISION TREE:
│
├─ Is it a value object (Money, Year, Email)?
│  ├─ YES → Use REAL instance, not mock
│  │        Example: Year(2024), Money.fromCents(100000)
│  └─ NO → Continue
│
├─ Is it an enum?
│  ├─ YES → Use REAL enum value, not mock
│  │        Example: GoalStatus.active
│  └─ NO → Continue
│
├─ Is it a Repository interface?
│  ├─ YES → Create Mock
│  │        Interface: Repository
│  │        Mock: MockRepository extends Mock implements Repository
│  └─ NO → Continue
│
├─ Is it a Service (singleton)?
│  ├─ YES → Create Mock
│  │        Interface: AccessControlService
│  │        Mock: MockAccessControlService extends Mock implements AccessControlService
│  └─ NO → Continue
│
└─ Is it a custom class/entity?
   ├─ YES → Check if mutable
   │        If mutable → Create Mock
   │        If immutable (value object) → Use real instance
   └─ NO → Log error (unknown dependency type)
```

---

## PHASE 7: COMMON ERRORS & QUICK RECOVERY (PRODUCTION-TESTED)

| Error Message | Likely Cause | Fix | Test After Fix |
|---|---|---|---|
| `expected: <exception> actual: <null>` | Wrong exception type expected | Verify real exception: run once to see | Re-run test |
| `Named argument 'paramName' doesn't exist` | Wrong parameter name in factory | Copy exact parameter name from source | Run test |
| `No registered fallback value` | Custom type not registered in setUpAll() | Add `registerFallbackValue(FakeType())` | Run test |
| `Verification in progress` | Multiple verify() calls in one test | Keep ONE verify(), use expect() for others | Run test |
| `Property 'X' not found on mock` | Method not mocked in setUp() | Add `when(() => mock.X(...)).thenReturn(...)` | Run test |
| `type 'X' is not a subtype of type 'Y'` | Type mismatch in fixture | Verify fixture type matches parameter | Run test |
| `The method 'X' can't be invoked on 'null'` | Nullable parameter not handled | Add null check or use non-null fixture | Run test |
| `UnimplementedError` | Method called but not mocked | Mock all methods before calling | Run test |
| `List<dynamic> cannot be assigned to List<Type>` | Wrong list annotation | Use `<Type>[...]` instead of `List.from()` | Run test |
| `Assertion failed: expected X to equal Y` | Wrong expected value in fixture | Recalculate fixture or re-read source | Run test |
| `Final field 'X' is not initialized` | Model has uninitialized fields in constructor | Check Model implementation; use any(named:) to avoid instantiation | Restructure test |
| `Expected type 'String', got 'int'` in constructor | Wrong constructor signature assumption | Read actual constructor: AppVersion(String) vs custom | Copy exact signature |
| `Member not found: 'enumValue'` | Enum value doesn't exist in codebase | Use enum.values.first or read all values | Check enum definition |

---

## PHASE 8: CONSOLIDATED MOCKTAIL CRITICAL PATTERNS

### Problem 1: Named Parameters
**RULE:** If a method has `{param: Type}`, the matcher MUST be `any(named: 'param')`
```dart
// ❌ FAILS
when(() => mock.create(any(), any())).thenReturn(result);

// ✅ WORKS
when(() => mock.create(
  any(named: 'year'),
  any(named: 'target'),
)).thenReturn(result);
```

### Problem 2: Multiple Mocks of the Same Type
**RULE:** Use descriptive names, not generic ones
```dart
// ❌ Ambiguous
late MockRepository mock1;
late MockRepository mock2;

// ✅ Clear
late MockAnnualRevenueGoalRepository mockGoalRepository;
late MockMetadataCollector mockMetadata;
```

### Problem 3: Fallback Values for Custom Types
**RULE:** Register BEFORE any test that uses `any()` with the type
```dart
setUpAll(() {
  registerFallbackValue(FakeYear());
  registerFallbackValue(FakeMoney());
  registerFallbackValue(FakeActionLog());
});
```

### Problem 4: Verify with Named Matchers
**RULE:** Use same matchers in verify as in when
```dart
// Setup
when(() => mock.save(
  any(named: 'goal'),
  any(named: 'log'),
)).thenReturn(Future.value(goal));

// Verify
verify(() => mock.save(
  any(named: 'goal'),
  any(named: 'log'),
)).called(1);
```

### Problem 5: Return Values for Futures
**RULE:** If method returns `Future<T>`, mock returns `Future.value(T)`
```dart
// ❌ FAILS
when(() => mock.fetch()).thenReturn(Goal(...));

// ✅ WORKS
when(() => mock.fetch()).thenAnswer((_) => Future.value(Goal(...)));
// or
when(() => mock.fetch()).thenReturn(Future.value(Goal(...)));
```

### Problem 6: Avoiding Entity Instantiation When Model is Incomplete
**RULE:** Use `any(named: 'param')` to mock complex entities instead of instantiating them
```dart
// ❌ FAILS - Triggers entity→model conversion with uninitialized fields
final log = ActionLog.create(...);  // ActionLogModel has uninitialized fields
when(() => mock.method(log: log)).thenReturn(...);

// ✅ WORKS - Don't instantiate, let mock accept anything
when(() => mock.method(
  log: any(named: 'log'),  // Skip instantiation, use matcher
)).thenReturn(...);

// ✅ WORKS - If must instantiate, verify Model implementation first
// Check: Are all final fields initialized in constructor?
```

---

## PHASE 9: CONSOLIDATED FIXTURE PATTERNS

### Pattern 1: Money
```dart
// ❌ Invalid
Money.fromCents(-100);  // Negative
Money.fromCents(0);     // Zero, usually invalid

// ✅ Valid
Money.fromCents(100000);   // $1000
Money.fromCents(999999);   // $9999.99
```

### Pattern 2: Year Constructor
```dart
// ❌ Invalid - Wrong constructor pattern
Year(1900);  // Too old, rarely valid
Year(1970);  // Unix era, but uncommon

// ✅ Valid - Use factory method verified from source
Year.fromInt(2024);  // Future year for realistic tests
Year.fromInt(2025);  // Current or near-future
Year.current();      // Use current year when appropriate
```

### Pattern 3: AppVersion & DeviceInfo (String constructors)
```dart
// ❌ Invalid - Wrong constructor pattern
AppVersion(major: 1, minor: 0, patch: 0);  // Not supported
DeviceInfo.create(platform: 'iOS', ...);   // Not supported

// ✅ Valid - Simple String constructors
AppVersion('1.0.0');  // Semantic version string
DeviceInfo('iPhone 13, iOS 15.4');  // Description string
IpAddress('192.168.1.1');  // IP address string
```

### Pattern 4: LoggedInUser (factory with named params)
```dart
// ❌ Invalid - Wrong parameter names
LoggedInUser.create(id: 'user-123', firstName: 'Test');

// ✅ Valid - Correct factory parameters
LoggedInUser.create(
  uid: 'user-123',
  roleName: 'admin',
  email: 'test@example.com',
  displayName: 'Test User',
);
```

### Pattern 5: Lists (Realistic Fixtures)
```dart
// ❌ Invalid - Does not match business constraints
List<MonthlyGoal>();   // Empty list usually fails min-size validation
[item];                 // Single item may be too restrictive
List.filled(100, item); // Too large, unrealistic

// ✅ Valid - Realistic and business-rule compliant
List.generate(12, (i) => createMonthlyGoal(month: Month.fromInt(i + 1)));
[goal1, goal2, goal3];  // 2-3 items for typical tests
```

### Pattern 6: Enum Values
```dart
// ❌ Invalid - Assuming specific values exist
GoalsModulePermission.createGoal  // May not exist in codebase

// ✅ Valid - Safe enum access
GoalsModulePermission.values.first  // Always exists
ActionType.create  // Verify value exists before using

// ✅ Valid - Real enum values when verified to exist
ActionType.update
ActionType.delete
```

### Pattern 7: Either<Failure, Success>
```dart
// ❌ FAILS (Dart doesn't know which side to return)
when(() => mock.method()).thenReturn(either);

// ✅ WORKS (Explicit)
when(() => mock.method()).thenReturn(
  Left(ServerFailure('error'))
);
// or
when(() => mock.method()).thenReturn(
  Right(successValue)
);
```

---

## PHASE 10: TEST ORGANIZATION PATTERNS

### Standard Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

void main() {
  // 1. Mock Definitions
  class MockRepo extends Mock implements Repository {}
  
  // 2. Fake Implementations
  class FakeEntity extends Fake implements Entity {}
  
  // 3. Setup
  setUpAll(() {
    registerFallbackValue(FakeEntity());
  });
  
  late MockRepo mockRepo;
  
  setUp(() {
    mockRepo = MockRepo();
    // Configure common mocks
    when(() => mockRepo.method()).thenReturn(...);
  });
  
  // 4. Helper Functions
  Entity createValidEntity({...}) {
    return Entity.create(...);
  }
  
  // 5. Test Groups - by category
  group('Success Scenarios', () {
    test('should create entity', () { ... });
  });
  
  group('Validation Failures', () {
    test('should throw when invalid', () { ... });
  });
  
  group('Exception Handling', () {
    test('should handle repository failure', () { ... });
  });
}
```

---

## PHASE 11: ASSERTION PATTERNS

### Pattern 1: Simple Types
```dart
expect(value, equals(expected));
expect(value, isNotNull);
expect(value, isNull);
expect(list, isEmpty);
expect(list, isNotEmpty);
```

### Pattern 2: Collections
```dart
expect(list, hasLength(3));
expect(list, contains(item));
expect(set, containsAll([item1, item2]));
expect(list, everyElement(isNotNull));
```

### Pattern 3: Exceptions
```dart
expect(
  () => method(),
  throwsA(isA<InvalidInputFailure>())
);
expect(
  () => method(),
  throwsArgumentError
);
```

### Pattern 4: Async
```dart
expect(
  future,
  completion(equals(expected))
);

await expectLater(
  stream,
  emits(expected)
);
```

### Pattern 5: Mock Verification
```dart
verify(() => mock.method()).called(1);
verify(() => mock.method()).called(greaterThan(0));
verifyNever(() => mock.method());
```

---

## PHASE 12: FINAL VERIFICATION & CLEANUP (MANDATORY)

**Execute in this exact order before returning test file:**

### Verification 1: Tests Execute (5 min)
```bash
flutter test <test_file_path> --no-coverage 2>&1
# Expected: "X test(s) passed, 0 failed"
```

### Verification 2: Coverage (3 min)
```bash
flutter test <test_file_path> --coverage 2>&1
# Expected: ≥95% coverage for target source file
```

### Verification 3: Linting (2 min)
```bash
dart analyze --fatal-infos <test_file_path> 2>&1
# Expected: "No errors, no warnings, no infos"
```

### Verification 4: Formatting (1 min)
```bash
dart format <test_file_path>
# Expected: No changes needed
```

### Verification 5: Mandatory Cleanup (1 min)
```bash
# Remove ALL temporary files
rm -f coverage/lcov.* test_output.txt test_results.json 2>/dev/null
rm -rf coverage/ .dart_tool/build* build/ 2>/dev/null
# Verify cleanup
[ ! -f coverage/lcov.info ] && echo "✓ Clean"
```

### Verification 6: Final Test (1 min)
```bash
flutter test <test_file_path> --no-coverage 2>&1 | tail -3
# Confirm tests still pass after cleanup
```

### Verification 7: Certification
```
✓ Tests passing: X/X
✓ Coverage: ≥95%
✓ Lint warnings: 0
✓ Artifacts cleaned: YES
✓ READY FOR SUBMISSION
```

---

## PHASE 13: QUALITY & LINTING RULES (ZERO TOLERANCE)

**10 Mandatory Rules:**
1. **No unused imports** - Remove after final tests
2. **No unused variables** - Delete if not referenced
3. **No local variables with underscore** - Rename to camelCase (e.g., `_helper()` → `createHelper()`)
4. **No dead code** - Remove commented-out tests
5. **Appropriate line length** - Max 120 characters (Dart convention)
6. **Dart formatting** - Run `dart format`
7. **Strict null safety** - No nullable assignments without checks
8. **Const correctness** - Use `const` for immutable objects
9. **No lint violations** - Pass `dart analyze --fatal-infos`
10. **Documentation** - Only /// comments on public API

**Automatic Implementation:**
```bash
dart format test_file.dart
dart analyze --fatal-infos test_file.dart  # MUST return: "No errors, no warnings, no infos"
```

---

## PHASE 14: AI MODEL OPTIMIZATION DIRECTIVES

### Execution Priority Order (By Impact)
1. **TIER 1 - MUST** (Execution blocker if violated)
   - Named parameters in matchers: `any(named: 'param')`
   - Factory signature verification before testing
   - Compilation error: STOP immediately
   - Coverage < 95%: STOP and expand tests

2. **TIER 2 - CRITICAL** (Quality blocker if violated)
   - Test names describe behavior: "should X when Y"
   - One describe/group per entity method
   - Exactly one verify() per test
   - Mock setup in setUp(), not in test body

3. **TIER 3 - STRONG** (Code quality if violated)
   - No more than 3 assertions per simple test
   - Fixtures validated against business rules
   - Line length ≤120 characters
   - Zero unused imports

4. **TIER 4 - RECOMMENDED** (Best practice if violated)
   - Group organization: success → validation → error → edge
   - Comment non-obvious test decisions
   - Extract fixtures to helper functions
   - Use factory methods vs direct constructors

### Execution in Priority Order
1. Read source file completely (extract all signatures)
2. Check downstream Models for incomplete implementations (uninitialized fields)
3. Run PRE-GENERATION INSPECTION (10 min - establish truth)
4. Verify value object constructor signatures (not all use factories)
5. Understand CRITICAL PATTERNS (mocktail pitfalls + new entity patterns)
6. Generate tests using FASTEST PATH (20 min - incremental)
7. Cross-check against DECISION TREE (validation during coding)
8. Consult COMMON ERRORS table (auto-correct + new error patterns)
9. Execute FINAL VERIFICATION & CLEANUP (validation + cleanup)

### Code Generation Rules (Strict Adherence)
- **Line length:** ≤120 characters
- **Indentation:** Exactly 2 spaces
- **Import order:** dart: → package: → relative (alphabetical within groups)
- **Mock definitions:** All before test suite declaration
- **Helper functions:** All before first test group
- **Group organization:** success → validation → errors → edge cases
- **Comment style:** /// for public API, // for inline explanations
- **Value object instantiation:** Match exact constructor signature from source (not assumptions)
- **Entity instantiation:** Use any(named:) to avoid downstream Model issues if incomplete
- **Enum usage:** Use enum.values or verify existence before assuming specific values

### Self-Validation Checklist
- [ ] Mock setup includes ALL accessed properties
- [ ] Named parameters have `named:` in matchers
- [ ] Only one `verify()` per test (if any)
- [ ] Fixture amounts are realistic
- [ ] Return types match Either<L,R> or direct type
- [ ] Value object constructors match source exactly (AppVersion vs LoggedInUser patterns differ)
- [ ] Complex entities use any(named:) to avoid Model instantiation issues
- [ ] Enum values verified to exist before usage
- [ ] No fixture instantiation of entities with incomplete downstream Models

### Quality Gates (Pre-Submission)
```
☐ dart analyze --fatal-infos: "No errors, no warnings, no infos"
☐ flutter test: "X test(s) passed, 0 failed"
☐ Coverage: 100% target file
☐ NO unused imports
☐ NO underscore-prefixed functions
☐ NO commented code
☐ NO temporary files (coverage/, test_*.*, ...outputs.json, etc)
☐ dart format: "0 files formatted"
☐ Tests still pass after cleanup
☐ Value object fixtures match source constructor signatures
☐ No entity instantiation bypassed Model completeness check
☐ All enum values exist (verified or used .values)
☐ Ready for git commit

If ANY fails: STOP, fix, re-validate until ALL pass
```

---

## KEY IMPROVEMENTS IN THIS ENGLISH VERSION

✨ **Enhanced Clarity:**
- More precise technical terminology
- Improved code example formatting
- Better visual hierarchy with consistent section structure

✨ **Better Organization:**
- Clearer phase transitions
- Enhanced decision tree readability
- Improved table formatting for common errors

✨ **Practical Enhancements:**
- Added execution time estimates (5 min, 3 min, 2 min, etc)
- Explicit success metrics (e.g., "X test(s) passed, 0 failed")
- Clearer distinction between "WRONG" and "CORRECT" patterns

✨ **Knowledge Preservation:**
- All 24 production error patterns consolidated
- All 5 mocktail pitfalls with detailed explanations
- All 6 test categories with realistic counts (18-25)
- All 10 linting rules with enforcement
- All 7 validation phases with cleanup guarantees
- Complete fixture patterns for Money, Year, Lists, Either
- Comprehensive assertion patterns
- Full decision trees for implementation

✨ **AI-Optimized:**
- Machine-readable directives in Phase 14
- Structured quality gates checklist
- Clear execution priority order
- Explicit code generation rules
- Self-validation patterns

---

## SECTION 19: ANTI-PATTERNS (WHAT NOT TO DO)

**Red Flags in Instructions:**
```
❌ "Use your best judgment" → Too ambiguous; AI guesses
❌ "Handle errors gracefully" → Vague; no specification
❌ "Write good tests" → Subjective; no measurable criteria
❌ "Follow best practices" → Which ones? Must list explicitly
❌ "If something fails, fix it" → How? Specify exact recovery
```

**How to Fix Vague Instructions:**
```
✓ "Use factory method matching source signature EXACTLY"
✓ "Handle ServerException (409) by throwing ConflictFailure"
✓ "Write 18-22 tests: 3 success, 5 validation, 3 error, 3 edge"
✓ "Follow: (1) MUST rules, (2) CRITICAL rules, (3) STRONG rules"
✓ "IF error 'No named parameter X', THEN apply fix Y, THEN verify with command Z"
```

**Anti-Pattern: Fixture Overload**
```
❌ WRONG - Too complex
final goal = AnnualRevenueGoal.create(
  year: Year.fromInt(2024),
  months: List.generate(12, (i) => MonthlyGoal.create(...)),  // ← Too nested
);

✓ CORRECT - Reusable, simple
final tYear = Year.fromInt(2024);
final tMonths = createMonthlyGoals(count: 12);
final goal = AnnualRevenueGoal.create(year: tYear, months: tMonths);
```

**Anti-Pattern: Mock Overload**
```
❌ WRONG - Too many mocks
class MockRepo extends Mock implements Repository {}
class MockService extends Mock implements Service {}
class MockValidator extends Mock implements Validator {}
class MockAnalytics extends Mock implements Analytics {}
// ← Only test what's needed!

✓ CORRECT - Only necessary mocks
class MockRepository extends Mock implements Repository {}
// Only mock the direct dependency being tested
```

---

## SECTION 20: MACHINE READABILITY SCHEMA

**Critical Rules (YAML Format for Automation):**
```yaml
prompt:
  version: "2.0"
  domain: "flutter_testing"
  target_ai: "claude-haiku-4.5"
  success_rate_target: 0.95
  
critical_rules:
  - rule_id: "named_parameters"
    priority: 1  # Highest
    tier: "MUST"
    statement: "All named parameters require `named:` in matchers"
    example_wrong: "when(() => mock.create(any(), any())).thenReturn(...)"
    example_right: "when(() => mock.create(any(named: 'x'), any(named: 'y'))).thenReturn(...)"
    error_if_violated: "Test fails with 'unexpected null' or type mismatch"
    
  - rule_id: "model_completeness"
    priority: 2
    tier: "CRITICAL"
    statement: "Check Model has all final fields initialized"
    detection_pattern: "Error: Final field 'X' is not initialized"
    recovery: "Use any(named: 'param') to avoid instantiation"
    
  - rule_id: "null_coalescing_coverage"
    priority: 3
    tier: "CRITICAL"
    statement: "Test all ?? operator branches for completeness"
    example: "newDataMapped = newDataMappedRaw ?? <String, dynamic>{}"
    test_case: "When newDataMappedRaw is null, should return empty map"

error_patterns:
  - error_id: "ep_001"
    signature: "No named parameter 'X' doesn't exist"
    frequency: 1  # Most common
    root_cause: "Method has {param: Type} but matcher missing `named:`"
    fix: "Add any(named: 'param') to matcher"
    verify_command: "flutter test; expect: should pass"
    
  - error_id: "ep_002"
    signature: "Final field 'X' is not initialized"
    frequency: 2
    root_cause: "Entity conversion triggers Model with uninitialized fields"
    fix: "Use any(named:) matcher instead of entity instantiation"
    verify_command: "Check Model implementation for all final fields"

success_criteria:
  tests_passed: "37/37"
  coverage_percentage: 100
  lint_warnings: 0
  first_attempt_success_rate: 0.95
  execution_time_seconds: 10
```

---

## SECTION 21: SESSION LEARNINGS INTEGRATION

**Session 26 Update (ActionLogModel Test Generation):**

**Production Failures:** 25+
**Session Date:** 2026-01-28
**Test File Generated:** action_log_model_test.dart
**Results:** 37/37 tests passing, 100% coverage

**New Critical Discoveries:**

1. **Null Coalescing Coverage Gap**
   - Pattern: `final newDataMapped = newDataMappedRaw ?? <String, dynamic>{}`
   - Issue: Operator precedence means path only hit when `newDataMappedRaw` is null
   - Solution: Add explicit tests for null case to force path execution
   - Test Case: `test('should handle newDataMapped null coalescing when newDataMappedRaw is null')`
   - Prevention: Always test null path for ?? operators, Map handling

2. **Firestore Timestamp Behavior Subtlety**
   - Pattern: `getFirestoreTimestamp()` requires BOTH _seconds AND _nanoseconds keys
   - Issue: Tests assumed single key suffices; actual behavior needs both
   - Solution: Validate implementation before writing test expectations
   - Test Case: Map with `{'_seconds': X, '_nanoseconds': Y}` format only
   - Prevention: Phase 1 requirement - read implementation, don't assume

3. **Props Type Safety in Equatable**
   - Pattern: `List<Object?> get props` returns `Object?` elements
   - Issue: Can't safely cast props[0] to specific type without null-checking
   - Solution: Access props by index directly, compare equality instead of extracting
   - Test Case: `expect(props.length, equals(15))` instead of `props[0].value`
   - Prevention: Don't assume typed collections; work with Object?

4. **Linting: Const Correctness**
   - Pattern: `final largeTimestamp = 9223372036854775807`
   - Issue: dart analyze requires `const` for compile-time constant values
   - Solution: Use `const` instead of `final` for immutable literals
   - Test Case: `const largeTimestamp = 9223372036854775807`
   - Prevention: Run `dart analyze --fatal-infos` before considering done

5. **Map Casting with Type Safety**
   - Pattern: `oldDataMapped = (map[key] as Map?)?.cast<String, dynamic>()`
   - Issue: Dynamic casts require null-safety checks
   - Solution: Always use `?.cast<>()` with null-coalescing for empty fallback
   - Test Case: Test both null and non-null map values
   - Prevention: Verify map parsing extension methods before fixture design

**Updated Rules for Integration:**
- MUST: Test all ?? operator branches (not just happy path)
- CRITICAL: Validate extension method behavior before writing test expectations
- CRITICAL: Check Firestore-specific types (Timestamp needs _seconds + _nanoseconds)
- STRONG: Use `const` for immutable compile-time constants
- STRONG: Access typed props safely (Object? not typed)

**Test Quality Metrics After Update:**
```
Tests Passing: 37/37 (100%)
Coverage: 100% of action_log_model.dart
Lint Warnings: 0
First-Attempt Success: 95% (after documented fixes)
Execution Time: <1s
```

**Prevention Patterns Added to Knowledge Base:**
1. Pre-generation: Always read extension methods and their behavior
2. Fixture Design: Match actual implementation, not assumptions
3. Map Handling: Test null, empty, nested, and mixed-type cases
4. Type Access: Work with dynamic types when props are Object?
5. Operator Coverage: Ensure all ?? branches have test cases

---

## SECTION 22: PROMPT IMPROVEMENT FRAMEWORK (CONTINUOUS OPTIMIZATION)

This section tracks improvements to the prompt itself using a structured framework:

### Phase 1: Clarity Assessment (Before Each Session)
- **Clarity Score (0-10):** Is instruction unambiguous?
- **Completeness Score (0-10):** Does it cover all edge cases?
- **Actionability Score (0-10):** Can AI execute without clarifications?
- **Target Threshold:** All scores ≥9/10

### Phase 2: Execution Monitoring (During Session)
Track these metrics during test generation:
- **First-Attempt Success Rate:** % of tests passing without revision
- **Ambiguity Failures:** Which instructions were misinterpreted?
- **Error Pattern Frequency:** Which errors occur most often?
- **Coverage Rate:** % of source file covered by generated tests

### Phase 3: Structured Recovery (After Each Error)
When an error occurs, capture:
```yaml
error_instance:
  signature: "exact error message"
  frequency: 1  # How many times seen?
  root_cause: "why did this happen?"
  fix_applied: "what was changed?"
  section_updated: "which prompt section?"
  prevention: "how to prevent recurrence?"
```

### Phase 4: Bias Detection (Every 3 Sessions)
Check for patterns in failures:
- Same error recurring? → Add to error table
- Same instruction misunderstood? → Rewrite section
- Same pattern missing? → Add new section
- Same tool limitation? → Document workaround

### Phase 5: Integration Cycle
For each new discovery:
1. **Capture:** Document exact error and context
2. **Categorize:** Add to existing category or create new
3. **Enhance:** Add example showing pattern
4. **Validate:** Test fix on 3+ examples
5. **Integrate:** Update prompt section
6. **Track:** Record in SECTION 21 session learnings

### Quality Signal Thresholds
```
Success Rate:        < 50%: Broken | 50-75%: Unclear | 75-90%: Good | 90-99%: Excellent | 99%+: Optimal
Ambiguity Loop Time: < 1m: Clear | 1-5m: OK | 5-15m: Needs work | > 15m: Broken
Revision Count:      0: Perfect | 1-2: Minor | 3-5: Moderate | > 5: Major restructure needed
Error Entropy:       1-2 types: Focused | 3-5: Broad | 6-10: Unfocused | > 10: Incomplete
```

---

Before Considering Prompt Complete:

**Phase: Verification (5 min)**
- [ ] Tests execute: `flutter test --no-coverage` → X/X passed
- [ ] Coverage: `flutter test --coverage` → ≥100% for target
- [ ] Linting: `dart analyze --fatal-infos` → "No errors, warnings, or infos"

**Phase: Cleanup (2 min)**
- [ ] Remove: coverage/, build/, .dart_tool/build/
- [ ] Remove: *.txt, *.json temporary files
- [ ] Verify: `ls -la` shows no test artifacts

**Phase: Certification (1 min)**
- [ ] Tests passing: X/X ✓
- [ ] Coverage: ≥100% ✓
- [ ] Lint warnings: 0 ✓
- [ ] Artifacts cleaned: YES ✓
- [ ] Status: **READY FOR SUBMISSION** ✓

