import {
  demoProcurementDataSet,
  InvoiceRecord,
  PaymentRecord,
  ProcurementDataSet,
  PurchaseOrderRecord,
  ReceiptRecord
} from './DemoProcurementData';

const importedPurchaseOrders: PurchaseOrderRecord[] = [
  {
    taskId: 'task-006',
    taskName: '7月笔记本电脑采购对账',
    poNumber: 'PO20260719001',
    supplier: '智联数码有限公司',
    itemName: '笔记本电脑',
    quantity: 20,
    unitPrice: 9800,
    totalAmount: 196000,
    createdDate: '2026-07-19'
  },
  {
    taskId: 'task-007',
    taskName: '网络设备采购对账',
    poNumber: 'PO20260719002',
    supplier: '云海网络科技有限公司',
    itemName: '交换机',
    quantity: 10,
    unitPrice: 6800,
    totalAmount: 68000,
    createdDate: '2026-07-19'
  },
  {
    taskId: 'task-008',
    taskName: '仓库扫码设备采购对账',
    poNumber: 'PO20260719003',
    supplier: '迅达智能设备有限公司',
    itemName: '扫码终端',
    quantity: 15,
    unitPrice: 4200,
    totalAmount: 63000,
    createdDate: '2026-07-19'
  },
  {
    taskId: 'task-009',
    taskName: '保洁用品采购对账',
    poNumber: 'PO20260719004',
    supplier: '清源日用品有限公司',
    itemName: '保洁套装',
    quantity: 100,
    unitPrice: 180,
    totalAmount: 18000,
    createdDate: '2026-07-19'
  },
  {
    taskId: 'task-010',
    taskName: '云服务年度费用对账',
    poNumber: 'PO20260719005',
    supplier: '星链云服务有限公司',
    itemName: '云服务',
    quantity: 1,
    unitPrice: 120000,
    totalAmount: 120000,
    createdDate: '2026-07-19'
  }
];

const importedInvoices: InvoiceRecord[] = [
  {
    invoiceId: 'INV20260719001',
    taskId: 'task-006',
    quantity: 20,
    unitPrice: 10000,
    totalAmount: 200000
  },
  {
    invoiceId: 'INV20260719002',
    taskId: 'task-007',
    quantity: 10,
    unitPrice: 6800,
    totalAmount: 68000
  },
  {
    invoiceId: 'INV20260719003',
    taskId: 'task-008',
    quantity: 15,
    unitPrice: 4200,
    totalAmount: 63000
  },
  {
    invoiceId: 'INV20260719005',
    taskId: 'task-010',
    quantity: 1,
    unitPrice: 120000,
    totalAmount: 120000
  }
];

const importedReceipts: ReceiptRecord[] = [
  {
    receiptId: 'REC20260719001',
    taskId: 'task-006',
    receivedQuantity: 20
  },
  {
    receiptId: 'REC20260719002',
    taskId: 'task-007',
    receivedQuantity: 10
  },
  {
    receiptId: 'REC20260719003',
    taskId: 'task-008',
    receivedQuantity: 12
  },
  {
    receiptId: 'REC20260719004',
    taskId: 'task-009',
    receivedQuantity: 100
  },
  {
    receiptId: 'REC20260719005',
    taskId: 'task-010',
    receivedQuantity: 1
  }
];

const importedPayments: PaymentRecord[] = [
  {
    paymentId: 'PAY20260719001',
    taskId: 'task-006',
    paidAmount: 196000
  },
  {
    paymentId: 'PAY20260719002',
    taskId: 'task-007',
    paidAmount: 60000
  },
  {
    paymentId: 'PAY20260719003',
    taskId: 'task-008',
    paidAmount: 63000
  },
  {
    paymentId: 'PAY20260719004',
    taskId: 'task-009',
    paidAmount: 18000
  }
];

export const importedProcurementDataSet: ProcurementDataSet = {
  metadata: {
    batchId: 'import-20260719',
    importedAt: '2026-07-19T10:30:00+08:00',
    sourceType: '内置导入批次',
    sourceName: '采购订单_20260719.xlsx',
    recordCount: importedPurchaseOrders.length
  },
  purchaseOrders: importedPurchaseOrders,
  invoices: importedInvoices,
  receipts: importedReceipts,
  payments: importedPayments
};

export const combinedProcurementDataSet: ProcurementDataSet = {
  metadata: {
    batchId: 'combined-20260719',
    importedAt: importedProcurementDataSet.metadata.importedAt,
    sourceType: '内置导入批次',
    sourceName: '基础采购数据 + 采购订单_20260719.xlsx',
    recordCount: demoProcurementDataSet.purchaseOrders.length +
      importedProcurementDataSet.purchaseOrders.length
  },
  purchaseOrders: demoProcurementDataSet.purchaseOrders.concat(
    importedProcurementDataSet.purchaseOrders
  ),
  invoices: demoProcurementDataSet.invoices.concat(importedProcurementDataSet.invoices),
  receipts: demoProcurementDataSet.receipts.concat(importedProcurementDataSet.receipts),
  payments: demoProcurementDataSet.payments.concat(importedProcurementDataSet.payments)
};

export function getProcurementDataSet(batchId: string): ProcurementDataSet {
  if (batchId === importedProcurementDataSet.metadata.batchId ||
    batchId === combinedProcurementDataSet.metadata.batchId) {
    return combinedProcurementDataSet;
  }
  return demoProcurementDataSet;
}
