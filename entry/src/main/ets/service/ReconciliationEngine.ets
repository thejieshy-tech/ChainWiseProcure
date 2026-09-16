import {
  demoProcurementDataSet,
  InvoiceRecord,
  PaymentRecord,
  ProcurementDataSet,
  PurchaseOrderRecord,
  ReceiptRecord
} from '../data/DemoProcurementData';

export interface ReconciliationIssue {
  type: string;
  title: string;
  detail: string;
  severity: string;
}

export interface TaskReconciliationResult {
  taskId: string;
  taskName: string;
  status: string;
  issues: ReconciliationIssue[];
}

export interface ReconciliationSummary {
  totalCount: number;
  differenceCount: number;
  completedCount: number;
  missingMaterialCount: number;
  aiConclusion: string;
}

export interface ReconciliationRunResult {
  summary: ReconciliationSummary;
  taskResults: TaskReconciliationResult[];
}

export function runReconciliation(
  input: ProcurementDataSet
): ReconciliationRunResult {
  const taskResults: TaskReconciliationResult[] = [];

  for (let orderIndex: number = 0; orderIndex < input.purchaseOrders.length; orderIndex++) {
    const order: PurchaseOrderRecord = input.purchaseOrders[orderIndex];
    let invoice: InvoiceRecord | undefined = undefined;
    let receipt: ReceiptRecord | undefined = undefined;
    let payment: PaymentRecord | undefined = undefined;

    for (let invoiceIndex: number = 0; invoiceIndex < input.invoices.length; invoiceIndex++) {
      if (input.invoices[invoiceIndex].taskId === order.taskId) {
        invoice = input.invoices[invoiceIndex];
        break;
      }
    }

    for (let receiptIndex: number = 0; receiptIndex < input.receipts.length; receiptIndex++) {
      if (input.receipts[receiptIndex].taskId === order.taskId) {
        receipt = input.receipts[receiptIndex];
        break;
      }
    }

    for (let paymentIndex: number = 0; paymentIndex < input.payments.length; paymentIndex++) {
      if (input.payments[paymentIndex].taskId === order.taskId) {
        payment = input.payments[paymentIndex];
        break;
      }
    }

    const issues: ReconciliationIssue[] = [];
    let hasMissingMaterial: boolean = false;

    if (invoice === undefined) {
      hasMissingMaterial = true;
      issues.push({
        type: 'missing_invoice',
        title: '缺少发票记录',
        detail: order.poNumber + ' 未找到对应发票记录',
        severity: '高'
      });
    }

    if (receipt === undefined) {
      hasMissingMaterial = true;
      issues.push({
        type: 'missing_receipt',
        title: '缺少收货记录',
        detail: order.poNumber + ' 未找到对应收货记录',
        severity: '高'
      });
    }

    if (payment === undefined) {
      hasMissingMaterial = true;
      issues.push({
        type: 'missing_payment',
        title: '缺少付款记录',
        detail: order.poNumber + ' 未找到对应付款记录',
        severity: '高'
      });
    }

    if (invoice !== undefined) {
      if (order.quantity !== invoice.quantity) {
        issues.push({
          type: 'invoice_quantity_difference',
          title: '发票数量差异',
          detail: '采购数量为' + order.quantity.toString() + '，发票数量为' + invoice.quantity.toString(),
          severity: '中'
        });
      }

      if (order.unitPrice !== invoice.unitPrice) {
        issues.push({
          type: 'invoice_unit_price_difference',
          title: '发票单价差异',
          detail: '采购单价为¥' + order.unitPrice.toString() + '，发票单价为¥' + invoice.unitPrice.toString(),
          severity: '中'
        });
      }

      if (order.totalAmount !== invoice.totalAmount) {
        issues.push({
          type: 'invoice_amount_difference',
          title: '发票金额差异',
          detail: '采购订单金额为¥' + order.totalAmount.toString() + '，发票金额为¥' + invoice.totalAmount.toString(),
          severity: '高'
        });
      }
    }

    if (receipt !== undefined && order.quantity !== receipt.receivedQuantity) {
      issues.push({
        type: 'receipt_quantity_difference',
        title: '收货数量差异',
        detail: '采购数量为' + order.quantity.toString() + '，收货数量为' + receipt.receivedQuantity.toString(),
        severity: '中'
      });
    }

    if (payment !== undefined && order.totalAmount !== payment.paidAmount) {
      issues.push({
        type: 'payment_amount_difference',
        title: '付款金额差异',
        detail: '采购订单金额为¥' + order.totalAmount.toString() + '，已付款金额为¥' + payment.paidAmount.toString(),
        severity: '高'
      });
    }

    let status: string = '已完成';
    if (hasMissingMaterial) {
      status = '待补充材料';
    } else if (issues.length > 0) {
      status = '存在差异';
    }

    taskResults.push({
      taskId: order.taskId,
      taskName: order.taskName,
      status: status,
      issues: issues
    });
  }

  let differenceCount: number = 0;
  let completedCount: number = 0;
  let missingMaterialCount: number = 0;

  for (let resultIndex: number = 0; resultIndex < taskResults.length; resultIndex++) {
    const taskResult: TaskReconciliationResult = taskResults[resultIndex];
    if (taskResult.status === '存在差异') {
      differenceCount = differenceCount + 1;
    } else if (taskResult.status === '已完成') {
      completedCount = completedCount + 1;
    } else if (taskResult.status === '待补充材料') {
      missingMaterialCount = missingMaterialCount + 1;
    }
  }

  const summary: ReconciliationSummary = {
    totalCount: taskResults.length,
    differenceCount: differenceCount,
    completedCount: completedCount,
    missingMaterialCount: missingMaterialCount,
    aiConclusion: ''
  };
  summary.aiConclusion = '系统基于采购订单、发票、收货和付款记录完成' +
    summary.totalCount.toString() + '条任务核验，发现' + summary.differenceCount.toString() +
    '条差异、' + summary.missingMaterialCount.toString() +
    '条材料不完整。建议优先处理高金额异常任务，并复核发票与付款凭证。';

  return {
    summary: summary,
    taskResults: taskResults
  };
}
export function runDemoReconciliation(): ReconciliationRunResult {
  return runReconciliation(demoProcurementDataSet);
}
