/**
 * 传感器数据 API · 对接设备端网关
 * 策略: HTTP 优先，失败降级到 MockData
 */
import { Sensor, SensorGroup, SensorReading } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';

export class SensorApi {
  /** 获取全部传感器 */
  static async getSensors(): Promise<Sensor[]> {
    const remote = await Http.get('/api/sensors');
    if (remote) {
      try {
        return JSON.parse(remote) as Sensor[];
      } catch (e) {
        // 降级
      }
    }
    return MockData.sensors;
  }

  /** 按分组获取 */
  static async getByGroup(group: SensorGroup): Promise<Sensor[]> {
    const all = await SensorApi.getSensors();
    return all.filter(s => s.group === group);
  }

  /** 获取单个传感器详情 */
  static async getSensor(id: string): Promise<Sensor | undefined> {
    const all = await SensorApi.getSensors();
    return all.find(s => s.id === id);
  }

  /** 获取历史趋势 */
  static async getHistory(id: string, hours: number = 24): Promise<number[]> {
    const s = MockData.sensors.find(x => x.id === id);
    return s ? s.history : [];
  }

  /** 订阅实时数据（模拟推送） */
  static subscribeRealtime(onReading: (id: string, reading: SensorReading) => void): () => void {
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
    const all = await SensorApi.getSensors();
    return all.filter(s => s.isAlert);
  }
}
