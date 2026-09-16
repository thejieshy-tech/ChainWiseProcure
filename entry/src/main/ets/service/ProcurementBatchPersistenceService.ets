import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const PREFERENCES_FILE_NAME: string = 'chainwise_procurement_preferences';
const KEY_BATCH_ID: string = 'recent_csv_batch_id';
const KEY_SOURCE_NAME: string = 'recent_csv_source_name';
const KEY_CSV_TEXT: string = 'recent_csv_text';
const KEY_IMPORTED_AT: string = 'recent_csv_imported_at';
const KEY_SCHEMA_VERSION: string = 'recent_csv_schema_version';
const CURRENT_SCHEMA_VERSION: string = '1';
const MAX_CSV_TEXT_LENGTH: number = 1048576;

export enum CsvBatchLoadStatus {
  SUCCESS,
  NOT_FOUND,
  CORRUPTED,
  UNSUPPORTED_SCHEMA,
  READ_FAILED
}

export interface PersistedCsvBatch {
  batchId: string;
  sourceName: string;
  csvText: string;
  importedAt: string;
  schemaVersion: string;
}

export interface CsvBatchLoadResult {
  status: CsvBatchLoadStatus;
  batch: PersistedCsvBatch | null;
  message: string;
}

export interface CsvBatchOperationResult {
  success: boolean;
  message: string;
}

interface PreferenceStringValue {
  exists: boolean;
  isString: boolean;
  value: string;
}

interface CsvBatchPreferenceSnapshot {
  batchId: PreferenceStringValue;
  sourceName: PreferenceStringValue;
  csvText: PreferenceStringValue;
  importedAt: PreferenceStringValue;
  schemaVersion: PreferenceStringValue;
}

export class ProcurementBatchPersistenceService {
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async saveCsvBatch(
    batchId: string,
    sourceName: string,
    csvText: string,
    importedAt: string
  ): Promise<CsvBatchOperationResult> {
    const validationResult: CsvBatchOperationResult | null =
      this.validateSaveInput(batchId, sourceName, csvText, importedAt);
    if (validationResult !== null) {
      return validationResult;
    }

    const result: CsvBatchOperationResult = await this.writeCsvBatch(
      batchId,
      sourceName,
      csvText,
      importedAt
    ).then((): CsvBatchOperationResult => {
      const successResult: CsvBatchOperationResult = {
        success: true,
        message: '最近CSV批次已保存'
      };
      return successResult;
    }).catch((error: BusinessError): CsvBatchOperationResult => {
      const failureResult: CsvBatchOperationResult = {
        success: false,
        message: this.formatBusinessErrorMessage('保存最近CSV批次失败', error)
      };
      return failureResult;
    });
    return result;
  }

  async loadCsvBatch(): Promise<CsvBatchLoadResult> {
    const result: CsvBatchLoadResult = await this.readPreferenceSnapshot().then(
      (snapshot: CsvBatchPreferenceSnapshot): CsvBatchLoadResult => {
        return this.evaluateSnapshot(snapshot);
      }
    ).catch((error: BusinessError): CsvBatchLoadResult => {
      const failureResult: CsvBatchLoadResult = {
        status: CsvBatchLoadStatus.READ_FAILED,
        batch: null,
        message: this.formatBusinessErrorMessage('读取最近CSV批次失败', error)
      };
      return failureResult;
    });
    return result;
  }

  async clearCsvBatch(): Promise<CsvBatchOperationResult> {
    const result: CsvBatchOperationResult = await this.deleteCsvBatchKeys().then(
      (): CsvBatchOperationResult => {
        const successResult: CsvBatchOperationResult = {
          success: true,
          message: '最近CSV批次已清除'
        };
        return successResult;
      }
    ).catch((error: BusinessError): CsvBatchOperationResult => {
      const failureResult: CsvBatchOperationResult = {
        success: false,
        message: this.formatBusinessErrorMessage('清除最近CSV批次失败', error)
      };
      return failureResult;
    });
    return result;
  }

  async hasSavedCsvBatch(): Promise<boolean> {
    const result: boolean = await this.hasAllCsvBatchKeys().catch(
      (error: BusinessError): boolean => {
        throw error;
      }
    );
    return result;
  }

