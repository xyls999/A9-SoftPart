/**
 * 传感器数据 API · 温湿度 / 空气 / 光照 / 人体 / 门窗 / 烟水浸 / 电量 / 体重姿态
 *
 * ====================================================================
 * 对接说明: 函数体返回 Mock，后端对接仅替换 return 部分。
 * ====================================================================
 *
 * 接口契约:
 *   GET /api/sensors                       → Sensor[]
 *   GET /api/sensors/{id}                  → Sensor
 *   GET /api/sensors/{id}/history?hours=24 → number[]
 *   GET /api/sensors/group/{group}         → Sensor[]
 *   WS  ws://host/sensors/realtime         → 实时推送 SensorReading
 *
 * 通信协议: WiFi（环境/能耗类）/ 星闪（安防/低功耗类）
 */
import { Sensor, SensorGroup, SensorReading } from './types';
import { MockData } from '../mock/mockData';

const DELAY = 260;
function delay<T>(data: T): Promise<T> {
  return new Promise(resolve => setTimeout(() => resolve(data), DELAY));
}

export class SensorApi {
  /** 获取全部传感器 */
  static async getSensors(): Promise<Sensor[]> {
    // TODO[后端对接]: GET /api/sensors
    return delay(MockData.sensors);
  }

  /** 按分组获取（环境/安防/能耗/其他） */
  static async getByGroup(group: SensorGroup): Promise<Sensor[]> {
    // TODO[后端对接]: GET /api/sensors/group/{group}
    return delay(MockData.sensors.filter(s => s.group === group));
  }

  /** 获取单个传感器详情 */
  static async getSensor(id: string): Promise<Sensor | undefined> {
    // TODO[后端对接]: GET /api/sensors/{id}
    return delay(MockData.sensors.find(s => s.id === id));
  }

  /** 获取历史趋势（默认 24 小时） */
  static async getHistory(id: string, hours: number = 24): Promise<number[]> {
    // TODO[后端对接]: GET /api/sensors/{id}/history?hours={hours}
    const s = MockData.sensors.find(x => x.id === id);
    return delay(s ? s.history : []);
  }

  /**
   * 订阅实时数据推送（WebSocket / 星闪广播）
   * TODO[后端对接]: 建立 ws://host/sensors/realtime 长连接
   * @param onReading 每次收到数据的回调
   * @returns 取消订阅函数
   */
  static subscribeRealtime(onReading: (id: string, reading: SensorReading) => void): () => void {
    // TODO[后端对接]: 替换为真实 WebSocket 订阅
    // 本地预览: 模拟每 3 秒推送一次随机波动
    const timer = setInterval(() => {
      MockData.sensors.forEach(s => {
        const fluctuation = (Math.random() - 0.5) * 0.4;
        const nextVal: number = s.current.value + fluctuation;
        const digits: number = s.current.unit === '触发' || s.current.unit === '关闭' ? 0 : 1;
        const reading: SensorReading = {
          value: parseFloat(nextVal.toFixed(digits)),
          unit: s.current.unit,
          timestamp: Date.now()
        };
        s.current = reading;
        onReading(s.id, s.current);
      });
    }, 3000);
    return () => clearInterval(timer);
  }

  /** 获取告警中的传感器 */
  static async getAlerts(): Promise<Sensor[]> {
    // TODO[后端对接]: GET /api/sensors?alert=true
    return delay(MockData.sensors.filter(s => s.isAlert));
  }
}
