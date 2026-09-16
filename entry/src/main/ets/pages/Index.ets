import { common } from '@kit.AbilityKit';
import { ProcurementDataSet, demoProcurementDataSet } from '../data/DemoProcurementData';
import {
  combinedProcurementDataSet,
  importedProcurementDataSet
} from '../data/ImportedProcurementData';
import {
  invalidProcurementCsvSample,
  validProcurementCsvSample
} from '../data/ProcurementCsvSample';
import {
  CsvParseError,
  CsvParseResult,
  parseProcurementCsv
} from '../service/CsvProcurementParser';
import {
  CsvFileImportResult,
  selectAndReadCsvFile
} from '../service/CsvFileImportService';
import { procurementBatchRepository } from '../service/ProcurementBatchRepository';
import { ReconciliationRunResult, runReconciliation } from '../service/ReconciliationEngine';

function getPendingReconciliationCount(result: ReconciliationRunResult): number {
  return result.summary.differenceCount + result.summary.missingMaterialCount;
}
interface HomeReconciliationTask {
  taskId: string;
  orderNo: string;
  supplier: string;
  amount: string;
  createDate: string;
  status: string;
  differenceCount: number;
  savedAmount: number;
}

interface HomeRiskRecord {
  riskId: string;
  supplier: string;
  title: string;
  level: string;
  status: string;
  suggestion: string;
}

interface OrderImportPreview {
  fileName: string;
  recordCount: number;
  source: string;
}

@Entry
@Component
struct Index {
  @State selectedFeature: string = '已选择：首页';
  @State showImportPanel: boolean = false;
  @State activeBatchId: string = demoProcurementDataSet.metadata.batchId;
  @State orderImported: boolean = false;
  @State pendingReconciliationCount: number =
    getPendingReconciliationCount(runReconciliation(demoProcurementDataSet));
  @State importFeedback: string = '';
  @State csvInputText: string = '';
  @State csvValidationPassed: boolean = false;
  @State csvValidationMessage: string = '';
  @State csvValidationErrorTexts: string[] = [];
  @State csvValidatedRecordCount: number = 0;
  @State csvValidatedSourceName: string = '';
  @State csvValidatedBatchId: string = '';
  @State csvBatchActivated: boolean = false;
  @State selectedCsvFileName: string = '';
  @State csvFileImportMessage: string = '';
  @State csvFileImportLoading: boolean = false;
  @State csvFileImportFailed: boolean = false;

  private readonly importPreview: OrderImportPreview = {
    fileName: importedProcurementDataSet.metadata.sourceName,
    recordCount: importedProcurementDataSet.metadata.recordCount,
    source: importedProcurementDataSet.metadata.sourceType
  };

  private readonly reconciliationTasks: HomeReconciliationTask[] = [
    {
      taskId: 'task-001',
      orderNo: 'PO20260716001',
      supplier: '华东办公设备有限公司',
      amount: '¥126,800',
      createDate: '2026-07-16',
      status: '待处理',
      differenceCount: 3,
      savedAmount: 5200
    },
    {
      taskId: 'task-002',
      orderNo: 'PO20260715008',
      supplier: '星云科技有限公司',
      amount: '¥286,000',
      createDate: '2026-07-15',
      status: '对账中',
      differenceCount: 1,
      savedAmount: 4100
    },
    {
      taskId: 'task-003',
      orderNo: 'PO20260714012',
      supplier: '优品服饰有限公司',
      amount: '¥58,600',
      createDate: '2026-07-14',
      status: '已完成',
      differenceCount: 0,
      savedAmount: 3800
    },
    {
      taskId: 'task-004',
      orderNo: 'PO20260713006',
      supplier: '联合包装有限公司',
      amount: '¥39,800',
      createDate: '2026-07-13',
      status: '待处理',
      differenceCount: 2,
      savedAmount: 2900
    },
    {
      taskId: 'task-005',
      orderNo: 'PO20260712003',
      supplier: '远航物流有限公司',
      amount: '¥76,500',
      createDate: '2026-07-12',
      status: '已完成',
      differenceCount: 0,
      savedAmount: 2600
    }
  ];

