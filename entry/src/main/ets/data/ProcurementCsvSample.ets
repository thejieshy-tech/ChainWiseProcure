export const validProcurementCsvSample: string =
  '\uFEFFtaskId,taskName,poNumber,supplier,itemName,orderQuantity,orderUnitPrice,' +
  'orderTotalAmount,createdDate,invoiceId,invoiceQuantity,invoiceUnitPrice,' +
  'invoiceTotalAmount,receiptId,receivedQuantity,paymentId,paidAmount\r\n' +
  'csv-task-001,"7月电脑采购,发票核对",PO20260720001,智联数码有限公司,' +
  '"笔记本电脑 ""商务版""",20,9800,196000,2026-07-20,INV20260720001,' +
  '20,9800,195000,REC20260720001,20,PAY20260720001,196000\r\n' +
  'csv-task-002,网络设备采购对账,PO20260720002,云海网络科技有限公司,交换机,' +
  '10,6800,68000,2026-07-20,INV20260720002,10,6800,68000,' +
  'REC20260720002,10,PAY20260720002,60000\r\n' +
  'csv-task-003,"仓库\n扫码设备采购对账",PO20260720003,迅达智能设备有限公司,' +
  '扫码终端,15,4200,63000,2026-07-20,INV20260720003,15,4200,63000,' +
  'REC20260720003,12,PAY20260720003,63000\r\n' +
  'csv-task-004,保洁用品采购对账,PO20260720004,清源日用品有限公司,保洁套装,' +
  '100,180,18000,2026-07-20,,,,,REC20260720004,100,PAY20260720004,18000\r\n' +
  'csv-task-005,云服务年度费用对账,PO20260720005,星链云服务有限公司,云服务,' +
  '1,120000,120000,2026-07-20,INV20260720005,1,120000,120000,' +
  'REC20260720005,1,,\r\n\r\n';

export const invalidProcurementCsvSample: string =
  'taskId,taskName,poNumber,supplier,itemName,orderQuantity,orderUnitPrice,' +
  'orderTotalAmount,createdDate,invoiceId,invoiceQuantity,invoiceUnitPrice,' +
  'invoiceTotalAmount,receiptId,receivedQuantity,paymentId,paidAmount\n' +
  'duplicate-task,有效采购任务,PO20260721001,华辰办公用品有限公司,打印耗材,' +
  '10,300,3000,2026-07-21,INV20260721001,10,300,3000,' +
  'REC20260721001,10,PAY20260721001,3000\n' +
  'duplicate-task,,PO20260721002,,网络模块,不是数字,500,5000,2026-07-21,' +
  'INV20260721002,10,500,,REC20260721002,10,PAY20260721002,5000\n';
