export interface PurchaseOrderRecord {
  taskId: string;
  taskName: string;
  poNumber: string;
  supplier: string;
  itemName: string;
  quantity: number;
  unitPrice: number;
  totalAmount: number;
  createdDate: string;
}

export interface InvoiceRecord {
  invoiceId: string;
  taskId: string;
  quantity: number;
  unitPrice: number;
  totalAmount: number;
}

export interface ReceiptRecord {
  receiptId: string;
  taskId: string;
  receivedQuantity: number;
}

export interface PaymentRecord {
  paymentId: string;
  taskId: string;
  paidAmount: number;
}

export interface ImportBatchMetadata {
  batchId: string;
  importedAt: string;
  sourceType: string;
  sourceName: string;
  recordCount: number;
}

export interface ProcurementDataSet {
  metadata: ImportBatchMetadata;
  purchaseOrders: PurchaseOrderRecord[];
  invoices: InvoiceRecord[];
  receipts: ReceiptRecord[];
  payments: PaymentRecord[];
}

export const demoPurchaseOrders: PurchaseOrderRecord[] = [
  {
    taskId: 'task-001',
    taskName: '7月办公用品采购对账',
    poNumber: 'PO20260716001',
    supplier: '华东办公设备有限公司',
    itemName: '办公设备及耗材',
    quantity: 200,
    unitPrice: 634,
    totalAmount: 126800,
    createdDate: '2026-07-16'
  },
  {
    taskId: 'task-002',
    taskName: '服务器配件采购对账',
    poNumber: 'PO20260715008',
    supplier: '星云科技有限公司',
    itemName: '服务器配件',
    quantity: 20,
    unitPrice: 14300,
    totalAmount: 286000,
    createdDate: '2026-07-15'
  },
  {
    taskId: 'task-003',
    taskName: '员工工服采购对账',
    poNumber: 'PO20260714012',
    supplier: '优品服饰有限公司',
    itemName: '员工工服',
    quantity: 100,
    unitPrice: 586,
    totalAmount: 58600,
    createdDate: '2026-07-14'
  },
  {
    taskId: 'task-004',
    taskName: '仓储耗材采购对账',
    poNumber: 'PO20260713006',
    supplier: '联合包装有限公司',
    itemName: '仓储包装耗材',
    quantity: 200,
    unitPrice: 199,
    totalAmount: 39800,
    createdDate: '2026-07-13'
  },
  {
    taskId: 'task-005',
    taskName: '物流运输费用对账',
    poNumber: 'PO20260712003',
    supplier: '远航物流有限公司',
    itemName: '物流运输服务',
    quantity: 15,
    unitPrice: 5100,
    totalAmount: 76500,
    createdDate: '2026-07-12'
  }
];

export const demoInvoices: InvoiceRecord[] = [
  {
    invoiceId: 'INV20260716001',
    taskId: 'task-001',
    quantity: 198,
    unitPrice: 640,
    totalAmount: 126800
  },
  {
    invoiceId: 'INV20260715008',
    taskId: 'task-002',
    quantity: 20,
    unitPrice: 14300,
    totalAmount: 285000
  },
  {
    invoiceId: 'INV20260714012',
    taskId: 'task-003',
    quantity: 100,
    unitPrice: 586,
    totalAmount: 58600
  },
  {
    invoiceId: 'INV20260712003',
    taskId: 'task-005',
    quantity: 15,
    unitPrice: 5100,
    totalAmount: 76500
  }
];

export const demoReceipts: ReceiptRecord[] = [
  {
    receiptId: 'REC20260716001',
    taskId: 'task-001',
    receivedQuantity: 200
  },
  {
    receiptId: 'REC20260715008',
    taskId: 'task-002',
    receivedQuantity: 20
  },
  {
    receiptId: 'REC20260714012',
    taskId: 'task-003',
    receivedQuantity: 100
  },
  {
    receiptId: 'REC20260712003',
    taskId: 'task-005',
    receivedQuantity: 15
  }
];

export const demoPayments: PaymentRecord[] = [
  {
    paymentId: 'PAY20260716001',
    taskId: 'task-001',
    paidAmount: 120000
  },
  {
    paymentId: 'PAY20260715008',
    taskId: 'task-002',
    paidAmount: 286000
  },
  {
    paymentId: 'PAY20260714012',
    taskId: 'task-003',
    paidAmount: 58600
  },
  {
    paymentId: 'PAY20260713006',
    taskId: 'task-004',
    paidAmount: 39800
  },
  {
    paymentId: 'PAY20260712003',
    taskId: 'task-005',
    paidAmount: 76500
  }
];
export const demoProcurementDataSet: ProcurementDataSet = {
  metadata: {
    batchId: 'demo-base',
    importedAt: '2026-07-12T09:00:00+08:00',
    sourceType: '内置演示数据',
    sourceName: '基础采购数据',
    recordCount: demoPurchaseOrders.length
  },
  purchaseOrders: demoPurchaseOrders,
  invoices: demoInvoices,
  receipts: demoReceipts,
  payments: demoPayments
};
