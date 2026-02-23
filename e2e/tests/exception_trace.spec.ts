import {
  test,
  expect,
  findClearTracesButton,
  findSwitchTracingButton,
  findFiltersButton,
  Page,
} from './dev-dbg-test';

const findTraces = (page: Page) =>
  page.locator('#global-traces-stream details');

const findGlobalCallbackTracesButton = (page: Page) =>
  page.locator('#global-traces-navbar-item a');

const findNodeInspectorButton = (page: Page) =>
  page.locator('#node-inspector-navbar-item a');

const findCrashModule = (page: Page) =>
  page.locator(
    `button[phx-value-module="Elixir.LiveDebuggerDev.LiveComponents.Crash"]`
  );

const findHandleEventFilterCheckbox = (page: Page, type: string) =>
  page.locator(`input[id="filters-${type}-form_handle_event/3"]`);

const findApplyButton = (page: Page) =>
  page.getByRole('button', { name: 'Apply', exact: true });

const findErrorButton = (page: Page, action: string) =>
  page.locator(`button[phx-click="${action}"]`);

const fillSearchInput = async (page: Page, text: string) => {
  const input = page.locator('#trace-search-input');
  await input.fill(text);
};

const assertTraceException = async (
  dbgApp: Page,
  errorName: string,
  stacktraceContent: string
) => {
  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(1);
  const trace = traces.first();
  await trace.locator('summary').click();

  await expect(trace.locator('summary.bg-error-bg')).toBeVisible();
  await expect(trace.locator('summary .text-error-text')).toContainText(
    errorName
  );

  await trace.locator('label', { hasText: 'Stacktrace' }).click();
  await expect(trace.getByTestId('stacktrace')).toContainText(
    stacktraceContent
  );

  await trace.getByText('Raw Error').click();
  await expect(trace.getByTestId('raw_error')).toContainText(errorName);
  await expect(trace.getByTestId('raw_error')).toContainText('terminating');
};

const navigateToNewProcess = async (dbgApp: Page) => {
  await dbgApp.getByRole('button', { name: 'Continue' }).click();

  await findGlobalCallbackTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
};

const testException = async (
  devApp: Page,
  dbgApp: Page,
  crashName: string,
  errorName: string,
  stacktraceContent: string
) => {
  await test.step(`Testing exception: ${crashName}`, async () => {
    await findErrorButton(devApp, crashName).click();
    await assertTraceException(dbgApp, errorName, stacktraceContent);
    await navigateToNewProcess(dbgApp);
  });
};

test('debugger captures runtime errors and exceptions in global callbacks 1', async ({
  devApp,
  dbgApp,
}) => {
  await findGlobalCallbackTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();

  const exceptions: [string, string, string][] = [
    ['crash_argument', 'ArgumentError', 'invalid_integer'],
    ['crash_match', 'MatchError', 'dev/live_components/crash'],
    ['crash_case', 'CaseClauseError', 'dev/live_components/crash'],
    ['crash_exit', ':exit_reason', '(Stacktrace not available)'],
  ];

  for (const [crashName, errorName, stacktraceContent] of exceptions) {
    await testException(
      devApp,
      dbgApp,
      crashName,
      errorName,
      stacktraceContent
    );
  }
});

test('debugger captures runtime errors and exceptions in global callbacks 2', async ({
  devApp,
  dbgApp,
}) => {
  await findGlobalCallbackTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();

  const exceptions: [string, string, string][] = [
    [
      'crash_throw',
      '{:bad_return_value, :throw_value}',
      '(Stacktrace not available)',
    ],
    [
      'crash_function_clause',
      'FunctionClauseError',
      'private_function(:error)',
    ],
    [
      'crash_undefined',
      'UndefinedFunctionError',
      'this_function_does_not_exist',
    ],
    ['crash_arithmetic', 'ArithmeticError', 'dev/live_components/crash'],
  ];

  for (const [crashName, errorName, stacktraceContent] of exceptions) {
    await testException(
      devApp,
      dbgApp,
      crashName,
      errorName,
      stacktraceContent
    );
  }
});

