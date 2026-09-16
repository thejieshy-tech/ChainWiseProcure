import {
  ImportBatchMetadata,
  InvoiceRecord,
  PaymentRecord,
  ProcurementDataSet,
  PurchaseOrderRecord,
  ReceiptRecord
} from '../data/DemoProcurementData';

export interface CsvParseError {
  line: number;
  field: string;
  message: string;
}

export interface CsvParseResult {
  success: boolean;
  dataSet?: ProcurementDataSet;
  errors: CsvParseError[];
}

interface CsvRawRow {
  line: number;
  cells: string[];
}

interface CsvRowsParseResult {
  rows: CsvRawRow[];
  errors: CsvParseError[];
}

const PROCUREMENT_CSV_HEADERS: string[] = [
  'taskId',
  'taskName',
  'poNumber',
  'supplier',
  'itemName',
  'orderQuantity',
  'orderUnitPrice',
  'orderTotalAmount',
  'createdDate',
  'invoiceId',
  'invoiceQuantity',
  'invoiceUnitPrice',
  'invoiceTotalAmount',
  'receiptId',
  'receivedQuantity',
  'paymentId',
  'paidAmount'
];

function appendError(
  errors: CsvParseError[],
  line: number,
  field: string,
  message: string
): void {
  const error: CsvParseError = {
    line: line,
    field: field,
    message: message
  };
  errors.push(error);
}

function appendRawRow(rows: CsvRawRow[], line: number, cells: string[]): void {
  const row: CsvRawRow = {
    line: line,
    cells: cells
  };
  rows.push(row);
}

function isBlankRow(row: CsvRawRow): boolean {
  for (let index: number = 0; index < row.cells.length; index++) {
    if (row.cells[index].trim() !== '') {
      return false;
    }
  }
  return true;
}

function parseCsvRows(csvText: string): CsvRowsParseResult {
  let normalizedText: string = csvText;
  if (normalizedText.length > 0 && normalizedText.charCodeAt(0) === 0xFEFF) {
    normalizedText = normalizedText.substring(1);
  }

  const rows: CsvRawRow[] = [];
  const errors: CsvParseError[] = [];
  let cells: string[] = [];
  let cell: string = '';
  let inQuotes: boolean = false;
  let quoteClosed: boolean = false;
  let currentLine: number = 1;
  let rowStartLine: number = 1;

  for (let index: number = 0; index < normalizedText.length; index++) {
    const current: string = normalizedText.charAt(index);
    const isCarriageReturn: boolean = current === '\r';
    const isLineFeed: boolean = current === '\n';

    if (inQuotes) {
      if (current === '"') {
        if (index + 1 < normalizedText.length &&
          normalizedText.charAt(index + 1) === '"') {
          cell = cell + '"';
          index = index + 1;
        } else {
          inQuotes = false;
          quoteClosed = true;
        }
      } else if (isCarriageReturn || isLineFeed) {
        if (isCarriageReturn && index + 1 < normalizedText.length &&
          normalizedText.charAt(index + 1) === '\n') {
          index = index + 1;
        }
        cell = cell + '\n';
        currentLine = currentLine + 1;
      } else {
        cell = cell + current;
      }
      continue;
    }

    if (quoteClosed) {
      if (current === ',') {
        cells.push(cell);
        cell = '';
        quoteClosed = false;
        continue;
      }
      if (isCarriageReturn || isLineFeed) {
        if (isCarriageReturn && index + 1 < normalizedText.length &&
          normalizedText.charAt(index + 1) === '\n') {
          index = index + 1;
        }
        cells.push(cell);
        appendRawRow(rows, rowStartLine, cells);
        cells = [];
        cell = '';
        quoteClosed = false;
        currentLine = currentLine + 1;
        rowStartLine = currentLine;
        continue;
      }
      if (current === ' ' || current === '\t') {
        continue;
      }
      appendError(errors, currentLine, 'CSV', '双引号结束后只能出现逗号或换行');
      quoteClosed = false;
      cell = cell + current;
      continue;
    }

    if (current === '"') {
      if (cell.length === 0) {
        inQuotes = true;
      } else {
        appendError(errors, currentLine, 'CSV', '双引号必须位于单元格开头');
        cell = cell + current;
      }
      continue;
    }

    if (current === ',') {
      cells.push(cell);
      cell = '';
      continue;
    }

    if (isCarriageReturn || isLineFeed) {
      if (isCarriageReturn && index + 1 < normalizedText.length &&
        normalizedText.charAt(index + 1) === '\n') {
        index = index + 1;
      }
      cells.push(cell);
      appendRawRow(rows, rowStartLine, cells);
      cells = [];
      cell = '';
      currentLine = currentLine + 1;
      rowStartLine = currentLine;
      continue;
    }

    cell = cell + current;
  }

  if (inQuotes) {
    appendError(errors, rowStartLine, 'CSV', '双引号包裹的单元格未正确闭合');
  }

  if (cells.length > 0 || cell.length > 0) {
    cells.push(cell);
    appendRawRow(rows, rowStartLine, cells);
  }

  while (rows.length > 0 && isBlankRow(rows[rows.length - 1])) {
    rows.pop();
  }

  const result: CsvRowsParseResult = {
    rows: rows,
    errors: errors
  };
  return result;
}