  private readonly riskRecords: HomeRiskRecord[] = [
    {
      riskId: 'risk-001',
      supplier: '华东办公设备有限公司',
      title: '办公椅数量与发票不一致',
      level: '高风险',
      status: '待处理',
      suggestion: '建议核对采购订单、发票和实际收货记录'
    },
    {
      riskId: 'risk-002',
      supplier: '远航服务器科技有限公司',
      title: '服务器配件单价异常上涨',
      level: '高风险',
      status: '待处理',
      suggestion: '建议复核合同调价条款并联系供应商说明'
    },
    {
      riskId: 'risk-003',
      supplier: '新城物流有限公司',
      title: '运输费用超过合同约定',
      level: '中风险',
      status: '核验中',
      suggestion: '建议核验运输签收单和附加费用审批记录'
    },
    {
      riskId: 'risk-004',
      supplier: '优品工服有限公司',
      title: '交付时间延迟',
      level: '中风险',
      status: '核验中',
      suggestion: '建议确认最新到货计划并评估延期责任'
    },
    {
      riskId: 'risk-005',
      supplier: '明辉仓储用品有限公司',
      title: '部分发票信息缺失',
      level: '低风险',
      status: '待补充',
      suggestion: '建议补齐发票明细后重新执行对账'
    },
    {
      riskId: 'risk-006',
      supplier: '恒达电子有限公司',
      title: '付款记录与订单日期异常',
      level: '已处理',
      status: '已关闭',
      suggestion: '相关日期差异已完成复核并归档'
    }
  ];

  private openImportPanel(): void {
    this.showImportPanel = true;
    this.selectFeature('导入订单');
  }

  private closeImportPanel(): void {
    this.showImportPanel = false;
    this.clearCsvValidationResult();
  }

  private clearCsvValidationResult(): void {
    this.csvValidationPassed = false;
    this.csvValidationMessage = '';
    this.csvValidationErrorTexts = [];
    this.csvValidatedRecordCount = 0;
    this.csvValidatedSourceName = '';
  }

  private clearStoredCsvBatch(): void {
    procurementBatchRepository.clearCsvDataSet();
    this.csvValidatedBatchId = '';
    this.csvBatchActivated = false;
  }

  private resetCsvValidationAndBatch(): void {
    this.clearCsvValidationResult();
    this.clearStoredCsvBatch();
  }

  private async chooseCsvFile(): Promise<void> {
    if (this.csvFileImportLoading) {
      return;
    }
    this.csvFileImportLoading = true;
    try {
      const context: common.UIAbilityContext =
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      const result: CsvFileImportResult = await selectAndReadCsvFile(context);
      if (result.canceled) {
        this.csvFileImportFailed = false;
        this.csvFileImportMessage = result.message;
        return;
      }
      if (!result.success) {
        this.csvFileImportFailed = true;
        this.csvFileImportMessage = result.message;
        return;
      }

      this.csvInputText = result.csvText;
      this.selectedCsvFileName = result.fileName;
      this.csvFileImportMessage = '文件读取成功，请点击校验CSV';
      this.csvFileImportFailed = false;
      this.resetCsvValidationAndBatch();
    } catch {
      this.csvFileImportFailed = true;
      this.csvFileImportMessage = '无法读取CSV文件，请重新选择';
    } finally {
      this.csvFileImportLoading = false;
    }
  }

  private getCsvFileImportMessageColor(): string {
    if (this.csvFileImportFailed) {
      return '#B54747';
    }
    if (this.csvFileImportMessage === '文件读取成功，请点击校验CSV') {
      return '#17795B';
    }
    return '#667085';
  }

  private getCsvFileImportMessageBackground(): string {
    if (this.csvFileImportFailed) {
      return '#FCEAEA';
    }
    if (this.csvFileImportMessage === '文件读取成功，请点击校验CSV') {
      return '#E8F7F1';
    }
    return '#EDF2F8';
  }

  private fillValidCsvSample(): void {
    this.csvInputText = validProcurementCsvSample;
    this.selectedCsvFileName = '';
    this.csvFileImportMessage = '';
    this.csvFileImportFailed = false;
    this.resetCsvValidationAndBatch();
  }