test('debugger captures runtime errors and exceptions in global callbacks 3', async ({
  devApp,
  dbgApp,
}) => {
  await findGlobalCallbackTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();

  const exceptions: [string, string, string][] = [
    ['crash_linked', 'RuntimeError', 'dev/live_components/crash'],
    ['crash_protocol', 'Protocol.UndefinedError', 'dev/live_components/crash'],
    ['crash_key', 'KeyError', 'dev/live_components/crash'],
    ['crash_bad_return', 'ArgumentError', 'lib/phoenix_live_view/channel'],
  ];

  for (const [crashName, errorName, stacktraceContent] of exceptions) {
    await testException(
      devApp,
      dbgApp,
      crashName,
      errorName,
      stacktraceContent
    );
  }
});

test.describe('exception appears in currently inspected node', () => {
  test('should not show flash message during crash of currently inspected node', async ({
    devApp,
    dbgApp,
  }) => {
    await findNodeInspectorButton(dbgApp).click();
    await findCrashModule(dbgApp).click();
    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).not.toBeVisible();
  });
  test('should show flash message when exception trace is hidden by active filters', async ({
    devApp,
    dbgApp,
  }) => {
    await findNodeInspectorButton(dbgApp).click();
    await findCrashModule(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await findFiltersButton(dbgApp).click();
    await findHandleEventFilterCheckbox(dbgApp, 'fullscreen').click();
    await findApplyButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();

    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).toBeVisible();
    await expect(flash).toContainText('LiveComponent crashed.');
    await expect(flash).toContainText('LiveDebuggerDev.LiveComponents.Crash');
    await expect(flash).toContainText('Open in Node Inspector');
  });

  test('should show flash message when exception trace is hidden by active search phrase', async ({
    devApp,
    dbgApp,
  }) => {
    await findNodeInspectorButton(dbgApp).click();
    await findCrashModule(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await fillSearchInput(dbgApp, '123456789');
    await findSwitchTracingButton(dbgApp).click();
    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).toBeVisible();
    await expect(flash).toContainText('LiveComponent crashed.');
    await expect(flash).toContainText('LiveDebuggerDev.LiveComponents.Crash');
    await expect(flash).toContainText('Open in Node Inspector');
  });
});

test('should show flash message when a non-inspected node crashes', async ({
  devApp,
  dbgApp,
}) => {
  await findNodeInspectorButton(dbgApp).click();
  await findErrorButton(devApp, 'crash_argument').click();

  const flash = dbgApp.locator('#flash-error');
  await expect(flash).toBeVisible();
  await expect(flash).toContainText('LiveComponent crashed.');
  await expect(flash).toContainText('LiveDebuggerDev.LiveComponents.Crash');
  await expect(flash).toContainText('Open in Node Inspector');
});

test.describe('exception inspected in global callbacks', () => {
  test('should not show flash when no filter and no search phrase are applied', async ({
    devApp,
    dbgApp,
  }) => {
    await findGlobalCallbackTracesButton(dbgApp).click();

    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).not.toBeVisible();
  });

  test('should show flash message when exception trace is hidden by active filters', async ({
    devApp,
    dbgApp,
  }) => {
    await findGlobalCallbackTracesButton(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await findHandleEventFilterCheckbox(dbgApp, 'sidebar').click();
    await findApplyButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).toBeVisible();
    await expect(flash).toContainText('LiveComponent crashed.');
    await expect(flash).toContainText('LiveDebuggerDev.LiveComponents.Crash');
    await expect(flash).toContainText('Open in Node Inspector');
  });

  test('should show flash message when exception trace is hidden by active search phrase', async ({
    devApp,
    dbgApp,
  }) => {
    await findGlobalCallbackTracesButton(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await fillSearchInput(dbgApp, '123456789');
    await findSwitchTracingButton(dbgApp).click();
    await findErrorButton(devApp, 'crash_argument').click();

    const flash = dbgApp.locator('#flash-error');
    await expect(flash).toBeVisible();
    await expect(flash).toContainText('LiveComponent crashed.');
    await expect(flash).toContainText('LiveDebuggerDev.LiveComponents.Crash');
    await expect(flash).toContainText('Open in Node Inspector');
  });
});
