/**
 * 设备控制 API · 对接设备端网关
 * 策略: v6.1 真实硬件优先。离线设备由后端标记 offline，控制失败不伪造成功状态。
 */
import { Device, DeviceType, DeviceStatus, ControlParams } from './types';
import { Http } from './http';
import { normalizeDevice } from './adapter';

interface DeviceMutationResult {
  success?: boolean;
  data?: Object;
}

interface DeviceControlResponse {
  success?: boolean;
  device?: Device;
  result?: DeviceMutationResult;
  error?: string;
}

interface DeviceListResponse {
  devices?: Record<string, Object>[];
  total?: number;
}

interface ControlRequestBody {
  action: string;
  params: ControlParams;
}

interface ToggleRequestBody {
  isOn: boolean;
  doorPassword?: string;
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

export interface DeviceSnapshot {
  available: boolean;
  devices: Device[];
}

export class DeviceApi {
  /** 获取全部设备列表 */
  static async getDevices(): Promise<Device[]> {
    return (await DeviceApi.getDeviceSnapshot()).devices;
  }

  /** 获取设备列表及接口可用状态，空数组不再和请求失败混为一谈。 */
  static async getDeviceSnapshot(): Promise<DeviceSnapshot> {
    const remote = await Http.get('/api/devices');
    if (remote) {
      try {
        const parsed = JSON.parse(remote) as Object;
        const data = Array.isArray(parsed) ? parsed as Record<string, Object>[] :
          (parsed as DeviceListResponse).devices || [];
        return {
          available: true,
          devices: data.map((item: Record<string, Object>) => normalizeDevice(item))
        };
      } catch (e) {
      }
    }
    return { available: false, devices: [] };
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
        if (resp.success === true || resp.result?.success === true) return true;
      } catch (e) {
      }
    }
    return false;
  }

  /** 开关设备 */
  static async toggle(id: string, isOn: boolean, doorPassword: string = ''): Promise<boolean> {
    const body: ToggleRequestBody = doorPassword.length > 0 ? { isOn: isOn, doorPassword: doorPassword } : { isOn: isOn };
    const respText = await Http.post(`/api/devices/${id}/toggle`, body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as DeviceControlResponse;
        if (resp.success === true || resp.result?.success === true) return true;
      } catch (e) {
      }
    }
    return false;
  }

  /** 门禁开锁 */
  static async unlockDoor(id: string, pin: string): Promise<boolean> {
    if (!pin) return false;
    return DeviceApi.toggle(id, true, pin);
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
        if (resp.success === true || resp.result?.success === true) return true;
      } catch (e) {
      }
    }
    return false;
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
    return false;
  }

  /** 生成新设备 ID */
  static genId(type: string): string {
    return type + '_' + Date.now();
  }
}
