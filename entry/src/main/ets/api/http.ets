/**
 * HTTP 客户端 · 对接设备端网关
 * App 与网关同设备运行，走 127.0.0.1 loopback（无防火墙问题）
 * 失败时返回 null，调用方自行 fallback 到 MockData
 */
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class Http {
  /** 网关地址（同设备 loopback） */
  static readonly BASE: string = 'http://127.0.0.1:8080';
  private static readonly TIMEOUT: number = 8000;

  static async get(path: string): Promise<string | null> {
    try {
      const httpInst = http.createHttp();
      const resp = await httpInst.request(Http.BASE + path, {
        method: http.RequestMethod.GET,
        connectTimeout: Http.TIMEOUT,
        readTimeout: Http.TIMEOUT,
        header: { 'Content-Type': 'application/json' } as Record<string, string>
      });
      httpInst.destroy();
      if (resp.responseCode === 200) {
        const r = resp.result;
        return typeof r === 'string' ? r : JSON.stringify(r);
      }
      console.warn(`[HTTP] GET ${path} code=${resp.responseCode}`);
      return null;
    } catch (e) {
      const err = e as BusinessError;
      console.warn(`[HTTP] GET ${path} error: ${err.message}`);
      return null;
    }
  }

  static async post(path: string, body: object): Promise<string | null> {
    try {
      const httpInst = http.createHttp();
      const resp = await httpInst.request(Http.BASE + path, {
        method: http.RequestMethod.POST,
        connectTimeout: Http.TIMEOUT,
        readTimeout: Http.TIMEOUT,
        header: { 'Content-Type': 'application/json' } as Record<string, string>,
        extraData: JSON.stringify(body)
      });
      httpInst.destroy();
      if (resp.responseCode === 200) {
        const r = resp.result;
        return typeof r === 'string' ? r : JSON.stringify(r);
      }
      console.warn(`[HTTP] POST ${path} code=${resp.responseCode}`);
      return null;
    } catch (e) {
      const err = e as BusinessError;
      console.warn(`[HTTP] POST ${path} error: ${err.message}`);
      return null;
    }
  }
}
