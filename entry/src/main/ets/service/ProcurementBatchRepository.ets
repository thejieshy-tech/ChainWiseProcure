import {
  ImportBatchMetadata,
  InvoiceRecord,
  PaymentRecord,
  ProcurementDataSet,
  PurchaseOrderRecord,
  ReceiptRecord
} from '../data/DemoProcurementData';
import { getProcurementDataSet } from '../data/ImportedProcurementData';

function cloneProcurementDataSet(dataSet: ProcurementDataSet): ProcurementDataSet {
  const metadata: ImportBatchMetadata = {
    batchId: dataSet.metadata.batchId,
    importedAt: dataSet.metadata.importedAt,
    sourceType: dataSet.metadata.sourceType,
    sourceName: dataSet.metadata.sourceName,
    recordCount: dataSet.metadata.recordCount
  };
  const purchaseOrders: PurchaseOrderRecord[] = [];
  const invoices: InvoiceRecord[] = [];
  const receipts: ReceiptRecord[] = [];
  const payments: PaymentRecord[] = [];

  for (let index: number = 0; index < dataSet.purchaseOrders.length; index++) {
    const source: PurchaseOrderRecord = dataSet.purchaseOrders[index];
    const purchaseOrder: PurchaseOrderRecord = {
      taskId: source.taskId,
      taskName: source.taskName,
      poNumber: source.poNumber,
      supplier: source.supplier,
      itemName: source.itemName,
      quantity: source.quantity,
      unitPrice: source.unitPrice,
      totalAmount: source.totalAmount,
      createdDate: source.createdDate
    };
    purchaseOrders.push(purchaseOrder);
  }

  for (let index: number = 0; index < dataSet.invoices.length; index++) {
    const source: InvoiceRecord = dataSet.invoices[index];
    const invoice: InvoiceRecord = {
      invoiceId: source.invoiceId,
      taskId: source.taskId,
      quantity: source.quantity,
      unitPrice: source.unitPrice,
      totalAmount: source.totalAmount
    };
    invoices.push(invoice);
  }

  for (let index: number = 0; index < dataSet.receipts.length; index++) {
    const source: ReceiptRecord = dataSet.receipts[index];
    const receipt: ReceiptRecord = {
      receiptId: source.receiptId,
      taskId: source.taskId,
      receivedQuantity: source.receivedQuantity
    };
    receipts.push(receipt);
  }

  for (let index: number = 0; index < dataSet.payments.length; index++) {
    const source: PaymentRecord = dataSet.payments[index];
    const payment: PaymentRecord = {
      paymentId: source.paymentId,
      taskId: source.taskId,
      paidAmount: source.paidAmount
    };
    payments.push(payment);
  }

  const clonedDataSet: ProcurementDataSet = {
    metadata: metadata,
    purchaseOrders: purchaseOrders,
    invoices: invoices,
    receipts: receipts,
    payments: payments
  };
  return clonedDataSet;
}

export class ProcurementBatchRepository {
  private csvDataSet: ProcurementDataSet | null = null;

  saveCsvDataSet(dataSet: ProcurementDataSet): void {
    this.csvDataSet = cloneProcurementDataSet(dataSet);
  }

  getCsvDataSet(batchId: string): ProcurementDataSet | null {
    if (this.csvDataSet === null || this.csvDataSet.metadata.batchId !== batchId) {
      return null;
    }
    return cloneProcurementDataSet(this.csvDataSet);
  }

  clearCsvDataSet(): void {
    this.csvDataSet = null;
  }
}

export const procurementBatchRepository: ProcurementBatchRepository =
  new ProcurementBatchRepository();

export function resolveProcurementDataSet(
  batchId: string
): ProcurementDataSet | null {
  if (batchId.startsWith('csv-')) {
    return procurementBatchRepository.getCsvDataSet(batchId);
  }
  return getProcurementDataSet(batchId);
}
