/** 将数据库操作、安全事件和鉴权状态规范成日志统计页数据。 */
import { Http } from './http';
import { AlertMessage } from './types';
import { normalizeAlert } from './adapter';

interface OperationResponse {
  id?: string;
  device_id?: string;
  action?: string;
  result?: string;
  source?: string;
  timestamp?: string | number;
}

interface OperationListResponse {
  operations?: OperationResponse[];
  total?: number;
}

interface AlertListResponse {
  alerts?: Record<string, Object>[];
  total?: number;
}

interface SecurityEventResponse {
  id?: number | string;
  ruleId?: string;
  rule_id?: string;
  severity?: string;
  category?: string;
  inputText?: string;
  input_text?: string;
  matchedText?: string;
  matched_text?: string;
  reason?: string;
  source?: string;
  blocked?: boolean;
  timestamp?: string | number;
}

interface SecurityEventsResponse {
  total?: number;
  events?: SecurityEventResponse[];
}

interface SeverityCountResponse {
  Critical?: number;
  High?: number;
  Medium?: number;
  Low?: number;
}

interface SecurityStatsResponse {
  today?: number;
  total?: number;
  bySeverity?: SeverityCountResponse;
  by_severity?: SeverityCountResponse;
  total_rules?: number;
  critical_rules?: number;
  high_rules?: number;
  medium_rules?: number;
}

interface AuthStatusResponse {
  enableAuth?: boolean;
  enable_auth?: boolean;
  doorPasswordRequired?: boolean;
  door_password_required?: boolean;
  sharedKeySet?: boolean;
  shared_key_set?: boolean;
  authAlgorithm?: string;
  auth_algorithm?: string;
  doorPasswordAlgorithm?: string;
  door_password_algorithm?: string;
}

export interface SecurityLogStats {
  available: boolean;
  today: number;
  total: number;
  critical: number;
  high: number;
  medium: number;
  low: number;
}

export interface EdgeAuthStatus {
  available: boolean;
  enableAuth: boolean;
  doorPasswordRequired: boolean;
  sharedKeySet: boolean;
  authAlgorithm: string;
  doorPasswordAlgorithm: string;
}

export interface LogSnapshot {
  available: boolean;
  complete: boolean;
  alerts: AlertMessage[];
  securityStats: SecurityLogStats;
  authStatus: EdgeAuthStatus;
}

function operationTime(value: string | number | undefined): number {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const normalized = value.replace(' ', 'T');
    const hasTimezone = normalized.endsWith('Z') || /[+-]\d{2}:\d{2}$/.test(normalized);
    const parsed = Date.parse(hasTimezone ? normalized : normalized + 'Z');
    if (parsed === parsed) return parsed;
  }
  return 0;
}

function operationMessage(raw: OperationResponse, index: number): AlertMessage {
  const timestamp = operationTime(raw.timestamp);
  const result = raw.result || 'unknown';
  const action = raw.action || 'operation';
  const device = raw.device_id || raw.source || '系统';
  return {
    id: raw.id || `operation_${device}_${timestamp}_${index}`,
    source: device,
    content: `${action} / ${result}`,
    level: result === 'ok' || result === 'success' ? 'info' : 'warning',
    timestamp: timestamp,
    isRead: true
  };
}

function securityLevel(value: string | undefined): 'info' | 'warning' | 'danger' {
  const level = (value || '').toLowerCase();
  if (level === 'critical' || level === 'high') return 'danger';
  if (level === 'medium') return 'warning';
  return 'info';
}

function securityMessage(raw: SecurityEventResponse, index: number): AlertMessage {
  const timestamp = operationTime(raw.timestamp);
  const rule = raw.ruleId || raw.rule_id || raw.category || 'security';
  const matchedText = raw.matchedText || raw.matched_text || '';
  const detail = matchedText ? `${raw.reason || '安全事件'} / 命中 ${matchedText}` : raw.reason || '安全事件';
  return {
    id: `security_${raw.id === undefined ? index : raw.id}`,
    source: raw.source || raw.category || '安全护栏',
    content: `[${rule}] ${detail}`,
    level: securityLevel(raw.severity),
    timestamp: timestamp,
    isRead: raw.blocked !== true
  };
}

function isToday(timestamp: number): boolean {
  if (timestamp <= 0) return false;
  const date = new Date(timestamp);
  const now = new Date();
  return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate();
}

function statsFromEvents(events: SecurityEventResponse[]): SecurityLogStats {
  let today = 0;
  let critical = 0;
  let high = 0;
  let medium = 0;
  let low = 0;
  for (const event of events) {
    if (isToday(operationTime(event.timestamp))) today++;
    const severity = (event.severity || '').toLowerCase();
    if (severity === 'critical') critical++;
    else if (severity === 'high') high++;
    else if (severity === 'medium') medium++;
    else low++;
  }
  return {
    available: true,
    today: today,
    total: events.length,
    critical: critical,
    high: high,
    medium: medium,
    low: low
  };
}