  private fillInvalidCsvSample(): void {
    this.csvInputText = invalidProcurementCsvSample;
    this.selectedCsvFileName = '';
    this.csvFileImportMessage = '';
    this.csvFileImportFailed = false;
    this.resetCsvValidationAndBatch();
  }

  private validateCsvInput(): void {
    this.clearCsvValidationResult();
    if (this.csvInputText.trim() === '') {
      this.clearStoredCsvBatch();
      this.csvValidationMessage = '请先粘贴CSV文本或选择样例';
      return;
    }

    const result: CsvParseResult = parseProcurementCsv(
      this.csvInputText,
      'csv-user-active',
      '用户粘贴CSV文本'
    );

    if (result.success && result.dataSet) {
      procurementBatchRepository.saveCsvDataSet(result.dataSet);
      this.csvValidatedBatchId = result.dataSet.metadata.batchId;
      this.csvBatchActivated = false;
      this.csvValidationPassed = true;
      this.csvValidationMessage = 'CSV格式校验通过';
      this.csvValidatedRecordCount = result.dataSet.metadata.recordCount;
      this.csvValidatedSourceName = result.dataSet.metadata.sourceName;
      this.csvValidationErrorTexts = [];
      return;
    }

    this.clearStoredCsvBatch();
    const formattedErrors: string[] = [];
    for (let index: number = 0; index < result.errors.length; index++) {
      const error: CsvParseError = result.errors[index];
      formattedErrors.push(
        '第' + error.line.toString() + '行｜' + error.field + '｜' + error.message
      );
    }
    if (formattedErrors.length === 0) {
      formattedErrors.push('第1行｜CSV｜解析结果未包含可用数据');
    }
    this.csvValidationPassed = false;
    this.csvValidatedRecordCount = 0;
    this.csvValidatedSourceName = '';
    this.csvValidationErrorTexts = formattedErrors;
    this.csvValidationMessage = 'CSV格式校验失败，共发现' +
      formattedErrors.length.toString() + '个问题';
  }

  private activateCsvBatchAndStartReconciliation(): void {
    const dataSet: ProcurementDataSet | null =
      procurementBatchRepository.getCsvDataSet(this.csvValidatedBatchId);
    if (dataSet === null) {
      this.clearCsvValidationResult();
      this.clearStoredCsvBatch();
      this.csvValidationMessage = 'CSV批次已失效，请重新校验';
      return;
    }

    const reconciliationResult: ReconciliationRunResult = runReconciliation(dataSet);
    this.activeBatchId = dataSet.metadata.batchId;
    this.pendingReconciliationCount = getPendingReconciliationCount(reconciliationResult);
    this.csvBatchActivated = true;
    this.openReconciliationList();
  }

  private confirmOrderImport(): void {
    if (this.orderImported) {
      return;
    }
    const reconciliationResult: ReconciliationRunResult =
      runReconciliation(combinedProcurementDataSet);
    this.activeBatchId = combinedProcurementDataSet.metadata.batchId;
    this.orderImported = true;
    this.pendingReconciliationCount = getPendingReconciliationCount(reconciliationResult);
    this.importFeedback = '内置导入批次已导入，共导入' +
      importedProcurementDataSet.metadata.recordCount.toString() + '条数据';
  }

  private getAbnormalItemCount(): string {
    return this.reconciliationTasks.filter((task: HomeReconciliationTask) => {
      return task.differenceCount > 0;
    }).length.toString();
  }

  private getHighRiskSupplierCount(): string {
    const suppliers: string[] = [];
    this.riskRecords.forEach((risk: HomeRiskRecord) => {
      if (risk.level === '高风险' && !this.isRiskProcessed(risk) &&
        suppliers.indexOf(risk.supplier) === -1) {
        suppliers.push(risk.supplier);
      }
    });
    return suppliers.length.toString();
  }

  private getMonthlySavingsAmount(): string {
    let total: number = 0;
    this.reconciliationTasks.forEach((task: HomeReconciliationTask) => {
      total += task.savedAmount;
    });
    return this.formatCurrency(total);
  }

