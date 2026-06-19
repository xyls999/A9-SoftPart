/**
 * 监控 API · 对接设备端网关
 * 策略: HTTP 优先，失败降级到 MockData
 */
import { Camera, AlertMessage } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';

export class MonitorApi {
  /** 获取全部摄像头 */
  static async getCameras(): Promise<Camera[]> {
    const remote = await Http.get('/api/cameras');
    if (remote) {
      try {
        return JSON.parse(remote) as Camera[];
      } catch (e) {
        // 降级
      }
    }
    return MockData.cameras;
  }

  /** 获取视频流地址（占位） */
  static async getStreamUrl(id: string): Promise<string> {
    return '';
  }

  /** 开关录像 */
  static async toggleRecord(id: string, on: boolean): Promise<boolean> {
    const cam = MockData.cameras.find(c => c.id === id);
    if (cam) cam.isRecording = on;
    return true;
  }

  /** 获取警报消息流 */
  static async getAlerts(): Promise<AlertMessage[]> {
    const remote = await Http.get('/api/alerts');
    if (remote) {
      try {
        return JSON.parse(remote) as AlertMessage[];
      } catch (e) {
        // 降级
      }
    }
    return MockData.alerts;
  }

  /** 标记已读 */
  static async markRead(id: string): Promise<boolean> {
    const a = MockData.alerts.find(x => x.id === id);
    if (a) a.isRead = true;
    return true;
  }
}