function emptySecurityStats(): SecurityLogStats {
  return { available: false, today: 0, total: 0, critical: 0, high: 0, medium: 0, low: 0 };
}

function emptyAuthStatus(): EdgeAuthStatus {
  return {
    available: false,
    enableAuth: false,
    doorPasswordRequired: false,
    sharedKeySet: false,
    authAlgorithm: '',
    doorPasswordAlgorithm: ''
  };
}

export class LogApi {
  static async getOperations(): Promise<AlertMessage[]> {
    const text = await Http.get('/api/operations');
    if (!text) return [];
    try {
      const parsed = JSON.parse(text) as Object;
      const data = Array.isArray(parsed) ? parsed as OperationResponse[] :
        (parsed as OperationListResponse).operations || [];
      return data.map((raw: OperationResponse, index: number): AlertMessage => operationMessage(raw, index));
    } catch (e) {
      return [];
    }
  }

  static async getSnapshot(): Promise<LogSnapshot> {
    const alertRequest = Http.get('/api/alerts');
    const operationRequest = Http.get('/api/operations?days=7');
    const eventRequest = Http.get('/api/security/events?limit=50');
    const statsRequest = Http.get('/api/security/stats');
    const authRequest = Http.get('/api/security/auth-status');

    const alertText = await alertRequest;
    const operationText = await operationRequest;
    const eventText = await eventRequest;
    const statsText = await statsRequest;
    const authText = await authRequest;
    const alerts: AlertMessage[] = [];
    let securityEvents: SecurityEventResponse[] = [];
    let securityEventsAvailable = false;
    let successCount = 0;

    if (alertText) {
      try {
        const parsed = JSON.parse(alertText) as Object;
        const data = Array.isArray(parsed) ? parsed as Record<string, Object>[] :
          (parsed as AlertListResponse).alerts || [];
        for (const raw of data) alerts.push(normalizeAlert(raw));
        successCount++;
      } catch (e) {
      }
    }
    if (operationText) {
      try {
        const parsed = JSON.parse(operationText) as Object;
        const data = Array.isArray(parsed) ? parsed as OperationResponse[] :
          (parsed as OperationListResponse).operations || [];
        for (let index = 0; index < data.length; index++) alerts.push(operationMessage(data[index], index));
        successCount++;
      } catch (e) {
      }
    }
    if (eventText) {
      try {
        const parsed = JSON.parse(eventText) as Object;
        securityEvents = Array.isArray(parsed) ? parsed as SecurityEventResponse[] :
          (parsed as SecurityEventsResponse).events || [];
        for (let index = 0; index < securityEvents.length; index++) {
          alerts.push(securityMessage(securityEvents[index], index));
        }
        securityEventsAvailable = true;
        successCount++;
      } catch (e) {
      }
    }

    let securityStats = securityEventsAvailable ? statsFromEvents(securityEvents) : emptySecurityStats();
    if (statsText) {
      try {
        const data = JSON.parse(statsText) as SecurityStatsResponse;
        const levels = data.bySeverity || data.by_severity;
        if (typeof data.today === 'number' && typeof data.total === 'number' && levels !== undefined) {
          securityStats = {
            available: true,
            today: data.today,
            total: data.total,
            critical: levels.Critical || 0,
            high: levels.High || 0,
            medium: levels.Medium || 0,
            low: levels.Low || 0
          };
        }
        if (typeof data.total_rules === 'number' || typeof data.total === 'number') successCount++;
      } catch (e) {
      }
    }

    let authStatus = emptyAuthStatus();
    if (authText) {
      try {
        const data = JSON.parse(authText) as AuthStatusResponse;
        const enableAuth = typeof data.enableAuth === 'boolean' ? data.enableAuth : data.enable_auth;
        const doorPasswordRequired = typeof data.doorPasswordRequired === 'boolean' ?
          data.doorPasswordRequired : data.door_password_required;
        const sharedKeySet = typeof data.sharedKeySet === 'boolean' ? data.sharedKeySet : data.shared_key_set;
        if (typeof enableAuth === 'boolean' && typeof doorPasswordRequired === 'boolean' &&
          typeof sharedKeySet === 'boolean') {
          authStatus = {
            available: true,
            enableAuth: enableAuth,
            doorPasswordRequired: doorPasswordRequired,
            sharedKeySet: sharedKeySet,
            authAlgorithm: data.authAlgorithm || data.auth_algorithm || '',
            doorPasswordAlgorithm: data.doorPasswordAlgorithm || data.door_password_algorithm || ''
          };
          successCount++;
        }
      } catch (e) {
      }
    }

    alerts.sort((a: AlertMessage, b: AlertMessage) => b.timestamp - a.timestamp);
    return {
      available: successCount > 0,
      complete: successCount === 5,
      alerts: alerts,
      securityStats: securityStats,
      authStatus: authStatus
    };
  }
}
