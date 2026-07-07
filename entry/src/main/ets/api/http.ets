/**
 * HTTP 客户端 · 对接设备端网关
 * App 与网关同设备运行时走 127.0.0.1 loopback。
 * 如果网关跑在局域网设备上，会自动尝试已知内网地址。
 * 失败时返回 null，调用方自行 fallback 到 MockData
 */
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'SmartHomeHttp';

export class Http {
  static readonly BASE: string = 'http://127.0.0.1:8080';
  private static readonly BASE_CANDIDATES: string[] = [
    'http://127.0.0.1:8080',
    'http://192.168.1.81:8080',
    'http://192.168.1.62:8080'
  ];
  private static readonly TIMEOUT: number = 30000;
  private static activeBase: string = Http.BASE;

  static getActiveBase(): string {
    return Http.activeBase;
  }

  static async get(path: string): Promise<string | null> {
    const bases = Http.orderedBases();
    for (let i = 0; i < bases.length; i++) {
      const result = await Http.getOnce(bases[i], path);
      if (result !== null) {
        Http.activeBase = bases[i];
        return result;
      }
    }
    return null;
  }

  static async post(path: string, body: object): Promise<string | null> {
    const bases = Http.orderedBases();
    for (let i = 0; i < bases.length; i++) {
      const result = await Http.postOnce(bases[i], path, body);
      if (result !== null) {
        Http.activeBase = bases[i];
        return result;
      }
    }
    return null;
  }

  private static async getOnce(base: string, path: string): Promise<string | null> {
    try {
      const httpInst = http.createHttp();
      const resp = await httpInst.request(base + path, {
        method: http.RequestMethod.GET,
        connectTimeout: Http.TIMEOUT,
        readTimeout: Http.TIMEOUT,
        header: { 'Content-Type': 'application/json' } as Record<string, string>
      });
      httpInst.destroy();
      if (resp.responseCode === 200) {
        const r = resp.result;
        const text = typeof r === 'string' ? r : JSON.stringify(r);
        return text;
      }
      hilog.warn(DOMAIN, TAG, `GET ${base}${path} code=${resp.responseCode}`);
      return null;
    } catch (e) {
      const err = e as BusinessError;
      hilog.warn(DOMAIN, TAG, `GET ${base}${path} err: ${err.message}`);
      return null;
    }
  }

  private static async postOnce(base: string, path: string, body: object): Promise<string | null> {
    try {
      const httpInst = http.createHttp();
      const resp = await httpInst.request(base + path, {
        method: http.RequestMethod.POST,
        connectTimeout: Http.TIMEOUT,
        readTimeout: Http.TIMEOUT,
        header: { 'Content-Type': 'application/json' } as Record<string, string>,
        extraData: JSON.stringify(body)
      });
      httpInst.destroy();
      if (resp.responseCode === 200) {
        const r = resp.result;
        const text = typeof r === 'string' ? r : JSON.stringify(r);
        hilog.info(DOMAIN, TAG, `POST ${base}${path} ok len=${text.length}`);
        return text;
      }
      hilog.warn(DOMAIN, TAG, `POST ${base}${path} code=${resp.responseCode}`);
      return null;
    } catch (e) {
      const err = e as BusinessError;
      hilog.warn(DOMAIN, TAG, `POST ${base}${path} err: ${err.message}`);
      return null;
    }
  }

  private static orderedBases(): string[] {
    const result: string[] = [Http.activeBase];
    for (let i = 0; i < Http.BASE_CANDIDATES.length; i++) {
      if (result.indexOf(Http.BASE_CANDIDATES[i]) < 0) {
        result.push(Http.BASE_CANDIDATES[i]);
      }
    }
    return result;
  }
}