function normalizeHeaders(headerRow: CsvRawRow): string[] {
  const headers: string[] = [];
  for (let index: number = 0; index < headerRow.cells.length; index++) {
    headers.push(headerRow.cells[index].trim());
  }
  return headers;
}

function isExpectedHeader(header: string): boolean {
  for (let index: number = 0; index < PROCUREMENT_CSV_HEADERS.length; index++) {
    if (PROCUREMENT_CSV_HEADERS[index] === header) {
      return true;
    }
  }
  return false;
}

function validateHeaders(
  headers: string[],
  line: number,
  errors: CsvParseError[]
): boolean {
  const initialErrorCount: number = errors.length;

  for (let expectedIndex: number = 0;
    expectedIndex < PROCUREMENT_CSV_HEADERS.length;
    expectedIndex++) {
    const expectedHeader: string = PROCUREMENT_CSV_HEADERS[expectedIndex];
    let occurrenceCount: number = 0;

    for (let actualIndex: number = 0; actualIndex < headers.length; actualIndex++) {
      if (headers[actualIndex] === expectedHeader) {
        occurrenceCount = occurrenceCount + 1;
      }
    }

    if (occurrenceCount === 0) {
      appendError(errors, line, expectedHeader, '缺少必需表头');
    } else if (occurrenceCount > 1) {
      appendError(errors, line, expectedHeader, '表头重复');
    }
  }

  for (let actualIndex: number = 0; actualIndex < headers.length; actualIndex++) {
    const actualHeader: string = headers[actualIndex];
    if (!isExpectedHeader(actualHeader)) {
      appendError(errors, line, actualHeader === '' ? 'header' : actualHeader, '存在不支持的表头');
    }
  }

  return errors.length === initialErrorCount;
}

function getHeaderIndex(headers: string[], field: string): number {
  for (let index: number = 0; index < headers.length; index++) {
    if (headers[index] === field) {
      return index;
    }
  }
  return -1;
}

function getCellValue(row: CsvRawRow, headers: string[], field: string): string {
  const fieldIndex: number = getHeaderIndex(headers, field);
  if (fieldIndex < 0 || fieldIndex >= row.cells.length) {
    return '';
  }
  return row.cells[fieldIndex].trim();
}

function validateRequiredText(
  value: string,
  line: number,
  field: string,
  errors: CsvParseError[]
): void {
  if (value === '') {
    appendError(errors, line, field, '必填字段不能为空');
  }
}

function parseNonNegativeNumber(
  value: string,
  line: number,
  field: string,
  required: boolean,
  errors: CsvParseError[]
): number | undefined {
  if (value === '') {
    if (required) {
      appendError(errors, line, field, '数值字段必须填写');
    }
    return undefined;
  }

  const parsedValue: number = Number(value);
  if (Number.isNaN(parsedValue) || !Number.isFinite(parsedValue) || parsedValue < 0) {
    appendError(errors, line, field, '必须为有效非负数字');
    return undefined;
  }
  return parsedValue;
}