  private async getPreferencesInstance(): Promise<preferences.Preferences> {
    const dataPreferences: preferences.Preferences =
      await preferences.getPreferences(this.context, PREFERENCES_FILE_NAME);
    return dataPreferences;
  }

  private async writeCsvBatch(
    batchId: string,
    sourceName: string,
    csvText: string,
    importedAt: string
  ): Promise<void> {
    const dataPreferences: preferences.Preferences = await this.getPreferencesInstance();
    await dataPreferences.put(KEY_BATCH_ID, batchId);
    await dataPreferences.put(KEY_SOURCE_NAME, sourceName);
    await dataPreferences.put(KEY_CSV_TEXT, csvText);
    await dataPreferences.put(KEY_IMPORTED_AT, importedAt);
    await dataPreferences.put(KEY_SCHEMA_VERSION, CURRENT_SCHEMA_VERSION);
    await dataPreferences.flush();
  }

  private async readPreferenceSnapshot(): Promise<CsvBatchPreferenceSnapshot> {
    const dataPreferences: preferences.Preferences = await this.getPreferencesInstance();
    const batchId: PreferenceStringValue =
      await this.readStringPreference(dataPreferences, KEY_BATCH_ID);
    const sourceName: PreferenceStringValue =
      await this.readStringPreference(dataPreferences, KEY_SOURCE_NAME);
    const csvText: PreferenceStringValue =
      await this.readStringPreference(dataPreferences, KEY_CSV_TEXT);
    const importedAt: PreferenceStringValue =
      await this.readStringPreference(dataPreferences, KEY_IMPORTED_AT);
    const schemaVersion: PreferenceStringValue =
      await this.readStringPreference(dataPreferences, KEY_SCHEMA_VERSION);
    const snapshot: CsvBatchPreferenceSnapshot = {
      batchId: batchId,
      sourceName: sourceName,
      csvText: csvText,
      importedAt: importedAt,
      schemaVersion: schemaVersion
    };
    return snapshot;
  }

  private async readStringPreference(
    dataPreferences: preferences.Preferences,
    key: string
  ): Promise<PreferenceStringValue> {
    const exists: boolean = await dataPreferences.has(key);
    if (!exists) {
      const missingValue: PreferenceStringValue = {
        exists: false,
        isString: false,
        value: ''
      };
      return missingValue;
    }

    const storedValue: preferences.ValueType = await dataPreferences.get(key, '');
    if (typeof storedValue !== 'string') {
      const invalidValue: PreferenceStringValue = {
        exists: true,
        isString: false,
        value: ''
      };
      return invalidValue;
    }

    const stringValue: PreferenceStringValue = {
      exists: true,
      isString: true,
      value: storedValue
    };
    return stringValue;
  }

  private evaluateSnapshot(snapshot: CsvBatchPreferenceSnapshot): CsvBatchLoadResult {
    const presentCount: number = this.countPresentValues(snapshot);
    if (presentCount === 0) {
      const notFoundResult: CsvBatchLoadResult = {
        status: CsvBatchLoadStatus.NOT_FOUND,
        batch: null,
        message: '未找到最近CSV批次'
      };
      return notFoundResult;
    }

    if (presentCount !== 5 || !this.areAllValuesStrings(snapshot)) {
      const corruptedResult: CsvBatchLoadResult = {
        status: CsvBatchLoadStatus.CORRUPTED,
        batch: null,
        message: '最近CSV批次数据不完整'
      };
      return corruptedResult;
    }

    if (snapshot.schemaVersion.value !== CURRENT_SCHEMA_VERSION) {
      const unsupportedResult: CsvBatchLoadResult = {
        status: CsvBatchLoadStatus.UNSUPPORTED_SCHEMA,
        batch: null,
        message: '最近CSV批次版本不受支持'
      };
      return unsupportedResult;
    }

    if (!this.areBatchFieldsValid(snapshot)) {
      const corruptedResult: CsvBatchLoadResult = {
        status: CsvBatchLoadStatus.CORRUPTED,
        batch: null,
        message: '最近CSV批次数据已损坏'
      };
      return corruptedResult;
    }

    const batch: PersistedCsvBatch = {
      batchId: snapshot.batchId.value,
      sourceName: snapshot.sourceName.value,
      csvText: snapshot.csvText.value,
      importedAt: snapshot.importedAt.value,
      schemaVersion: snapshot.schemaVersion.value
    };
    const successResult: CsvBatchLoadResult = {
      status: CsvBatchLoadStatus.SUCCESS,
      batch: batch,
      message: '最近CSV批次读取成功'
    };
    return successResult;
  }

