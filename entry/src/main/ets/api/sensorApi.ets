/**
 * 传感器数据 API · 对接设备端网关
 * 策略: v5 真实硬件优先。离线传感器 current=null，前端显示离线且不补模拟值。
 */
import { Sensor, SensorGroup, SensorReading } from './types';
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
      }
    }
    return [];
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
    return [];
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
    const fallback: TempHumidHistory = {
      temp: [],
      humid: [],
      labels: []
    };
    return fallback;
  }

  /** 订阅实时数据：轮询 v5 真实状态，不再生成模拟波动 */
  static subscribeRealtime(onReading: (id: string, reading: SensorReading) => void): () => void {
    const timer = setInterval(() => {
      SensorApi.getSensors().then((sensors: Sensor[]) => {
        sensors.forEach((s: Sensor) => {
          if (s.current && s.current.unit !== '离线') {
            onReading(s.id, s.current);
          }
        });
      }).catch(() => {
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
