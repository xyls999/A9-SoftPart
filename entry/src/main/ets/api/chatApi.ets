/**
 * 大模型对话 API · 对接 A9 网关当前配置的 AI 服务。
 * 策略: HTTP POST /api/chat/send 获取真实回复
 * 流式: 网关返回完整文本，前端模拟逐字打字效果
 */
import { ChartData, ChatMessage, ChatRole } from './types';
import { Http } from './http';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'SmartHomeChat';

let msgIdCounter = 100;

interface ChatSendRequest {
  message: string;
  messages: ChatPayloadMessage[];
}

interface ChatPayloadMessage {
  role: string;
  content: string;
}

interface ChatReplyResponse {
  reply?: string;
  role?: string;
  provider?: string;
  source?: string;
  tts_audio?: string;
  error?: string;
  code?: number;
  chartData?: ChartData;
}

interface VoiceInputRequest {
  audio_base64: string;
}

interface VoiceInputResponse {
  text?: string;
  transcript?: string;
  message?: string;
  error?: string;
}

interface TtsSpeakResponse {
  ok?: boolean;
  played?: boolean;
  backend?: string;
}

interface TtsSpeakRequest {
  text: string;
  speed: number;
}

interface AiModelConfig {
  model?: string;
}

interface AiConfigResponse {
  provider?: string;
  models?: Record<string, AiModelConfig>;
}

interface TtsConfigResponse {
  enabled?: boolean;
  backend?: string;
}

export interface ChatBackendStatus {
  provider: string;
  model: string;
  ttsBackend: string;
  ttsEnabled: boolean;
}

export class ChatApi {
  private static expectedChartType(text: string): string {
    if (text.includes('对话来源')) return 'chat_source_pie';
    if (text.includes('操作时段') || text.includes('操作热力')) return 'ops_heatmap';
    if (text.includes('安全趋势')) return 'security_trend';
    if (text.includes('设备分布') || text.includes('设备类型')) return 'device_pie';
    if (text.includes('设备状态') || text.includes('房间设备')) return 'device_status_bar';
    if (text.includes('区域状态') || text.includes('区域健康')) return 'area_radar';
    if (text.includes('能耗') || text.includes('用电')) return 'energy_bar';
    if (text.includes('温度')) return 'temp_line';
    if (text.includes('湿度')) return 'humid_line';
    if (text.includes('安全')) return 'security_pie';
    if (text.includes('AI对话') || text.includes('对话趋势')) return 'chat_line';
    if (text.includes('设备操作') || text.includes('操作统计')) return 'ops_bar';
    if (text.includes('在线率') || text.includes('设备在线')) return 'online_area';
    if (text.includes('今日实时') || text.includes('今日统计')) return 'today_gauge';
    if (text.includes('请求趋势') || text.includes('七日趋势')) return 'daily_line';
    if (text.includes('七日统计') || text.includes('请求统计')) return 'daily_bar';
    if (text.includes('综合') || text.includes('概览') || text.includes('总览')) return 'overview';
    return '';
  }

  private static async alignChartData(text: string, current: ChartData | undefined): Promise<ChartData | undefined> {
    const expected = ChatApi.expectedChartType(text);
    if (!expected || current?.chart_type === expected) return current;
    const raw = await Http.get(`/api/log/chart?type=${expected}&days=7`);
    if (!raw) return current;
    try {
      const aligned = JSON.parse(raw) as ChartData;
      return aligned.charts && aligned.charts.length > 0 ? aligned : current;
    } catch (e) {
      return current;
    }
  }

  /** 获取后端完整回复，由需要自行控制呈现节奏的页面使用。 */
  static async sendComplete(messages: ChatMessage[]): Promise<ChatMessage> {
    let currentMessage = '';
    let currentContext = '';
    for (let index = messages.length - 1; index >= 0; index--) {
      if (messages[index].role === ChatRole.USER && messages[index].content.trim().length > 0) {
        currentMessage = messages[index].content.trim();
        currentContext = messages[index].context ? messages[index].context?.trim() || '' : '';
        break;
      }
    }
    if (!currentMessage) throw new Error('请输入消息');
    const body: ChatSendRequest = {
      message: currentContext.length > 0 ?
        `${currentMessage}\n\n[前端图表结构化数据]\n${currentContext}` : currentMessage,
      messages: messages.map((message: ChatMessage): ChatPayloadMessage => ({
        role: message.role,
        content: message.context && message.context.trim().length > 0 ?
          `${message.content}\n\n[前端图表结构化数据]\n${message.context}` : message.content
      }))
    };
    hilog.info(DOMAIN, TAG, `sendComplete start, msgs=${messages.length}`);

    const respText = await ChatApi.raceTimeout(Http.post('/api/chat/send', body), 45000);
    if (!respText) throw new Error('智能服务暂时无法连接，请稍后再试');

    let reply: string = '';
    let backendError: string = '';
    let chartData: ChartData | undefined = undefined;
    try {
      const resp = JSON.parse(respText) as ChatReplyResponse;
      backendError = resp.error || '';
      reply = resp.reply ? resp.reply.trim() : '';
      chartData = resp.chartData;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `JSON parse failed, raw: ${respText.substring(0, 80)}`);
      throw new Error('AI 后端返回格式异常');
    }
    if (!reply && backendError) throw new Error(backendError);
    if (!reply) throw new Error('AI 后端没有返回 reply');
    chartData = await ChatApi.alignChartData(currentMessage, chartData);
    if (currentContext.length > 0 && !ChatApi.isChartAwareReply(reply)) {
      reply = ChatApi.chartFallback(currentContext);
    }