  private formatCurrency(amount: number): string {
    return '¥' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  private getRecentTasks(): HomeReconciliationTask[] {
    return this.reconciliationTasks.slice().sort(
      (left: HomeReconciliationTask, right: HomeReconciliationTask) => {
        if (left.createDate === right.createDate) {
          return 0;
        }
        return left.createDate < right.createDate ? 1 : -1;
      }
    ).slice(0, 3);
  }

  private getPriorityRisks(): HomeRiskRecord[] {
    return this.riskRecords.filter((risk: HomeRiskRecord) => {
      return !this.isRiskProcessed(risk);
    }).slice().sort((left: HomeRiskRecord, right: HomeRiskRecord) => {
      const priorityDifference: number =
        this.getRiskPriority(right.level) - this.getRiskPriority(left.level);
      if (priorityDifference !== 0) {
        return priorityDifference;
      }
      if (left.riskId === right.riskId) {
        return 0;
      }
      return left.riskId < right.riskId ? -1 : 1;
    }).slice(0, 2);
  }

  private isRiskProcessed(risk: HomeRiskRecord): boolean {
    return risk.status === '已关闭' || risk.level === '已处理';
  }

  private getRiskPriority(level: string): number {
    if (level === '高风险') {
      return 3;
    }
    if (level === '中风险') {
      return 2;
    }
    if (level === '低风险') {
      return 1;
    }
    return 0;
  }

  private getTaskStatusBackground(status: string): string {
    if (status === '待处理') {
      return '#FFF2E5';
    }
    if (status === '对账中') {
      return '#EAF2FF';
    }
    if (status === '已完成') {
      return '#E8F7F1';
    }
    return '#EDF2F8';
  }

  private getTaskStatusColor(status: string): string {
    if (status === '待处理') {
      return '#B65E10';
    }
    if (status === '对账中') {
      return '#1769E0';
    }
    if (status === '已完成') {
      return '#17795B';
    }
    return '#59677B';
  }

  private getRiskLevelColor(level: string): string {
    if (level === '高风险') {
      return '#B54747';
    }
    if (level === '中风险') {
      return '#A76512';
    }
    if (level === '低风险') {
      return '#1769E0';
    }
    return '#17795B';
  }

  private getRiskLevelBackground(level: string): string {
    if (level === '高风险') {
      return '#FCEAEA';
    }
    if (level === '中风险') {
      return '#FFF3DF';
    }
    if (level === '低风险') {
      return '#EAF2FF';
    }
    return '#E8F7F1';
  }

  private openReconciliationDetail(taskId: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ReconciliationDetailPage',
      params: {
        taskId: taskId,
        batchId: this.activeBatchId
      }
    }).catch(() => {
      this.selectedFeature = '页面跳转失败，请稍后重试';
    });
  }

  private openRiskDetail(riskId: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RiskDetailPage',
      params: { riskId: riskId }
    }).catch(() => {
      this.selectedFeature = '页面跳转失败，请稍后重试';
    });
  }

  openReconciliationList(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/ReconciliationListPage',
      params: {
        batchId: this.activeBatchId
      }
    }).catch(() => {
      this.selectedFeature = '页面跳转失败，请稍后重试';
    });
  }

  openRiskCenter(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/RiskCenterPage'
    }).catch(() => {
      this.selectedFeature = '页面跳转失败，请稍后重试';
    });
  }
  openAiAssistant(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/AiAssistantPage'
    }).catch(() => {
      this.selectedFeature = 'AI助手页面跳转失败，请稍后重试';
    });
  }

  openMyPage(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/MyPage'
    }).catch(() => {
      this.selectedFeature = '个人中心页面跳转失败，请稍后重试';
    });
  }

  selectFeature(featureName: string): void {
    this.selectedFeature = '已选择：' + featureName;
  }

  @Builder
  SectionTitle(title: string, description: string) {
    Column({ space: 3 }) {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
      Text(description)
        .fontSize(12)
        .fontColor('#7B879C')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  MetricCard(title: string, value: string, description: string, accentColor: string, badge: string) {
    Column({ space: 12 }) {
      Row() {
        Text(title)
          .fontSize(14)
          .fontColor('#667085')
          .layoutWeight(1)
        Text(badge)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(accentColor)
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F2F6FC')
          .borderRadius(17)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
        .width('100%')

      Row({ space: 6 }) {
        Text('●')
          .fontSize(9)
          .fontColor(accentColor)
        Text(description)
          .fontSize(11)
          .fontColor('#8A94A6')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
    }
    .width('100%')
    .height(132)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
  }

  @Builder
  PendingReconciliationMetricCard() {
    Column({ space: 12 }) {
      Row() {
        Text('待对账')
          .fontSize(14)
          .fontColor('#667085')
          .layoutWeight(1)
        Text('待')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F74E8')
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F2F6FC')
          .borderRadius(17)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.pendingReconciliationCount.toString())
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#14213D')
        .width('100%')

      Row({ space: 6 }) {
        Text('●')
          .fontSize(9)
          .fontColor('#2F74E8')
        Text('较昨日新增 2 项')
          .fontSize(11)
          .fontColor('#8A94A6')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
    }
    .width('100%')
    .height(132)
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: '#120F2D4A', offsetX: 0, offsetY: 3 })
  }

  @Builder
  QuickAction(symbol: string, title: string, description: string, accentColor: string, action: () => void) {
    Column({ space: 8 }) {
      Text(symbol)
        .fontSize(symbol === 'AI' ? 14 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(accentColor)
        .borderRadius(13)
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#25324B')
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(1)
      Text(description)
        .fontSize(11)
        .fontColor('#8A94A6')
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(140)
    .padding({ left: 12, right: 12, top: 14, bottom: 14 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      action();
    })
  }

  @Builder
  OrderImportPanel() {
    Column({ space: 14 }) {
      Row() {
        Text('订单导入预览')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25324B')
          .layoutWeight(1)
        Text(this.orderImported ? '已导入' : '待确认')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.orderImported ? '#17795B' : '#B65E10')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.orderImported ? '#E8F7F1' : '#FFF3E6')
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 10 }) {
        Row({ space: 12 }) {
          Text('文件名').fontSize(13).fontColor('#7B879C').width(76)
          Text(this.importPreview.fileName).fontSize(14).fontColor('#40506A').layoutWeight(1)
        }
        .width('100%')
        Row({ space: 12 }) {
          Text('数据条数').fontSize(13).fontColor('#7B879C').width(76)
          Text(this.importPreview.recordCount.toString() + '条')
            .fontSize(14)
            .fontColor('#40506A')
            .layoutWeight(1)
        }
        .width('100%')
        Row({ space: 12 }) {
          Text('数据来源').fontSize(13).fontColor('#7B879C').width(76)
          Text(this.importPreview.source).fontSize(14).fontColor('#40506A').layoutWeight(1)
        }
        .width('100%')
        Row({ space: 12 }) {
          Text('导入状态').fontSize(13).fontColor('#7B879C').width(76)
          Text(this.orderImported ? '已导入' : '待确认')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.orderImported ? '#17795B' : '#B65E10')
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#F8FAFD')
      .borderRadius(12)

      if (this.importFeedback !== '') {
        Text(this.importFeedback)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#17795B')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#E8F7F1')
          .borderRadius(12)
      }

      Row({ space: 10 }) {
        Button('取消')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1769E0')
          .layoutWeight(1)
          .height(42)
          .backgroundColor('#EAF2FF')
          .borderRadius(21)
          .onClick(() => {
            this.closeImportPanel();
          })
        Button(this.orderImported ? '已完成导入' : '确认导入')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.orderImported ? '#17795B' : '#FFFFFF')
          .layoutWeight(1)
          .height(42)
          .backgroundColor(this.orderImported ? '#E8F7F1' : '#1769E0')
          .borderRadius(21)
          .enabled(!this.orderImported)
          .onClick(() => {
            this.confirmOrderImport();
          })
      }
      .width('100%')

      if (this.orderImported) {
        Button('立即开始对账')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .width('100%')
          .height(44)
          .backgroundColor('#0E8A7A')
          .borderRadius(22)
          .onClick(() => {
            this.openReconciliationList();
          })
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#C8DAF5' })
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  CsvValidationPanel() {
    Column({ space: 14 }) {
      Column({ space: 5 }) {
        Text('CSV文本校验')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25324B')
        Text('粘贴CSV文本，或使用内置样例验证采购数据格式。本阶段仅校验，不会覆盖当前稳定数据。')
          .fontSize(13)
          .fontColor('#7B879C')
          .lineHeight(20)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Text('CSV批次仅在本次应用运行期间有效')
        .fontSize(12)
        .fontColor('#A76512')
        .width('100%')
        .padding({ left: 12, right: 12, top: 9, bottom: 9 })
        .backgroundColor('#FFF3DF')
        .borderRadius(10)

      Button(this.csvFileImportLoading ? '正在读取...' : '选择CSV文件')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')
        .height(44)
        .backgroundColor(this.csvFileImportLoading ? '#98A2B3' : '#1769E0')
        .borderRadius(22)
        .enabled(!this.csvFileImportLoading)
        .onClick(() => {
          this.chooseCsvFile();
        })

      if (this.selectedCsvFileName !== '') {
        Text('已选择：' + this.selectedCsvFileName)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#17795B')
          .width('100%')
          .padding({ left: 12, right: 12, top: 9, bottom: 9 })
          .backgroundColor('#E8F7F1')
          .borderRadius(10)
      }

      if (this.csvFileImportMessage !== '') {
        Text(this.csvFileImportMessage)
          .fontSize(13)
          .fontColor(this.getCsvFileImportMessageColor())
          .width('100%')
          .padding({ left: 12, right: 12, top: 9, bottom: 9 })
          .backgroundColor(this.getCsvFileImportMessageBackground())
          .borderRadius(10)
      }

      TextArea({
        text: this.csvInputText,
        placeholder: '请粘贴采购订单CSV文本'
      })
        .width('100%')
        .height(180)
        .fontSize(13)
        .fontColor('#40506A')
        .placeholderColor('#98A2B3')
        .padding(12)
        .backgroundColor('#F8FAFD')
        .border({ width: 1, color: '#D7E1EF' })
        .borderRadius(12)
        .onChange((value: string) => {
          this.csvInputText = value;
          this.resetCsvValidationAndBatch();
        })

      GridRow({
        columns: { xs: 1, sm: 3, md: 3, lg: 3 },
        gutter: { x: 10, y: 10 }
      }) {
        GridCol({ span: 1 }) {
          Button('填入有效样例')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1769E0')
            .width('100%')
            .height(42)
            .backgroundColor('#EAF2FF')
            .borderRadius(21)
            .onClick(() => {
              this.fillValidCsvSample();
            })
        }
        GridCol({ span: 1 }) {
          Button('填入错误样例')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#B54747')
            .width('100%')
            .height(42)
            .backgroundColor('#FCEAEA')
            .borderRadius(21)
            .onClick(() => {
              this.fillInvalidCsvSample();
            })
        }
        GridCol({ span: 1 }) {
          Button('校验CSV')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(42)
            .backgroundColor('#0E8A7A')
            .borderRadius(21)
            .onClick(() => {
              this.validateCsvInput();
            })
        }
      }
      .width('100%')

      if (this.csvValidationPassed) {
        Column({ space: 7 }) {
          Text(this.csvValidationMessage)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#17795B')
          Text('采购任务：' + this.csvValidatedRecordCount.toString() + '条')
            .fontSize(13)
            .fontColor('#326B5B')
          Text('数据来源：' + this.csvValidatedSourceName)
            .fontSize(13)
            .fontColor('#326B5B')
          Button('使用该CSV开始对账')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width('100%')
            .height(44)
            .margin({ top: 5 })
            .backgroundColor('#0E8A7A')
            .borderRadius(22)
            .onClick(() => {
              this.activateCsvBatchAndStartReconciliation();
            })
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#E8F7F1')
        .borderRadius(12)
      } else if (this.csvValidationMessage !== '') {
        Column({ space: 9 }) {
          Text(this.csvValidationMessage)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#B54747')
          ForEach(this.csvValidationErrorTexts, (errorText: string) => {
            Text('• ' + errorText)
              .fontSize(13)
              .fontColor('#8E3D3D')
              .lineHeight(20)
              .width('100%')
          }, (errorText: string) => errorText)
        }
        .width('100%')
        .padding(14)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#FCEAEA')
        .borderRadius(12)
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#C8DAF5' })
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TaskCard(task: HomeReconciliationTask) {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 5 }) {
          Text(task.orderNo)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25324B')
          Text('供应商：' + task.supplier)
            .fontSize(13)
            .fontColor('#667085')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(task.status)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTaskStatusColor(task.status))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getTaskStatusBackground(task.status))
          .borderRadius(12)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        Text('订单金额')
          .fontSize(12)
          .fontColor('#98A2B3')
          .layoutWeight(1)
        Text(task.amount)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#14213D')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.openReconciliationDetail(task.taskId);
    })
  }

  @Builder
  RiskCard(risk: HomeRiskRecord) {
    Row({ space: 12 }) {
      Text('!')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getRiskLevelColor(risk.level))
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getRiskLevelBackground(risk.level))
        .borderRadius(12)

      Column({ space: 5 }) {
        Text(risk.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#25324B')
          .maxLines(2)
        Text(risk.suggestion)
          .fontSize(12)
          .fontColor('#8A94A6')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(risk.level)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getRiskLevelColor(risk.level))
        .padding({ left: 9, right: 9, top: 4, bottom: 4 })
        .backgroundColor(this.getRiskLevelBackground(risk.level))
        .borderRadius(10)
    }
    .width('100%')
    .padding(16)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#100F2D4A', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.openRiskDetail(risk.riskId);
    })
  }

  @Builder
  NavigationItem(symbol: string, title: string, isActive: boolean, action: () => void) {
    Column({ space: 4 }) {
      Text(symbol)
        .fontSize(symbol === 'AI' ? 12 : 18)
        .fontWeight(isActive ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(isActive ? '#1769E0' : '#98A2B3')
      Text(title)
        .fontSize(11)
        .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(isActive ? '#1769E0' : '#667085')
    }
    .height(58)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      action();
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Column({ space: 26 }) {
            // 顶部欢迎区
            Row() {
              Column({ space: 7 }) {
                Text('早上好，祖杰')
                  .fontSize(14)
                  .fontColor('#C8D8F4')
                Text('链智采')
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('AI采购对账与供应链风险助手')
                  .fontSize(14)
                  .fontColor('#DDE8FA')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('祖')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .width(44)
                .height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor('#2C5289')
                .borderRadius(22)
                .onClick(() => {
                  this.openMyPage();
                })
            }
            .width('100%')
            .padding(22)
            .alignItems(VerticalAlign.Center)
            .backgroundColor('#0B2D5C')
            .borderRadius(22)
            .shadow({ radius: 14, color: '#24102D55', offsetX: 0, offsetY: 5 })

            // 数据概览区
            Column() {
              this.SectionTitle('数据概览', '关键采购指标实时掌握')
              GridRow({
                columns: { xs: 2, sm: 2, md: 4, lg: 4 },
                gutter: { x: 12, y: 12 }
              }) {
                GridCol({ span: 1 }) {
                  this.PendingReconciliationMetricCard()
                }
                GridCol({ span: 1 }) {
                  this.MetricCard('异常项目', this.getAbnormalItemCount(), '需优先核验差异', '#D97706', '异')
                }
                GridCol({ span: 1 }) {
                  this.MetricCard('风险供应商', this.getHighRiskSupplierCount(), '本周新增 1 家', '#C2415A', '险')
                }
                GridCol({ span: 1 }) {
                  this.MetricCard('本月节省', this.getMonthlySavingsAmount(), '智能比价累计节省', '#138A66', '省')
                }
              }
              .width('100%')
            }
            .width('100%')

            // 快捷操作区
            Column() {
              this.SectionTitle('快捷操作', '高频工作一步直达')
              GridRow({
                columns: { xs: 2, sm: 2, md: 4, lg: 4 },
                gutter: { x: 12, y: 12 }
              }) {
                GridCol({ span: 1 }) {
                  this.QuickAction('⇧', '导入订单', '录入采购数据', '#2F74E8', () => {
                    this.openImportPanel();
                  })
                }
                GridCol({ span: 1 }) {
                  this.QuickAction('✓', '开始对账', '智能匹配单据', '#0E8A7A', () => {
                    this.openReconciliationList();
                  })
                }
                GridCol({ span: 1 }) {
                  this.QuickAction('!', '风险中心', '查看风险预警', '#C65D3B', () => {
                    this.openRiskCenter();
                  })
                }
                GridCol({ span: 1 }) {
                  this.QuickAction('AI', 'AI助手', '获取采购建议', '#6554C0', () => {
                    this.openAiAssistant();
                  })
                }
              }
              .width('100%')

              Row({ space: 8 }) {
                Text('●')
                  .fontSize(9)
                  .fontColor('#1769E0')
                Text(this.selectedFeature)
                  .fontSize(13)
                  .fontColor('#40506A')
              }
              .width('100%')
              .margin({ top: 12 })
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .backgroundColor('#EAF2FF')
              .borderRadius(12)

              if (this.showImportPanel) {
                this.OrderImportPanel()
                this.CsvValidationPanel()
              }
            }
            .width('100%')

            // 最近对账任务
            Column({ space: 12 }) {
              this.SectionTitle('最近对账任务', '优先处理异常与待办项目')
              ForEach(this.getRecentTasks(), (task: HomeReconciliationTask) => {
                this.TaskCard(task)
              }, (task: HomeReconciliationTask) => task.taskId)
            }
            .width('100%')

            // 风险提醒区
            Column({ space: 12 }) {
              this.SectionTitle('风险提醒', 'AI持续监测采购异常')
              ForEach(this.getPriorityRisks(), (risk: HomeRiskRecord) => {
                this.RiskCard(risk)
              }, (risk: HomeRiskRecord) => risk.riskId)
            }
            .width('100%')

            // AI洞察卡片
            Column({ space: 16 }) {
              Row({ space: 10 }) {
                Text('AI')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .width(38)
                  .height(38)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#6554C0')
                  .borderRadius(12)
                Column({ space: 3 }) {
                  Text('今日AI洞察')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                  Text('智能分析 · 每日更新')
                    .fontSize(11)
                    .fontColor('#D9D4FA')
                }
                .alignItems(HorizontalAlign.Start)
              }

              Text('系统发现本月办公设备采购价格较上月上涨8.6%，建议复核三家供应商的最新报价。')
                .fontSize(14)
                .fontColor('#F4F2FF')
                .lineHeight(23)

              Button('查看分析')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#4E3DA4')
                .height(38)
                .padding({ left: 18, right: 18 })
                .backgroundColor('#FFFFFF')
                .borderRadius(19)
                .onClick(() => {
                  this.openAiAssistant();
                })
            }
            .width('100%')
            .padding(20)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor('#4E3DA4')
            .borderRadius(20)
            .shadow({ radius: 12, color: '#244E3DA4', offsetX: 0, offsetY: 4 })
          }
          .width('100%')
          .constraintSize({ maxWidth: 1180 })
          .padding({ left: 16, right: 16, top: 18, bottom: 116 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部导航栏
      Row() {
        this.NavigationItem('⌂', '首页', true, () => {
          this.selectFeature('首页');
        })
        this.NavigationItem('≋', '对账', false, () => {
          this.openReconciliationList();
        })
        this.NavigationItem('◆', '风险', false, () => {
          this.openRiskCenter();
        })
        this.NavigationItem('AI', 'AI助手', false, () => {
          this.openAiAssistant();
        })
        this.NavigationItem('◎', '我的', false, () => {
          this.openMyPage();
        })
      }
      .width('100%')
      .height(66)
      .padding({ left: 8, right: 8, bottom: 4 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 12, color: '#160F2D4A', offsetX: 0, offsetY: -3 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7FB')
  }
}
