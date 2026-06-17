/**
 * 监控 API · 摄像头 / 警报消息
 *
 * 接口契约:
 *   GET  /api/cameras               → Camera[]
 *   GET  /api/cameras/{id}/stream   → 视频流地址 (RTSP/HLS)
 *   GET  /api/alerts                → AlertMessage[]
 *   POST /api/alerts/{id}/read      → 标记已读
 *   POST /api/cameras/{id}/record   { on } → 开关录像
 */
import { Camera, AlertMessage } from './types';
import { MockData } from '../mock/mockData';

const DELAY = 260;
function delay<T>(data: T): Promise<T> {
  return new Promise(resolve => setTimeout(() => resolve(data), DELAY));
}

export class MonitorApi {
  /** 获取全部摄像头 */
  static async getCameras(): Promise<Camera[]> {
    // TODO[后端对接]: GET /api/cameras
    return delay(MockData.cameras);
  }

  /**
   * 获取视频流地址
   * TODO[后端对接]: GET /api/cameras/{id}/stream → { url }
   * 本地预览: 返回空字符串，UI 用 previewColor 占位
   */
  static async getStreamUrl(id: string): Promise<string> {
    // TODO[后端对接]: 返回 RTSP/HLS 流地址
    return delay('');
  }

  /** 开关录像 */
  static async toggleRecord(id: string, on: boolean): Promise<boolean> {
    // TODO[后端对接]: POST /api/cameras/{id}/record  body: { on }
    const cam = MockData.cameras.find(c => c.id === id);
    if (cam) cam.isRecording = on;
    return delay(true);
  }

  /** 获取警报消息流 */
  static async getAlerts(): Promise<AlertMessage[]> {
    // TODO[后端对接]: GET /api/alerts
    return delay(MockData.alerts);
  }

  /** 标记已读 */
  static async markRead(id: string): Promise<boolean> {
    // TODO[后端对接]: POST /api/alerts/{id}/read
    const a = MockData.alerts.find(x => x.id === id);
    if (a) a.isRead = true;
    return delay(true);
  }
}
