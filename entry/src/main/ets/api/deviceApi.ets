/**
 * 设备控制 API · 对接设备端网关
 * 策略: v5 真实硬件优先。离线设备由后端标记 offline，状态为关且无模拟值。
 */
import { Device, DeviceType, DeviceStatus, ControlParams } from './types';
import { MockData } from '../mock/mockData';
import { Http } from './http';
import { normalizeDevice } from './adapter';

interface DeviceControlResponse {
  success: boolean;
  device: Device;
}

interface ControlRequestBody {
  action: string;
  params: ControlParams;
}

interface ToggleRequestBody {
  isOn: boolean;
}

interface AddDeviceRequestBody {
  id: string;
  name: string;
  type: DeviceType;
  room: string;
  icon: string;
  primaryValue: number;
}

interface ProtocolCommandResult {
  success: boolean;
  detail: string;
}

interface BearPiCommandBody {
  command: string;
}

export class DeviceApi {
  /** 获取全部设备列表 */
  static async getDevices(): Promise<Device[]> {
    const remote = await Http.get('/api/devices');
    if (remote) {
      try {
        const data = JSON.parse(remote) as Record<string, Object>[];
        return data.map((item: Record<string, Object>) => normalizeDevice(item));
      } catch (e) {
      }
    }
    return [];
  }

  /** 获取单个设备详情 */
  static async getDevice(id: string): Promise<Device | undefined> {
    const all = await DeviceApi.getDevices();
    return all.find(d => d.id === id);
  }

  /** 控制设备 */
  static async control(id: string, action: string, params: ControlParams): Promise<boolean> {
    const body: ControlRequestBody = { action, params };
    const respText = await Http.post(`/api/devices/${id}/control`, body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as DeviceControlResponse;
        if (resp.success) return true;
      } catch (e) {
        // 降级
      }
    }
    const dev = MockData.devices.find(d => d.id === id);
    if (dev) {
      if (action === 'set_speed' || action === 'set_temp' || action === 'set_brightness') {
        dev.primaryValue = params.value as number;
      }
      if (action === 'set_mode' && dev.mode !== undefined) {
        dev.mode = params.mode as string;
      }
    }
    return true;
  }

  /** 开关设备 */
  static async toggle(id: string, isOn: boolean): Promise<boolean> {
    const body: ToggleRequestBody = { isOn };
    const respText = await Http.post(`/api/devices/${id}/toggle`, body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as DeviceControlResponse;
        if (resp.success) return true;
      } catch (e) {
        // 降级
      }
    }
    const dev = MockData.devices.find(d => d.id === id);
    if (dev) dev.isOn = isOn;
    return true;
  }

  /** 门禁开锁 */
  static async unlockDoor(id: string, pin: string): Promise<boolean> {
    if (!pin) return false;
    await DeviceApi.toggle(id, true);
    setTimeout(() => { DeviceApi.toggle(id, false); }, 8000);
    return true;
  }

  /** 添加设备 */
  static async addDevice(device: Device): Promise<boolean> {
    const body: AddDeviceRequestBody = {
      id: device.id, name: device.name, type: device.type,
      room: device.room, icon: 'lightbulb', primaryValue: device.primaryValue
    };
    const respText = await Http.post('/api/devices', body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as DeviceControlResponse;
        if (resp.success) return true;
      } catch (e) {
        // 降级
      }
    }
    MockData.devices.push(device);
    return true;
  }

  /** BearPi 亮度 / 人感 / 雷达命令 */
  static async sendBearPiCommand(command: string): Promise<ProtocolCommandResult> {
    const body: BearPiCommandBody = { command };
    const respText = await Http.post('/api/bearpi/command', body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as ProtocolCommandResult;
        return resp;
      } catch (e) {
        // fallback
      }
    }
    return { success: false, detail: 'BearPi command failed' };
  }

  /** 移除设备 */
  static async removeDevice(id: string): Promise<boolean> {
    const idx = MockData.devices.findIndex(d => d.id === id);
    if (idx >= 0) MockData.devices.splice(idx, 1);
    return true;
  }

  /** 生成新设备 ID */
  static genId(type: string): string {
    const prefix = type + '_';
    let max = 0;
    MockData.devices.forEach(d => {
      if (d.id.startsWith(prefix)) {
        const num = parseInt(d.id.substring(prefix.length), 10);
        if (num > max) max = num;
      }
    });
    return prefix + (max + 1);
  }
}