    hilog.info(DOMAIN, TAG, `got complete reply, len=${reply.length}`);
    return {
      id: 'msg_' + (msgIdCounter++),
      role: ChatRole.ASSISTANT,
      content: reply,
      timestamp: Date.now(),
      chartData: chartData
    };
  }

  /**
   * 发送消息（流式打字效果）
   * 先从网关获取完整回复，再逐字吐出模拟流式
   * 关键修复: 无论 HTTP 成功或失败，onDone 必定被调用
   */
  static async sendStream(
    messages: ChatMessage[],
    onToken: (token: string) => void,
    onDone: (full: ChatMessage) => void
  ): Promise<void> {
    hilog.info(DOMAIN, TAG, `sendStream start, msgs=${messages.length}`);
    const fullMessage = await ChatApi.sendComplete(messages);
    const reply = fullMessage.content;

    hilog.info(DOMAIN, TAG, `starting typewriter, reply len=${reply.length}`);
    let i = 0;
    return new Promise<void>(resolve => {
      const timer = setInterval(() => {
        if (i >= reply.length) {
          clearInterval(timer);
          onDone(fullMessage);
          hilog.info(DOMAIN, TAG, `typewriter done`);
          resolve();
          return;
        }
        const step = reply[i] === ' ' ? 2 : 1;
        onToken(reply.slice(0, i + step));
        i += step;
      }, 35);
    });
  }

  /**
   * 超时竞速: 如果 promise 在 ms 内未完成，返回 null
   * 防止 Http.post 永久挂起导致聊天卡死
   */
  private static raceTimeout(promise: Promise<string | null>, ms: number): Promise<string | null> {
    return new Promise<string | null>(resolve => {
      let done = false;
      const timer = setTimeout(() => {
        if (!done) {
          done = true;
          hilog.warn(DOMAIN, TAG, `raceTimeout fired after ${ms}ms`);
          resolve(null);
        }
      }, ms);
      promise.then(result => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(result);
        }
      }).catch(() => {
        if (!done) {
          done = true;
          clearTimeout(timer);
          resolve(null);
        }
      });
    });
  }

  private static isChartAwareReply(reply: string): boolean {
    if (reply.includes('未配置AI') || reply.includes('AI暂时不可用')) return false;
    return reply.includes('请求') || reply.includes('AI对话') || reply.includes('AI消息') || reply.includes('设备操作') ||
      reply.includes('安全事件') || reply.includes('图表') || reply.includes('趋势');
  }

  private static chartFallback(context: string): string {
    const lines = context.split('\n');
    let summary = '';
    for (const line of lines) {
      if (line.startsWith('前端校验摘要：')) {
        summary = line.substring('前端校验摘要：'.length);
        break;
      }
    }
    if (!summary) summary = '图表数据已收到，但当前数据不足以生成可靠趋势结论';
    return `图表分析\n${summary}\n\n数据来源：后端实时 ECharts 图表接口。`;
  }

  /** 上传 base64 音频并返回后端真实识别文字。 */
  static async voiceToText(audioBase64: string): Promise<string> {
    const audio = audioBase64.trim();
    if (!audio) return '';
    const body: VoiceInputRequest = { audio_base64: audio };
    const text = await Http.post('/api/voice/input', body);
    if (!text) return '';
    try {
      const response = JSON.parse(text) as VoiceInputResponse;
      return (response.text || response.transcript || response.message || '').trim();
    } catch (e) {
      return '';
    }
  }

  /** 调用后端 TTS 播报文本 */
  static async speak(text: string): Promise<boolean> {
    if (!text.trim()) return false;
    const body: TtsSpeakRequest = { text, speed: 5 };
    const respText = await Http.post('/api/tts/speak', body);
    if (respText) {
      try {
        const resp = JSON.parse(respText) as TtsSpeakResponse;
        return resp.ok === true || resp.played === true;
      } catch (e) {
      }
    }
    return false;
  }

  /** 兼容旧调用：文字转语音 */
  static async textToVoice(text: string): Promise<string> {
    await ChatApi.speak(text);
    return '';
  }

  /** 获取 AI/TTS 后端状态，用于原有顶部状态文案 */
  static async getBackendStatus(): Promise<ChatBackendStatus> {
    const status: ChatBackendStatus = {
      provider: '暂无',
      model: '暂无',
      ttsBackend: '暂无',
      ttsEnabled: false
    };

    const aiText = await Http.get('/api/ai/config');
    if (aiText) {
      try {
        const ai = JSON.parse(aiText) as AiConfigResponse;
        status.provider = ai.provider || status.provider;
        const modelConfig = ai.models ? ai.models[status.provider] : undefined;
        status.model = modelConfig?.model || status.model;
      } catch (e) {
      }
    }

    const ttsText = await Http.get('/api/tts/config');
    if (ttsText) {
      try {
        const tts = JSON.parse(ttsText) as TtsConfigResponse;
        status.ttsBackend = tts.backend || status.ttsBackend;
        status.ttsEnabled = tts.enabled !== false;
      } catch (e) {
      }
    }

    return status;
  }

  /** 欢迎语 */
  static getWelcome(): string {
    return '你好，我是明日家居。你可以直接输入问题，我会为你处理。';
  }
}
