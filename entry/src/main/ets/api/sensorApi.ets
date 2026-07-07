/**
 * 传感器数据 API · 对接设备端网关
 * 策略: HTTP 优先，失败降级到 MockData
 */
import { Sensor, SensorGroup, SensorReading } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';
import { normalizeSensor } from './adapter';

/** 传感器历史数据点 */
interface SensorHistoryPoint {
  value: number;
  time: string;
}

/** 温湿度历史响应 */
interface TempHumidHistory {
  temp: number[];
  humid: number[];
  labels: string[];
}

export class SensorApi {
  /** 获取全部传感器 */
  static async getSensors(): Promise<Sensor[]> {
    const remote = await Http.get('/api/sensors');
    if (remote) {
      try {
        const data = JSON.parse(remote) as Record<string, Object>[];
        return data.map((item: Record<string, Object>) => normalizeSensor(item));
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

  /** 获取历史趋势 (真实数据) */
  static async getHistory(id: string, hours: number = 24): Promise<number[]> {
    const remote = await Http.get('/api/sensors/history');
    if (remote) {
      try {
        const data = JSON.parse(remote) as Record<string, SensorHistoryPoint[]>;
        const key = id === 'temp_01' ? 'temp' : id === 'humid_01' ? 'humid' : '';
        if (key && data[key]) {
          return data[key].map((p: SensorHistoryPoint) => p.value);
        }
      } catch (e) {
        // 降级
      }
    }
    const s = MockData.sensors.find(x => x.id === id);
    return s ? s.history : [];
  }

  /** 获取温湿度历史 (完整结构,含时间标签) */
  static async getTempHumidHistory(): Promise<TempHumidHistory> {
    const remote = await Http.get('/api/sensors/history');
    if (remote) {
      try {
        const data = JSON.parse(remote) as Record<string, SensorHistoryPoint[]>;
        if (data.temp && data.temp.length > 0) {
          const result: TempHumidHistory = {
            temp: data.temp.map((p: SensorHistoryPoint) => p.value),
            humid: data.humid ? data.humid.map((p: SensorHistoryPoint) => p.value) : [],
            labels: data.temp.map((p: SensorHistoryPoint) => p.time)
          };
          return result;
        }
      } catch (e) {
        // 降级
      }
    }
    // 降级: 返回 mock
    const fallback: TempHumidHistory = {
      temp: [22.5, 22.0, 21.8, 22.1, 23.0, 24.1, 25.2, 26.0, 26.5, 25.8, 24.3, 23.1],
      humid: [58, 60, 62, 61, 56, 52, 48, 45, 43, 46, 50, 55],
      labels: ['0', '2', '4', '6', '8', '10', '12', '14', '16', '18', '20', '22']
    };
    return fallback;
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