function createFailureResult(errors: CsvParseError[]): CsvParseResult {
  const result: CsvParseResult = {
    success: false,
    errors: errors
  };
  return result;
}

export function parseProcurementCsv(
  csvText: string,
  batchId: string,
  sourceName: string
): CsvParseResult {
  const rowsResult: CsvRowsParseResult = parseCsvRows(csvText);
  const errors: CsvParseError[] = rowsResult.errors;

  if (rowsResult.rows.length === 0) {
    appendError(errors, 1, 'CSV', 'CSV内容为空');
    return createFailureResult(errors);
  }

  const headerRow: CsvRawRow = rowsResult.rows[0];
  const headers: string[] = normalizeHeaders(headerRow);
  const headersValid: boolean = validateHeaders(headers, headerRow.line, errors);
  if (!headersValid) {
    return createFailureResult(errors);
  }

  const purchaseOrders: PurchaseOrderRecord[] = [];
  const invoices: InvoiceRecord[] = [];
  const receipts: ReceiptRecord[] = [];
  const payments: PaymentRecord[] = [];
  const seenTaskIds: string[] = [];

  for (let rowIndex: number = 1; rowIndex < rowsResult.rows.length; rowIndex++) {
    const row: CsvRawRow = rowsResult.rows[rowIndex];
    const rowErrorStart: number = errors.length;

    if (row.cells.length !== headers.length) {
      appendError(
        errors,
        row.line,
        'CSV',
        '字段数量与表头不一致，应为' + headers.length.toString() + '列'
      );
    }

    const taskId: string = getCellValue(row, headers, 'taskId');
    const taskName: string = getCellValue(row, headers, 'taskName');
    const poNumber: string = getCellValue(row, headers, 'poNumber');
    const supplier: string = getCellValue(row, headers, 'supplier');
    const itemName: string = getCellValue(row, headers, 'itemName');
    const orderQuantityText: string = getCellValue(row, headers, 'orderQuantity');
    const orderUnitPriceText: string = getCellValue(row, headers, 'orderUnitPrice');
    const orderTotalAmountText: string = getCellValue(row, headers, 'orderTotalAmount');
    const createdDate: string = getCellValue(row, headers, 'createdDate');

    validateRequiredText(taskId, row.line, 'taskId', errors);
    validateRequiredText(taskName, row.line, 'taskName', errors);
    validateRequiredText(poNumber, row.line, 'poNumber', errors);
    validateRequiredText(supplier, row.line, 'supplier', errors);
    validateRequiredText(itemName, row.line, 'itemName', errors);
    validateRequiredText(createdDate, row.line, 'createdDate', errors);

    if (taskId !== '') {
      if (seenTaskIds.indexOf(taskId) >= 0) {
        appendError(errors, row.line, 'taskId', 'taskId不得重复');
      } else {
        seenTaskIds.push(taskId);
      }
    }

    const orderQuantity: number | undefined = parseNonNegativeNumber(
      orderQuantityText,
      row.line,
      'orderQuantity',
      true,
      errors
    );
    const orderUnitPrice: number | undefined = parseNonNegativeNumber(
      orderUnitPriceText,
      row.line,
      'orderUnitPrice',
      true,
      errors
    );
    const orderTotalAmount: number | undefined = parseNonNegativeNumber(
      orderTotalAmountText,
      row.line,
      'orderTotalAmount',
      true,
      errors
    );

    const invoiceId: string = getCellValue(row, headers, 'invoiceId');
    const invoiceQuantityText: string = getCellValue(row, headers, 'invoiceQuantity');
    const invoiceUnitPriceText: string = getCellValue(row, headers, 'invoiceUnitPrice');
    const invoiceTotalAmountText: string = getCellValue(row, headers, 'invoiceTotalAmount');
    const hasInvoiceGroup: boolean = invoiceId !== '' ||
      invoiceQuantityText !== '' ||
      invoiceUnitPriceText !== '' ||
      invoiceTotalAmountText !== '';
    let invoiceQuantity: number | undefined = undefined;
    let invoiceUnitPrice: number | undefined = undefined;
    let invoiceTotalAmount: number | undefined = undefined;

    if (hasInvoiceGroup) {
      validateRequiredText(invoiceId, row.line, 'invoiceId', errors);
      invoiceQuantity = parseNonNegativeNumber(
        invoiceQuantityText,
        row.line,
        'invoiceQuantity',
        true,
        errors
      );
      invoiceUnitPrice = parseNonNegativeNumber(
        invoiceUnitPriceText,
        row.line,
        'invoiceUnitPrice',
        true,
        errors
      );
      invoiceTotalAmount = parseNonNegativeNumber(
        invoiceTotalAmountText,
        row.line,
        'invoiceTotalAmount',
        true,
        errors
      );
    }

    const receiptId: string = getCellValue(row, headers, 'receiptId');
    const receivedQuantityText: string = getCellValue(row, headers, 'receivedQuantity');
    const hasReceiptGroup: boolean = receiptId !== '' || receivedQuantityText !== '';
    let receivedQuantity: number | undefined = undefined;

    if (hasReceiptGroup) {
      validateRequiredText(receiptId, row.line, 'receiptId', errors);
      receivedQuantity = parseNonNegativeNumber(
        receivedQuantityText,
        row.line,
        'receivedQuantity',
        true,
        errors
      );
    }

    const paymentId: string = getCellValue(row, headers, 'paymentId');
    const paidAmountText: string = getCellValue(row, headers, 'paidAmount');
    const hasPaymentGroup: boolean = paymentId !== '' || paidAmountText !== '';
    let paidAmount: number | undefined = undefined;

    if (hasPaymentGroup) {
      validateRequiredText(paymentId, row.line, 'paymentId', errors);
      paidAmount = parseNonNegativeNumber(
        paidAmountText,
        row.line,
        'paidAmount',
        true,
        errors
      );
    }

    if (errors.length !== rowErrorStart ||
      taskId === '' ||
      taskName === '' ||
      poNumber === '' ||
      supplier === '' ||
      itemName === '' ||
      createdDate === '' ||
      orderQuantity === undefined ||
      orderUnitPrice === undefined ||
      orderTotalAmount === undefined) {
      continue;
    }

    const purchaseOrder: PurchaseOrderRecord = {
      taskId: taskId,
      taskName: taskName,
      poNumber: poNumber,
      supplier: supplier,
      itemName: itemName,
      quantity: orderQuantity,
      unitPrice: orderUnitPrice,
      totalAmount: orderTotalAmount,
      createdDate: createdDate
    };
    purchaseOrders.push(purchaseOrder);

    if (invoiceId !== '' &&
      invoiceQuantity !== undefined &&
      invoiceUnitPrice !== undefined &&
      invoiceTotalAmount !== undefined) {
      const invoice: InvoiceRecord = {
        invoiceId: invoiceId,
        taskId: taskId,
        quantity: invoiceQuantity,
        unitPrice: invoiceUnitPrice,
        totalAmount: invoiceTotalAmount
      };
      invoices.push(invoice);
    }

    if (receiptId !== '' && receivedQuantity !== undefined) {
      const receipt: ReceiptRecord = {
        receiptId: receiptId,
        taskId: taskId,
        receivedQuantity: receivedQuantity
      };
      receipts.push(receipt);
    }

    if (paymentId !== '' && paidAmount !== undefined) {
      const payment: PaymentRecord = {
        paymentId: paymentId,
        taskId: taskId,
        paidAmount: paidAmount
      };
      payments.push(payment);
    }
  }

  if (errors.length > 0) {
    return createFailureResult(errors);
  }

  const metadata: ImportBatchMetadata = {
    batchId: batchId,
    importedAt: '2026-07-19T12:00:00+08:00',
    sourceType: 'CSV文本导入',
    sourceName: sourceName,
    recordCount: purchaseOrders.length
  };
  const dataSet: ProcurementDataSet = {
    metadata: metadata,
    purchaseOrders: purchaseOrders,
    invoices: invoices,
    receipts: receipts,
    payments: payments
  };
  const result: CsvParseResult = {
    success: true,
    dataSet: dataSet,
    errors: errors
  };
  return result;
}
