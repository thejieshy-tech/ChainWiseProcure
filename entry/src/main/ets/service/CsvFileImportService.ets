import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, picker } from '@kit.CoreFileKit';

const MAX_CSV_FILE_SIZE: number = 1048576;

export interface CsvFileImportResult {
  success: boolean;
  canceled: boolean;
  fileName: string;
  csvText: string;
  message: string;
}

function getFileNameFromUri(uri: string): string {
  let normalizedUri: string = uri;
  const queryIndex: number = normalizedUri.indexOf('?');
  if (queryIndex >= 0) {
    normalizedUri = normalizedUri.substring(0, queryIndex);
  }
  const fragmentIndex: number = normalizedUri.indexOf('#');
  if (fragmentIndex >= 0) {
    normalizedUri = normalizedUri.substring(0, fragmentIndex);
  }
  const separatorIndex: number = normalizedUri.lastIndexOf('/');
  const encodedFileName: string = separatorIndex >= 0 ?
    normalizedUri.substring(separatorIndex + 1) : normalizedUri;
  try {
    return decodeURIComponent(encodedFileName);
  } catch {
    return encodedFileName;
  }
}

function isPickerCancellation(error: BusinessError): boolean {
  return error.message.toLowerCase().includes('cancel');
}

export async function selectAndReadCsvFile(
  context: common.UIAbilityContext
): Promise<CsvFileImportResult> {
  const selectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
  selectOptions.maxSelectNumber = 1;
  selectOptions.fileSuffixFilters = ['.csv'];

  const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
  let pickerFailed: boolean = false;
  let pickerCanceled: boolean = false;
  const selectedUris: string[] = await documentPicker.select(selectOptions).catch(
    (error: BusinessError): string[] => {
      pickerCanceled = isPickerCancellation(error);
      pickerFailed = !pickerCanceled;
      const emptyUris: string[] = [];
      return emptyUris;
    }
  );

  if (pickerCanceled || (!pickerFailed && selectedUris.length === 0)) {
    const result: CsvFileImportResult = {
      success: false,
      canceled: true,
      fileName: '',
      csvText: '',
      message: '已取消选择文件'
    };
    return result;
  }

  if (pickerFailed) {
    const result: CsvFileImportResult = {
      success: false,
      canceled: false,
      fileName: '',
      csvText: '',
      message: '无法读取CSV文件，请重新选择'
    };
    return result;
  }

  if (selectedUris.length !== 1) {
    const result: CsvFileImportResult = {
      success: false,
      canceled: false,
      fileName: '',
      csvText: '',
      message: '一次只能选择一个CSV文件'
    };
    return result;
  }

  const selectedUri: string = selectedUris[0];
  const fileName: string = getFileNameFromUri(selectedUri);
  if (!fileName.toLowerCase().endsWith('.csv')) {
    const result: CsvFileImportResult = {
      success: false,
      canceled: false,
      fileName: fileName,
      csvText: '',
      message: '仅支持CSV文件'
    };
    return result;
  }

  let openedFile: fileIo.File | null = null;
  try {
    openedFile = fileIo.openSync(selectedUri, fileIo.OpenMode.READ_ONLY);
    const fileStat: fileIo.Stat = fileIo.statSync(openedFile.fd);
    if (fileStat.size > MAX_CSV_FILE_SIZE) {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: 'CSV文件超过1 MB，请拆分后重新选择'
      };
      return result;
    }
    if (fileStat.size === 0) {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: 'CSV文件为空'
      };
      return result;
    }

    const contentBuffer: ArrayBuffer = new ArrayBuffer(fileStat.size);
    const readLength: number = fileIo.readSync(openedFile.fd, contentBuffer);
    if (readLength <= 0) {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: 'CSV文件为空'
      };
      return result;
    }
    if (readLength !== fileStat.size) {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: '无法读取CSV文件，请重新选择'
      };
      return result;
    }

    const contentBytes: Uint8Array = new Uint8Array(contentBuffer, 0, readLength);
    const textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    const csvText: string = textDecoder.decodeWithStream(contentBytes);
    if (csvText === '' || csvText === '\uFEFF') {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: 'CSV文件为空'
      };
      return result;
    }
    if (csvText.indexOf('\uFFFD') >= 0) {
      const result: CsvFileImportResult = {
        success: false,
        canceled: false,
        fileName: fileName,
        csvText: '',
        message: '文件编码异常，请将文件另存为UTF-8后重试'
      };
      return result;
    }

    const result: CsvFileImportResult = {
      success: true,
      canceled: false,
      fileName: fileName,
      csvText: csvText,
      message: '文件读取成功，请点击校验CSV'
    };
    return result;
  } catch {
    const result: CsvFileImportResult = {
      success: false,
      canceled: false,
      fileName: fileName,
      csvText: '',
      message: '无法读取CSV文件，请重新选择'
    };
    return result;
  } finally {
    if (openedFile !== null) {
      try {
        fileIo.closeSync(openedFile);
      } catch {
      }
    }
  }
}