  private countPresentValues(snapshot: CsvBatchPreferenceSnapshot): number {
    let count: number = 0;
    if (snapshot.batchId.exists) {
      count = count + 1;
    }
    if (snapshot.sourceName.exists) {
      count = count + 1;
    }
    if (snapshot.csvText.exists) {
      count = count + 1;
    }
    if (snapshot.importedAt.exists) {
      count = count + 1;
    }
    if (snapshot.schemaVersion.exists) {
      count = count + 1;
    }
    return count;
  }

  private areAllValuesStrings(snapshot: CsvBatchPreferenceSnapshot): boolean {
    return snapshot.batchId.isString &&
      snapshot.sourceName.isString &&
      snapshot.csvText.isString &&
      snapshot.importedAt.isString &&
      snapshot.schemaVersion.isString;
  }

  private areBatchFieldsValid(snapshot: CsvBatchPreferenceSnapshot): boolean {
    if (snapshot.batchId.value.trim() === '' ||
      !snapshot.batchId.value.startsWith('csv-')) {
      return false;
    }
    if (snapshot.sourceName.value.trim() === '') {
      return false;
    }
    if (snapshot.csvText.value.trim() === '' ||
      snapshot.csvText.value.length > MAX_CSV_TEXT_LENGTH) {
      return false;
    }
    if (snapshot.importedAt.value.trim() === '') {
      return false;
    }
    return true;
  }

  private validateSaveInput(
    batchId: string,
    sourceName: string,
    csvText: string,
    importedAt: string
  ): CsvBatchOperationResult | null {
    if (batchId.trim() === '') {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV批次ID不能为空'
      };
      return result;
    }
    if (!batchId.startsWith('csv-')) {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV批次ID必须以csv-开头'
      };
      return result;
    }
    if (sourceName.trim() === '') {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV来源名称不能为空'
      };
      return result;
    }
    if (csvText.trim() === '') {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV文本不能为空'
      };
      return result;
    }
    if (csvText.length > MAX_CSV_TEXT_LENGTH) {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV文本长度不能超过1048576'
      };
      return result;
    }
    if (importedAt.trim() === '') {
      const result: CsvBatchOperationResult = {
        success: false,
        message: 'CSV导入时间不能为空'
      };
      return result;
    }
    return null;
  }

  private async deleteCsvBatchKeys(): Promise<void> {
    const dataPreferences: preferences.Preferences = await this.getPreferencesInstance();
    await dataPreferences.delete(KEY_BATCH_ID);
    await dataPreferences.delete(KEY_SOURCE_NAME);
    await dataPreferences.delete(KEY_CSV_TEXT);
    await dataPreferences.delete(KEY_IMPORTED_AT);
    await dataPreferences.delete(KEY_SCHEMA_VERSION);
    await dataPreferences.flush();
  }

  private async hasAllCsvBatchKeys(): Promise<boolean> {
    const dataPreferences: preferences.Preferences = await this.getPreferencesInstance();
    const hasBatchId: boolean = await dataPreferences.has(KEY_BATCH_ID);
    const hasSourceName: boolean = await dataPreferences.has(KEY_SOURCE_NAME);
    const hasCsvText: boolean = await dataPreferences.has(KEY_CSV_TEXT);
    const hasImportedAt: boolean = await dataPreferences.has(KEY_IMPORTED_AT);
    const hasSchemaVersion: boolean = await dataPreferences.has(KEY_SCHEMA_VERSION);
    return hasBatchId && hasSourceName && hasCsvText && hasImportedAt && hasSchemaVersion;
  }

  private formatBusinessErrorMessage(prefix: string, error: BusinessError): string {
    return prefix + '，错误码：' + error.code.toString();
  }
}
